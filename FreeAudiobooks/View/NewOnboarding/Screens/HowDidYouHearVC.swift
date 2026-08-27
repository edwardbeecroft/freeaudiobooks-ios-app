//
//  HowDidYouHearVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

/// "Where did you hear about FreeAudiobooks?" screen (Screen 4)
class HowDidYouHearVC: SelectionOnboardingVC {

    // MARK: - Properties

    override var step: NewOnboardingStep { .howDidYouHear }
    override var allowsMultipleSelection: Bool { false }
    override var minimumSelections: Int { 1 }

    override var options: [OnboardingOption] {
        return [
            OnboardingOption(id: "tiktok", title: "TikTok", icon: "tiktok-onboarding", iconIsTemplate: false),
            OnboardingOption(id: "instagram", title: "Instagram", icon: "instagram-onboarding", iconIsTemplate: false),
            OnboardingOption(id: "app_store", title: "App Store", icon: "appstore-onboarding", iconIsTemplate: false),
            OnboardingOption(id: "twitter", title: "X", icon: "x-onboarding", iconIsTemplate: false),
            OnboardingOption(id: "tv", title: "TV", icon: "tv-onboarding", iconIsTemplate: true),
            OnboardingOption(id: "facebook", title: "Facebook", icon: "facebook-onboarding", iconIsTemplate: false),
            OnboardingOption(id: "google", title: "Google", icon: "google-onboarding", iconIsTemplate: false),
            OnboardingOption(id: "youtube", title: "YouTube", icon: "youtube-onboarding", iconIsTemplate: false),
            OnboardingOption(id: "friend", title: "Friend or family", icon: "friend-family-onboarding", iconIsTemplate: true),
            OnboardingOption(id: "other", title: "Other", icon: "other-onboarding", iconIsTemplate: true)
        ]
    }

    // MARK: - Configuration

    override func getTitle() -> String {
        return RCValues.shared.string(forKey: .onbHowDidYouHearTitle)
    }

    override func getSubtitle() -> String {
        return ""
    }

    override func handleSelections(_ selectedIds: [String]) {
        coordinator.dataStore.howDidYouHear = selectedIds.first
    }

    override func getInitialSelections() -> [String] {
        if let source = coordinator.dataStore.howDidYouHear {
            return [source]
        }
        return []
    }
}
