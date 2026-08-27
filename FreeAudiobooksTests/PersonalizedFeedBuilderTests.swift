//
//  PersonalizedFeedBuilderTests.swift
//  FreeAudiobooksTests
//
//  Created by OpenAI on 07/08/2026.
//

import CoreData
import FirebaseFirestore
import XCTest
@testable import FreeAudiobooks

final class PersonalizedFeedBuilderTests: XCTestCase {

    private var context: NSManagedObjectContext!
    private var storyEntity: NSEntityDescription!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let modelURL = try XCTUnwrap(
            Bundle(for: CDBookInternal.self).url(forResource: "FreeAudiobooks", withExtension: "momd")
        )
        let model = try XCTUnwrap(NSManagedObjectModel(contentsOf: modelURL))
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try coordinator.addPersistentStore(
            ofType: NSInMemoryStoreType,
            configurationName: nil,
            at: nil
        )

        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        storyEntity = try XCTUnwrap(model.entitiesByName["CDBookInternal"])
        ReadingUserDefaults.clearOffsets()
    }

    override func tearDown() {
        ReadingUserDefaults.clearOffsets()
        storyEntity = nil
        context = nil
        super.tearDown()
    }

    func testFailedSingleHeroCandidateRemainsAvailableToFallback() throws {
        let stories = makeStories(count: 18)
        let survivingHero = stories[12]
        configureAsValidHero(survivingHero)

        let sections = buildSections(stories: stories)
        let fallback = try XCTUnwrap(sections.first { $0.id == "hero-fallback-fantasy" })

        XCTAssertEqual(fallback.stories.count, 6)
        XCTAssertTrue(fallback.stories.contains { $0.contentUUID == survivingHero.contentUUID })
    }

    func testHeroSelectionUsesStableDailyShuffleAndCapsAtFive() throws {
        let stories = makeStories(count: 30)
        stories.forEach(configureAsValidHero)

        let firstSelection = try heroStoryIDs(from: buildSections(stories: stories, dailySeedOverride: 123))
        let repeatedSelection = try heroStoryIDs(from: buildSections(stories: stories, dailySeedOverride: 123))
        let nextSelection = try heroStoryIDs(from: buildSections(stories: stories, dailySeedOverride: 456))

        XCTAssertEqual(firstSelection.count, 5)
        XCTAssertEqual(firstSelection, repeatedSelection)
        XCTAssertNotEqual(firstSelection, nextSelection)
    }

    func testFailedTagShelfDoesNotStarvePopularityFallback() throws {
        let stories = makeStories(count: 30)
        let remainingStories = Array(stories[24...29])
        stories.prefix(10).forEach { $0.tagsData = ["too-narrow"] as NSArray }
        remainingStories.prefix(5).forEach { $0.tagsData = ["too-narrow"] as NSArray }
        let tag = try makeTag(tag: "too-narrow")

        let sections = buildSections(stories: stories, tags: [tag])
        let popularity = try XCTUnwrap(sections.first { $0.id == "popular-fantasy" })

        XCTAssertNil(sections.first { $0.id == "tag-too-narrow" })
        XCTAssertEqual(popularity.stories.map(\.contentUUID), remainingStories.map(\.contentUUID))
    }

    func testTagSelectionFallsBackToPartialAndPreventsReuse() throws {
        let stories = makeStories(count: 30)
        let remainingStories = Array(stories[24...29])
        stories.prefix(9).forEach { $0.tagsData = ["viable", "viable"] as NSArray }
        remainingStories.forEach { $0.tagsData = ["viable", "viable"] as NSArray }
        let tag = try makeTag(tag: "viable")

        let sections = buildSections(stories: stories, tags: [tag])
        let tagSection = try XCTUnwrap(sections.first { $0.id == "tag-viable" })
        let storyIDs = sections.flatMap(\.stories).map(\.contentUUID)

        XCTAssertEqual(tagSection.stories.map(\.contentUUID), remainingStories.map(\.contentUUID))
        XCTAssertNil(sections.first { $0.id == "popular-fantasy" })
        XCTAssertEqual(storyIDs.count, Set(storyIDs).count)
    }

    func testTagSelectionPrefersAFullRowOverEarlierPartialCandidate() throws {
        let stories = makeStories(count: 42)
        Array(stories[0...8] + stories[24...29]).forEach {
            $0.tagsData = ["partial"] as NSArray
        }
        Array(stories[9...11] + stories[30...41]).forEach {
            $0.tagsData = ["full"] as NSArray
        }
        // Temporarily give "partial" twelve unused books so we can find a seed where it is first
        // in the stable daily shuffle. We then restore its real six-book remainder below.
        stories[30...35].forEach { $0.tagsData = ($0.tags + ["partial"]) as NSArray }
        let tags = try [makeTag(tag: "partial"), makeTag(tag: "full")]
        let seedWithPartialFirst = try XCTUnwrap((1...100).first { seed in
            buildSections(stories: stories, tags: tags, dailySeedOverride: UInt64(seed))
                .first(where: { $0.tag != nil })?.id == "tag-partial"
        })
        stories[30...35].forEach { $0.tagsData = $0.tags.filter { $0 != "partial" } as NSArray }

        let tagSections = buildSections(stories: stories,
                                        tags: tags,
                                        dailySeedOverride: UInt64(seedWithPartialFirst))
            .filter { $0.tag != nil }

        XCTAssertEqual(tagSections.first?.id, "tag-full")
        XCTAssertEqual(tagSections.first?.stories.count, 12)
        XCTAssertEqual(tagSections.dropFirst().first?.id, "tag-partial")
        XCTAssertEqual(tagSections.dropFirst().first?.stories.count, 6)
    }

    func testTagSelectionIsStableForTheSameDailySeed() throws {
        let stories = makeStories(count: 60)
        let tagNames = ["alpha", "bravo", "charlie", "delta"]
        stories.forEach { $0.tagsData = tagNames as NSArray }
        let tags = try tagNames.map { try makeTag(tag: $0) }

        let firstSelection = buildSections(stories: stories, tags: tags, dailySeedOverride: 456)
            .filter { $0.tag != nil }
            .map(\.id)
        let repeatedSelection = buildSections(stories: stories, tags: tags, dailySeedOverride: 456)
            .filter { $0.tag != nil }
            .map(\.id)

        XCTAssertEqual(firstSelection.count, 3)
        XCTAssertEqual(firstSelection, repeatedSelection)
    }

    func testHomeTagNeedsFifteenBooksToEnterCandidatePool() throws {
        let stories = makeStories(count: 30)
        stories.suffix(14).forEach { $0.tagsData = ["fourteen-books"] as NSArray }
        let tag = try makeTag(tag: "fourteen-books")

        let sections = buildSections(stories: stories, tags: [tag])

        XCTAssertNil(sections.first { $0.id == "tag-fourteen-books" })
        XCTAssertNotNil(sections.first { $0.id == "popular-fantasy" })
    }

    func testHomeTagSelectionCanReachBeyondFormerTopTwentyPool() throws {
        let stories = makeStories(count: 30)
        let tags = (0...20).map { String(format: "tag-%02d", $0) }
        stories.forEach { $0.tagsData = tags as NSArray }
        let bookInternalTags = try tags.map { try makeTag(tag: $0) }

        let selectedTagIDs = (1...256).reduce(into: Set<String>()) { selectedTagIDs, seed in
            let sections = buildSections(
                stories: stories,
                tags: bookInternalTags,
                dailySeedOverride: UInt64(seed)
            )
            if let tagSection = sections.first(where: { $0.id.hasPrefix("tag-") }) {
                selectedTagIDs.insert(tagSection.id)
            }
        }

        XCTAssertTrue(selectedTagIDs.contains("tag-tag-20"))
    }

    func testTagBrowserRanksByVisibleBookCountThenTitle() throws {
        let stories = makeStories(count: 30)
        stories.prefix(14).forEach { $0.tagsData = ["large"] as NSArray }
        stories.prefix(10).forEach { story in
            story.tagsData = (story.tags + ["medium"]) as NSArray
        }
        stories.prefix(6).forEach { story in
            story.tagsData = (story.tags + ["alpha", "zulu"]) as NSArray
        }
        let tags = try [
            makeTag(tag: "alpha"),
            makeTag(tag: "medium"),
            makeTag(tag: "zulu"),
            makeTag(tag: "large")
        ]

        let sections = buildSections(stories: stories, tags: tags)
        let tagBrowser = try XCTUnwrap(sections.first { $0.id == "tag-browser-fantasy" })

        XCTAssertEqual(tagBrowser.previewTags.map(\.tag), ["large", "medium", "alpha", "zulu"])
    }

    func testTagBrowserSupportsSearchSpecificInventoryFloor() throws {
        let stories = makeStories(count: 5)
        stories.prefix(3).forEach { $0.tagsData = ["three-books"] as NSArray }
        stories.prefix(2).forEach { story in
            story.tagsData = (story.tags + ["two-books"]) as NSArray
        }
        let tags = try [makeTag(tag: "three-books"), makeTag(tag: "two-books")]

        let searchTags = PersonalizedHomeTagBrowserRanking.rankedTags(
            from: tags,
            visibleStories: stories,
            minimumBookCount: 3
        )
        let homeTags = PersonalizedHomeTagBrowserRanking.rankedTags(
            from: tags,
            visibleStories: stories
        )

        XCTAssertEqual(searchTags.map(\.tag), ["three-books"])
        XCTAssertTrue(homeTags.isEmpty)
    }

    func testMultipleFavoriteGenresUseUniqueTagBrowserSectionIDs() throws {
        let stories = makeStories(count: 24)
        stories[0...11].forEach { $0.tagsData = ["fantasy-tag"] as NSArray }
        stories[12...23].forEach {
            $0.genreString = BookInternalGenre.romance.rawValue
            $0.tagsData = ["romance-tag"] as NSArray
        }
        let tags = try [
            makeTag(tag: "fantasy-tag", genre: .fantasy),
            makeTag(tag: "romance-tag", genre: .romance)
        ]
        var builder = PersonalizedFeedBuilder(
            favoriteGenres: [.fantasy, .romance],
            allStories: stories,
            userIsSubscribed: false,
            userID: "multiple-tag-browser-test",
            tags: tags,
            genreCharts: [],
            completedBookUUIDs: [],
            dailySeedOverride: 123
        )

        let tagBrowserIDs = builder.buildSections()
            .filter { $0.kind == .tagBrowser }
            .map(\.id)

        XCTAssertEqual(Set(tagBrowserIDs), ["tag-browser-fantasy", "tag-browser-romance"])
        XCTAssertEqual(tagBrowserIDs.count, Set(tagBrowserIDs).count)
    }

    func testPersonalizedTopTenPreservesItsGenreSpecificTitle() {
        let title = "Top 10 Romance in the U.K."
        let presentation = PersonalizedHomeSectionPresentation(
            id: "top-romance",
            legacySectionUUID: nil,
            kind: .carousel,
            discoverSectionType: .thisWeeksTopTen,
            title: title,
            subtitle: nil,
            stories: [],
            genre: .romance,
            tag: nil
        )

        let section = presentation.asDiscoverSection(position: 0)

        XCTAssertEqual(section.dynamicTitle, title)

        let ordinaryPresentation = PersonalizedHomeSectionPresentation(
            id: "new-romance",
            legacySectionUUID: nil,
            kind: .carousel,
            discoverSectionType: .genre,
            title: "New in Romance",
            subtitle: nil,
            stories: [],
            genre: .romance,
            tag: nil
        )
        XCTAssertNil(ordinaryPresentation.asDiscoverSection(position: 1).dynamicTitle)
    }

    func testExploreInterleavesExistingPopularityBuckets() throws {
        let stories = makeStories(count: 36)
        stories[24...29].forEach { $0.genreString = BookInternalGenre.romance.rawValue }
        stories[30...35].forEach { $0.genreString = BookInternalGenre.thriller.rawValue }

        let sections = buildSections(stories: stories)
        let explore = try XCTUnwrap(sections.first { $0.id == "explore" })

        XCTAssertEqual(explore.stories.map(\.contentUUID), [
            "story-24", "story-30", "story-25", "story-31", "story-26", "story-32",
            "story-27", "story-33", "story-28", "story-34", "story-29", "story-35"
        ])
    }

    func testBecauseYouReadUsesOnlyTheSourceGenreBucket() throws {
        let stories = makeStories(count: 37)
        stories[24...36].forEach { $0.genreString = BookInternalGenre.romance.rawValue }

        let sections = buildSections(stories: stories, completedBookUUIDs: ["story-24"])
        let becauseYouRead = try XCTUnwrap(sections.first { $0.id == "because-you-read" })

        XCTAssertEqual(becauseYouRead.stories.count, 12)
        XCTAssertTrue(becauseYouRead.stories.allSatisfy { $0.genre == .romance })
        XCTAssertFalse(becauseYouRead.stories.contains { $0.contentUUID == "story-24" })
    }

    func testBecauseYouReadExcludesAllCompletedAndStartedStories() throws {
        let stories = makeStories(count: 40)
        stories[24...39].forEach { $0.genreString = BookInternalGenre.romance.rawValue }
        ReadingUserDefaults.setOffsetForBookWithUUID(
            "story-26",
            currentSection: 1,
            totalSections: 10,
            currentSectionYOffset: 0,
            currentSectionTotalYOffset: 1
        )

        let sections = buildSections(
            stories: stories,
            completedBookUUIDs: ["story-25", "story-24"]
        )
        let becauseYouRead = try XCTUnwrap(sections.first { $0.id == "because-you-read" })
        let storyIDs = Set(becauseYouRead.stories.map(\.contentUUID))

        XCTAssertTrue(storyIDs.isDisjoint(with: ["story-24", "story-25", "story-26"]))
    }

    func testEarlyAccessFormatterUsesPOSIXGregorianCalendar() throws {
        let formatter = DateFormatters.earlyAccessDateFormatter

        XCTAssertEqual(formatter.locale.identifier, "en_US_POSIX")
        XCTAssertEqual(formatter.calendar.identifier, .gregorian)
        XCTAssertEqual(formatter.string(from: try XCTUnwrap(formatter.date(from: "2026-08-15"))),
                       "2026-08-15")
    }

    func testPastTodayAndUnparseableUnlockDatesStayGenerallyAvailable() throws {
        let stories = makeStories(count: 30)
        stories[0].availableForAllDateString = unlockDateString(daysFromToday: -30)
        stories[1].availableForAllDateString = unlockDateString(daysFromToday: 0)
        stories[2].availableForAllDateString = "not-a-date"
        stories[3].availableForAllDateString = nil

        let sections = buildSections(stories: stories)
        let placedStoryIDs = Set(sections.flatMap(\.stories).map(\.contentUUID))

        XCTAssertNil(sections.first { $0.kind == .earlyAccess })
        for story in stories.prefix(4) {
            XCTAssertTrue(placedStoryIDs.contains(story.contentUUID))
        }
    }

    func testEarlyAccessShelfOrdersByUnlockDayForSubscribersAndNonSubscribers() throws {
        let stories = makeStories(count: 30)
        let dayOffsets = [9, 3, 12, 1, 7, 5, 14, 2, 8, 4, 10, 6, 13, 11]
        let earlyAccessStories = Array(stories.prefix(dayOffsets.count))
        for (story, offset) in zip(earlyAccessStories, dayOffsets) {
            story.availableForAllDateString = unlockDateString(daysFromToday: offset)
        }
        let expectedStoryIDs = zip(earlyAccessStories, dayOffsets)
            .sorted { $0.1 < $1.1 }
            .map { $0.0.contentUUID }
        let earlyAccessStoryIDs = Set(expectedStoryIDs)

        for userIsSubscribed in [false, true] {
            let sections = buildSections(stories: stories, userIsSubscribed: userIsSubscribed)
            let earlyAccess = try XCTUnwrap(sections.first { $0.kind == .earlyAccess })

            XCTAssertEqual(earlyAccess.stories.map(\.contentUUID), expectedStoryIDs)
            XCTAssertFalse(sections
                .filter { $0.kind != .earlyAccess }
                .flatMap(\.stories)
                .contains { earlyAccessStoryIDs.contains($0.contentUUID) })
        }
    }

    func testEarlyAccessShelfAppearsWithExactlyTenBooks() throws {
        let stories = makeStories(count: 30)
        let earlyAccessStories = Array(stories.prefix(PersonalizedHomeFeedRules.minimumEarlyAccessCount))
        for (index, story) in earlyAccessStories.enumerated() {
            story.availableForAllDateString = unlockDateString(daysFromToday: index + 1)
        }

        for userIsSubscribed in [false, true] {
            let sections = buildSections(stories: stories, userIsSubscribed: userIsSubscribed)
            let earlyAccess = try XCTUnwrap(sections.first { $0.kind == .earlyAccess })

            XCTAssertEqual(earlyAccess.stories.count, PersonalizedHomeFeedRules.minimumEarlyAccessCount)
        }
    }

    func testGenreSectionsRunNewThenChartThenHero() throws {
        let stories = makeStories(count: 40)
        stories.forEach(configureAsValidHero)
        let chart = GenreChart(id: "fantasy-chart",
                               genre: .fantasy,
                               bookIDs: (20..<30).map { "story-\($0)" })

        let sections = buildSections(stories: stories, genreCharts: [chart])
        let sectionIDs = sections.map(\.id)
        let newIndex = try XCTUnwrap(sectionIDs.firstIndex(of: "new-fantasy"))
        let chartIndex = try XCTUnwrap(sectionIDs.firstIndex(of: "top-fantasy"))
        let heroIndex = try XCTUnwrap(sectionIDs.firstIndex(of: "hero-fantasy"))

        XCTAssertLessThan(newIndex, chartIndex)
        XCTAssertLessThan(chartIndex, heroIndex)
    }

    func testChartKeepsAllTenBooksEvenWhenTheNewRowAlreadyUsedThem() throws {
        let stories = makeStories(count: 40)
        stories.forEach(configureAsValidHero)
        // Every one of these is among the twelve newest, so the "New in" row claims them first.
        let chartBookIDs = ["story-3", "story-7", "story-0", "story-11", "story-5",
                            "story-9", "story-1", "story-8", "story-2", "story-6"]
        let chart = GenreChart(id: "fantasy-chart", genre: .fantasy, bookIDs: chartBookIDs)

        let sections = buildSections(stories: stories, genreCharts: [chart])
        let chartSection = try XCTUnwrap(sections.first { $0.id == "top-fantasy" })

        XCTAssertEqual(chartSection.stories.map(\.contentUUID), chartBookIDs)
    }

    func testChartMarksItsBooksUsedForTheRowsBuiltAfterIt() throws {
        let stories = makeStories(count: 40)
        // Hero art on the ten charted books and on four others, none of which the "New in" row
        // claims first. The hero wants five books, so if the chart failed to reserve its own the
        // hero would fill all five slots from the combined pool instead of returning just these
        // four — a difference no shuffle can hide, whatever the daily seed.
        let chartBookIDs = (20..<30).map { "story-\($0)" }
        let heroOnlyBookIDs = (30..<34).map { "story-\($0)" }
        stories
            .filter { chartBookIDs.contains($0.contentUUID) || heroOnlyBookIDs.contains($0.contentUUID) }
            .forEach(configureAsValidHero)
        let chart = GenreChart(id: "fantasy-chart", genre: .fantasy, bookIDs: chartBookIDs)

        let sections = buildSections(stories: stories, dailySeedOverride: 4242, genreCharts: [chart])
        let heroSection = try XCTUnwrap(sections.first { $0.id == "hero-fantasy" })

        XCTAssertEqual(heroSection.stories.count, heroOnlyBookIDs.count)
        XCTAssertEqual(Set(heroSection.stories.map(\.contentUUID)), Set(heroOnlyBookIDs))
    }

    func testChartFallsBackToPopularityRowWhenItHoldsADuplicateOrForeignGenreBook() throws {
        let stories = makeStories(count: 40)
        stories.forEach(configureAsValidHero)
        var chartBookIDs = (20..<30).map { "story-\($0)" }

        chartBookIDs[9] = chartBookIDs[0]
        let duplicateChart = GenreChart(id: "fantasy-chart", genre: .fantasy, bookIDs: chartBookIDs)
        let duplicateSections = buildSections(stories: stories, genreCharts: [duplicateChart])
        XCTAssertNil(duplicateSections.first { $0.id == "top-fantasy" })
        XCTAssertNotNil(duplicateSections.first { $0.id == "popular-fantasy" })

        stories[29].genreString = BookInternalGenre.romance.rawValue
        let foreignGenreChart = GenreChart(id: "fantasy-chart",
                                           genre: .fantasy,
                                           bookIDs: (20..<30).map { "story-\($0)" })
        let foreignGenreSections = buildSections(stories: stories, genreCharts: [foreignGenreChart])
        XCTAssertNil(foreignGenreSections.first { $0.id == "top-fantasy" })
        XCTAssertNotNil(foreignGenreSections.first { $0.id == "popular-fantasy" })
    }

    func testChartFallsBackToPopularityRowWhenItDoesNotHoldExactlyTenBooks() throws {
        let stories = makeStories(count: 40)
        stories.forEach(configureAsValidHero)
        let chart = GenreChart(id: "fantasy-chart",
                               genre: .fantasy,
                               bookIDs: (20..<31).map { "story-\($0)" })

        let sections = buildSections(stories: stories, genreCharts: [chart])

        XCTAssertNil(sections.first { $0.id == "top-fantasy" })
        XCTAssertNotNil(sections.first { $0.id == "popular-fantasy" })
    }

    func testChartFallsBackToPopularityRowWhenAChartedBookIsUnavailable() throws {
        let stories = makeStories(count: 40)
        stories.forEach(configureAsValidHero)
        stories[25].availableForAllDateString = unlockDateString(daysFromToday: 14)
        let chart = GenreChart(id: "fantasy-chart",
                               genre: .fantasy,
                               bookIDs: (20..<30).map { "story-\($0)" })

        let sections = buildSections(stories: stories, genreCharts: [chart])
        let sectionIDs = sections.map(\.id)
        let popularityIndex = try XCTUnwrap(sectionIDs.firstIndex(of: "popular-fantasy"))
        let heroIndex = try XCTUnwrap(sectionIDs.firstIndex(of: "hero-fantasy"))

        XCTAssertNil(sections.first { $0.id == "top-fantasy" })
        XCTAssertLessThan(popularityIndex, heroIndex)
    }

    func testSearchObjectFiltersAndCopiesSelectedTag() throws {
        let stories = makeStories(count: 3)
        stories[0].tagsData = ["found-family"] as NSArray
        stories[1].tagsData = ["found-family", "quest"] as NSArray
        stories[2].tagsData = ["quest"] as NSArray
        let tag = try makeTag(tag: "found-family")
        let searchObject = CDBookInternalSearchObject()
        searchObject.genre = .fantasy
        searchObject.tag = tag

        let filteredIDs = searchObject.applyFiltersToStories(stories).map(\.contentUUID)
        let copiedSearchObject = searchObject.copy()

        XCTAssertEqual(filteredIDs, ["story-0", "story-1"])
        XCTAssertEqual(copiedSearchObject.tag, tag)
        XCTAssertEqual(copiedSearchObject.activeFilterCount, 2)
    }

    func testClearingGenreAlsoClearsItsSelectedTag() throws {
        let searchObject = CDBookInternalSearchObject()
        searchObject.genre = .fantasy
        searchObject.tag = try makeTag(tag: "quest")

        searchObject.removeFilter(byId: "genre")

        XCTAssertNil(searchObject.genre)
        XCTAssertNil(searchObject.tag)
    }

    private func unlockDateString(daysFromToday: Int) -> String {
        let day = Calendar.current.date(byAdding: .day, value: daysFromToday, to: Date()) ?? Date()
        return DateFormatters.earlyAccessDateFormatter.string(from: day)
    }

    private func buildSections(
        stories: [CDBookInternal],
        tags: [BookInternalTag] = [],
        dailySeedOverride: UInt64? = nil,
        completedBookUUIDs: [String] = [],
        userIsSubscribed: Bool = false,
        genreCharts: [GenreChart] = []
    ) -> [PersonalizedHomeSectionPresentation] {
        var builder = PersonalizedFeedBuilder(
            favoriteGenres: [.fantasy],
            allStories: stories,
            userIsSubscribed: userIsSubscribed,
            userID: "personalized-feed-builder-tests",
            tags: tags,
            genreCharts: genreCharts,
            completedBookUUIDs: completedBookUUIDs,
            dailySeedOverride: dailySeedOverride
        )
        return builder.buildSections()
    }

    private func heroStoryIDs(from sections: [PersonalizedHomeSectionPresentation]) throws -> [String] {
        try XCTUnwrap(sections.first { $0.id == "hero-fantasy" }).stories.map(\.contentUUID)
    }

    private func makeStories(count: Int) -> [CDBookInternal] {
        let publicationBase = Date(timeIntervalSince1970: 2_000_000_000)

        return (0..<count).map { index in
            let story = CDBookInternal(entity: storyEntity, insertInto: context)
            story.uuid = "story-\(index)"
            story.bookTypeString = BookInternalType.shortStory.rawValue
            story.title = "Story \(index)"
            story.blurb = "Test blurb"
            story.coverImageURLXL = "cover-xl-\(index)"
            story.coverImageURL = "cover-\(index)"
            story.coverImageURLThumbnail = "cover-thumbnail-\(index)"
            story.genreString = BookInternalGenre.fantasy.rawValue
            story.readerCount = Int32(count - index)
            story.datePublished = publicationBase.addingTimeInterval(TimeInterval(-index))
            story.dateUpdated = publicationBase
            story.datePersisted = publicationBase
            story.isHidden = false
            story.tagsData = [] as NSArray
            return story
        }
    }

    private func configureAsValidHero(_ story: CDBookInternal) {
        story.heroBackgroundImageURL = "hero-background"
        story.heroBackgroundImageURLXL = "hero-background-xl"
        story.heroLayout = HeroCarouselLayout.coverLeading.rawValue
        story.heroTitle = "Hero title"
        story.heroSubtitle = "Hero subtitle"
    }

    private func makeTag(tag: String,
                         genre: BookInternalGenre = .fantasy) throws -> BookInternalTag {
        try XCTUnwrap(BookInternalTag(id: tag, data: [
            BookInternalTagVariables.id.rawValue: tag,
            BookInternalTagVariables.genre.rawValue: genre.rawValue,
            BookInternalTagVariables.tag.rawValue: tag,
            BookInternalTagVariables.title.rawValue: tag,
            BookInternalTagVariables.isHomeEligible.rawValue: true,
            // Legacy backend data is intentionally ignored by the app model.
            "minInventory": 999
        ]))
    }
}

final class BookInternalTagManagerTests: XCTestCase {
    func testSuccessfulEmptyGenreIsCached() {
        let loader = ControlledBookInternalTagLoader()
        let manager = BookInternalTagManager(loader: loader)
        let first = expectation(description: "first empty result")

        manager.ensureHomeEligibleTags(for: .fantasy) { success, tags in
            XCTAssertTrue(success)
            XCTAssertTrue(tags.isEmpty)
            first.fulfill()
        }
        XCTAssertEqual(loader.genreRequests, [.fantasy])
        loader.completeGenre(.fantasy, with: .success([]))
        wait(for: [first], timeout: 1)

        let second = expectation(description: "cached empty result")
        manager.ensureHomeEligibleTags(for: .fantasy) { success, tags in
            XCTAssertTrue(success)
            XCTAssertTrue(tags.isEmpty)
            second.fulfill()
        }
        wait(for: [second], timeout: 1)
        XCTAssertEqual(loader.genreRequests, [.fantasy])
    }

    func testConcurrentSameGenreLoadsAreCoalesced() throws {
        let loader = ControlledBookInternalTagLoader()
        let manager = BookInternalTagManager(loader: loader)
        let first = expectation(description: "first waiter")
        let second = expectation(description: "second waiter")
        let tag = try makeManagerTag(id: "fantasy-cozy", genre: .fantasy, tag: "cozy")

        manager.ensureHomeEligibleTags(for: .fantasy) { success, tags in
            XCTAssertTrue(success)
            XCTAssertEqual(tags, [tag])
            first.fulfill()
        }
        manager.ensureHomeEligibleTags(for: .fantasy) { success, tags in
            XCTAssertTrue(success)
            XCTAssertEqual(tags, [tag])
            second.fulfill()
        }

        XCTAssertEqual(loader.genreRequests, [.fantasy])
        loader.completeGenre(.fantasy, with: .success([tag]))
        wait(for: [first, second], timeout: 1)
    }

    func testFailedGenreLoadCanRetry() throws {
        let loader = ControlledBookInternalTagLoader()
        let manager = BookInternalTagManager(loader: loader)
        let failure = expectation(description: "failure")

        manager.ensureHomeEligibleTags(for: .romance) { success, tags in
            XCTAssertFalse(success)
            XCTAssertTrue(tags.isEmpty)
            failure.fulfill()
        }
        loader.completeGenre(.romance, with: .failure(TestTagLoaderError.failed))
        wait(for: [failure], timeout: 1)

        let retry = expectation(description: "retry")
        let tag = try makeManagerTag(id: "romance-sweet", genre: .romance, tag: "sweet")
        manager.ensureHomeEligibleTags(for: .romance) { success, tags in
            XCTAssertTrue(success)
            XCTAssertEqual(tags, [tag])
            retry.fulfill()
        }
        XCTAssertEqual(loader.genreRequests, [.romance, .romance])
        loader.completeGenre(.romance, with: .success([tag]))
        wait(for: [retry], timeout: 1)
    }

    func testMultiGenreLoadRequestsOnlyMissingGenresAndPreservesOrder() throws {
        let loader = ControlledBookInternalTagLoader()
        let manager = BookInternalTagManager(loader: loader)
        let fantasy = try makeManagerTag(id: "fantasy-magic", genre: .fantasy, tag: "magic")
        let romance = try makeManagerTag(id: "romance-sweet", genre: .romance, tag: "sweet")
        let primed = expectation(description: "fantasy primed")

        manager.ensureHomeEligibleTags(for: .fantasy) { _, _ in primed.fulfill() }
        loader.completeGenre(.fantasy, with: .success([fantasy]))
        wait(for: [primed], timeout: 1)

        let combined = expectation(description: "combined genres")
        manager.ensureHomeEligibleTags(for: [.fantasy, .romance, .fantasy]) { success, tags in
            XCTAssertTrue(success)
            XCTAssertEqual(tags, [fantasy, romance])
            combined.fulfill()
        }
        XCTAssertEqual(loader.genreRequests, [.fantasy, .romance])
        loader.completeGenre(.romance, with: .success([romance]))
        wait(for: [combined], timeout: 1)
    }

    func testCustomerLoadDoesNotCreateCompleteAdminCache() throws {
        let loader = ControlledBookInternalTagLoader()
        let manager = BookInternalTagManager(loader: loader)
        let eligible = try makeManagerTag(id: "fantasy-magic", genre: .fantasy, tag: "magic")
        let ineligible = try makeManagerTag(id: "fantasy-draft",
                                            genre: .fantasy,
                                            tag: "draft",
                                            isHomeEligible: false)
        let customerLoaded = expectation(description: "customer loaded")

        manager.ensureHomeEligibleTags(for: .fantasy) { _, _ in customerLoaded.fulfill() }
        loader.completeGenre(.fantasy, with: .success([eligible]))
        wait(for: [customerLoaded], timeout: 1)
        XCTAssertNil(manager.adminBookInternalTag(for: eligible.tag, genre: .fantasy))

        let adminLoaded = expectation(description: "admin loaded")
        manager.ensureAllBookInternalTagsLoadedForAdmin { success, tags in
            XCTAssertTrue(success)
            XCTAssertEqual(Set(tags), Set([eligible, ineligible]))
            adminLoaded.fulfill()
        }
        XCTAssertEqual(loader.allTagRequestCount, 1)
        loader.completeAll(with: .success([eligible, ineligible]))
        wait(for: [adminLoaded], timeout: 1)
        XCTAssertEqual(manager.adminBookInternalTag(for: ineligible.tag, genre: .fantasy), ineligible)
    }

    func testSavedTagReconciliationHandlesEligibilityAndGenreChanges() throws {
        let original = try makeManagerTag(id: "shared-id", genre: .fantasy, tag: "quest")
        let disabled = try makeManagerTag(id: "shared-id",
                                          genre: .fantasy,
                                          tag: "quest",
                                          isHomeEligible: false)
        let moved = try makeManagerTag(id: "shared-id", genre: .romance, tag: "quest")
        var cache = BookInternalTagCache()
        cache.storeEligibleTags([original], for: .fantasy)
        cache.storeEligibleTags([], for: .romance)
        cache.storeAllAdminTags([original])

        cache.reconcileSavedTag(disabled)
        XCTAssertEqual(cache.eligibleTags(for: .fantasy), [])
        XCTAssertEqual(cache.adminTag(for: "quest", genre: .fantasy), disabled)

        cache.reconcileSavedTag(moved)
        XCTAssertEqual(cache.eligibleTags(for: .fantasy), [])
        XCTAssertEqual(cache.eligibleTags(for: .romance), [moved])
        XCTAssertNil(cache.adminTag(for: "quest", genre: .fantasy))
        XCTAssertEqual(cache.adminTag(for: "quest", genre: .romance), moved)
    }

    func testSavedTagDoesNotTurnUnloadedCachesIntoPartialCaches() throws {
        let tag = try makeManagerTag(id: "romance-sweet", genre: .romance, tag: "sweet")
        var cache = BookInternalTagCache()
        cache.storeEligibleTags([], for: .fantasy)

        cache.reconcileSavedTag(tag)

        XCTAssertNil(cache.allAdminTags())
        XCTAssertNil(cache.eligibleTags(for: .romance))
        XCTAssertEqual(cache.eligibleTags(for: .fantasy), [])
    }

    func testFullAdminRefreshOnlyRebuildsAlreadyLoadedCustomerBuckets() throws {
        let fantasy = try makeManagerTag(id: "fantasy-magic", genre: .fantasy, tag: "magic")
        let romance = try makeManagerTag(id: "romance-sweet", genre: .romance, tag: "sweet")
        var cache = BookInternalTagCache()
        cache.storeEligibleTags([], for: .fantasy)

        cache.storeAllAdminTags([fantasy, romance])

        XCTAssertEqual(cache.eligibleTags(for: .fantasy), [fantasy])
        XCTAssertNil(cache.eligibleTags(for: .romance))
    }

    func testFullAdminRefreshToleratesDuplicateLogicalIDs() throws {
        let original = try makeManagerTag(id: "duplicate-id", genre: .fantasy, tag: "magic")
        let latest = try makeManagerTag(id: "duplicate-id", genre: .romance, tag: "sweet")
        var cache = BookInternalTagCache()

        cache.storeAllAdminTags([original, latest])

        XCTAssertEqual(cache.allAdminTags(), [latest])
        XCTAssertNil(cache.adminTag(for: "magic", genre: .fantasy))
        XCTAssertEqual(cache.adminTag(for: "sweet", genre: .romance), latest)
    }
}

private enum TestTagLoaderError: Error {
    case failed
}

private final class ControlledBookInternalTagLoader: BookInternalTagLoading {
    private(set) var genreRequests: [BookInternalGenre] = []
    private(set) var allTagRequestCount = 0
    private var genreCompletions: [BookInternalGenre: (Result<[BookInternalTag], Error>) -> Void] = [:]
    private var allTagsCompletion: ((Result<[BookInternalTag], Error>) -> Void)?

    func fetchHomeEligibleTags(for genre: BookInternalGenre,
                               source: FirestoreSource,
                               completion: @escaping (Result<[BookInternalTag], Error>) -> Void) {
        genreRequests.append(genre)
        genreCompletions[genre] = completion
    }

    func fetchAllTags(source: FirestoreSource,
                      completion: @escaping (Result<[BookInternalTag], Error>) -> Void) {
        allTagRequestCount += 1
        allTagsCompletion = completion
    }

    func completeGenre(_ genre: BookInternalGenre, with result: Result<[BookInternalTag], Error>) {
        let completion = genreCompletions.removeValue(forKey: genre)
        XCTAssertNotNil(completion)
        completion?(result)
    }

    func completeAll(with result: Result<[BookInternalTag], Error>) {
        let completion = allTagsCompletion
        allTagsCompletion = nil
        XCTAssertNotNil(completion)
        completion?(result)
    }
}

private func makeManagerTag(id: String,
                            genre: BookInternalGenre,
                            tag: String,
                            isHomeEligible: Bool = true) throws -> BookInternalTag {
    try XCTUnwrap(BookInternalTag(id: id, data: [
        BookInternalTagVariables.id.rawValue: id,
        BookInternalTagVariables.genre.rawValue: genre.rawValue,
        BookInternalTagVariables.tag.rawValue: tag,
        BookInternalTagVariables.title.rawValue: tag.capitalized,
        BookInternalTagVariables.isHomeEligible.rawValue: isHomeEligible
    ]))
}
