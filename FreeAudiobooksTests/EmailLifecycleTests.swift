import XCTest
import CoreData
import FirebaseFirestore
@testable import FreeAudiobooks

@MainActor
final class EmailLifecycleTests: XCTestCase {
    func testTagAndLibraryLinksAcceptBothFormsAndRejectMalformedPaths() {
        for base in ["https://links.freeaudiobooksapp.com/", "freeaudiobooks://"] {
            XCTAssertEqual(DeeplinkManager.shared.getLaunchActionFromDeeplinkURL(url:
                URL(string: base + "genre/romance/tag/stable-tag-123?src=email")!),
                .genreTag(genre: .romance, tagID: "stable-tag-123"))
            for destination in LibraryDestination.allCases {
                XCTAssertEqual(DeeplinkManager.shared.getLaunchActionFromDeeplinkURL(url:
                    URL(string: base + "library/" + destination.rawValue)!), .library(destination: destination))
            }
            for path in ["genre/romance/tag", "genre/romance/tag/", "genre/romance/tag/%20",
                         "genre/romance/tag/id/extra", "genre/nope/tag/id", "genre/romance/tags/id",
                         "library", "library/", "library/completed", "library/saved/extra"] {
                XCTAssertNil(DeeplinkManager.shared.getLaunchActionFromDeeplinkURL(url: URL(string: base + path)!))
            }
        }
    }

    func testLibraryAndTagRoutesDeferAndSavedBooksExplicitlySelectsSaved() {
        final class Destination: AppTabBarController {
            var library: LibraryDestination?
            var tag: String?
            override func showLibrary(destination: LibraryDestination) { library = destination }
            override func showGenreTag(genre: BookInternalGenre, tagID: String) { tag = tagID }
        }
        let oldLoaded = AppNotifiers.shared.tabBarHasLoaded
        let oldPending = AppNotifiers.shared.launchActionNeedsHandling
        defer {
            AppNotifiers.shared.tabBarHasLoaded = oldLoaded
            AppNotifiers.shared.launchActionNeedsHandling = oldPending
        }
        let app = AppDelegate()
        let tabs = Destination()
        app.tabBarController = tabs
        for action in [LaunchAction.library(destination: .downloads), .genreTag(genre: .romance, tagID: "id")] {
            AppNotifiers.shared.tabBarHasLoaded = false
            app.handleLaunchAction(action)
            XCTAssertEqual(AppNotifiers.shared.launchActionNeedsHandling, action)
            AppNotifiers.shared.tabBarHasLoaded = true
            app.handleLaunchAction(action)
            XCTAssertNil(AppNotifiers.shared.launchActionNeedsHandling)
        }
        XCTAssertEqual(tabs.library, .downloads)
        XCTAssertEqual(tabs.tag, "id")
        app.handleLaunchAction(.savedBooks)
        XCTAssertEqual(tabs.library, .saved)
    }

    func testLibraryEntryReplacesPreviousSectionAndDownloadedFilter() {
        let library = LibraryVC()
        for destination in [LibraryDestination.downloads, .inProgress, .downloads, .saved, .inProgress] {
            library.applyEntryDestination(destination)
            XCTAssertEqual(library.entryDestination, destination)
        }
    }

    func testTagLinkResolvesStableIDAndClearsPreviousFilters() {
        let previous = CDBookInternalSearchObject()
        previous.query = "old query"
        previous.genre = .horror
        previous.minReadingTime = 30
        previous.maxReadingTime = 90
        previous.minimumRating = .fourPlus
        previous.sortOption = .newest
        previous.page = 4
        let search = SearchVC(initialFilters: previous)
        let tag = BookInternalTag(id: "stable-id", data: [
            "genre": "mystery", "tag": "locked_room", "title": "Locked Room", "isHomeEligible": true
        ])!
        search.applyGenreTag(genre: .mystery, tagID: tag.id) { genre, complete in
            XCTAssertEqual(genre, .mystery)
            complete(true, [tag])
        }
        let filters = search.entryFilters
        XCTAssertEqual(filters.genre, .mystery)
        XCTAssertEqual(filters.tag?.id, "stable-id")
        XCTAssertEqual(filters.tag?.tag, "locked_room")
        XCTAssertNil(filters.query)
        XCTAssertNil(filters.minReadingTime)
        XCTAssertNil(filters.maxReadingTime)
        XCTAssertEqual(filters.minimumRating, .any)
        XCTAssertEqual(filters.sortOption, .relevance)
        XCTAssertEqual(filters.page, 1)
    }

    func testUnavailableTagFallsBackToGenreAndLateResultsCannotReplaceNewSearch() {
        let search = SearchVC()
        let valid = BookInternalTag(id: "id", data: [
            "genre": "mystery", "tag": "locked_room", "title": "Locked Room", "isHomeEligible": true
        ])!
        let disabled = BookInternalTag(id: "id", data: [
            "genre": "mystery", "tag": "locked_room", "title": "Locked Room", "isHomeEligible": false
        ])!
        let wrongGenre = BookInternalTag(id: "id", data: [
            "genre": "romance", "tag": "slow_burn", "title": "Slow Burn", "isHomeEligible": true
        ])!
        for (success, tags) in [(false, [valid]), (true, []), (true, [disabled]), (true, [wrongGenre])] {
            search.applyGenreTag(genre: .mystery, tagID: "id") { _, complete in complete(success, tags) }
            XCTAssertEqual(search.entryFilters.genre, .mystery)
            XCTAssertNil(search.entryFilters.tag)
        }
        var finish: ((Bool, [BookInternalTag]) -> Void)?
        search.applyGenreTag(genre: .mystery, tagID: "id") { _, complete in finish = complete }
        let newer = CDBookInternalSearchObject()
        newer.genre = .fantasy
        search.applyEntryFilters(newer)
        finish?(true, [valid])
        XCTAssertEqual(search.entryFilters.genre, .fantasy)
        XCTAssertNil(search.entryFilters.tag)

        search.applyGenreTag(genre: .mystery, tagID: "id") { _, complete in finish = complete }
        search.viewWillDisappear(false)
        finish?(true, [valid])
        XCTAssertNil(search.entryFilters.tag)
    }

    func testEveryGenreAcceptsUniversalAndCustomLinksWithEmailAttribution() {
        for genre in BookInternalGenre.allCases {
            for base in ["https://links.freeaudiobooksapp.com/", "freeaudiobooks://"] {
                let url = URL(string: "\(base)genre/\(genre.rawValue)?src=email&c=onboarding_v1&s=2")!
                XCTAssertEqual(DeeplinkManager.shared.getLaunchActionFromDeeplinkURL(url: url), .genre(genre: genre))
            }
        }
    }

    func testGenreLinksRejectUnknownMissingOrExtraPathComponents() {
        for path in ["genre", "genre/", "genre/not-a-genre", "genre/romance/extra", "genre/science-fiction"] {
            for base in ["https://links.freeaudiobooksapp.com/", "freeaudiobooks://"] {
                XCTAssertNil(DeeplinkManager.shared.getLaunchActionFromDeeplinkURL(url: URL(string: base + path)!))
            }
        }
        XCTAssertNil(DeeplinkManager.shared.getLaunchActionFromDeeplinkURL(url: URL(string: "https://example.com/genre/romance")!))
        XCTAssertNil(DeeplinkManager.shared.getLaunchActionFromDeeplinkURL(url: URL(string: "http://links.freeaudiobooksapp.com/genre/romance")!))
    }

    func testGenreRouteSuppliesFreshFiltersAndDefersUntilTabsLoad() {
        final class SearchDestination: AppTabBarController {
            var receivedFilters: CDBookInternalSearchObject?
            override func showSearch(initialFilters: CDBookInternalSearchObject?) {
                receivedFilters = initialFilters
            }
        }
        let originalLoaded = AppNotifiers.shared.tabBarHasLoaded
        let originalPending = AppNotifiers.shared.launchActionNeedsHandling
        defer {
            AppNotifiers.shared.tabBarHasLoaded = originalLoaded
            AppNotifiers.shared.launchActionNeedsHandling = originalPending
        }
        let app = AppDelegate()
        let tabs = SearchDestination()
        app.tabBarController = tabs
        let previous = CDBookInternalSearchObject()
        previous.query = "old search"
        previous.genre = .horror
        previous.minReadingTime = 30
        previous.maxReadingTime = 90
        previous.format = .audiobook
        previous.minimumRating = .fourPlus
        previous.sortOption = .newest
        previous.includeAdultContentForRomance = true
        previous.page = 4
        tabs.receivedFilters = previous

        AppNotifiers.shared.tabBarHasLoaded = false
        app.handleLaunchAction(.genre(genre: .romance))
        XCTAssertEqual(AppNotifiers.shared.launchActionNeedsHandling, .genre(genre: .romance))
        XCTAssertTrue(tabs.receivedFilters === previous)

        AppNotifiers.shared.tabBarHasLoaded = true
        app.handleLaunchAction(AppNotifiers.shared.launchActionNeedsHandling!)
        XCTAssertNil(AppNotifiers.shared.launchActionNeedsHandling)
        let fresh = tabs.receivedFilters!
        XCTAssertFalse(fresh === previous)
        XCTAssertEqual(fresh.genre, .romance)
        XCTAssertNil(fresh.query)
        XCTAssertNil(fresh.tag)
        XCTAssertNil(fresh.minReadingTime)
        XCTAssertNil(fresh.maxReadingTime)
        XCTAssertEqual(fresh.format, .any)
        XCTAssertEqual(fresh.minimumRating, .any)
        XCTAssertEqual(fresh.sortOption, .relevance)
        XCTAssertFalse(fresh.includeAdultContentForRomance)
        XCTAssertEqual(fresh.page, 1)
        XCTAssertEqual(fresh.activeFilterCount, 1)

        app.handleLaunchAction(.genre(genre: .fantasy))
        XCTAssertEqual(tabs.receivedFilters?.genre, .fantasy)
        XCTAssertFalse(tabs.receivedFilters === fresh)
    }

    func testEmailOfferUsesExactPlacementAndBothURLForms() {
        let parser = DeeplinkManager.shared
        XCTAssertEqual(parser.getLaunchActionFromDeeplinkURL(url: URL(string: "https://links.freeaudiobooksapp.com/onboardingEmailDiscount")!), .onboardingEmailDiscount)
        XCTAssertEqual(parser.getLaunchActionFromDeeplinkURL(url: URL(string: "freeaudiobooks://onboardingEmailDiscount")!), .onboardingEmailDiscount)
        XCTAssertEqual(PaywallPlacement.onboardingEmailDiscount.rawValue, "onboardingEmailDiscount")
    }

    func testUntrustedHostCannotRouteAnEmailOffer() {
        XCTAssertNil(DeeplinkManager.shared.getLaunchActionFromDeeplinkURL(url: URL(string: "https://example.com/onboardingEmailDiscount")!))
        XCTAssertNil(DeeplinkManager.shared.getLaunchActionFromDeeplinkURL(url: URL(string: "http://links.freeaudiobooksapp.com/onboardingEmailDiscount")!))
    }

    func testBookLinkKeepsDestinationWithEmailAttribution() {
        let link = URL(string: "https://links.freeaudiobooksapp.com/book-internal/book123?src=email&c=onboarding_v1&s=1&d=fixture")!
        XCTAssertEqual(DeeplinkManager.shared.getLaunchActionFromDeeplinkURL(url: link), .bookInternal(uuid: "book123"))
    }

    func testIncompleteBookLinkDoesNotProduceNavigation() {
        XCTAssertNil(DeeplinkManager.shared.getLaunchActionFromDeeplinkURL(url: URL(string: "https://links.freeaudiobooksapp.com/book-internal")!))
    }
    func testAutoEnrolRequiresFirstAppOnboardingWithoutPreviousChoice() {
        func eligible(enabled: Bool = true, country: String = "USA", email: String = "reader@example.com", fresh: Bool = true,
                      isEmailSubscribed: Bool = false, answered: Bool = false, isEmailUnsubscribed: Bool = false,
                      dismissed: Bool = false) -> Bool {
            EmailMarketingService.shouldAutoEnrol(enabled: enabled, country: country, email: email, isFirstAppOnboarding: fresh,
                isEmailSubscribed: isEmailSubscribed, previouslyAnswered: answered, isEmailUnsubscribed: isEmailUnsubscribed, dismissed: dismissed)
        }
        XCTAssertTrue(eligible())
        XCTAssertFalse(eligible(enabled: false))
        XCTAssertFalse(eligible(country: ""))
        XCTAssertFalse(eligible(country: "GBR"))
        XCTAssertFalse(eligible(email: ""))
        XCTAssertFalse(eligible(fresh: false))
        XCTAssertFalse(eligible(isEmailSubscribed: true))
        XCTAssertFalse(eligible(answered: true))
        XCTAssertFalse(eligible(isEmailUnsubscribed: true))
        XCTAssertFalse(eligible(dismissed: true))
    }

    func testPaywallPathOnlyAcceptsTheEmailPlacement() {
        let parser = DeeplinkManager.shared
        XCTAssertEqual(parser.getLaunchActionFromDeeplinkURL(url: URL(string: "freeaudiobooks://paywall/onboardingEmailDiscount")!), .onboardingEmailDiscount)
        XCTAssertNil(parser.getLaunchActionFromDeeplinkURL(url: URL(string: "freeaudiobooks://paywall/anotherPlacement")!))
    }


    func testFirstAppOnboardingDoesNotDependOnSharedAccountAge() {
        let app = EmailMarketingService.appID
        let other = app == "freebooks" ? "freeaudiobooks" : "freebooks"
        let originalJoin = Timestamp(date: Date(timeIntervalSince1970: 1000))
        XCTAssertTrue(EmailMarketingService.isFirstAppOnboarding(in: ["apps": [
            app: ["marketingPromptAnswered": false]
        ]]))
        // An old shared account can join the second app without restarting the first.
        var apps: [String: [String: Any]] = [other: ["emailOnboardingCompletedAt": originalJoin]]
        XCTAssertTrue(EmailMarketingService.isFirstAppOnboarding(in: ["createdDate": originalJoin, "apps": apps]))
        apps[app] = ["emailOnboardingCompletedAt": originalJoin]
        XCTAssertFalse(EmailMarketingService.isFirstAppOnboarding(in: ["apps": apps]))
        // A historical account or a device-profile refresh alone is not a new signup.
        XCTAssertFalse(EmailMarketingService.isFirstAppOnboarding(in: ["createdDate": originalJoin]))
        XCTAssertFalse(EmailMarketingService.isFirstAppOnboarding(in: ["apps": [app: ["platform": "ios"]]]))
    }

    func testOtherAppAndLegacyPermissionDoNotAuthoriseThisApp() {
        let document: [String: Any] = ["marketingPermission": true, "apps": [
            "freebooks": ["marketingPermission": true],
            "freeaudiobooks": ["marketingPermission": false]
        ]]
        XCTAssertEqual(EmailMarketingService.profile(from: document)["marketingPermission"] as? Bool, false)
        XCTAssertTrue(EmailMarketingService.profile(from: ["marketingPermission": true]).isEmpty)
        let write = EmailMarketingService.profileData(["marketingPermission": true])
        let apps = write["apps"] as? [String: [String: Any]]
        XCTAssertEqual(Set(apps?.keys.map { $0 } ?? []), ["freeaudiobooks"])
    }

    func testOtherAppDomainAndSchemeCannotOpenThisApp() {
        XCTAssertNil(DeeplinkManager.shared.getLaunchActionFromDeeplinkURL(url: URL(string: "https://links.freebooksapp.org/book-internal/book123")!))
        XCTAssertNil(DeeplinkManager.shared.getLaunchActionFromDeeplinkURL(url: URL(string: "freebooks://book-internal/book123")!))
    }
}

@MainActor
final class FABLinkMigrationTests: XCTestCase {
    func testV4MigrationPreservesBooksAndDownloadedAudioWithoutCopyingFreeBooksURL() throws {
        let bundle = Bundle(for: CDBookInternal.self)
        let directory = try XCTUnwrap(bundle.url(forResource: "FreeAudiobooks", withExtension: "momd"))
        let oldModel = try XCTUnwrap(NSManagedObjectModel(contentsOf: directory.appendingPathComponent("FreeAudiobooksV4.mom")))
        let newModel = try XCTUnwrap(NSManagedObjectModel(contentsOf: directory.appendingPathComponent("FreeAudiobooksV5.mom")))
        // Generic objects let the fixture use historical attributes absent from today's generated class.
        for model in [oldModel, newModel] {
            for entity in model.entities { entity.managedObjectClassName = "NSManagedObject" }
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: url) }
        let storeURL = url.appendingPathComponent("library.sqlite")
        let oldCoordinator = NSPersistentStoreCoordinator(managedObjectModel: oldModel)
        let oldStore = try oldCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL)
        let oldContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        oldContext.persistentStoreCoordinator = oldCoordinator
        func insert(_ name: String) -> NSManagedObject {
            let object = NSEntityDescription.insertNewObject(forEntityName: name, into: oldContext)
            for (key, attribute) in object.entity.attributesByName where !attribute.isOptional && attribute.defaultValue == nil {
                switch attribute.attributeType {
                case .stringAttributeType: object.setValue("fixture", forKey: key)
                case .dateAttributeType: object.setValue(Date(timeIntervalSince1970: 1000), forKey: key)
                case .booleanAttributeType: object.setValue(false, forKey: key)
                case .binaryDataAttributeType: object.setValue(Data(), forKey: key)
                default: break
                }
            }
            return object
        }
        let book = insert("CDBookInternal")
        book.setValue("book123", forKey: "uuid")
        book.setValue("A saved book", forKey: "title")
        book.setValue("https://links.freebooksapp.org/book-internal/book123", forKey: "deeplinkURL")
        let audio = insert("CDBookInternalAudio")
        audio.setValue("book123", forKey: "bookID")
        audio.setValue(Data([1, 2, 3, 4]), forKey: "audioData")
        audio.setValue(false, forKey: "isTemporaryDownload")
        try oldContext.save()
        oldContext.reset()
        try oldCoordinator.remove(oldStore)

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: newModel)
        let store = try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL,
            options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true])
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        let books = try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "CDBookInternal"))
        XCTAssertEqual(books.count, 1)
        let migrated = try XCTUnwrap(books.first)
        XCTAssertEqual(migrated.value(forKey: "title") as? String, "A saved book")
        XCTAssertNil(migrated.entity.attributesByName["deeplinkURL"])
        XCTAssertNil(migrated.value(forKey: "deeplinkURLFAB"))
        let downloads = try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "CDBookInternalAudio"))
        XCTAssertEqual(downloads.count, 1)
        XCTAssertEqual(downloads.first?.value(forKey: "audioData") as? Data, Data([1, 2, 3, 4]))
        XCTAssertEqual(downloads.first?.value(forKey: "isTemporaryDownload") as? Bool, false)
        migrated.setValue("https://links.freeaudiobooksapp.com/book-internal/book123", forKey: "deeplinkURLFAB")
        try context.save()
        context.reset()
        try coordinator.remove(store)
    }

    func testDecoderRequiresFABURLAndIgnoresTheFreeBooksField() throws {
        let fabURL = "https://links.freeaudiobooksapp.com/book-internal/book123"
        var data: [String: Any] = [
            "uuid": "book123", "bookType": "shortStory", "title": "A book", "blurb": "A story",
            "coverImageURLXL": "cover", "coverImageURL": "cover", "coverImageURLThumbnail": "cover",
            "genre": "romance", "readingTimeMinutes": 10, "readerCount": 0,
            "datePublished": Timestamp(date: Date()), "dateUpdated": Timestamp(date: Date()),
            "isHidden": false, "isSubscriptionOnly": false, "containsAdultContent": false,
            "rating": 4.0, "numberOfRatings": 0, "audio": [[String: Any]](),
            "authorName": "Author", "creatorID": "creator", "chapterCount": 1,
            "deeplinkURL": "https://links.freebooksapp.org/book-internal/book123"
        ]
        XCTAssertNil(APIBookInternal(data: data))
        data["deeplinkURLFAB"] = ""
        XCTAssertNil(APIBookInternal(data: data))
        data["deeplinkURLFAB"] = data["deeplinkURL"]
        XCTAssertNil(APIBookInternal(data: data))
        data["deeplinkURLFAB"] = "https://links.freeaudiobooksapp.com/book-internal/another-book"
        XCTAssertNil(APIBookInternal(data: data))
        data["deeplinkURLFAB"] = fabURL
        XCTAssertEqual(try XCTUnwrap(APIBookInternal(data: data)).deeplinkURLFAB, fabURL)
    }
}
