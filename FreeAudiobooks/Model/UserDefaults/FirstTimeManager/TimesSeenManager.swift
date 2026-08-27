//
//  TimesSeenManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 19/11/2025.
//  Copyright © 2025 Kneady Technologies. All rights reserved.
//

import Foundation

//enum TimesSeenItem: String {
//    case feedbackCell
//}
//
//struct TimesSeenManager {
//    private static var incrementedThisSession: Set<TimesSeenItem> = []
//
//    static func canShow(item: TimesSeenItem, viewLimit: Int) -> Bool {
//        var count = UserDefaults.standard.integer(forKey: item.rawValue)
//
//        // Only increment once per session
//        if !incrementedThisSession.contains(item) {
//            incrementedThisSession.insert(item)
//            count += 1
//            UserDefaults.standard.set(count, forKey: item.rawValue)
//        }
//
//        return count <= viewLimit
//    }
//}
