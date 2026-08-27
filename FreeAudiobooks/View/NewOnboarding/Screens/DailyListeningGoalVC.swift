//
//  DailyListeningGoalVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

/// Daily listening goal selection screen
class DailyListeningGoalVC: SelectionOnboardingVC {

    override var step: NewOnboardingStep { .dailyListeningGoal }
    override var allowsMultipleSelection: Bool { false }
    override var minimumSelections: Int { 1 }

    override var options: [OnboardingOption] {
        return [
            OnboardingOption(id: "10", title: "10 minutes", subtitle: "An easy daily win", icon: "sparkles"),
            OnboardingOption(id: "20", title: "20 minutes", subtitle: "A focused session", icon: "bolt.fill"),
            OnboardingOption(id: "30", title: "30 minutes", subtitle: "Time for a chapter or two", icon: "headphones"),
            OnboardingOption(id: "60", title: "60+ minutes", subtitle: "Get lost in a story", icon: "moon.stars.fill")
        ]
    }

    override func getTitle() -> String {
        return RCValues.shared.string(forKey: .onbDailyListeningGoalTitleAB)
    }

    override func getSubtitle() -> String {
        return RCValues.shared.string(forKey: .onbDailyListeningGoalSubtitleAB)
    }

    override func handleSelections(_ selectedIds: [String]) {
        if let goalString = selectedIds.first, let goal = Int(goalString) {
            coordinator.dataStore.dailyListeningGoal = goal
        }
    }

    override func getInitialSelections() -> [String] {
        if let goal = coordinator.dataStore.dailyListeningGoal {
            return [String(goal)]
        }
        return []
    }
}
