//
//  FreeAudiobooksTests.swift
//  FreeAudiobooksTests
//
//  Created by Ed Beecroft on 15/07/2019.
//  Copyright © 2019 AIDA. All rights reserved.
//

import XCTest
@testable import FreeAudiobooks

final class AvatarInitialsTests: XCTestCase {

    func testFirstAndLastNamesUseBothInitials() {
        XCTAssertEqual(AvatarInitials.from(firstName: "Ed", lastName: "Beecroft"), "EB")
    }

    func testMultiWordDisplayNameUsesFirstAndLastWords() {
        XCTAssertEqual(AvatarInitials.from(displayName: "Mary Jane Watson"), "MW")
    }

    func testSingleNameUsesOneInitial() {
        XCTAssertEqual(AvatarInitials.from(displayName: "Plato"), "P")
        XCTAssertEqual(AvatarInitials.from(firstName: "Plato", lastName: nil), "P")
    }

    func testWhitespaceIsTrimmed() {
        XCTAssertEqual(AvatarInitials.from(displayName: "  Ed   Beecroft  \n"), "EB")
        XCTAssertEqual(AvatarInitials.from(firstName: " Ed ", lastName: " Beecroft "), "EB")
    }

    func testMissingNamesUseFreeAudiobooksFallback() {
        XCTAssertEqual(AvatarInitials.from(displayName: nil), "FA")
        XCTAssertEqual(AvatarInitials.from(displayName: "  \n "), "FA")
        XCTAssertEqual(AvatarInitials.from(firstName: nil, lastName: nil), "FA")
        XCTAssertEqual(AvatarInitials.from(firstName: " ", lastName: "\n"), "FA")
    }
}

class AIDATests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}

final class BookDetailMetadataTests: XCTestCase {

    func testListeningTimeFormatting() {
        XCTAssertNil(BookDetailVC.listeningTimeText(minutes: 0))
        XCTAssertEqual(BookDetailVC.listeningTimeText(minutes: 42), "42 min")
        XCTAssertEqual(BookDetailVC.listeningTimeText(minutes: 60), "1 hr")
        XCTAssertEqual(BookDetailVC.listeningTimeText(minutes: 65), "1 hr 5 min")
        XCTAssertEqual(BookDetailVC.listeningTimeText(minutes: 105), "1 hr 45 min")
        XCTAssertEqual(BookDetailVC.listeningTimeText(minutes: 120), "2 hr")
    }

    func testRatingRequiresFiveRatings() {
        XCTAssertFalse(BookDetailVC.hasDisplayableRating(numberOfRatings: nil))
        XCTAssertFalse(BookDetailVC.hasDisplayableRating(numberOfRatings: 0))
        XCTAssertFalse(BookDetailVC.hasDisplayableRating(numberOfRatings: 4))
        XCTAssertTrue(BookDetailVC.hasDisplayableRating(numberOfRatings: 5))
    }

    func testRatingChipUsesTwoDecimalPlaces() {
        XCTAssertEqual(BookDetailRatingChipView.formattedRating(4.4), "4.40")
        XCTAssertEqual(BookDetailRatingChipView.formattedRating(4.456), "4.46")
    }
}

final class SmallMetadataViewTests: XCTestCase {

    func testDurationIsShownBeforeProgressStarts() {
        XCTAssertEqual(
            SmallMetadataView.metadataText(
                duration: "2 hr 20 min",
                isCompleted: false,
                progressPercentage: nil
            ),
            "2 hr 20 min"
        )
    }

    func testProgressReplacesDuration() {
        XCTAssertEqual(
            SmallMetadataView.metadataText(
                duration: "2 hr 20 min",
                isCompleted: false,
                progressPercentage: 40
            ),
            "40% completed"
        )
    }

    func testCompletionReplacesProgressAndDuration() {
        XCTAssertEqual(
            SmallMetadataView.metadataText(
                duration: "2 hr 20 min",
                isCompleted: true,
                progressPercentage: 100
            ),
            "Completed"
        )
    }

    func testReleaseAndDownloadedFileSizeArePreserved() {
        XCTAssertEqual(
            SmallMetadataView.metadataText(
                duration: "2 hr 20 min",
                isCompleted: false,
                progressPercentage: nil,
                releaseText: "Releases 26 Aug 2026",
                fileSize: "52 MB"
            ),
            "Releases 26 Aug 2026 · 52 MB"
        )
    }

    func testMissingDurationAndProgressShowsNotStarted() {
        XCTAssertEqual(
            SmallMetadataView.metadataText(
                duration: nil,
                isCompleted: false,
                progressPercentage: nil
            ),
            "Not started"
        )
    }

    func testAuthorIsUsedWhenGenreIsUnavailable() {
        XCTAssertEqual(
            SmallMetadataView.secondaryText(genre: nil, authors: "Jane Austen"),
            "Jane Austen"
        )
        XCTAssertEqual(
            SmallMetadataView.secondaryText(genre: " Romance ", authors: "Jane Austen"),
            "Romance"
        )
    }

    func testMissingMetadataCannotCollapseRowHeight() {
        let view = SmallMetadataView()
        let fittingSize = view.systemLayoutSizeFitting(
            CGSize(width: 390, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        XCTAssertGreaterThanOrEqual(fittingSize.height, 80)
    }
}
