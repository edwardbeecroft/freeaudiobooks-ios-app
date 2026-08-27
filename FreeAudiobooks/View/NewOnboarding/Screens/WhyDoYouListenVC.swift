//
//  WhyDoYouListenVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

/// "Why do you listen?" screen
class WhyDoYouListenVC: SelectionOnboardingVC {

    override var step: NewOnboardingStep { .whyDoYouListen }
    override var allowsMultipleSelection: Bool { true }
    override var minimumSelections: Int { 1 }

    override var options: [OnboardingOption] {
        return [
            OnboardingOption(id: "entertainment", title: "Entertainment", subtitle: "To get hooked on stories", icon: "face.smiling.fill"),
            OnboardingOption(id: "escapism", title: "Escapism", subtitle: "To escape into new worlds", icon: "sparkles"),
            OnboardingOption(id: "relaxation", title: "Relaxation", subtitle: "To unwind and de-stress", icon: "leaf.fill"),
            OnboardingOption(id: "habit", title: "Habit", subtitle: "To build a daily routine", icon: "checkmark.circle.fill"),
            OnboardingOption(id: "curiosity", title: "Curiosity", subtitle: "To discover new perspectives", icon: "eye.fill")
        ]
    }

    override func getTitle() -> String {
        return RCValues.shared.string(forKey: .onbWhyDoYouListenTitleAB)
    }

    override func getSubtitle() -> String {
        return RCValues.shared.string(forKey: .onbWhyDoYouListenSubtitleAB)
    }

    override func handleSelections(_ selectedIds: [String]) {
        coordinator.dataStore.listeningReasons = selectedIds
    }

    override func getInitialSelections() -> [String] {
        return coordinator.dataStore.listeningReasons
    }
}
