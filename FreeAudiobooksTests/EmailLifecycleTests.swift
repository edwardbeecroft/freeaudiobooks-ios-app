import XCTest
import CoreData
import FirebaseFirestore
@testable import FreeAudiobooks

@MainActor
final class EmailLifecycleTests: XCTestCase {
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
