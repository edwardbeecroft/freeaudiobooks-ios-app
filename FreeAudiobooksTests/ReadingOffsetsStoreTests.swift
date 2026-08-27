import XCTest
@testable import FreeAudiobooks

final class ReadingOffsetsStoreTests: XCTestCase {
    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private let key = "testReadingOffsets"

    override func setUp() {
        super.setUp()
        suiteName = "ReadingOffsetsStoreTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testSetOffsetUpdatesCacheAndPersistentStoreImmediately() {
        let store = ReadingOffsetsStore(userDefaults: userDefaults, key: key)

        store.setOffset(
            bookUUID: "book-1",
            currentSection: 2,
            totalSections: 10,
            currentSectionYOffset: 40,
            currentSectionTotalYOffset: 100
        )

        assertOffset(store.offset(for: "book-1"), currentSection: 2, yOffset: 40)

        let freshlyLoadedStore = ReadingOffsetsStore(userDefaults: userDefaults, key: key)
        assertOffset(freshlyLoadedStore.offset(for: "book-1"), currentSection: 2, yOffset: 40)

        store.setOffset(
            bookUUID: "book-1",
            currentSection: 3,
            totalSections: 10,
            currentSectionYOffset: 60,
            currentSectionTotalYOffset: 100
        )

        assertOffset(store.offset(for: "book-1"), currentSection: 3, yOffset: 60)
    }

    func testExternalPersistentChangeRefreshesWarmCache() throws {
        let store = ReadingOffsetsStore(userDefaults: userDefaults, key: key)
        XCTAssertTrue(store.offsets().isEmpty)

        let externallyWrittenOffset = ReadingOffset(
            bookUUID: "external-book",
            currentSection: 4,
            totalSections: 12,
            currentSectionYOffset: 75,
            currentSectionTotalYOffset: 100
        )
        userDefaults.set(
            try JSONEncoder().encode([externallyWrittenOffset]),
            forKey: key
        )

        assertOffset(store.offset(for: "external-book"), currentSection: 4, yOffset: 75)

        userDefaults.removeObject(forKey: key)
        XCTAssertTrue(store.offsets().isEmpty)
    }

    func testClearOffsetAndClearAllUpdateCacheAndPersistentStore() {
        let store = ReadingOffsetsStore(userDefaults: userDefaults, key: key)
        store.setOffset(
            bookUUID: "book-1",
            currentSection: 1,
            totalSections: 10,
            currentSectionYOffset: 20,
            currentSectionTotalYOffset: 100
        )
        store.setOffset(
            bookUUID: "book-2",
            currentSection: 2,
            totalSections: 10,
            currentSectionYOffset: 40,
            currentSectionTotalYOffset: 100
        )

        store.clearOffset(bookUUID: "book-1")
        XCTAssertNil(store.offset(for: "book-1"))
        assertOffset(store.offset(for: "book-2"), currentSection: 2, yOffset: 40)

        store.clearOffsets()
        XCTAssertTrue(store.offsets().isEmpty)
        XCTAssertNil(userDefaults.data(forKey: key))
    }

    private func assertOffset(
        _ offset: ReadingOffset?,
        currentSection: Int,
        yOffset: CGFloat,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertNotNil(offset, file: file, line: line)
        XCTAssertEqual(offset?.currentSection, currentSection, file: file, line: line)
        XCTAssertEqual(offset?.currentSectionYOffset, yOffset, file: file, line: line)
    }
}

final class TemporaryTextRetentionPolicyTests: XCTestCase {
    func testResumeBookIsRetainedRegardlessOfProgressOrAge() {
        XCTAssertTrue(
            TemporaryTextRetentionPolicy.shouldRetain(
                contentUUID: "resume-book",
                resumeBookUUID: "resume-book",
                hasStartedReading: false,
                daysSinceLastRead: 300
            )
        )
    }

    func testInProgressTextIsRetainedBeforeThirtyDays() {
        for daysSinceLastRead in [0, 29] {
            XCTAssertTrue(
                TemporaryTextRetentionPolicy.shouldRetain(
                    contentUUID: "book",
                    resumeBookUUID: nil,
                    hasStartedReading: true,
                    daysSinceLastRead: daysSinceLastRead
                )
            )
        }
    }

    func testInProgressTextIsDeletedAtThirtyDaysAndBeyond() {
        for daysSinceLastRead in [30, 31] {
            XCTAssertFalse(
                TemporaryTextRetentionPolicy.shouldRetain(
                    contentUUID: "book",
                    resumeBookUUID: nil,
                    hasStartedReading: true,
                    daysSinceLastRead: daysSinceLastRead
                )
            )
        }
    }

    func testTextWithoutProgressIsDeleted() {
        XCTAssertFalse(
            TemporaryTextRetentionPolicy.shouldRetain(
                contentUUID: "book",
                resumeBookUUID: nil,
                hasStartedReading: false,
                daysSinceLastRead: 0
            )
        )
    }

    func testTextWithoutLastReadDateIsDeleted() {
        XCTAssertFalse(
            TemporaryTextRetentionPolicy.shouldRetain(
                contentUUID: "book",
                resumeBookUUID: nil,
                hasStartedReading: true,
                daysSinceLastRead: nil
            )
        )
    }
}
