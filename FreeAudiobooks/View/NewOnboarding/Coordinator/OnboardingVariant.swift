//
//  OnboardingVariant.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation

/// Defines different onboarding flow variants for A/B testing
/// The variant is controlled via RemoteConfig's `onboardingVariant` key
enum OnboardingVariant: String {
    case fullFlow
    case noPersonalizedPicks
    case noPaywall
    case mini
    case welcomeAndGenre
    case genreOnly
    case fullFlowAuthFirst

    /// Gets the current variant from RemoteConfig
    static var current: OnboardingVariant {
        let variantString = RCValues.shared.string(forKey: .onboardingVariantv2)
        return OnboardingVariant(rawValue: variantString) ?? .fullFlow
    }

    /// The ordered list of steps for this variant
    var steps: [NewOnboardingStep] {
        let allSteps: [NewOnboardingStep] = [
            .welcomeVideo,
            .genreSelection,
            .listeningOccasion,
            .whyDoYouListen,
            .howDidYouHear,
            .previousApps,
            .buildsHabitsLineChart,
            .readingBarriers,
            .readingBarrierResolution,
            .dailyListeningGoal,
            .pushNotification,
            .credibilityReviews,
            .personalizedPicks,
            .paywall,
            .saveProgressAuth
        ]
        let availableSteps = RCValues.shared.bool(forKey: .isarAB3)
            ? allSteps.filter { $0 != .credibilityReviews }
            : allSteps

        switch self {
        case .fullFlow:
            return availableSteps
        case .fullFlowAuthFirst:
            var modifiedSteps = availableSteps
            if let paywallIndex = modifiedSteps.firstIndex(of: .paywall),
               let authIndex = modifiedSteps.firstIndex(of: .saveProgressAuth) {
                modifiedSteps.swapAt(paywallIndex, authIndex)
            }
            return modifiedSteps
        case .noPersonalizedPicks:
            var modifiedSteps = availableSteps
            modifiedSteps.removeAll(where: { $0 == .personalizedPicks })
            return modifiedSteps
        case .noPaywall:
            var modifiedSteps = availableSteps
            modifiedSteps.removeAll(where: { $0 == .paywall })
            return modifiedSteps
        case .mini:
            return [.welcomeVideo,
                    .genreSelection,
                    .whyDoYouListen]
        case .welcomeAndGenre:
            return [.welcomeVideo,
                    .genreSelection]
        case .genreOnly:
            return [.genreSelection]
        }
    }

    /// Number of steps that contribute to progress bar
    var progressStepCount: Int {
        return steps.filter { $0.includesInProgressBar }.count
    }
}
