//
//  PersonalizedHomeFeed.swift
//  FreeAudiobooks
//
//  Created by OpenAI Codex on 27/03/2026.
//

import Foundation

enum PersonalizedHomeSectionKind {
    case continueReading
    case hero
    case carousel
    case earlyAccess
    case tagBrowser
}

enum PersonalizedHomeFeedRules {
    static let minimumCarouselCount = 6
    static let minimumEarlyAccessCount = 10
    static let minimumHomeTagInventory = 15
    /// Below this many hero-ready books a genre shows a plain carousel instead of a hero carousel.
    static let minimumHeroCount = 2
}

enum PersonalizedHomeTagBrowserRanking {
    static func rankedTags(from tags: [BookInternalTag],
                           stories: [CDBookInternal],
                           userIsSubscribed: Bool,
                           minimumBookCount: Int = PersonalizedHomeFeedRules.minimumCarouselCount) -> [BookInternalTag] {
        let visibleStories = userIsSubscribed ? stories : stories.filter(\.isAvailableToUser)
        return rankedTags(from: tags,
                          visibleStories: visibleStories,
                          minimumBookCount: minimumBookCount)
    }

    static func rankedTags(from tags: [BookInternalTag],
                           visibleStories: [CDBookInternal],
                           minimumBookCount: Int = PersonalizedHomeFeedRules.minimumCarouselCount) -> [BookInternalTag] {
        guard !tags.isEmpty else { return [] }

        let configuredTagsByGenre = Dictionary(grouping: tags, by: \.genre)
            .mapValues { Set($0.map(\.tag)) }
        var bookCountsByGenreTag: [String: Int] = [:]

        for story in visibleStories {
            guard let configuredTags = configuredTagsByGenre[story.genre] else { continue }
            for tag in Set(story.tags) where configuredTags.contains(tag) {
                bookCountsByGenreTag[key(genre: story.genre, tag: tag), default: 0] += 1
            }
        }

        return tags
            .map { tag in
                (tag: tag,
                 bookCount: bookCountsByGenreTag[key(genre: tag.genre, tag: tag.tag), default: 0])
            }
            .filter { $0.bookCount >= minimumBookCount }
            .sorted { left, right in
                if left.bookCount != right.bookCount {
                    return left.bookCount > right.bookCount
                }
                let titleComparison = left.tag.title.localizedCaseInsensitiveCompare(right.tag.title)
                if titleComparison != .orderedSame {
                    return titleComparison == .orderedAscending
                }
                return left.tag.id < right.tag.id
            }
            .map { $0.tag }
    }

    private static func key(genre: BookInternalGenre, tag: String) -> String {
        "\(genre.rawValue)|\(tag)"
    }
}

struct PersonalizedHomeSectionPresentation {
    let id: String
    let legacySectionUUID: String?
    let kind: PersonalizedHomeSectionKind
    let discoverSectionType: DiscoverSectionType
    let title: String
    let subtitle: String?
    let stories: [CDBookInternal]
    let genre: BookInternalGenre?
    let tag: String?
    let previewTags: [BookInternalTag]
    let browseGenres: [BookInternalGenre]

    init(id: String,
         legacySectionUUID: String?,
         kind: PersonalizedHomeSectionKind,
         discoverSectionType: DiscoverSectionType,
         title: String,
         subtitle: String?,
         stories: [CDBookInternal],
         genre: BookInternalGenre?,
         tag: String?,
         previewTags: [BookInternalTag] = [],
         browseGenres: [BookInternalGenre] = []) {
        self.id = id
        self.legacySectionUUID = legacySectionUUID
        self.kind = kind
        self.discoverSectionType = discoverSectionType
        self.title = title
        self.subtitle = subtitle
        self.stories = stories
        self.genre = genre
        self.tag = tag
        self.previewTags = previewTags
        self.browseGenres = browseGenres
    }

    func asDiscoverSection(position: Int) -> DiscoverSection {
        let section = DiscoverSection(uuid: legacySectionUUID ?? id,
                                      position: position,
                                      title: title,
                                      subtitle: subtitle,
                                      showReaderCount: false,
                                      type: discoverSectionType,
                                      isHidden: false,
                                      bookIDs: nil,
                                      genre: discoverSectionType == .genre ? genre : nil)
        section.stories = stories
        if discoverSectionType == .thisWeeksTopTen {
            // Personalized charts have a genre-specific title. Mark it as dynamic so the shared
            // carousel does not replace it with the generic, type-level localized Top 10 title.
            section.dynamicTitle = title
        }
        return section
    }
}

struct PersonalizedHomeCountryContext {
    let displayName: String

    static var current: PersonalizedHomeCountryContext {
        let locale = Locale.autoupdatingCurrent
        let rawRegion = locale.region?.identifier.uppercased() ?? "US"
        let regionCode = rawRegion == "UK" ? "GB" : rawRegion
        let countryName = locale.localizedString(forRegionCode: regionCode) ?? regionCode
        let isEnglish = locale.language.languageCode?.identifier == "en"
        let displayName: String
        switch (isEnglish, regionCode) {
        case (true, "US"): displayName = "the U.S."
        case (true, "GB"): displayName = "the U.K."
        default: displayName = countryName
        }
        return PersonalizedHomeCountryContext(displayName: displayName)
    }
}

struct PersonalizedFeedBuilder {
    private let favoriteGenres: [BookInternalGenre]
    private let allStories: [CDBookInternal]
    private let userIsSubscribed: Bool
    private let genreCharts: [GenreChart]
    private let completedBookUUIDs: [String]
    private let countryContext: PersonalizedHomeCountryContext
    private let generallyAvailableStoriesByGenre: [BookInternalGenre: [CDBookInternal]]
    private let newestStoriesByGenre: [BookInternalGenre: [CDBookInternal]]
    private let popularStoriesByGenre: [BookInternalGenre: [CDBookInternal]]
    private let lockedEarlyAccessStoriesByGenre: [BookInternalGenre: [CDBookInternal]]
    private let subscriberEarlyAccessStoriesByGenre: [BookInternalGenre: [CDBookInternal]]
    private let generallyAvailableStoriesByID: [String: CDBookInternal]
    private let homeTagsByGenre: [BookInternalGenre: [BookInternalTag]]
    private let rankedTagBrowserTags: [BookInternalTag]
    private let tagStoriesByGenreTag: [String: [CDBookInternal]]
    private let minimumCarouselCount = PersonalizedHomeFeedRules.minimumCarouselCount
    private let heroCount = 5
    private let carouselCount = 12
    private let chartCount = GenreChartRules.requiredBookCount
    private var usedBookIDs = Set<String>()
    private let dailySeed: UInt64

    init(favoriteGenres: [BookInternalGenre],
         allStories: [CDBookInternal],
         userIsSubscribed: Bool,
         userID: String,
         tags: [BookInternalTag],
         genreCharts: [GenreChart],
         completedBookUUIDs: [String],
         countryContext: PersonalizedHomeCountryContext = .current,
         dailySeedOverride: UInt64? = nil) {
        let normalizedFavoriteGenres = PersonalizedFeedBuilder.normalizedGenres(favoriteGenres)
        self.favoriteGenres = normalizedFavoriteGenres
        self.allStories = allStories
        self.userIsSubscribed = userIsSubscribed
        self.genreCharts = genreCharts
        self.completedBookUUIDs = completedBookUUIDs
        self.countryContext = countryContext
        self.dailySeed = dailySeedOverride ?? PersonalizedFeedBuilder.makeDailySeed(userID: userID)

        // `isEarlyAccess` and `isAvailableToUser` both re-parse `availableForAllDateString`
        // on every call, so the unlock day is parsed once here and reused throughout.
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var generallyAvailableStories: [CDBookInternal] = []
        var earlyAccessStories: [(story: CDBookInternal, unlockDay: Date)] = []
        generallyAvailableStories.reserveCapacity(allStories.count)

        for story in allStories {
            let unlockDay = story.availableForAllDateString
                .flatMap { DateFormatters.earlyAccessDateFormatter.date(from: $0) }
                .map { calendar.startOfDay(for: $0) }
            if let unlockDay, today < unlockDay {
                // Still inside the early access window, so visibility depends on the subscription.
                earlyAccessStories.append((story, unlockDay))
            } else {
                // No date, an unparseable date, or the unlock day has arrived: available to everyone.
                generallyAvailableStories.append(story)
            }
        }

        let storiesByGenre = Dictionary(grouping: generallyAvailableStories, by: \.genre)
        self.generallyAvailableStoriesByGenre = storiesByGenre
        self.newestStoriesByGenre = Dictionary(uniqueKeysWithValues: normalizedFavoriteGenres.map { genre in
            (genre, (storiesByGenre[genre] ?? []).sorted { ($0.datePublished ?? .distantPast) > ($1.datePublished ?? .distantPast) })
        })
        self.popularStoriesByGenre = Dictionary(uniqueKeysWithValues: BookInternalGenre.allCases.map { genre in
            (genre, (storiesByGenre[genre] ?? []).sorted { $0.readerCount > $1.readerCount })
        })

        let sortedEarlyAccessByGenre = Dictionary(grouping: earlyAccessStories, by: { $0.story.genre })
            .mapValues { entries in
                entries.sorted { $0.unlockDay < $1.unlockDay }.map(\.story)
            }
        // Inside the early access window a book is available to subscribers only, so the
        // subscription flag alone decides which collection these belong in.
        self.lockedEarlyAccessStoriesByGenre = userIsSubscribed ? [:] : sortedEarlyAccessByGenre
        self.subscriberEarlyAccessStoriesByGenre = userIsSubscribed ? sortedEarlyAccessByGenre : [:]

        self.generallyAvailableStoriesByID = Dictionary(uniqueKeysWithValues: generallyAvailableStories.map { ($0.contentUUID, $0) })

        let favoriteGenreSet = Set(normalizedFavoriteGenres)
        let homeTags = tags.filter {
            $0.isHomeEligible && favoriteGenreSet.contains($0.genre)
        }
        let homeTagsByGenre = Dictionary(grouping: homeTags, by: \.genre)
        self.homeTagsByGenre = homeTagsByGenre
        self.rankedTagBrowserTags = PersonalizedHomeTagBrowserRanking.rankedTags(
            from: homeTags,
            stories: allStories,
            userIsSubscribed: userIsSubscribed
        )

        let configuredHomeTagsByGenre = homeTagsByGenre.mapValues { Set($0.map(\.tag)) }
        var tagStoriesByGenreTag: [String: [CDBookInternal]] = [:]
        for story in generallyAvailableStories {
            guard let configuredTags = configuredHomeTagsByGenre[story.genre] else { continue }
            for tag in Set(story.tags) where configuredTags.contains(tag) {
                let key = Self.genreTagKey(genre: story.genre, tag: tag)
                tagStoriesByGenreTag[key, default: []].append(story)
            }
        }
        self.tagStoriesByGenreTag = tagStoriesByGenreTag.mapValues { stories in
            stories.sorted {
                if $0.readerCount == $1.readerCount {
                    return ($0.datePublished ?? .distantPast) > ($1.datePublished ?? .distantPast)
                }
                return $0.readerCount > $1.readerCount
            }
        }
    }

    mutating func buildSections() -> [PersonalizedHomeSectionPresentation] {
        var sections: [PersonalizedHomeSectionPresentation] = []

        if let continueReading = makeContinueReadingSection() {
            sections.append(continueReading)
        }

        sections.append(contentsOf: makeDedicatedGenreSections(for: favoriteGenres))

        if let favoriteGenresCTA = makeFavoriteGenresCTASection() {
            sections.append(favoriteGenresCTA)
        }

        if let browseByGenre = makeBrowseByGenreSection() {
            sections.append(browseByGenre)
        }

        if let becauseYouRead = makeBecauseYouReadSection() {
            sections.append(becauseYouRead)
        }


        if let explore = makeExploreSection() {
            sections.append(explore)
        }

        if let searchCTA = makeSearchCTASection() {
            sections.append(searchCTA)
        }

        return sections
    }

    private mutating func makeDedicatedGenreSections(for genres: [BookInternalGenre]) -> [PersonalizedHomeSectionPresentation] {
        var sections: [PersonalizedHomeSectionPresentation] = []
        let tagRowCountPerGenre: Int
        switch genres.count {
        case 0:
            tagRowCountPerGenre = 0
        case 1:
            tagRowCountPerGenre = 3
        case 2, 3:
            tagRowCountPerGenre = 2
        default:
            tagRowCountPerGenre = 1
        }

        for genre in genres {
            if let newSection = makeGenreRow(id: "new-\(genre.rawValue)",
                                             title: "New in \(genre.displayString)",
                                             genre: genre,
                                             stories: newestStories(for: genre)) {
                sections.append(newSection)
            }
            let chartSection = makeChartRow(for: genre,
                                            title: "Top 10 \(genre.displayString) in \(countryContext.displayName)")
            if let chartSection {
                sections.append(chartSection)
            }
            let chartSlotIndex = sections.endIndex

            if let hero = makeHeroSection(for: genre, title: "Featured \(genre.displayString)") {
                sections.append(hero)
            }
            sections.append(contentsOf: makeTagSections(for: genre, maxRows: tagRowCountPerGenre))

            // A genre without a usable chart shows its popularity row in the chart's slot, but it
            // is built last so the hero and tag rows keep first pick of the catalogue: a generic
            // fallback row should absorb what is left over, not starve the rows it stands in for.
            if chartSection == nil,
               let popularitySection = makePopularityRow(for: genre, title: "Popular in \(genre.displayString)") {
                sections.insert(popularitySection, at: chartSlotIndex)
            }
            if let earlyAccess = makeGenreEarlyAccessSection(for: genre) {
                sections.append(earlyAccess)
            }
            if let tagBrowser = makeTagBrowserSection(for: [genre]) {
                sections.append(tagBrowser)
            }
        }

        return sections
    }

    private mutating func makeContinueReadingSection() -> PersonalizedHomeSectionPresentation? {
        let inProgressStories = ReadingUserDefaults.getReadingInProgressContent()
            .compactMap { $0 as? CDBookInternal }
        let stories = takeStories(from: inProgressStories, limit: 10, minimumCount: 1)
        guard stories.count >= 1 else { return nil }

        return PersonalizedHomeSectionPresentation(id: "continue-reading",
                                                   legacySectionUUID: nil,
                                                   kind: .continueReading,
                                                   discoverSectionType: .continueReading,
                                                   title: "Continue listening",
                                                   subtitle: nil,
                                                   stories: stories,
                                                   genre: nil,
                                                   tag: nil)
    }

    private mutating func makeGenreEarlyAccessSection(for genre: BookInternalGenre) -> PersonalizedHomeSectionPresentation? {
        let matchingStories = eligibleGenreEarlyAccessStories(for: genre)
        guard matchingStories.count >= PersonalizedHomeFeedRules.minimumEarlyAccessCount else { return nil }
        let stories = takeStories(from: matchingStories,
                                  limit: matchingStories.count,
                                  minimumCount: PersonalizedHomeFeedRules.minimumEarlyAccessCount)
        guard stories.count >= PersonalizedHomeFeedRules.minimumEarlyAccessCount else { return nil }

        return PersonalizedHomeSectionPresentation(id: "early-access-\(genre.rawValue)",
                                                   legacySectionUUID: nil,
                                                   kind: .earlyAccess,
                                                   discoverSectionType: .earlyAccess,
                                                   title: "Early Access in \(genre.displayString)",
                                                   subtitle: nil,
                                                   stories: stories,
                                                   genre: genre,
                                                   tag: nil)
    }

    private mutating func makeHeroSection(for genre: BookInternalGenre,
                                          title: String) -> PersonalizedHomeSectionPresentation? {
        let candidateStories = seededShuffle(
            popularStories(for: genre).filter(\.isValidHeroCarouselStory),
            salt: "hero-\(genre.rawValue)"
        )
        let stories = takeStories(from: candidateStories,
                                  limit: heroCount,
                                  minimumCount: PersonalizedHomeFeedRules.minimumHeroCount)
        if stories.count >= PersonalizedHomeFeedRules.minimumHeroCount {
            return PersonalizedHomeSectionPresentation(id: "hero-\(genre.rawValue)",
                                                       legacySectionUUID: nil,
                                                       kind: .hero,
                                                       discoverSectionType: .heroCarousel,
                                                       title: title,
                                                       subtitle: nil,
                                                       stories: stories,
                                                       genre: nil,
                                                       tag: nil)
        }

        let fallbackStories = takeStories(from: popularStories(for: genre),
                                          limit: carouselCount,
                                          minimumCount: minimumCarouselCount)
        guard fallbackStories.count >= minimumCarouselCount else { return nil }

        return PersonalizedHomeSectionPresentation(id: "hero-fallback-\(genre.rawValue)",
                                                   legacySectionUUID: nil,
                                                   kind: .carousel,
                                                   discoverSectionType: .genre,
                                                   title: title,
                                                   subtitle: nil,
                                                   stories: fallbackStories,
                                                   genre: genre,
                                                   tag: nil)
    }

    private mutating func makeGenreRow(id: String,
                                       title: String,
                                       genre: BookInternalGenre,
                                       stories: [CDBookInternal]) -> PersonalizedHomeSectionPresentation? {
        let uniqueStories = takeStories(from: stories,
                                        limit: carouselCount,
                                        minimumCount: minimumCarouselCount)
        guard uniqueStories.count >= minimumCarouselCount else { return nil }

        return PersonalizedHomeSectionPresentation(id: id,
                                                   legacySectionUUID: nil,
                                                   kind: .carousel,
                                                   discoverSectionType: .genre,
                                                   title: title,
                                                   subtitle: nil,
                                                   stories: uniqueStories,
                                                   genre: genre,
                                                   tag: nil)
    }

    private mutating func makeCarouselSection(id: String,
                                              title: String,
                                              stories: [CDBookInternal],
                                              discoverSectionType: DiscoverSectionType,
                                              genre: BookInternalGenre? = nil,
                                              tag: String? = nil,
                                              legacySectionUUID: String? = nil) -> PersonalizedHomeSectionPresentation? {
        guard stories.count >= minimumCarouselCount else { return nil }

        return PersonalizedHomeSectionPresentation(id: id,
                                                   legacySectionUUID: legacySectionUUID,
                                                   kind: .carousel,
                                                   discoverSectionType: discoverSectionType,
                                                   title: title,
                                                   subtitle: nil,
                                                   stories: stories,
                                                   genre: genre,
                                                   tag: tag)
    }

    private mutating func makeChartRow(for genre: BookInternalGenre,
                                       title: String) -> PersonalizedHomeSectionPresentation? {
        guard let chartStories = storiesForGenreChart(genre: genre) else { return nil }
        // The chart is a curated, complete list, so it is allowed to repeat books already shown
        // in an earlier row. A row titled "Top 10" either shows ten books or gives way to the
        // popularity row; it never renders with holes in it.
        let stories = takeStories(from: chartStories,
                                  limit: chartCount,
                                  minimumCount: chartCount,
                                  allowingAlreadyUsedStories: true)
        guard stories.count == chartCount else { return nil }

        return makeCarouselSection(id: "top-\(genre.rawValue)",
                                   title: title,
                                   stories: stories,
                                   discoverSectionType: .thisWeeksTopTen,
                                   genre: genre)
    }

    private mutating func makePopularityRow(for genre: BookInternalGenre,
                                            title: String) -> PersonalizedHomeSectionPresentation? {
        makeGenreRow(id: "popular-\(genre.rawValue)",
                     title: title,
                     genre: genre,
                     stories: popularStories(for: genre))
    }

    private mutating func makeTagSections(for genre: BookInternalGenre,
                                          maxRows: Int) -> [PersonalizedHomeSectionPresentation] {
        guard maxRows > 0 else { return [] }

        var builtSections: [PersonalizedHomeSectionPresentation] = []
        var remainingTags = eligibleHomeTags(for: genre)

        while builtSections.count < maxRows,
              let tag = preferredAvailableTag(from: remainingTags) {
            remainingTags.removeAll { $0.id == tag.id }
            guard let section = makeTagSection(for: tag, genre: genre) else { continue }
            builtSections.append(section)
        }

        return builtSections
    }

    /// Preserves the stable daily shuffle while preferring a tag that can still fill all 12
    /// positions. The first viable partial tag is retained as a fallback so a row is not lost when
    /// the catalogue cannot supply a full one without repeating books.
    private func preferredAvailableTag(from tags: [BookInternalTag]) -> BookInternalTag? {
        var partialFallback: BookInternalTag?

        for tag in tags {
            let unusedCount = unusedInventoryCount(for: tag, stoppingAt: carouselCount)
            if unusedCount >= carouselCount {
                return tag
            }
            if partialFallback == nil, unusedCount >= minimumCarouselCount {
                partialFallback = tag
            }
        }

        return partialFallback
    }

    private mutating func makeTagSection(for tag: BookInternalTag,
                                         genre: BookInternalGenre) -> PersonalizedHomeSectionPresentation? {
        let matchingStories = tagStoriesByGenreTag[Self.genreTagKey(genre: genre, tag: tag.tag)] ?? []
        let stories = takeStories(from: matchingStories,
                                  limit: carouselCount,
                                  minimumCount: minimumCarouselCount)
        return makeCarouselSection(id: "tag-\(tag.id)",
                                   title: tag.title,
                                   stories: stories,
                                   discoverSectionType: .genre,
                                   genre: genre,
                                   tag: tag.tag)
    }

    private func makeTagBrowserSection(for genres: [BookInternalGenre]) -> PersonalizedHomeSectionPresentation? {
        let previewTags = previewTags(for: genres, limit: 20)
        guard !previewTags.isEmpty else { return nil }
        let sectionID = "tag-browser-" + genres.map(\.rawValue).joined(separator: "-")

        let title: String
        if genres.count == 1, let genre = genres.first {
            title = "Top \(genre.displayString) tags"
        } else {
            title = "Top tags for your genres"
        }

        return PersonalizedHomeSectionPresentation(id: sectionID,
                                                   legacySectionUUID: nil,
                                                   kind: .tagBrowser,
                                                   discoverSectionType: .genre,
                                                   title: title,
                                                   subtitle: nil,
                                                   stories: [],
                                                   genre: genres.first,
                                                   tag: nil,
                                                   previewTags: previewTags,
                                                   browseGenres: genres)
    }

    private func makeBrowseByGenreSection() -> PersonalizedHomeSectionPresentation? {
        PersonalizedHomeSectionPresentation(id: "browse-by-genre",
                                            legacySectionUUID: nil,
                                            kind: .carousel,
                                            discoverSectionType: .genreShortcuts,
                                            title: "Browse all genres",
                                            subtitle: nil,
                                            stories: [],
                                            genre: nil,
                                            tag: nil)
    }


    private func makeFavoriteGenresCTASection() -> PersonalizedHomeSectionPresentation? {
        let customiseText = Locale.isUK ? "Customise" : "Customize"
        let favoriteText = Locale.isUK ? "favourite" : "favorite"
        let personalizeText = Locale.isUK ? "personalise" : "personalize"
        let subtitle: String
        if favoriteGenres.isEmpty {
            subtitle = "Choose your \(favoriteText) genres to \(personalizeText) Home"
        } else {
            subtitle = favoriteGenres.map(\.displayString).joined(separator: ", ")
        }

        return PersonalizedHomeSectionPresentation(id: "favorite-genres-cta",
                                                   legacySectionUUID: nil,
                                                   kind: .carousel,
                                                   discoverSectionType: .favoriteGenresCTA,
                                                   title: "\(customiseText) your Home",
                                                   subtitle: subtitle,
                                                   stories: [],
                                                   genre: nil,
                                                   tag: nil)
    }

    private func makeSearchCTASection() -> PersonalizedHomeSectionPresentation? {
        PersonalizedHomeSectionPresentation(id: "search-cta",
                                            legacySectionUUID: nil,
                                            kind: .carousel,
                                            discoverSectionType: .searchPromptCTA,
                                            title: "Find your perfect listen",
                                            subtitle: nil,
                                            stories: [],
                                            genre: nil,
                                            tag: nil)
    }

    private mutating func makeBecauseYouReadSection() -> PersonalizedHomeSectionPresentation? {
        guard
            let completedUUID = completedBookUUIDs.last,
            let sourceStory = allStories.first(where: { $0.contentUUID == completedUUID }) else {
            return nil
        }

        var generator = SeededGenerator(seed: dailySeed ^ 0xB3C4_515A)
        let excludedUUIDs = Set(completedBookUUIDs)
            .union(ReadingUserDefaults.bookUUIDsWithProgress())
        let candidateStories = (generallyAvailableStoriesByGenre[sourceStory.genre] ?? [])
            .filter { !excludedUUIDs.contains($0.contentUUID) }
            .shuffled(using: &generator)
        let stories = takeStories(from: candidateStories,
                                  limit: carouselCount,
                                  minimumCount: minimumCarouselCount)

        return makeCarouselSection(id: "because-you-read",
                                   title: "Because you listened to \(sourceStory.title ?? "this story")",
                                   stories: stories,
                                   discoverSectionType: .becauseYouRead,
                                   genre: sourceStory.genre)
    }

    private mutating func makeExploreSection() -> PersonalizedHomeSectionPresentation? {
        let excludedGenres = Set(favoriteGenres)
        let exploreGenres = BookInternalGenre.allCases.filter { !excludedGenres.contains($0) }
        let lists = exploreGenres.map(popularStories)
        let stories = takeStories(from: interleave(lists),
                                  limit: carouselCount,
                                  minimumCount: minimumCarouselCount)
        let title = favoriteGenres.count == 1
            ? "Explore beyond \(favoriteGenres[0].displayString)"
            : "Explore beyond your genres"
        return makeCarouselSection(id: "explore",
                                   title: title,
                                   stories: stories,
                                   discoverSectionType: .mostPopular)
    }

    /// Only populated for favorite genres, which are the only genres that get a "New in" row.
    private func newestStories(for genre: BookInternalGenre) -> [CDBookInternal] {
        newestStoriesByGenre[genre] ?? []
    }

    private func popularStories(for genre: BookInternalGenre) -> [CDBookInternal] {
        popularStoriesByGenre[genre] ?? []
    }

    private func eligibleGenreEarlyAccessStories(for genre: BookInternalGenre) -> [CDBookInternal] {
        userIsSubscribed ? (subscriberEarlyAccessStoriesByGenre[genre] ?? []) : (lockedEarlyAccessStoriesByGenre[genre] ?? [])
    }

    private func storiesForGenreChart(genre: BookInternalGenre) -> [CDBookInternal]? {
        guard
            let chart = genreCharts.first(where: { $0.genre == genre }),
            GenreChartRules.isComplete(bookIDs: chart.bookIDs,
                                       genre: genre,
                                       genreOfEligibleBook: { generallyAvailableStoriesByID[$0]?.genre }) else {
            return nil
        }

        return chart.bookIDs.compactMap { generallyAvailableStoriesByID[$0] }
    }

    private func eligibleHomeTags(for genre: BookInternalGenre) -> [BookInternalTag] {
        let tags = (homeTagsByGenre[genre] ?? [])
            .filter { tag in
                inventoryCount(for: tag) >= PersonalizedHomeFeedRules.minimumHomeTagInventory
            }

        return seededShuffle(tags, salt: "home-tags-\(genre.rawValue)")
    }

    private func previewTags(for genres: [BookInternalGenre], limit: Int) -> [BookInternalTag] {
        guard !genres.isEmpty, limit > 0 else { return [] }

        let genreSet = Set(genres)
        return Array(rankedTagBrowserTags
            .lazy
            .filter { genreSet.contains($0.genre) }
            .prefix(limit))
    }

    private func inventoryCount(for tag: BookInternalTag) -> Int {
        let stories = tagStoriesByGenreTag[Self.genreTagKey(genre: tag.genre, tag: tag.tag)] ?? []
        return stories.count
    }

    private func unusedInventoryCount(for tag: BookInternalTag, stoppingAt limit: Int) -> Int {
        let stories = tagStoriesByGenreTag[Self.genreTagKey(genre: tag.genre, tag: tag.tag)] ?? []
        var count = 0

        for story in stories where !usedBookIDs.contains(story.contentUUID) {
            count += 1
            if count == limit {
                break
            }
        }
        return count
    }

    /// - Parameter allowingAlreadyUsedStories: when `true` the row may repeat books shown by an
    ///   earlier row. Collected books are still marked as used, so later rows continue to skip them.
    private mutating func takeStories(from source: [CDBookInternal],
                                      limit: Int,
                                      minimumCount: Int,
                                      allowingAlreadyUsedStories: Bool = false) -> [CDBookInternal] {
        var collected: [CDBookInternal] = []
        var collectedBookIDs = Set<String>()
        collected.reserveCapacity(limit)

        for story in source {
            let bookID = story.contentUUID
            guard
                allowingAlreadyUsedStories || !usedBookIDs.contains(bookID),
                collectedBookIDs.insert(bookID).inserted else {
                continue
            }
            collected.append(story)
            if collected.count == limit {
                break
            }
        }

        guard collected.count >= minimumCount else { return [] }
        usedBookIDs.formUnion(collectedBookIDs)
        return collected
    }

    private func seededShuffle<T>(_ items: [T], salt: String) -> [T] {
        var generator = SeededGenerator(seed: dailySeed ^ PersonalizedFeedBuilder.hash64(salt))
        return items.shuffled(using: &generator)
    }

    private func interleave<T>(_ lists: [[T]]) -> [T] {
        guard !lists.isEmpty else { return [] }

        var result: [T] = []
        let maxCount = lists.map(\.count).max() ?? 0

        for index in 0..<maxCount {
            for list in lists where index < list.count {
                result.append(list[index])
            }
        }

        return result
    }

    private static func normalizedGenres(_ genres: [BookInternalGenre]) -> [BookInternalGenre] {
        var seen = Set<BookInternalGenre>()
        var normalized: [BookInternalGenre] = []

        for genre in genres where seen.insert(genre).inserted {
            normalized.append(genre)
        }

        return normalized
    }

    private static func makeDailySeed(userID: String) -> UInt64 {
        let date = Date()
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd"
        return hash64("\(userID)|\(formatter.string(from: date))")
    }

    private static func genreTagKey(genre: BookInternalGenre, tag: String) -> String {
        "\(genre.rawValue)|\(tag)"
    }

    private static func hash64(_ string: String) -> UInt64 {
        let bytes = Array(string.utf8)
        var hash: UInt64 = 1469598103934665603
        for byte in bytes {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        return hash
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
