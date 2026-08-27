//
//  PreviousAppsVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

/// "Have you used other audiobook apps?" screen
class PreviousAppsVC: SelectionOnboardingVC {

    // MARK: - Properties

    override var step: NewOnboardingStep { .previousApps }
    override var allowsMultipleSelection: Bool { true }
    override var minimumSelections: Int { 1 }

    override var options: [OnboardingOption] {
        return [
            OnboardingOption(id: "audible", title: "Audible", icon: "headphones"),
            OnboardingOption(id: "storytel", title: "Storytel", icon: "text.bubble.fill"),
            OnboardingOption(id: "librivox", title: "LibriVox", icon: "waveform"),
            OnboardingOption(id: "libby", title: "Libby", icon: "building.columns.fill"),
            OnboardingOption(id: "spotify", title: "Spotify", icon: "music.note"),
            OnboardingOption(id: "apple_books", title: "Apple Books", icon: "books.vertical.fill"),
            OnboardingOption(id: "none", title: "None of these", icon: "xmark.circle")
        ]
    }

    // MARK: - Configuration

    override func getTitle() -> String {
        return RCValues.shared.string(forKey: .onbPreviousAppsTitleAB)
    }

    override func getSubtitle() -> String {
        return RCValues.shared.string(forKey: .onbPreviousAppsSubtitle)
    }

    override func handleSelections(_ selectedIds: [String]) {
        coordinator.dataStore.previousApps = selectedIds
    }

    override func getInitialSelections() -> [String] {
        return coordinator.dataStore.previousApps
    }
}
