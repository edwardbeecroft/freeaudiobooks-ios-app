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

final class EngagementNotificationTimingTests: XCTestCase {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testNonCollidingEngagementDateIsUnchanged() throws {
        let proposed = try makeDate(day: 10, hour: 17, minute: 59)
        let reminder = DateComponents(hour: 20, minute: 0)

        let adjusted = EngagementNotificationTiming.adjustedFireDate(
            proposedFireDate: proposed,
            dailyReminderTimeComponents: reminder,
            calendar: calendar
        )

        XCTAssertEqual(adjusted, proposed)
    }

    func testEveningCollisionMovesToNextMorningOutsideQuietHours() throws {
        let proposed = try makeDate(day: 10, hour: 19, minute: 0)
        let reminder = DateComponents(hour: 20, minute: 0)

        let adjusted = EngagementNotificationTiming.adjustedFireDate(
            proposedFireDate: proposed,
            dailyReminderTimeComponents: reminder,
            calendar: calendar
        )

        XCTAssertEqual(adjusted, try makeDate(day: 11, hour: 8, minute: 30))
    }

    func testMorningCollisionMovesAfterReminderBuffer() throws {
        let proposed = try makeDate(day: 10, hour: 8, minute: 30)
        let reminder = DateComponents(hour: 8, minute: 0)

        let adjusted = EngagementNotificationTiming.adjustedFireDate(
            proposedFireDate: proposed,
            dailyReminderTimeComponents: reminder,
            calendar: calendar
        )

        XCTAssertEqual(adjusted, try makeDate(day: 10, hour: 10, minute: 30))
    }

    func testQuietHoursMoveToNextMorningWithoutDailyReminder() throws {
        let proposed = try makeDate(day: 10, hour: 23, minute: 15)

        let adjusted = EngagementNotificationTiming.adjustedFireDate(
            proposedFireDate: proposed,
            dailyReminderTimeComponents: nil,
            calendar: calendar
        )

        XCTAssertEqual(adjusted, try makeDate(day: 11, hour: 8, minute: 30))
    }

    func testLegacyMilestoneWithoutModeDefaultsToText() throws {
        let data = try XCTUnwrap(
            """
            {
              "bookUUID": "book-1",
              "bookTitle": "A Book",
              "bookCoverImageURL": "https://example.com/cover.jpg",
              "contentTypeString": "bookInternal"
            }
            """.data(using: .utf8)
        )

        let milestone = try JSONDecoder().decode(BookProgressMilestone.self, from: data)

        XCTAssertEqual(milestone.mode, .text)
    }

    func testEngagementCadenceHasInitialAndSevenDayFollowUp() {
        XCTAssertEqual(EngagementNotificationStage.allCases, [.initial, .followUp])
        XCTAssertEqual(EngagementNotificationStage.initial.defaultDelayDays, 2)
        XCTAssertEqual(EngagementNotificationStage.followUp.defaultDelayDays, 7)
        XCTAssertNotEqual(
            EngagementNotificationStage.initial.identifier,
            EngagementNotificationStage.followUp.identifier
        )
    }

    private func makeDate(day: Int, hour: Int, minute: Int) throws -> Date {
        try XCTUnwrap(
            calendar.date(
                from: DateComponents(
                    year: 2027,
                    month: 1,
                    day: day,
                    hour: hour,
                    minute: minute
                )
            )
        )
    }
}
