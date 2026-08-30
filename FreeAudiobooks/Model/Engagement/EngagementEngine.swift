//
//  EngagementEngine.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 06/11/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import UserNotifications
import Kingfisher
import UniformTypeIdentifiers

struct BookProgressMilestone: Codable {
    let bookUUID: String
    let bookTitle: String
    let bookCoverImageURL: String
    // let progressPercentage: Int // In case we wanted to show the % in a book
    let contentTypeString: String // Maps to contentType enum
    let mode: LastReadMode

    init(
        bookUUID: String,
        bookTitle: String,
        bookCoverImageURL: String,
        contentTypeString: String,
        mode: LastReadMode
    ) {
        self.bookUUID = bookUUID
        self.bookTitle = bookTitle
        self.bookCoverImageURL = bookCoverImageURL
        self.contentTypeString = contentTypeString
        self.mode = mode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bookUUID = try container.decode(String.self, forKey: .bookUUID)
        bookTitle = try container.decode(String.self, forKey: .bookTitle)
        bookCoverImageURL = try container.decode(String.self, forKey: .bookCoverImageURL)
        contentTypeString = try container.decode(String.self, forKey: .contentTypeString)
        mode = try container.decodeIfPresent(LastReadMode.self, forKey: .mode) ?? .text
    }
}

struct EngagementNotificationTiming {
    static let overlapBuffer: TimeInterval = 2 * 60 * 60

    private static let postReminderSpacing: TimeInterval = overlapBuffer + (30 * 60)
    private static let quietHoursStartHour = 22
    private static let quietHoursEndHour = 8
    private static let quietHoursShiftMinute = 30

    static func adjustedFireDate(
        proposedFireDate: Date,
        dailyReminderTimeComponents: DateComponents?,
        calendar: Calendar = .current
    ) -> Date {
        var candidate = shiftedOutOfQuietHours(proposedFireDate, calendar: calendar)

        guard let reminderHour = dailyReminderTimeComponents?.hour else {
            return candidate
        }
        let reminderMinute = dailyReminderTimeComponents?.minute ?? 0

        // Re-check after a shift because moving out of quiet hours can put the
        // notification close to the following day's reminder.
        for _ in 0..<3 {
            var reminderComponents = calendar.dateComponents([.year, .month, .day], from: candidate)
            reminderComponents.hour = reminderHour
            reminderComponents.minute = reminderMinute
            reminderComponents.second = 0

            guard let reminderDate = calendar.date(from: reminderComponents) else {
                return candidate
            }

            guard abs(candidate.timeIntervalSince(reminderDate)) <= overlapBuffer else {
                return candidate
            }

            candidate = shiftedOutOfQuietHours(
                reminderDate.addingTimeInterval(postReminderSpacing),
                calendar: calendar
            )
        }

        return candidate
    }

    private static func shiftedOutOfQuietHours(_ date: Date, calendar: Calendar) -> Date {
        let hour = calendar.component(.hour, from: date)
        guard hour >= quietHoursStartHour || hour < quietHoursEndHour else {
            return date
        }

        let targetDay: Date
        if hour >= quietHoursStartHour {
            targetDay = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        } else {
            targetDay = date
        }

        return calendar.date(
            bySettingHour: quietHoursEndHour,
            minute: quietHoursShiftMinute,
            second: 0,
            of: targetDay
        ) ?? date
    }
}

enum EngagementNotificationStage: String, CaseIterable {
    case initial
    case followUp

    var identifier: String {
        switch self {
        case .initial: return "book-progress-engagement"
        case .followUp: return "book-progress-engagement-follow-up"
        }
    }

    var remoteConfigDelayKey: RCKeys {
        switch self {
        case .initial: return .engagementNotificationsDaysDelay
        case .followUp: return .engagementNotificationsFollowUpDaysDelay
        }
    }

    var defaultDelayDays: Double {
        switch self {
        case .initial: return 2
        case .followUp: return 7
        }
    }
}

struct EngagementEngine {
    private static let bookMilestonesPath: String = "recordedBookProgressMilestones"
    private static let notificationIdentifiers = EngagementNotificationStage.allCases.map(\.identifier)
    static let userDefaults = UserDefaults.standard
    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()

    private static var nextPNTitleIndex: Int {
        get {
            return userDefaults.integer(forKey: "nextPNTitleIndex")
        }
        set {
            userDefaults.set(newValue, forKey: "nextPNTitleIndex")
        }
    }

    private static var nextPNBodyIndex: Int {
        get {
            return userDefaults.integer(forKey: "nextPNBodyIndex")
        }
        set {
            userDefaults.set(newValue, forKey: "nextPNBodyIndex")
        }
    }

    static let lastBookUUIDKey = "lastBookUUIDScheduledForEngagementNotification"
    static var lastBookUUIDScheduledForNotification: String? {
        get {
            return userDefaults.string(forKey: lastBookUUIDKey)
        }
        set {
            userDefaults.set(newValue, forKey: lastBookUUIDKey)
        }
    }

    private static let lastUpdateTimestampKey = "engagementEngineLastUpdateTimestamp"
    private static var lastUpdateTimestamp: Date? {
        get {
            return userDefaults.object(forKey: lastUpdateTimestampKey) as? Date
        }
        set {
            userDefaults.set(newValue, forKey: lastUpdateTimestampKey)
        }
    }

    private static let lastNotificationScheduleTimestampKey = "engagementEngineLastNotificationScheduleTimestamp"
    private static var lastNotificationScheduleTimestamp: Date? {
        get {
            return userDefaults.object(forKey: lastNotificationScheduleTimestampKey) as? Date
        }
        set {
            userDefaults.set(newValue, forKey: lastNotificationScheduleTimestampKey)
        }
    }

    static var bookMilestones: [BookProgressMilestone] {
        get {
            guard
                let milestonesData = userDefaults.data(forKey: bookMilestonesPath),
                let milestones = try? decoder.decode([BookProgressMilestone].self, from: milestonesData) else {
                return []
            }
            return milestones
        }
        set {
            guard let newMilestonesData = try? encoder.encode(newValue) else {
                return
            }
            userDefaults.set(newMilestonesData, forKey: bookMilestonesPath)
        }
    }

    static func recordBookProgress(
        metadata: ReadableContentMetadata,
        progressPercentage: Int,
        mode: LastReadMode = .text,
        forceNotification: Bool = false
    ) {

        let hasExistingMilestone = bookMilestones.contains {
            $0.bookUUID == metadata.contentUUID && $0.mode == mode
        }

        // Activation can register a title before 5%. Once registered, later
        // progress keeps its rolling engagement notification current.
        guard forceNotification || progressPercentage >= 5 || hasExistingMilestone else {
            print("Engagement Engine: Progress not yet at 5% - currently \(progressPercentage)%")
            return
        }

        guard let coverImageURL = metadata.coverImageThumbnailURLString else {
            print("Engagement Engine: No cover image URL, skipping engagement notification")
            return
        }

        guard let title = metadata.title else {
            print("Engagement Engine: No book title, skipping engagement notification")
            return
        }

        guard RCValues.shared.bool(forKey: .shouldSendEngagementEngineNotifications) == true else {
            print("Engagement Engine: Notifications disabled")
            return
        }

        // Create milestone (used for both storage and notification scheduling)
        let milestone = BookProgressMilestone(
            bookUUID: metadata.contentUUID,
            bookTitle: title,
            bookCoverImageURL: coverImageURL,
            contentTypeString: metadata.contentType.rawValue,
            mode: mode
        )

        // Throttle milestone STORAGE at 30 seconds
        let milestoneMinimumInterval: TimeInterval = 30
        var shouldUpdateMilestone = true
        if !forceNotification, let lastUpdate = lastUpdateTimestamp {
            let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
            if timeSinceLastUpdate < milestoneMinimumInterval {
                shouldUpdateMilestone = false
            }
        }

        if shouldUpdateMilestone {
            var milestones = bookMilestones
            milestones.removeAll(where: { $0.bookUUID == metadata.contentUUID })
            milestones.insert(milestone, at: 0)
            milestones = Array(milestones.prefix(50))
            bookMilestones = milestones
            lastUpdateTimestamp = Date()
            print("Engagement Engine: Book progress recorded: \(metadata.title ?? "Unknown") at \(progressPercentage)%")
        } else {
            print("Engagement Engine: Throttling milestone storage.")
        }

        // Throttle notification scheduling at 10 seconds (independent of milestone storage)
        let notificationMinimumInterval: TimeInterval = 10
        var shouldSendNotification = true
        if !forceNotification {
            if let lastSchedule = lastNotificationScheduleTimestamp {
                let timeSinceLastSchedule = Date().timeIntervalSince(lastSchedule)
                if timeSinceLastSchedule < notificationMinimumInterval {
                    shouldSendNotification = false
                }
            }
        }

        // Schedule or reschedule notification
        if shouldSendNotification {
            lastNotificationScheduleTimestamp = Date()

            DailyReminderScheduler.scheduledReminderTimeComponents { dailyReminderTimeComponents in
                UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { requests in
                    let existingIdentifiers = Set(
                        requests
                            .map(\.identifier)
                            .filter(notificationIdentifiers.contains)
                    )

                    schedulePushNotificationsForBookMilestone(
                        milestone,
                        existingIdentifiers: existingIdentifiers,
                        dailyReminderTimeComponents: dailyReminderTimeComponents
                    )
                })
            }
        } else {
            print("Engagement Engine: Throttling notification scheduling.")
        }
    }

    static func cancelPendingNotification(includeStores: Bool) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: notificationIdentifiers)
        if includeStores {
            userDefaults.removeObject(forKey: bookMilestonesPath)
            userDefaults.removeObject(forKey: lastBookUUIDKey)
        }
    }

    /// Cancel engagement notification if this book has one pending
    static func cancelNotificationForBookIfNeeded(bookUUID: String) {
        // Check if this book is the one with a pending notification
        guard lastBookUUIDScheduledForNotification == bookUUID else {
            // This book doesn't have a pending notification
            return
        }

        // Cancel the pending notification
        cancelPendingNotification(includeStores: false)

        // Clear the tracking
        lastBookUUIDScheduledForNotification = nil

        print("Engagement Engine: Cancelled scheduled notification for completed book: \(bookUUID)")
    }
}

extension EngagementEngine {
    private static func schedulePushNotificationsForBookMilestone(
        _ milestone: BookProgressMilestone,
        existingIdentifiers: Set<String>,
        dailyReminderTimeComponents: DateComponents?
    ) {

        cancelPendingNotification(includeStores: false)

        let kingfisherManager = KingfisherManager(downloader: ImageDownloader.default, cache: ImageCache.default)
        guard let url = URL(string: milestone.bookCoverImageURL) else { return }
        let resource = KF.ImageResource(downloadURL: url)
        kingfisherManager.retrieveImage(with: resource) { result in
            switch result {
            case .success(let imgResult):
                let uiImage = imgResult.image
                guard let attachment = UNNotificationAttachment.create(identifier: milestone.bookUUID, image: uiImage, options: nil) else { return }

                for stage in EngagementNotificationStage.allCases {
                    scheduleNotification(
                        for: milestone,
                        stage: stage,
                        attachment: attachment,
                        isSuperceding: existingIdentifiers.contains(stage.identifier),
                        dailyReminderTimeComponents: dailyReminderTimeComponents
                    )
                }
            case .failure(let err):
                print("Engagement Engine: Failed to schedule notification with error: \(err.errorDescription ?? "Unknown")")
            }
        }
    }

    private static func scheduleNotification(
        for milestone: BookProgressMilestone,
        stage: EngagementNotificationStage,
        attachment: UNNotificationAttachment,
        isSuperceding: Bool,
        dailyReminderTimeComponents: DateComponents?
    ) {
        let notificationContent = notificationContent(
            for: milestone,
            stage: stage,
            attachment: attachment
        )
        let delayDays = RCValues.shared.double(
            forKey: stage.remoteConfigDelayKey,
            defaultValue: stage.defaultDelayDays
        )
        let proposedFireDate = Date().addingTimeInterval(60 * 60 * 24 * delayDays)
        let fireDate = EngagementNotificationTiming.adjustedFireDate(
            proposedFireDate: proposedFireDate,
            dailyReminderTimeComponents: dailyReminderTimeComponents
        )
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, fireDate.timeIntervalSinceNow),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: stage.identifier,
            content: notificationContent,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }

            if !isSuperceding {
                AnalyticsManager.shared.trackScheduledBookEngagementPushNotification(stage: stage.rawValue)
            }

            if stage == .initial, !isSuperceding {
                rotateCopyIndices(for: milestone.mode)
            }

            lastBookUUIDScheduledForNotification = milestone.bookUUID

            if let nextTriggerDate = trigger.nextTriggerDate() {
                print("Engagement Engine: Scheduled \(stage.rawValue) notification for \(nextTriggerDate.localizedFullDateString).\nTitle: \(notificationContent.title)\nBody: \(notificationContent.body)")
            }
        }
    }

    private static func notificationContent(
        for milestone: BookProgressMilestone,
        stage: EngagementNotificationStage,
        attachment: UNNotificationAttachment
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        switch stage {
        case .initial:
            let availableTitles = titleOptions(for: milestone.mode)
            let availableBodies = bodyOptions(for: milestone.mode)
            let titlePrefix = availableTitles[nextPNTitleIndex % availableTitles.count]
            content.title = "\(titlePrefix) \(milestone.bookTitle)?"
            content.body = availableBodies[nextPNBodyIndex % availableBodies.count]
        case .followUp:
            content.title = "Ready to continue \(milestone.bookTitle)?"
            content.body = "Tap to pick up where you left off."
        }

        content.badge = NSNumber(value: 1)
        content.sound = .default
        content.attachments = [attachment]
        content.userInfo = [
            "bookUUID": milestone.bookUUID,
            "contentType": milestone.contentTypeString,
            "mode": milestone.mode.rawValue,
            "engagementStage": stage.rawValue
        ]
        return content
    }

    private static func rotateCopyIndices(for mode: LastReadMode) {
        let availableTitles = titleOptions(for: mode)
        let availableBodies = bodyOptions(for: mode)
        nextPNTitleIndex = (nextPNTitleIndex + 1) % availableTitles.count
        nextPNBodyIndex = (nextPNBodyIndex + 1) % availableBodies.count
    }
}

extension UNNotificationAttachment {
    static func create(identifier: String, image: UIImage, options: [NSObject : AnyObject]?) -> UNNotificationAttachment? {
        let fileManager = FileManager.default
        let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
        let tmpSubFolderURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tmpSubFolderName, isDirectory: true)
        do {
            try fileManager.createDirectory(at: tmpSubFolderURL, withIntermediateDirectories: true, attributes: nil)
            let imageFileIdentifier = identifier + ".jpg"
            let fileURL = tmpSubFolderURL.appendingPathComponent(imageFileIdentifier)

            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("Engagement Engine - UNNotificationAttachment: Failed to create JPEG data from image")
                return nil
            }
            try imageData.write(to: fileURL)

            let attachmentOptions: [String: Any] = [
                UNNotificationAttachmentOptionsTypeHintKey: UTType.jpeg.identifier
            ]

            let imageAttachment = try UNNotificationAttachment(identifier: imageFileIdentifier, url: fileURL, options: attachmentOptions)
            return imageAttachment
        } catch {
            print("Engagement Engine - UNNotificationAttachment: Error creating attachment - " + error.localizedDescription)
        }
        return nil
    }
}

extension EngagementEngine {
    private static func titleOptions(for mode: LastReadMode) -> [String] {
        switch mode {
        case .text: return readingTitleOptions
        case .audio: return listeningTitleOptions
        }
    }

    private static func bodyOptions(for mode: LastReadMode) -> [String] {
        switch mode {
        case .text: return readingBodyOptions
        case .audio: return listeningBodyOptions
        }
    }

    private static let readingTitleOptions = [
        "Enjoying",
        "Continue",
        "Keep reading",
        "Back to",
        "Ready to finish"
    ]

    private static let listeningTitleOptions = [
        "Enjoying",
        "Continue",
        "Keep listening",
        "Back to",
        "Ready to finish"
    ]

    private static let readingBodyOptions = [
        "Take a moment for yourself — a few pages await.",
        "You're in the flow — keep those pages turning.",
        "Time to unwind with your book — you’ve earned it.",
        "Slow down, breathe, and enjoy another chapter.",
        "You're flying through — keep that momentum going!",
        "Your book’s waiting — the perfect escape for a quiet moment.",
        "You’re making great progress — keep it up!",
        "A calm moment and a good story — sounds perfect.",
        "Let’s get lost in the story for a little while.",
        "Adventure and discovery await — let’s continue.",
        "The next chapter might be your favorite yet.",
        "The world can wait — it’s reading time.",
        "Every page takes you closer to the ending — keep reading!",
        "Make yourself comfortable — your next chapter awaits.",
        "Nothing better than a quiet moment and a good read.",
        "Time to relax and reconnect with your story.",
        "You’re deep in the story — stay with it a little longer.",
        "Pour a cup of tea and enjoy a few pages.",
        "The perfect way to wind down — open your book.",
        "Your story’s getting good — don’t stop now!",
        "Your story’s still waiting — take a little time for you.",
        "Pause the day — and pick up where you left off.",
        "The best part might be just ahead — ready to dive back in?",
        "Reading time is your time — let’s continue the journey.",
        "Let’s finish this chapter strong — you’ve got this."
    ]

    private static let listeningBodyOptions = [
        // A mixture of calm, self-care focused, and momentum-focused
        "Take a moment for yourself — your next chapter awaits.",
        "You're in the flow — keep the story going.",
        "Time to unwind with your audiobook — you’ve earned it.",
        "Slow down, breathe, and enjoy another chapter.",
        "You're flying through — keep that momentum going!",
        "Your audiobook’s waiting — the perfect escape for a quiet moment.",
        "You’re making great progress — keep it up!",
        "A calm moment and a good story — sounds perfect.",
        "Let’s get lost in the story for a little while.",
        "Adventure and discovery await — let’s continue.",
        "The next chapter might be your favorite yet.",
        "The world can wait — it’s listening time.",
        "Every chapter takes you closer to the ending — keep listening!",
        "Make yourself comfortable — your next chapter awaits.",
        "Nothing better than a quiet moment and a great listen.",
        "Time to relax and reconnect with your story.",
        "You’re deep in the story — stay with it a little longer.",
        "Pour a cup of tea and enjoy another chapter.",
        "The perfect way to wind down — press play.",
        "Your story’s getting good — don’t stop now!",
        "Your story’s still waiting — take a little time for you.",
        "Pause the day — and pick up where you left off.",
        "The best part might be just ahead — ready to dive back in?",
        "Listening time is your time — let’s continue the journey.",
        "Let’s finish this chapter strong — you’ve got this."
    ]
}
