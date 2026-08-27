//
//  AudioPlaybackProgressManagerTests.swift
//  FreeAudiobooksTests
//
//  Created by Codex on 03/07/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import XCTest
@testable import FreeAudiobooks

final class AudioPlayerManagerSleepTimerTests: XCTestCase, AudioPlayerManagerDelegate {

    private let manager = AudioPlayerManager.shared
    private var observedTimerDurations: [TimeInterval?] = []
    private var expirationExpectation: XCTestExpectation?

    override func setUp() {
        super.setUp()
        manager.delegate = nil
        manager.cancelSleepTimer()
        observedTimerDurations = []
        expirationExpectation = nil
        manager.delegate = self
    }

    override func tearDown() {
        manager.delegate = nil
        manager.cancelSleepTimer()
        expirationExpectation = nil
        super.tearDown()
    }

    func testSettingSleepTimerPublishesDurationAndDeadline() throws {
        let startDate = Date()

        manager.setSleepTimer(duration: 60)

        XCTAssertEqual(manager.activeSleepTimerDuration, 60)
        XCTAssertEqual(observedTimerDurations, [60])

        let endDate = try XCTUnwrap(manager.sleepTimerEndDate)
        XCTAssertEqual(endDate.timeIntervalSince(startDate), 60, accuracy: 0.25)

        let remainingTime = try XCTUnwrap(manager.sleepTimerRemainingTime)
        XCTAssertGreaterThan(remainingTime, 59)
        XCTAssertLessThanOrEqual(remainingTime, 60)
    }

    func testReplacingSleepTimerInvalidatesPreviousDeadline() {
        manager.setSleepTimer(duration: 0.05)
        manager.setSleepTimer(duration: 60)

        let replacementSurvives = expectation(description: "Replacement timer remains active")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            XCTAssertEqual(self.manager.activeSleepTimerDuration, 60)
            XCTAssertEqual(self.observedTimerDurations, [0.05, 60])
            replacementSurvives.fulfill()
        }

        wait(for: [replacementSurvives], timeout: 1)
    }

    func testCancellingSleepTimerClearsStateAndPublishesCancellation() {
        manager.setSleepTimer(duration: 60)

        manager.cancelSleepTimer()

        XCTAssertNil(manager.activeSleepTimerDuration)
        XCTAssertNil(manager.sleepTimerEndDate)
        XCTAssertNil(manager.sleepTimerRemainingTime)
        XCTAssertEqual(observedTimerDurations, [60, nil])
    }

    func testSleepTimerExpiryClearsStateAndPublishesCancellation() {
        expirationExpectation = expectation(description: "Sleep timer expires")

        manager.setSleepTimer(duration: 0.05)

        wait(for: [expirationExpectation!], timeout: 1)
        XCTAssertNil(manager.activeSleepTimerDuration)
        XCTAssertNil(manager.sleepTimerEndDate)
        XCTAssertNil(manager.sleepTimerRemainingTime)
        XCTAssertEqual(observedTimerDurations, [0.05, nil])
    }

    func audioPlayerDidUpdateTime(_ currentTime: TimeInterval, duration: TimeInterval) {}

    func audioPlayerDidChangePlaybackState(_ isPlaying: Bool) {}

    func audioPlayerSleepTimerDidChange(_ selectedDuration: TimeInterval?) {
        observedTimerDurations.append(selectedDuration)
        if selectedDuration == nil {
            expirationExpectation?.fulfill()
        }
    }

    func audioPlayerDidFinishPlaying() {}

    func audioPlayerDidFail(with error: Error) {}
}

final class AudioPlaybackProgressManagerTests: XCTestCase {

    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var manager: AudioPlaybackProgressManager!
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    override func setUpWithError() throws {
        try super.setUpWithError()
        suiteName = "AudioPlaybackProgressManagerTests-\(UUID().uuidString)"
        userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)
        manager = AudioPlaybackProgressManager(userDefaults: userDefaults, now: { self.now })
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        manager = nil
        userDefaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testProgressRoundTripsPositionDurationAndUpdatedAt() throws {
        manager.savePosition(42, for: "book-1")
        manager.saveDuration(300, for: "book-1")

        let progress = try XCTUnwrap(manager.getProgress(for: "book-1"))
        XCTAssertEqual(progress.bookUUID, "book-1")
        XCTAssertEqual(progress.position, 42)
        XCTAssertEqual(progress.duration, 300)
        XCTAssertEqual(progress.updatedAt, now)
    }

    func testLegacyPositionFallbackWorksWithoutNewRecord() throws {
        userDefaults.set(123, forKey: "audiobook_position_book-legacy")

        let progress = try XCTUnwrap(manager.getProgress(for: "book-legacy"))
        XCTAssertEqual(progress.bookUUID, "book-legacy")
        XCTAssertEqual(progress.position, 123)
        XCTAssertEqual(progress.duration, 0)
    }

    func testSavingPositionPreservesDuration() throws {
        manager.saveDuration(600, for: "book-1")
        manager.savePosition(120, for: "book-1")

        let progress = try XCTUnwrap(manager.getProgress(for: "book-1"))
        XCTAssertEqual(progress.position, 120)
        XCTAssertEqual(progress.duration, 600)
    }

    func testSavingDurationPreservesPosition() throws {
        manager.savePosition(90, for: "book-1")
        manager.saveDuration(450, for: "book-1")

        let progress = try XCTUnwrap(manager.getProgress(for: "book-1"))
        XCTAssertEqual(progress.position, 90)
        XCTAssertEqual(progress.duration, 450)
    }

    func testClearProgressRemovesNewAndLegacyKeys() {
        manager.savePosition(90, for: "book-1")
        userDefaults.set(120, forKey: "audiobook_position_book-1")

        manager.clearProgress(for: "book-1")

        XCTAssertNil(manager.getProgress(for: "book-1"))
        XCTAssertNil(userDefaults.object(forKey: "audiobook_position_book-1"))
    }

    func testClearAllProgressRemovesNewAndLegacyKeys() {
        manager.savePosition(90, for: "book-1")
        userDefaults.set(120, forKey: "audiobook_position_book-legacy")

        manager.clearAllProgress()

        XCTAssertNil(manager.getProgress(for: "book-1"))
        XCTAssertNil(manager.getProgress(for: "book-legacy"))
    }

    func testUUIDListingIncludesNewAndLegacyRecordsWithoutDuplicates() {
        manager.savePosition(90, for: "book-1")
        userDefaults.set(120, forKey: "audiobook_position_book-legacy")
        userDefaults.set(240, forKey: "audiobook_position_book-1")

        XCTAssertEqual(Set(manager.getBookUUIDsWithSavedProgress()), ["book-1", "book-legacy"])
    }
}
