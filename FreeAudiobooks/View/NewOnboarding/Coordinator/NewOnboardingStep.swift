//
//  NewOnboardingStep.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

/// Represents each screen in the new onboarding flow
enum NewOnboardingStep: String, CaseIterable {
    case welcomeVideo
    case genreSelection
    case listeningOccasion
    case readingFrequency
    case howDidYouHear
    case previousApps
    case buildsHabitsLineChart
    case whyDoYouListen
    case readingBarriers
    case readingBarrierResolution
    case dailyListeningGoal
    case pushNotification
    case credibilityReviews
    case personalizedPicks
    case saveProgressAuth
    case paywall

    /// Whether this step should be included in the progress bar calculation
    var includesInProgressBar: Bool {
        switch self {
        case .paywall:
            return false
        default:
            return true
        }
    }

    /// Prefix used for analytics events (e.g., "onbWelcomeVideo")
    var analyticsPrefix: String {
        return "onb\(rawValue.prefix(1).uppercased() + rawValue.dropFirst())"
    }

    /// Whether this step has been completed based on the dataStore
    /// Pass-through steps (info screens, loading screens) always return true
    /// Data-collecting steps check if their corresponding data exists
    func isComplete(dataStore: NewOnboardingDataStore) -> Bool {
        switch self {
        // Data-collecting steps
        case .genreSelection:
            return !dataStore.selectedGenres.isEmpty
        case .readingFrequency:
            return dataStore.readingFrequency != nil
        case .listeningOccasion:
            return !dataStore.listeningOccasions.isEmpty
        case .howDidYouHear:
            return dataStore.howDidYouHear != nil
        case .previousApps:
            return !dataStore.previousApps.isEmpty
        case .whyDoYouListen:
            return !dataStore.listeningReasons.isEmpty
        case .readingBarriers:
            return !dataStore.readingBarriers.isEmpty
        case .readingBarrierResolution:
            return dataStore.didViewReadingBarrierResolution
        case .dailyListeningGoal:
            return dataStore.dailyListeningGoal != nil
        case .pushNotification:
            return dataStore.didRequestPushPermission
        case .saveProgressAuth:
            return dataStore.authMethod != nil

        // Welcome video is complete only if user has started the flow (completed genre selection)
        case .welcomeVideo:
            return !dataStore.selectedGenres.isEmpty

        // Stat screens that require user to click continue
        case .buildsHabitsLineChart:
            return dataStore.didViewBuildsHabitsLineChart

        // Pass-through steps (always considered complete - they don't block progress)
        case .credibilityReviews,
             .personalizedPicks:
            return true

        // Paywall is complete once user has seen it and taken action (dismiss or subscribe)
        case .paywall:
            return dataStore.didCompletePaywall
        }
    }

    /// Creates the view controller for this step
    func makeViewController(coordinator: NewOnboardingCoordinator) -> UIViewController {
        switch self {
        case .welcomeVideo:
            return WelcomeVideoVC(coordinator: coordinator)
        case .genreSelection:
            return GenreSelectionOnboardingVC(coordinator: coordinator)
        case .listeningOccasion:
            return ListeningOccasionVC(coordinator: coordinator)
        case .readingFrequency:
            return ListeningOccasionVC(coordinator: coordinator)
        case .howDidYouHear:
            return HowDidYouHearVC(coordinator: coordinator)
        case .previousApps:
            return PreviousAppsVC(coordinator: coordinator)
        case .buildsHabitsLineChart:
            return BuildsHabitsLineChartVC(coordinator: coordinator)
        case .whyDoYouListen:
            return WhyDoYouListenVC(coordinator: coordinator)
        case .readingBarriers:
            return ReadingBarriersVC(coordinator: coordinator)
        case .readingBarrierResolution:
            return ReadingBarrierResolutionVC(coordinator: coordinator)
        case .dailyListeningGoal:
            return DailyListeningGoalVC(coordinator: coordinator)
        case .pushNotification:
            return PushNotificationVC(coordinator: coordinator)
        case .credibilityReviews:
            return CredibilityReviewsVC(coordinator: coordinator)
        case .personalizedPicks:
            return PersonalizedPicksVC(coordinator: coordinator)
        case .saveProgressAuth:
            return SaveProgressAuthVC(coordinator: coordinator)
        case .paywall:
            return OnboardingPaywallVC(coordinator: coordinator)
        }
    }
}
