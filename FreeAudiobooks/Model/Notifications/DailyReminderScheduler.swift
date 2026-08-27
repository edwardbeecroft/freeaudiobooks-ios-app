//
//  DailyReminderScheduler.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 28/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import UserNotifications

/// Handles scheduling and cancelling daily listening reminder notifications
class DailyReminderScheduler {

    // MARK: - Constants

    private static let dailyReminderIdentifier = "daily-reading-reminder"

    /// Keys used in notification userInfo dictionary
    enum UserInfoKey: String {
        case action
        case source
    }

    /// Actions that can be triggered by tapping a notification
    enum NotificationAction: String {
        case continueReading = "continue-reading"
    }

    /// Source identifiers for analytics tracking
    enum NotificationSource: String {
        case dailyReminder = "daily-reminder"
    }

    // MARK: - Public Methods

    /// Checks if a daily reminder is currently scheduled
    /// - Parameter completion: Returns true if daily reminder exists in pending requests
    static func hasDailyReminderScheduled(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let hasDaily = requests.contains { $0.identifier == dailyReminderIdentifier }
            DispatchQueue.main.async {
                completion(hasDaily)
            }
        }
    }

    /// Schedules a daily repeating notification at the specified time
    /// - Parameters:
    ///   - time: The preferred time of day for the reminder
    ///   - goalMinutes: The user's daily listening goal in minutes
    ///   - customHour: Custom hour (0-23) when time is .custom
    ///   - customMinute: Custom minute (0-59) when time is .custom
    static func scheduleDaily(at time: ReminderTime, goalMinutes: Int, customHour: Int? = nil, customMinute: Int? = nil) {
        let center = UNUserNotificationCenter.current()

        // Cancel existing daily reminder first
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderIdentifier])

        let content = UNMutableNotificationContent()
        content.title = RCValues.shared.string(forKey: .dailyReminderNotificationTitleAB)
            .replacingOccurrences(of: "{minutes}", with: "\(goalMinutes)")
        content.body = RCValues.shared.string(forKey: .dailyReminderNotificationBody)
        content.sound = .default

        // Action-based userInfo - AppDelegate fetches current last-read book at tap time
        content.userInfo = [
            UserInfoKey.action.rawValue: NotificationAction.continueReading.rawValue,
            UserInfoKey.source.rawValue: NotificationSource.dailyReminder.rawValue
        ]

        var dateComponents = DateComponents()
        if time == .custom, let hour = customHour {
            dateComponents.hour = hour
            dateComponents.minute = customMinute ?? 0
        } else {
            dateComponents.hour = time.hour
            dateComponents.minute = 0
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: dailyReminderIdentifier,
            content: content,
            trigger: trigger
        )

        let timeString = time == .custom ? "Custom (\(dateComponents.hour ?? 0):\(String(format: "%02d", dateComponents.minute ?? 0)))" : time.displayString
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule daily reminder: \(error.localizedDescription)")
            } else {
                AnalyticsManager.shared.trackScheduledDailyReminderNotification()
                print("Daily reminder scheduled for \(timeString)")
            }
        }
    }

    /// Cancels any pending daily listening reminder
    static func cancelDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderIdentifier])
        print("Daily reminder cancelled")
    }

    /// Updates the existing reminder with a new time (reschedules)
    /// - Parameters:
    ///   - time: The new preferred time
    ///   - goalMinutes: The user's daily listening goal in minutes
    ///   - customHour: Custom hour (0-23) when time is .custom
    ///   - customMinute: Custom minute (0-59) when time is .custom
    static func updateReminderTime(_ time: ReminderTime, goalMinutes: Int, customHour: Int? = nil, customMinute: Int? = nil) {
        // Simply reschedule - this will cancel existing and create new
        scheduleDaily(at: time, goalMinutes: goalMinutes, customHour: customHour, customMinute: customMinute)
    }
}
