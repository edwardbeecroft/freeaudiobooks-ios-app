//
//  NewOnboardingUserDefaults.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation

struct NewOnboardingUserDefaults {

    // MARK: - Keys

    private static let hasCompletedOnboardingKey = "newOnboarding_hasCompleted"
    private static let currentStepIndexKey = "newOnboarding_currentStepIndex"
    private static let selectedGenresKey = "newOnboarding_selectedGenres"
    private static let readingFrequencyKey = "newOnboarding_readingFrequency"
    private static let listeningOccasionsKey = "newOnboarding_listeningOccasions"
    private static let howDidYouHearKey = "newOnboarding_howDidYouHear"
    private static let previousAppsKey = "newOnboarding_previousApps"
    private static let listeningReasonsKey = "newOnboarding_listeningReasons"
    private static let readingBarriersKey = "newOnboarding_readingBarriers"
    private static let dailyListeningGoalKey = "newOnboarding_dailyListeningGoal"
    private static let didRequestPushPermissionKey = "newOnboarding_didRequestPushPermission"
    private static let didGrantPushPermissionKey = "newOnboarding_didGrantPushPermission"
    private static let selectedReminderTimeKey = "newOnboarding_selectedReminderTime"
    private static let customReminderHourKey = "newOnboarding_customReminderHour"
    private static let customReminderMinuteKey = "newOnboarding_customReminderMinute"
    private static let onboardingVariantKey = "newOnboarding_variant"
    private static let didViewBuildsHabitsLineChartKey = "newOnboarding_didViewBuildsHabitsLineChart"
    private static let didViewReadingBarrierResolutionKey = "newOnboarding_didViewReadingBarrierResolution"
    private static let paywallCompletedKey = "newOnboarding_paywallCompleted"

    // MARK: - Session Tracking (non-persistent, in-memory only)

    private static var didCompleteOnboardingThisSession = false

    /// Marks that onboarding was completed this session (does not persist)
    static func markOnboardingCompletedThisSession() {
        didCompleteOnboardingThisSession = true
    }

    /// Checks if onboarding was completed during this app session
    static func didCompleteThisSession() -> Bool {
        return didCompleteOnboardingThisSession
    }

    // MARK: - Completion Status

    /// Marks onboarding as completed
    static func markOnboardingCompleted() {
        UserDefaults.standard.set(true, forKey: hasCompletedOnboardingKey)
    }

    /// Checks if onboarding has been completed
    static func hasCompletedOnboarding() -> Bool {
        return UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
    }

    /// Resets completion flag (useful for testing)
    static func resetCompletionFlag() {
        UserDefaults.standard.removeObject(forKey: hasCompletedOnboardingKey)
    }

    // MARK: - Step Persistence

    /// Saves the current step index for resuming later
    static func saveCurrentStepIndex(_ index: Int) {
        UserDefaults.standard.set(index, forKey: currentStepIndexKey)
    }

    /// Gets the saved step index, or nil if not set
    static func getCurrentStepIndex() -> Int? {
        if UserDefaults.standard.object(forKey: currentStepIndexKey) == nil {
            return nil
        }
        return UserDefaults.standard.integer(forKey: currentStepIndexKey)
    }

    /// Clears the saved step index (called on completion)
    static func clearCurrentStepIndex() {
        UserDefaults.standard.removeObject(forKey: currentStepIndexKey)
    }

    // MARK: - Onboarding Variant

    /// Saves which variant the user went through (for analytics)
    static func saveOnboardingVariant(_ variant: String) {
        UserDefaults.standard.set(variant, forKey: onboardingVariantKey)
    }

    /// Gets which variant the user went through
    static func getOnboardingVariant() -> String? {
        return UserDefaults.standard.string(forKey: onboardingVariantKey)
    }

    // MARK: - Selected Genres

    static func saveSelectedGenres(_ genres: [BookInternalGenre]) {
        let genreStrings = genres.map { $0.rawValue }
        UserDefaults.standard.set(genreStrings, forKey: selectedGenresKey)
    }

    static func getSelectedGenres() -> [BookInternalGenre]? {
        guard let genreStrings = UserDefaults.standard.stringArray(forKey: selectedGenresKey) else {
            return nil
        }
        return genreStrings.compactMap { BookInternalGenre(rawValue: $0) }
    }

    // MARK: - Reading Frequency

    static func saveReadingFrequency(_ frequency: String) {
        UserDefaults.standard.set(frequency, forKey: readingFrequencyKey)
    }

    static func getReadingFrequency() -> String? {
        return UserDefaults.standard.string(forKey: readingFrequencyKey)
    }

    // MARK: - Listening Occasions

    static func saveListeningOccasions(_ occasions: [String]) {
        UserDefaults.standard.set(occasions, forKey: listeningOccasionsKey)
    }

    static func getListeningOccasions() -> [String]? {
        return UserDefaults.standard.stringArray(forKey: listeningOccasionsKey)
    }

    // MARK: - How Did You Hear

    static func saveHowDidYouHear(_ source: String) {
        UserDefaults.standard.set(source, forKey: howDidYouHearKey)
    }

    static func getHowDidYouHear() -> String? {
        return UserDefaults.standard.string(forKey: howDidYouHearKey)
    }

    // MARK: - Previous Apps

    static func savePreviousApps(_ apps: [String]) {
        UserDefaults.standard.set(apps, forKey: previousAppsKey)
    }

    static func getPreviousApps() -> [String]? {
        return UserDefaults.standard.stringArray(forKey: previousAppsKey)
    }

    // MARK: - Reading Reasons

    static func saveListeningReasons(_ reasons: [String]) {
        UserDefaults.standard.set(reasons, forKey: listeningReasonsKey)
    }

    static func getListeningReasons() -> [String]? {
        return UserDefaults.standard.stringArray(forKey: listeningReasonsKey)
    }

    // MARK: - Reading Barriers

    static func saveReadingBarriers(_ barriers: [String]) {
        UserDefaults.standard.set(barriers, forKey: readingBarriersKey)
    }

    static func getReadingBarriers() -> [String]? {
        return UserDefaults.standard.stringArray(forKey: readingBarriersKey)
    }

    // MARK: - Daily Listening Goal

    static func saveDailyListeningGoal(_ minutes: Int) {
        UserDefaults.standard.set(minutes, forKey: dailyListeningGoalKey)
    }

    static func getDailyListeningGoal() -> Int? {
        let value = UserDefaults.standard.integer(forKey: dailyListeningGoalKey)
        return value > 0 ? value : nil
    }

    // MARK: - Push Permission

    static func saveDidRequestPushPermission(_ requested: Bool) {
        UserDefaults.standard.set(requested, forKey: didRequestPushPermissionKey)
    }

    static func getDidRequestPushPermission() -> Bool {
        return UserDefaults.standard.bool(forKey: didRequestPushPermissionKey)
    }

    static func saveDidGrantPushPermission(_ granted: Bool) {
        UserDefaults.standard.set(granted, forKey: didGrantPushPermissionKey)
    }

    static func getDidGrantPushPermission() -> Bool? {
        if UserDefaults.standard.object(forKey: didGrantPushPermissionKey) == nil {
            return nil
        }
        return UserDefaults.standard.bool(forKey: didGrantPushPermissionKey)
    }

    // MARK: - Reminder Time

    static func saveSelectedReminderTime(_ time: String) {
        UserDefaults.standard.set(time, forKey: selectedReminderTimeKey)
    }

    static func getSelectedReminderTime() -> String? {
        return UserDefaults.standard.string(forKey: selectedReminderTimeKey)
    }

    static func saveCustomReminderTime(hour: Int, minute: Int) {
        UserDefaults.standard.set(hour, forKey: customReminderHourKey)
        UserDefaults.standard.set(minute, forKey: customReminderMinuteKey)
    }

    static func getCustomReminderTime() -> (hour: Int, minute: Int)? {
        let hour = UserDefaults.standard.integer(forKey: customReminderHourKey)
        let minute = UserDefaults.standard.integer(forKey: customReminderMinuteKey)
        // Only return if at least hour has been set (0 is valid but also default)
        if UserDefaults.standard.object(forKey: customReminderHourKey) != nil {
            return (hour, minute)
        }
        return nil
    }

    // MARK: - Stat Screen Views

    static func saveDidViewBuildsHabitsLineChart(_ viewed: Bool) {
        UserDefaults.standard.set(viewed, forKey: didViewBuildsHabitsLineChartKey)
    }

    static func getDidViewBuildsHabitsLineChart() -> Bool {
        return UserDefaults.standard.bool(forKey: didViewBuildsHabitsLineChartKey)
    }

    static func saveDidViewReadingBarrierResolution(_ viewed: Bool) {
        UserDefaults.standard.set(viewed, forKey: didViewReadingBarrierResolutionKey)
    }

    static func getDidViewReadingBarrierResolution() -> Bool {
        return UserDefaults.standard.bool(forKey: didViewReadingBarrierResolutionKey)
    }

    // MARK: - Paywall Completion

    /// Marks that the paywall step was completed (user saw paywall and took action)
    static func setPaywallCompleted(_ completed: Bool) {
        UserDefaults.standard.set(completed, forKey: paywallCompletedKey)
    }

    /// Checks if the paywall step was completed
    static func hasCompletedPaywall() -> Bool {
        return UserDefaults.standard.bool(forKey: paywallCompletedKey)
    }

    /// Clears the paywall completion flag (called on sign out)
    static func clearPaywallCompleted() {
        UserDefaults.standard.removeObject(forKey: paywallCompletedKey)
    }

    // MARK: - Clear All

    /// Clears all new onboarding UserDefaults (useful for testing)
    static func clearAll() {
        let keys = [
            hasCompletedOnboardingKey,
            currentStepIndexKey,
            selectedGenresKey,
            readingFrequencyKey,
            listeningOccasionsKey,
            howDidYouHearKey,
            previousAppsKey,
            listeningReasonsKey,
            readingBarriersKey,
            dailyListeningGoalKey,
            didRequestPushPermissionKey,
            didGrantPushPermissionKey,
            selectedReminderTimeKey,
            customReminderHourKey,
            customReminderMinuteKey,
            onboardingVariantKey,
            didViewBuildsHabitsLineChartKey,
            didViewReadingBarrierResolutionKey,
            paywallCompletedKey
        ]

        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }
}
