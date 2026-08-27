//
//  DiscoverSectionType.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 03/11/2025.
//  Copyright © 2025 Kneady Technologies. All rights reserved.
//

import Foundation

enum DiscoverSectionType: String, CaseIterable {
    case continueReading
    case heroCarousel
    case forYou
    case thisWeeksTopTen
    case earlyAccess
    case zeroToThirtyMinutes
    case thirtyToNinetyMinutes
    case ninetyPlusMinutes
    //    case longerReads
    case mostPopular
    case latestReleases
    case favoriteGenresCTA
    case searchPromptCTA
    case genre
    case genreShortcuts
    case becauseYouRead
    case adultContent

    var localizedTitle: String? {
        switch self {
        case .thisWeeksTopTen:
            if AppConstants.shared.developmentMode == .screenshots {
                return "This week's top 10"
            }
            let locale = Locale.autoupdatingCurrent
            guard var regionCode = locale.region?.identifier.uppercased(),
                  let countryName = locale.localizedString(forRegionCode: regionCode) else {
                return nil
            }
            if regionCode == "UK" { regionCode = "GB" }
            let isEnglish = locale.language.languageCode?.identifier == "en"
            let displayName: String
            switch (isEnglish, regionCode) {
            case (true, "US"): displayName = "the U.S."
            case (true, "GB"): displayName = "the U.K."
            default:           displayName = countryName
            }
            return "Top 10 in \(displayName)"
        default:
            return nil
        }
    }

    var isCTASection: Bool {
        switch self {
        case .favoriteGenresCTA, .searchPromptCTA, .genreShortcuts:
            return true
        default:
            return false
        }
    }

    var supportsSubtitle: Bool {
        switch self {
        case .thisWeeksTopTen, .zeroToThirtyMinutes, .thirtyToNinetyMinutes, .ninetyPlusMinutes, .mostPopular, .latestReleases, .genre, .becauseYouRead, .adultContent:
            return true
        default:
            return false
        }
    }

}
