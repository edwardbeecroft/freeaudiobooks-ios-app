//
//  OnboardingVariant.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation

/// Defines different onboarding flow variants for A/B testing
/// The variant is controlled via RemoteConfig's `onboardingVariantv3AB` key
enum OnboardingVariant: String {
    case fullFlow
    case setupBeforePersonalizedPicks
    case setupBeforePaywall
    case noPersonalizedPicks
    case noPaywall
    case mini
    case welcomeAndGenre
    case genreOnly
    case fullFlowAuthFirst

    /// Gets the current variant from RemoteConfig
    static var current: OnboardingVariant {
        let variantString = RCValues.shared.string(forKey: .onboardingVariantv3AB)
        return OnboardingVariant(rawValue: variantString) ?? .fullFlowAuthFirst
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

        switch self {
        case .fullFlow:
            return allSteps
        case .setupBeforePersonalizedPicks, .setupBeforePaywall:
            var modifiedSteps = OnboardingVariant.fullFlowAuthFirst.steps
            let destination: NewOnboardingStep = self == .setupBeforePersonalizedPicks ? .personalizedPicks : .paywall
            if let index = modifiedSteps.firstIndex(of: destination) {
                modifiedSteps.insert(.settingEverythingUp, at: index)
            }
            return modifiedSteps
        case .fullFlowAuthFirst:
            // Keep the reviews screen in all three experiment arms. The native
            // review request is controlled by shouldRequestSKReviewInOnboardingAB.
            var modifiedSteps = allSteps
            if let paywallIndex = modifiedSteps.firstIndex(of: .paywall),
               let authIndex = modifiedSteps.firstIndex(of: .saveProgressAuth) {
                modifiedSteps.swapAt(paywallIndex, authIndex)
            }
            return modifiedSteps
        case .noPersonalizedPicks:
            var modifiedSteps = allSteps
            modifiedSteps.removeAll(where: { $0 == .personalizedPicks })
            return modifiedSteps
        case .noPaywall:
            var modifiedSteps = allSteps
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
