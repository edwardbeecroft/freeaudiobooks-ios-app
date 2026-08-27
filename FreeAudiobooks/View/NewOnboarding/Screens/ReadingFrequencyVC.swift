//
//  ListeningOccasionVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

/// Listening occasion selection screen
class ListeningOccasionVC: SelectionOnboardingVC {

    // MARK: - Properties

    override var step: NewOnboardingStep { .listeningOccasion }
    override var allowsMultipleSelection: Bool { true }
    override var minimumSelections: Int { 1 }

    override var options: [OnboardingOption] {
        return [
            OnboardingOption(id: "commute", title: "On my commute", icon: "car.fill"),
            OnboardingOption(id: "chores", title: "Doing chores", icon: "sparkles"),
            OnboardingOption(id: "falling_asleep", title: "Falling asleep", icon: "moon.stars.fill"),
            OnboardingOption(id: "workouts", title: "During workouts", icon: "figure.run"),
            OnboardingOption(id: "relaxing_home", title: "While relaxing at home", icon: "house.fill"),
            OnboardingOption(id: "whenever_i_can", title: "Whenever I can", icon: "headphones")
        ]
    }

    // MARK: - Configuration

    override func getTitle() -> String {
        return RCValues.shared.string(forKey: .onbListeningOccasionTitleAB)
    }

    override func getSubtitle() -> String {
        return RCValues.shared.string(forKey: .onbListeningOccasionSubtitleAB)
    }

    override func handleSelections(_ selectedIds: [String]) {
        coordinator.dataStore.listeningOccasions = selectedIds
    }

    override func getInitialSelections() -> [String] {
        return coordinator.dataStore.listeningOccasions
    }
}
