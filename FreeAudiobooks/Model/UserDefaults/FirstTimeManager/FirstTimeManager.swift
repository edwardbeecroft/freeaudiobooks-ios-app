//
//  FirstTimeManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 05/04/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation

enum FirstTimeItem: String {
    case notificationsPromptOnCompletingBook
    case readingCoachmarks
    case readingControlsToastSeen
    case readingChromeRevealLearned
    case readingStarted
    case readingActivated
    case bookDetailCarouselSwipeHint

    var path: String {
        switch self {
        case .notificationsPromptOnCompletingBook: return "notificationsPromptOnCompletingBook"
        case .readingCoachmarks: return "readingCoachmarks"
        case .readingControlsToastSeen: return "readingControlsToastSeen"
        case .readingChromeRevealLearned: return "readingChromeRevealLearned"
        case .readingStarted: return "readingStarted"
        case .readingActivated: return "readingActivated"
        case .bookDetailCarouselSwipeHint: return "bookDetailCarouselSwipeHint"
        }
    }
}

struct FirstTimeManager {
    static func hasSeen(item: FirstTimeItem) -> Bool {
        return UserDefaults.standard.bool(forKey: item.path)
    }

    static func markSeen(item: FirstTimeItem) {
        UserDefaults.standard.set(true, forKey: item.path)
    }
}
