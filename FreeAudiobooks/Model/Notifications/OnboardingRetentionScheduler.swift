//
//  OnboardingRetentionScheduler.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 10/04/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import UserNotifications

/// Schedules a sequence of activation nudges across the first ~4-48 hours after
/// a new user grants push permission during onboarding. Nudges are:
///   - Slot 1: T0 + 4h (light reminder)
///   - Slot 2: next day 17:30 local (strongest push)
///   - Slot 3: day 2 17:30 local (final nudge)
///
/// Evening slots are anchored at 17:30 specifically so they sit >2h clear of
/// the 20:00 default daily reminder and survive the ±2h overlap guard.
///
/// Content is segmented by current user behaviour (no book chosen / book chosen
/// but not opened / started reading but not yet activated) and is re-evaluated
/// on state transitions by calling `rescheduleRemaining()`.
///
/// All pending nudges are cancelled once the user hits the `readingActivated`
/// event. Any slot whose fire time lands within ±2h of the user-chosen daily
/// reminder is dropped — the daily reminder always wins.
class OnboardingRetentionScheduler {

    // MARK: - Constants

    /// Flip to `true` locally to test the full schedule end-to-end without
    /// waiting hours. When enabled:
    ///   - Slot 1 fires ~1 minute after T0
    ///   - Slot 2 fires ~3 minutes after T0
    ///   - Slot 3 fires ~5 minutes after T0
    ///   - Quiet-hours shifting and the ±2h daily-reminder overlap guard are
    ///     bypassed so all three slots reliably fire
    /// Note: `UNCalendarNotificationTrigger` drops seconds, so the actual fire
    /// times land at the start of the target minute — the first slot can be
    /// as little as ~1s away from T0 if T0 is late in its minute. That's fine
    /// for testing; production uses 4h / 17:30 which is unaffected.
    /// Revert to `false` before committing — production must use real offsets.
    static let isTestingMode = false

    private static let retentionT0Key = "onboardingRetention_t0"
    private static let retentionWindowSeconds: TimeInterval = 48 * 60 * 60
    private static let overlapBufferSeconds: TimeInterval = 2 * 60 * 60
    private static let quietHoursStartHour = 22
    private static let quietHoursEndHour = 8
    private static let quietHoursShiftHour = 8
    private static let quietHoursShiftMinute = 30

    // MARK: - Types

    enum RetentionSlot: Int, CaseIterable {
        case early = 1        // T0 + 4h
        case dayOneEvening    // Next calendar day @ 17:30 local
        case finalNudge       // T0 + 2 days @ 17:30 local

        var identifier: String {
            return "retention-nudge-\(rawValue)"
        }

        /// Raw computed fire date (pre quiet-hours / overlap adjustments).
        /// Evening slots target 17:30 local — far enough from the 20:00 default
        /// daily reminder to survive the ±2h overlap guard.
        func computeFireDate(from t0: Date) -> Date {
            if OnboardingRetentionScheduler.isTestingMode {
                // 1 / 3 / 5 minutes — offsets cross distinct minute boundaries
                // so the calendar-trigger rounding still lands each slot in a
                // unique, future minute.
                switch self {
                case .early:         return t0.addingTimeInterval(1 * 60)
                case .dayOneEvening: return t0.addingTimeInterval(3 * 60)
                case .finalNudge:    return t0.addingTimeInterval(5 * 60)
                }
            }
            let calendar = Calendar.current
            switch self {
            case .early:
                return t0.addingTimeInterval(4 * 60 * 60)
            case .dayOneEvening:
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: t0) ?? t0
                return calendar.date(bySettingHour: 17, minute: 30, second: 0, of: tomorrow) ?? tomorrow
            case .finalNudge:
                let dayTwo = calendar.date(byAdding: .day, value: 2, to: t0) ?? t0
                return calendar.date(bySettingHour: 17, minute: 30, second: 0, of: dayTwo) ?? dayTwo
            }
        }
    }

    enum RetentionSegment: String {
        case noBookChosen
        case bookChosenNotOpened
        case startedNotActivated
    }

    enum UserInfoKey: String {
        case action
        case source
        case segment
        case slot
    }

    /// Placeholder token used inside Remote Config title/body strings. Replaced
    /// at schedule time with the current book's title for segments where a
    /// specific book is in scope. Falls back to `titleFallback` if nil.
    private static let titlePlaceholder = "{title}"
    private static let titleFallback = "your book"

    static let sourcePrefix = "onboarding-retention-nudge-"

    // MARK: - Public API

    /// True if we're still within the 48h retention window from `T0`.
    static var isInRetentionWindow: Bool {
        guard let t0 = storedT0 else { return false }
        return Date() < t0.addingTimeInterval(retentionWindowSeconds)
    }

    /// Called from `PushNotificationVC` after push permission is granted.
    /// Creates the retention window on first grant only; later calls keep the
    /// original `T0` and just refresh any remaining slots.
    static func scheduleInitialNudges(relativeTo t0: Date = Date()) {
        if storedT0 == nil {
            UserDefaults.standard.set(t0, forKey: retentionT0Key)
            refreshRemainingNudges()
            AnalyticsManager.shared.trackScheduledOnboardingRetentionNudges()
        } else {
            refreshRemainingNudges()
        }
    }

    /// Re-evaluates any remaining nudges without creating or resetting `T0`.
    static func refreshRemainingNudges() {
        rescheduleRemaining()
    }

    /// Re-evaluates segment and reschedules any remaining future slots. Safe to
    /// call on app foreground, after `readingStarted`, etc. Cheap and idempotent.
    static func rescheduleRemaining() {
        guard let t0 = storedT0 else { return }

        // Kill switch via Remote Config.
        guard RCValues.shared.bool(forKey: .shouldSendOnboardingRetentionNudges) else {
            cancelAll(reason: "killSwitch")
            return
        }

        // Terminal state — user has activated. Cancel everything.
        if FirstTimeManager.hasSeen(item: .readingActivated) {
            cancelAll(reason: "activated")
            return
        }

        // Wipe existing pending identifiers so we can re-add cleanly.
        let center = UNUserNotificationCenter.current()
        let allIdentifiers = RetentionSlot.allCases.map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: allIdentifiers)

        let segment = currentSegment()
        // Resolve the current book once per reschedule so slots 1/2/3 all use
        // the same title/UUID. Uses the exact same lookup order as the tap
        // handler in AppDelegate — routing still resolves at tap time, this
        // copy of the book is only for notification *display* + analytics.
        let currentBook = ReadingUserDefaults.getReadingInProgressContent().first
            ?? ReadingUserDefaults.getRecentlyViewedContent(limit: 1).first
        let now = Date()
        let ceiling = t0.addingTimeInterval(retentionWindowSeconds)

        for slot in RetentionSlot.allCases {
            var fireDate = slot.computeFireDate(from: t0)
            // In testing mode we want all three slots to fire reliably, so
            // skip the quiet-hours shift and the overlap guard entirely.
            if !isTestingMode {
                fireDate = quietHoursShifted(fireDate)
            }

            guard fireDate <= ceiling else {
                print("OnboardingRetention: slot \(slot.rawValue) dropped (past 48h ceiling)")
                continue
            }

            guard fireDate > now else {
                // Slot time has already passed — skip silently.
                continue
            }

            if !isTestingMode, overlapsDailyReminder(fireDate) {
                print("OnboardingRetention: slot \(slot.rawValue) dropped (within ±2h of daily reminder)")
                continue
            }

            schedule(slot: slot, segment: segment, fireDate: fireDate, book: currentBook)
        }
    }

    /// Cancels all retention nudges and clears stored `T0`.
    static func cancelAll(reason: String = "manual") {
        let center = UNUserNotificationCenter.current()
        let allIdentifiers = RetentionSlot.allCases.map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: allIdentifiers)
        UserDefaults.standard.removeObject(forKey: retentionT0Key)
        AnalyticsManager.shared.trackCancelledOnboardingRetentionNudges(reason: reason)
        print("OnboardingRetention: cancelled all (reason: \(reason))")
    }

    // MARK: - Helpers

    private static var storedT0: Date? {
        return UserDefaults.standard.object(forKey: retentionT0Key) as? Date
    }

    private static func currentSegment() -> RetentionSegment {
        // readingStarted is the strongest signal — user has opened a book.
        if FirstTimeManager.hasSeen(item: .readingStarted) {
            return .startedNotActivated
        }

        let hasInProgress = !ReadingUserDefaults.getReadingInProgressContent().isEmpty
        let hasRecentlyViewed = !ReadingUserDefaults.getRecentlyViewedContent(limit: 1).isEmpty

        if hasInProgress || hasRecentlyViewed {
            return .bookChosenNotOpened
        }

        return .noBookChosen
    }

    /// If `date` falls inside quiet hours (22:00–08:00), shift to 08:30 of the
    /// following morning (same morning if already pre-08:00).
    private static func quietHoursShifted(_ date: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        let inQuietHours = hour >= quietHoursStartHour || hour < quietHoursEndHour
        guard inQuietHours else { return date }

        let baseDay: Date
        if hour >= quietHoursStartHour {
            baseDay = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        } else {
            baseDay = date
        }

        return calendar.date(
            bySettingHour: quietHoursShiftHour,
            minute: quietHoursShiftMinute,
            second: 0,
            of: baseDay
        ) ?? date
    }

    /// Returns true if `date` falls within ±2h of the user-chosen daily reminder
    /// time (on the same calendar day as `date`).
    private static func overlapsDailyReminder(_ date: Date) -> Bool {
        guard let (drHour, drMinute) = dailyReminderHourMinute() else {
            return false
        }

        let calendar = Calendar.current
        guard let dailyReminderOnSameDay = calendar.date(
            bySettingHour: drHour,
            minute: drMinute,
            second: 0,
            of: date
        ) else {
            return false
        }

        let diff = abs(date.timeIntervalSince(dailyReminderOnSameDay))
        return diff < overlapBufferSeconds
    }

    /// Reads the onboarding-selected reminder time for overlap checks.
    private static func dailyReminderHourMinute() -> (Int, Int)? {
        guard let timeRaw = NewOnboardingUserDefaults.getSelectedReminderTime(),
              let time = ReminderTime(rawValue: timeRaw) else {
            return nil
        }
        if time == .custom, let custom = NewOnboardingUserDefaults.getCustomReminderTime() {
            return (custom.hour, custom.minute)
        }
        return (time.hour, 0)
    }

    private static func schedule(
        slot: RetentionSlot,
        segment: RetentionSegment,
        fireDate: Date,
        book: ReadableContentMetadata?
    ) {
        let copy = copyFor(slot: slot, segment: segment, bookTitle: book?.title)

        // Guard against blank Remote Config values — never schedule an empty push.
        guard !copy.title.isEmpty, !copy.body.isEmpty else {
            print("OnboardingRetention: skipping slot \(slot.rawValue) — empty copy for segment \(segment.rawValue)")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = copy.title
        content.body = copy.body
        content.sound = .default
        content.userInfo = [
            UserInfoKey.action.rawValue: DailyReminderScheduler.NotificationAction.continueReading.rawValue,
            UserInfoKey.source.rawValue: "\(sourcePrefix)\(slot.rawValue)",
            UserInfoKey.segment.rawValue: segment.rawValue,
            UserInfoKey.slot.rawValue: slot.rawValue
        ]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: slot.identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("OnboardingRetention: failed slot \(slot.rawValue): \(error.localizedDescription)")
            } else {
                print("OnboardingRetention: scheduled slot \(slot.rawValue) [\(segment.rawValue)] for \(fireDate)")
            }
        }
    }

    private static func copyFor(
        slot: RetentionSlot,
        segment: RetentionSegment,
        bookTitle: String?
    ) -> (title: String, body: String) {
        let rc = RCValues.shared
        let rawCopy: (title: String, body: String)
        switch (slot, segment) {
        case (.early, .noBookChosen):
            rawCopy = (rc.string(forKey: .retentionNudgeEarlyNoBookTitle),
                       rc.string(forKey: .retentionNudgeEarlyNoBookBodyAB))
        case (.early, .bookChosenNotOpened):
            rawCopy = (rc.string(forKey: .retentionNudgeEarlyBookChosenTitle),
                       rc.string(forKey: .retentionNudgeEarlyBookChosenBody))
        case (.early, .startedNotActivated):
            rawCopy = (rc.string(forKey: .retentionNudgeEarlyStartedTitle),
                       rc.string(forKey: .retentionNudgeEarlyStartedBodyAB))
        case (.dayOneEvening, .noBookChosen):
            rawCopy = (rc.string(forKey: .retentionNudgeEveningNoBookTitle),
                       rc.string(forKey: .retentionNudgeEveningNoBookBodyAB))
        case (.dayOneEvening, .bookChosenNotOpened):
            rawCopy = (rc.string(forKey: .retentionNudgeEveningBookChosenTitle),
                       rc.string(forKey: .retentionNudgeEveningBookChosenBodyAB))
        case (.dayOneEvening, .startedNotActivated):
            rawCopy = (rc.string(forKey: .retentionNudgeEveningStartedTitle),
                       rc.string(forKey: .retentionNudgeEveningStartedBody))
        case (.finalNudge, .noBookChosen):
            rawCopy = (rc.string(forKey: .retentionNudgeFinalNoBookTitleAB),
                       rc.string(forKey: .retentionNudgeFinalNoBookBodyAB))
        case (.finalNudge, .bookChosenNotOpened):
            rawCopy = (rc.string(forKey: .retentionNudgeFinalBookChosenTitle),
                       rc.string(forKey: .retentionNudgeFinalBookChosenBodyAB))
        case (.finalNudge, .startedNotActivated):
            rawCopy = (rc.string(forKey: .retentionNudgeFinalStartedTitle),
                       rc.string(forKey: .retentionNudgeFinalStartedBody))
        }

        return (interpolate(rawCopy.title, bookTitle: bookTitle),
                interpolate(rawCopy.body, bookTitle: bookTitle))
    }

    /// Replaces the `{title}` placeholder with the current book title, or a
    /// safe fallback (`"your book"`) when no book is in scope. Mirrors the
    /// `metadata.title ?? "a great book"` pattern used elsewhere in the app.
    private static func interpolate(_ template: String, bookTitle: String?) -> String {
        guard template.contains(titlePlaceholder) else { return template }
        let replacement = (bookTitle?.isEmpty == false ? bookTitle : nil) ?? titleFallback
        return template.replacingOccurrences(of: titlePlaceholder, with: replacement)
    }
}
