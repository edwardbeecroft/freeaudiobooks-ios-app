//
//  ListeningQuotaManagerTests.swift
//  FreeAudiobooksTests
//
//  Created by Codex on 20/05/2026.
//  Copyright © 2026 AIDA. All rights reserved.
//

import XCTest
@testable import FreeAudiobooks

final class ListeningQuotaManagerTests: XCTestCase {

    func testFreshWindowStartsWithFullAllowance() {
        let state = ListeningQuotaState(bookUUIDs: [], weekStartedAt: nil, now: Date())

        XCTAssertEqual(state.remaining(limit: 3), 3)
        XCTAssertTrue(state.canListen(contentUUID: "book-1", limit: 3))
    }

    func testRepeatedUUIDDoesNotConsumeAdditionalAllowance() {
        let now = Date()
        let state = ListeningQuotaState(bookUUIDs: ["book-1"], weekStartedAt: now, now: now)
        let next = state.nextRecordedState(consuming: "book-1")

        XCTAssertEqual(next.bookUUIDs, ["book-1"])
        XCTAssertEqual(state.remaining(limit: 3), 2)
        XCTAssertTrue(state.canListen(contentUUID: "book-1", limit: 3))
    }

    func testAllowanceExhaustsAtLimitForNewBooks() {
        let now = Date()
        let state = ListeningQuotaState(
            bookUUIDs: ["book-1", "book-2", "book-3"],
            weekStartedAt: now,
            now: now
        )

        XCTAssertEqual(state.remaining(limit: 3), 0)
        XCTAssertFalse(state.canListen(contentUUID: "book-4", limit: 3))
        XCTAssertTrue(state.canListen(contentUUID: "book-3", limit: 3))
    }

    func testRollingWindowResetsAfterSevenDays() {
        let startedAt = Date(timeIntervalSince1970: 1_000)
        let now = startedAt.addingTimeInterval(ListeningQuotaState.windowDuration + 1)
        let state = ListeningQuotaState(
            bookUUIDs: ["book-1", "book-2", "book-3"],
            weekStartedAt: startedAt,
            now: now
        )
        let next = state.nextRecordedState(consuming: "book-4")

        XCTAssertEqual(state.normalisedBookUUIDs, [])
        XCTAssertEqual(state.remaining(limit: 3), 3)
        XCTAssertEqual(next.bookUUIDs, ["book-4"])
        XCTAssertEqual(next.weekStartedAt, now)
    }
}
