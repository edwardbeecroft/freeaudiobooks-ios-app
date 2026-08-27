//
//  NewOnboardingDataStore.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation

/// Reading barrier options
enum ReadingBarrier: String {
    case lackOfTime = "lack_of_time"
    case tooManyChoices = "too_many_choices"
    case hardToStayMotivated = "hard_to_stay_motivated"
}

/// Preferred time for daily listening reminder
enum ReminderTime: String {
    case morning = "morning"     // 8 AM
    case afternoon = "afternoon" // 1 PM
    case evening = "evening"     // 8 PM
    case custom = "custom"       // User-defined time

    var hour: Int {
        switch self {
        case .morning: return 8
        case .afternoon: return 13
        case .evening: return 20
        case .custom: return 20  // Default fallback; actual custom time stored separately
        }
    }

    var displayString: String {
        switch self {
        case .morning: return "Morning (8 AM)"
        case .afternoon: return "Afternoon (1 PM)"
        case .evening: return "Evening (8 PM)"
        case .custom: return "Custom"
        }
    }
}

/// Holds user selections during the onboarding flow
/// This is an in-memory store that persists to UserDefaults on completion
class NewOnboardingDataStore {

    // MARK: - User Selections

    /// Selected favorite genres (screen 2)
    var selectedGenres: [BookInternalGenre] = []

    /// Reading frequency selection (screen 3)
    /// e.g., "daily", "few_times_week", "occasionally"
    var readingFrequency: String?

    /// Listening occasions selected during onboarding
    /// e.g., ["commute", "falling_asleep", "chores"]
    var listeningOccasions: [String] = []

    /// How the user heard about FreeAudiobooks (screen 4)
    var howDidYouHear: String?

    /// Previous reading apps used (screen 5)
    /// e.g., ["kindle", "libby", "audible"]
    var previousApps: [String] = []

    /// Why the user reads (screen 8)
    /// e.g., ["relaxation", "learning", "escapism", "inspiration"]
    var listeningReasons: [String] = []

    /// What stops the user from reading more (screen 9)
    /// e.g., ["lack_of_time", "too_many_choices", "hard_to_stay_motivated"]
    var readingBarriers: [String] = []

    /// Daily listening goal in minutes
    /// e.g., 10, 20, 30, 60
    var dailyListeningGoal: Int?

    // MARK: - State Tracking

    /// Whether the social proof stat screen was viewed
    var didViewBuildsHabitsLineChart: Bool = false

    /// Whether the reading barrier resolution screen was viewed
    var didViewReadingBarrierResolution: Bool = false

    /// Whether push notification permission was requested
    var didRequestPushPermission: Bool = false

    /// Whether push notification permission was granted
    var didGrantPushPermission: Bool = false

    /// Whether we've already requested an App Store review during this onboarding session
    var didRequestAppReview: Bool = false

    /// Selected time for daily listening reminder (defaults to evening)
    var selectedReminderTime: ReminderTime = .evening

    /// Custom reminder hour (0-23), used when selectedReminderTime is .custom
    var customReminderHour: Int = 20

    /// Custom reminder minute (0-59), used when selectedReminderTime is .custom
    var customReminderMinute: Int = 0

    /// Whether the user subscribed via paywall
    var didSubscribe: Bool = false

    /// Whether the paywall step was completed (user saw it and took action)
    var didCompletePaywall: Bool = false

    /// Authentication method used (e.g., "apple", "google")
    var authMethod: String?

    /// The variant this user went through
    var variant: OnboardingVariant = .fullFlow

    // MARK: - Superwall Paywall Info
    // Captured when the onboarding paywall is presented so that the
    // `paywallViewed → newOnboardingCompleted` funnel in GA can be sliced by
    // the actual Superwall paywall variant that was shown.

    var superwallPaywallName: String?
    var superwallPaywallIdentifier: String?
    var superwallExperimentId: String?
    var superwallVariantId: String?
    var superwallVariantType: String?

    // MARK: - Initialization

    init() {}

    // MARK: - Reset

    /// Resets all stored data (call when starting fresh)
    func reset() {
        selectedGenres = []
        readingFrequency = nil
        listeningOccasions = []
        howDidYouHear = nil
        previousApps = []
        listeningReasons = []
        readingBarriers = []
        dailyListeningGoal = nil
        didViewBuildsHabitsLineChart = false
        didViewReadingBarrierResolution = false
        didRequestPushPermission = false
        didGrantPushPermission = false
        didRequestAppReview = false
        selectedReminderTime = .evening
        customReminderHour = 20
        customReminderMinute = 0
        didSubscribe = false
        didCompletePaywall = false
        authMethod = nil
        variant = .fullFlow
        superwallPaywallName = nil
        superwallPaywallIdentifier = nil
        superwallExperimentId = nil
        superwallVariantId = nil
        superwallVariantType = nil
    }

    // MARK: - Persistence

    /// Saves all current data to UserDefaults.
    ///
    /// This is used for two purposes:
    /// 1. **Incremental saves** - Called after each step to enable crash recovery/resume
    /// 2. **Final save** - Called at onboarding completion
    ///
    /// Note: This does NOT mark onboarding as completed. Call `NewOnboardingUserDefaults.markOnboardingCompleted()`
    /// separately when onboarding actually finishes successfully.
    func saveToUserDefaults() {
        // Variant
        NewOnboardingUserDefaults.saveOnboardingVariant(variant.rawValue)

        // User selections
        if !selectedGenres.isEmpty {
            NewOnboardingUserDefaults.saveSelectedGenres(selectedGenres)
        }
        if let frequency = readingFrequency {
            NewOnboardingUserDefaults.saveReadingFrequency(frequency)
        }
        if !listeningOccasions.isEmpty {
            NewOnboardingUserDefaults.saveListeningOccasions(listeningOccasions)
        }
        if let source = howDidYouHear {
            NewOnboardingUserDefaults.saveHowDidYouHear(source)
        }
        if !previousApps.isEmpty {
            NewOnboardingUserDefaults.savePreviousApps(previousApps)
        }
        if !listeningReasons.isEmpty {
            NewOnboardingUserDefaults.saveListeningReasons(listeningReasons)
        }
        if !readingBarriers.isEmpty {
            NewOnboardingUserDefaults.saveReadingBarriers(readingBarriers)
        }
        if let goal = dailyListeningGoal {
            NewOnboardingUserDefaults.saveDailyListeningGoal(goal)
        }

        // Reminder settings
        NewOnboardingUserDefaults.saveSelectedReminderTime(selectedReminderTime.rawValue)
        if selectedReminderTime == .custom {
            NewOnboardingUserDefaults.saveCustomReminderTime(hour: customReminderHour, minute: customReminderMinute)
        }

        // State tracking flags
        NewOnboardingUserDefaults.saveDidRequestPushPermission(didRequestPushPermission)
        NewOnboardingUserDefaults.saveDidGrantPushPermission(didGrantPushPermission)
        NewOnboardingUserDefaults.saveDidViewBuildsHabitsLineChart(didViewBuildsHabitsLineChart)
        NewOnboardingUserDefaults.saveDidViewReadingBarrierResolution(didViewReadingBarrierResolution)
        NewOnboardingUserDefaults.setPaywallCompleted(didCompletePaywall)
    }

}
