//
//  PaywallPlacement.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 20/10/2025.
//  Copyright © 2025 Kneady Technologies. All rights reserved.
//

import Foundation

enum PaywallPlacement: String {
    case downloadOfflineAudio
    case downloadOfflineAudioConnection
    case listeningQuota
    case bookDetailAdFreeUpsell
    case homeHeroUpsell
    case savedBooksUpsell
    case accountUpsell
    case earlyAccess
    case earlyAccessSearchResultsUpsell
    case readingUpgradeNavIcon
    case readingInterstitialAdDismissed
    case readingMode
    case onboarding

    var popupTitle: String {
        switch self {
        case .downloadOfflineAudio, .downloadOfflineAudioConnection, .listeningQuota, .bookDetailAdFreeUpsell, .savedBooksUpsell, .homeHeroUpsell, .accountUpsell, .earlyAccess, .earlyAccessSearchResultsUpsell, .readingUpgradeNavIcon, .readingInterstitialAdDismissed, .readingMode, .onboarding: return "" // Unused - go straight to paywall
        }
    }
    var popupSubtitle: String {
        switch self {
        case .downloadOfflineAudio, .downloadOfflineAudioConnection, .listeningQuota, .bookDetailAdFreeUpsell, .savedBooksUpsell, .homeHeroUpsell, .accountUpsell, .earlyAccess, .earlyAccessSearchResultsUpsell, .readingUpgradeNavIcon, .readingInterstitialAdDismissed, .readingMode, .onboarding: return "" // Unused - go straight to paywall
        }
    }
}
