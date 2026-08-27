//
//  PickUpWhereYouLeftOffUserDefaults.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 10/07/2021.
//  Copyright © 2021 Radically Better Ltd. All rights reserved.
//

import Foundation

struct PickUpWhereYouLeftOffUserDefaults {
    
    private static let lastRecipeViewedUUIDPath = "lastRecipeViewedUUIDPath"
    private static let lastRecipeViewedDatePath = "lastRecipeViewedDatePath"
    
    static var viewedRecipeUUID: String? {
        get {
            return UserDefaults.standard.string(forKey: lastRecipeViewedUUIDPath)
        }
        set {
            UserDefaults.standard.setValue(Date(), forKey: lastRecipeViewedDatePath)
            UserDefaults.standard.setValue(newValue, forKey: lastRecipeViewedUUIDPath)
        }
    }
    
    private static var lastViewedDate: Date? {
        return UserDefaults.standard.object(forKey: lastRecipeViewedDatePath) as? Date
    }
    
    // Returns true if left the app whilst viewing a recipe in the last X days
    static var shouldShowPickUpWhereYouLeftOffView: Bool {
        guard let lastViewedDate = lastViewedDate else { return false }
        
        let calendar = Calendar.current
        if let datePlusXHours = calendar.date(byAdding: .day, value: 2, to: lastViewedDate) {
            return datePlusXHours > Date()
        } else {
            reset()
            return false
        }
    }
    
    static func reset() {
        UserDefaults.standard.setValue(nil, forKey: lastRecipeViewedDatePath)
        UserDefaults.standard.setValue(nil, forKey: lastRecipeViewedUUIDPath)
    }
}
