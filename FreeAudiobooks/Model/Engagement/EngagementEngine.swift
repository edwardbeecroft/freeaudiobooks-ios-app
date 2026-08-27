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
}

struct EngagementEngine {
    private static let bookMilestonesPath: String = "recordedBookProgressMilestones"
    private static let notificationIdentifier: String = "book-progress-engagement"
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

    static func recordBookProgress(metadata: ReadableContentMetadata, progressPercentage: Int, forceNotification: Bool = false) {

        // Only trigger at 5% or higher (user has made decent progress)
        guard forceNotification || progressPercentage >= 5 else {
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
            contentTypeString: metadata.contentType.rawValue
        )

        // Throttle milestone STORAGE at 30 seconds
        let milestoneMinimumInterval: TimeInterval = 30
        var shouldUpdateMilestone = true
        if let lastUpdate = lastUpdateTimestamp {
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

            // Check if daily reminders are active - if so, skip engagement notifications
            DailyReminderScheduler.hasDailyReminderScheduled { hasDaily in
                if hasDaily {
                    print("EngagementEngine: Daily reminder active, skipping re-engagement notification")
                    return
                }

                UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { requests in
                    let hasExisting = requests.contains(where: { $0.identifier == notificationIdentifier })

                    // Schedule notification for this book
                    if !hasExisting {
                        AnalyticsManager.shared.trackScheduledBookEngagementPushNotification()
                    }
                    schedulePushNotificationForBookMilestone(milestone, isSuperceding: hasExisting) // testTimeInterval: 30
                })
            }
        } else {
            print("Engagement Engine: Throttling notification scheduling.")
        }
    }

    static func cancelPendingNotification(includeStores: Bool) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
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
    private static func schedulePushNotificationForBookMilestone(_ milestone: BookProgressMilestone, isSuperceding: Bool, testTimeInterval: TimeInterval? = nil) {

        cancelPendingNotification(includeStores: false)

        let notificationContent = UNMutableNotificationContent()

        let titlePrefix = titleOptions[nextPNTitleIndex]
        let title = "\(titlePrefix) \(milestone.bookTitle)?"
        notificationContent.title = title
        notificationContent.body = bodyOptions[nextPNBodyIndex]

        notificationContent.badge = NSNumber(value: 1)
        notificationContent.sound = .default
        notificationContent.userInfo = [
            "bookUUID": milestone.bookUUID,
            "contentType": milestone.contentTypeString
        ]

        let kingfisherManager = KingfisherManager(downloader: ImageDownloader.default, cache: ImageCache.default)
        guard let url = URL(string: milestone.bookCoverImageURL) else { return }
        let resource = KF.ImageResource(downloadURL: url)
        kingfisherManager.retrieveImage(with: resource) { result in
            switch result {
            case .success(let imgResult):
                let uiImage = imgResult.image
                guard let attachment = UNNotificationAttachment.create(identifier: milestone.bookUUID, image: uiImage, options: nil) else { return }
                notificationContent.attachments = [attachment]

                let timeInterval: TimeInterval
                if let testInterval = testTimeInterval {
                    timeInterval = testInterval
                } else {
                    let engagementNotificationsDaysDelay = RCValues.shared.double(forKey: .engagementNotificationsDaysDelay, defaultValue: 2)
                    timeInterval = 60*60*24*engagementNotificationsDaysDelay // 2 days default
                }

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)

                let request = UNNotificationRequest(identifier: notificationIdentifier, content: notificationContent, trigger: trigger)

                let center = UNUserNotificationCenter.current()
                center.add(request) { error in
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        if !isSuperceding {
                            // Rotate title index
                            var nextTitleIdx = nextPNTitleIndex + 1
                            if nextTitleIdx > titleOptions.count - 1 {
                                nextTitleIdx = 0
                            }
                            nextPNTitleIndex = nextTitleIdx

                            // Rotate body index
                            var nextBodyIdx = nextPNBodyIndex + 1
                            if nextBodyIdx > bodyOptions.count - 1 {
                                nextBodyIdx = 0
                            }
                            nextPNBodyIndex = nextBodyIdx
                        }

                        lastBookUUIDScheduledForNotification = milestone.bookUUID

                        print("Engagement Engine: Scheduled notification for \(trigger.nextTriggerDate()!.localizedFullDateString).\nTitle: \(notificationContent.title)\nBody: \(notificationContent.body)")
                    }
                }
            case .failure(let err):
                print("Engagement Engine: Failed to schedule notification with error: \(err.errorDescription ?? "Unknown")")
            }
        }
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
    private static let titleOptions = [
        "Enjoying",
        "Continue",
        "Keep listening",
        "Back to",
        "Ready to finish"
    ]

    private static let bodyOptions = [
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
