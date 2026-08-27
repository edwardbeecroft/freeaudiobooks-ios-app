//
//  DismissedManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 19/11/2025.
//  Copyright © 2025 Kneady Technologies. All rights reserved.
//

import Foundation

enum DismissableItem: String {
    case feedbackPrompt
}

struct DismissedManager {
    static func hasDismissed(item: DismissableItem) -> Bool {
        let hasSeen = UserDefaults.standard.bool(forKey: item.rawValue)
        return hasSeen
    }
    static func markDismissed(item: DismissableItem) {
        UserDefaults.standard.set(true, forKey: item.rawValue)
    }
}
