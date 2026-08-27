//
//  ReminderTilesSelectionStateTests.swift
//  FreeAudiobooksTests
//

import XCTest
@testable import FreeAudiobooks

final class ReminderTilesSelectionStateTests: XCTestCase {

    func testTimePeriodBoundaries() {
        XCTAssertEqual(ReminderTimeTilePeriod.period(forHour: 4, minute: 59), .evening)
        XCTAssertEqual(ReminderTimeTilePeriod.period(forHour: 5, minute: 0), .morning)
        XCTAssertEqual(ReminderTimeTilePeriod.period(forHour: 11, minute: 59), .morning)
        XCTAssertEqual(ReminderTimeTilePeriod.period(forHour: 12, minute: 0), .day)
        XCTAssertEqual(ReminderTimeTilePeriod.period(forHour: 17, minute: 59), .day)
        XCTAssertEqual(ReminderTimeTilePeriod.period(forHour: 18, minute: 0), .evening)
        XCTAssertEqual(ReminderTimeTilePeriod.period(forHour: 0, minute: 0), .evening)
        XCTAssertEqual(ReminderTimeTilePeriod.period(forHour: 23, minute: 55), .evening)
    }

    func testSelectingRowsUsesPresetsAndClearsCustomTime() {
        var state = ReminderTilesSelectionState(
            selectedTime: .custom,
            customHour: 9,
            customMinute: 35
        )

        state.selectPreset(.day)

        XCTAssertEqual(state.selectedTime, .afternoon)
        XCTAssertEqual(state.selectedPeriod, .day)
        XCTAssertEqual(state.customHour, 20)
        XCTAssertEqual(state.customMinute, 0)
        XCTAssertEqual(state.displayedTime(for: .day).hour, 13)
        XCTAssertEqual(state.displayedTime(for: .day).minute, 0)
    }

    func testBeginningToEditAnUnselectedRowSelectsItsPreset() {
        var state = ReminderTilesSelectionState(
            selectedTime: .evening,
            customHour: 20,
            customMinute: 0
        )

        let pickerTime = state.beginEditing(.morning)

        XCTAssertEqual(state.selectedTime, .morning)
        XCTAssertEqual(state.selectedPeriod, .morning)
        XCTAssertEqual(pickerTime.hour, 8)
        XCTAssertEqual(pickerTime.minute, 0)
    }

    func testCustomEditsStayInTheirMatchingRow() {
        var state = ReminderTilesSelectionState(
            selectedTime: .morning,
            customHour: 20,
            customMinute: 0
        )

        state.applyCustomTime(hour: 9, minute: 25)

        XCTAssertEqual(state.selectedTime, .custom)
        XCTAssertEqual(state.selectedPeriod, .morning)
        XCTAssertEqual(state.displayedTime(for: .morning).hour, 9)
        XCTAssertEqual(state.displayedTime(for: .morning).minute, 25)
        XCTAssertEqual(state.displayedTime(for: .day).hour, 13)
        XCTAssertEqual(state.displayedTime(for: .evening).hour, 20)
    }

    func testCrossBoundaryEditMovesTheCustomTimeToTheMatchingRow() {
        var state = ReminderTilesSelectionState(
            selectedTime: .morning,
            customHour: 20,
            customMinute: 0
        )

        state.applyCustomTime(hour: 18, minute: 5)

        XCTAssertEqual(state.selectedPeriod, .evening)
        XCTAssertEqual(state.displayedTime(for: .morning).hour, 8)
        XCTAssertEqual(state.displayedTime(for: .evening).hour, 18)
        XCTAssertEqual(state.displayedTime(for: .evening).minute, 5)
    }

    func testRestoredCustomTimeSelectsAndEditsItsMatchingRow() {
        var state = ReminderTilesSelectionState(
            selectedTime: .custom,
            customHour: 14,
            customMinute: 40
        )

        let pickerTime = state.beginEditing(.day)

        XCTAssertEqual(state.selectedTime, .custom)
        XCTAssertEqual(state.selectedPeriod, .day)
        XCTAssertEqual(pickerTime.hour, 14)
        XCTAssertEqual(pickerTime.minute, 40)
    }
}
