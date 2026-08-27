//
//  EmailOptInTrigger.swift
//  FreeAudiobooks
//
//  Created by Claude on 29/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation

/// Triggers that can show the email opt-in prompt
enum EmailOptInTrigger: String {
    case bookSaved = "book_saved"
    case bookCompleted = "book_completed"
    case fifthBookDetailView = "fifth_book_detail_view"
    case accountSettings = "account_settings"  // Manual toggle in account preferences
    case newOnboarding = "new_onboarding"  // Post-paywall epilogue in new onboarding flow

    // MARK: - Remote Config Keys

    var titleKey: RCKeys {
        switch self {
            // accountSettings
        case .bookSaved, .accountSettings:
            return .emailOptInBookSavedTitle
        case .bookCompleted:
            return .emailOptInBookCompletedTitle
        case .fifthBookDetailView:
            return .emailOptInDetailViewTitleAB
        case .newOnboarding:
            return .emailOptInOnboardingTitleAB
        }
    }

    var subtitleKey: RCKeys {
        switch self {
        case .bookSaved, .accountSettings:
            return .emailOptInBookSavedSubtitle
        case .bookCompleted:
            return .emailOptInBookCompletedSubtitleAB
        case .fifthBookDetailView:
            return .emailOptInDetailViewSubtitle
        case .newOnboarding:
            return .emailOptInOnboardingSubtitle
        }
    }

    var ctaKey: RCKeys {
        switch self {
        case .bookSaved, .accountSettings:
            return .emailOptInBookSavedCTAAB
        case .bookCompleted:
            return .emailOptInBookCompletedCTA
        case .fifthBookDetailView:
            return .emailOptInDetailViewCTA
        case .newOnboarding:
            return .emailOptInOnboardingCTAAB
        }
    }

    var ctaKeyPaid: RCKeys {
        switch self {
        case .bookSaved, .accountSettings:
            return .emailOptInBookSavedCTAPaidAB
        case .bookCompleted:
            return .emailOptInBookCompletedCTAPaid
        case .fifthBookDetailView:
            return .emailOptInDetailViewCTAPaid
        case .newOnboarding:
            return .emailOptInOnboardingCTAAB
        }
    }

    // MARK: - Paid Subscriber Keys

    var titleKeyPaid: RCKeys {
        switch self {
        case .bookSaved, .accountSettings:
            return .emailOptInBookSavedTitlePaid
        case .bookCompleted:
            return .emailOptInBookCompletedTitlePaidAB
        case .fifthBookDetailView:
            return .emailOptInDetailViewTitlePaid
        case .newOnboarding:
            return .emailOptInOnboardingTitleAB
        }
    }

    var subtitleKeyPaid: RCKeys {
        switch self {
        case .bookSaved, .accountSettings:
            return .emailOptInBookSavedSubtitlePaid
        case .bookCompleted:
            return .emailOptInBookCompletedSubtitlePaid
        case .fifthBookDetailView:
            return .emailOptInDetailViewSubtitlePaid
        case .newOnboarding:
            return .emailOptInOnboardingSubtitle
        }
    }

    // MARK: - Copy (from Remote Config, defaults in plist)

    var title: String {
        RCValues.shared.string(forKey: titleKey)
    }

    var subtitle: String {
        RCValues.shared.string(forKey: subtitleKey)
    }

    var ctaText: String {
        RCValues.shared.string(forKey: ctaKey)
    }

    // MARK: - Subscriber-Aware Copy

    func title(forSubscriber isSubscriber: Bool) -> String {
        let key = isSubscriber ? titleKeyPaid : titleKey
        return RCValues.shared.string(forKey: key)
    }

    func subtitle(forSubscriber isSubscriber: Bool) -> String {
        let key = isSubscriber ? subtitleKeyPaid : subtitleKey
        return RCValues.shared.string(forKey: key)
    }

    func ctaText(forSubscriber isSubscriber: Bool) -> String {
        let key = isSubscriber ? ctaKeyPaid : ctaKey
        return RCValues.shared.string(forKey: key)
    }
}

/// Reasons why the email opt-in prompt was suppressed
enum EmailOptInSuppressionReason: String {
    case shownThisSession = "shown_this_session"
    case notAuthenticated = "not_authenticated"
    case alreadySubscribed = "already_subscribed"
    case permanentlySuppressed = "permanently_suppressed"
    case inCooldown = "in_cooldown"
    case recentPushPrompt = "recent_push_prompt"
    case recentSKReview = "recent_sk_review"
}
