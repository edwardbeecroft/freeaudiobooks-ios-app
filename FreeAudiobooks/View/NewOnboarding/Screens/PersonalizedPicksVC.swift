//
//  PersonalizedPicksVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import SwiftUI

enum PersonalizedPicksVariant: String {
    case original
    case subtitleNoBadge

    static var current: PersonalizedPicksVariant {
        let raw = RCValues.shared.string(forKey: .personalizedPicksVariant)
        return PersonalizedPicksVariant(rawValue: raw) ?? .original
    }
}

/// "Your library is ready" screen with sorting animation and personalized library
class PersonalizedPicksVC: BaseNewOnboardingVC {

    override var step: NewOnboardingStep { .personalizedPicks }

    private var animationView: PersonalizedPicksAnimationWrapper?
    private var hasSkippedAnimation = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAnimationView()
        trackRomanceActivationIfNeeded()
    }

    private func trackRomanceActivationIfNeeded() {
        guard coordinator.dataStore.selectedGenres.first == .romance else { return }
        let imageVariant = RCValues.shared.string(forKey: .onbPersonalizedPicksRomanceImagev2)
        AnalyticsManager.shared.trackOnbPersonalizedPicksRomanceActivated(imageVariant: imageVariant)
    }

    // MARK: - Setup

    private func setupAnimationView() {
        let selectedGenres = coordinator.dataStore.selectedGenres
        let dailyGoal = coordinator.dataStore.dailyListeningGoal ?? 20
        let reminderText = formatReminderText()
        let listeningReasons = coordinator.dataStore.listeningReasons

        let variant = PersonalizedPicksVariant.current
        let showBadge: Bool
        let title: String
        let subtitle: String?

        switch variant {
        case .original:
            showBadge = true
            title = RCValues.shared.string(forKey: .onbPersonalizedPicksTitleOriginal)
            subtitle = nil
        case .subtitleNoBadge:
            showBadge = false
            title = RCValues.shared.string(forKey: .onbPersonalizedPicksTitleNoBadge)
            subtitle = RCValues.shared.string(forKey: .onbPersonalizedPicksSubtitleAB)
        }

        let animation = PersonalizedPicksAnimationWrapper(
            selectedGenres: selectedGenres,
            dailyGoal: dailyGoal,
            reminderText: reminderText,
            title: title,
            listeningReasons: listeningReasons,
            showBadge: showBadge,
            subtitle: subtitle
        )
        animation.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(animation)

        NSLayoutConstraint.activate([
            animation.topAnchor.constraint(equalTo: contentView.topAnchor),
            animation.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            animation.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            animation.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        animationView = animation
    }

    /// Formats the reminder time for display
    private func formatReminderText() -> String {
        let reminderTime = coordinator.dataStore.selectedReminderTime
        switch reminderTime {
        case .morning:
            return "8:00 AM"
        case .afternoon:
            return "1:00 PM"
        case .evening:
            return "8:00 PM"
        case .custom:
            let hour = coordinator.dataStore.customReminderHour
            let minute = coordinator.dataStore.customReminderMinute
            let period = hour >= 12 ? "PM" : "AM"
            let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
            return String(format: "%d:%02d %@", displayHour, minute, period)
        }
    }

    // MARK: - Continue Button Override

    override func continueButtonTapped() {
        trackContinueTapped()

        // If animation is still running, skip to final state first
        if !hasSkippedAnimation {
            hasSkippedAnimation = true
            animationView?.skipAnimation()

            // Brief delay to let final state render, then proceed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                self?.coordinator.goToNextScreen()
            }
        } else {
            coordinator.goToNextScreen()
        }
    }
}
