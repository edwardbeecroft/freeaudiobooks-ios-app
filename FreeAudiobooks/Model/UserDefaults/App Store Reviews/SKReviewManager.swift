//
//  SKReviewManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 26/01/2019.
//  Copyright © 2019 Ed Beecroft. All rights reserved.
//

import UIKit
import StoreKit
import FirebaseCore

struct SKReviewManager {
	
	// MARK: - Tracking Counts

    static let storyViewsPath = "storyViews"
    static var storyViews: Int {
        return UserDefaults.standard.integer(forKey: storyViewsPath)
    }
    static func incrementStoryViews() {
        let newCount = storyViews + 1
        UserDefaults.standard.set(newCount, forKey: storyViewsPath)
    }
	
	static let launchCountPath = "launchCountPath"
	static var launchCount: Int {
		return UserDefaults.standard.integer(forKey: launchCountPath)
	}
	static func incrementLaunchCount() {
		let newCount = launchCount + 1
		UserDefaults.standard.set(newCount, forKey: launchCountPath)
	}

	static func clearCountData() {
		UserDefaults.standard.removeObject(forKey: storyViewsPath)
		UserDefaults.standard.removeObject(forKey: launchCountPath)
        UserDefaults.standard.removeObject(forKey: fullScreenTappedNotNowPath)
        UserDefaults.standard.removeObject(forKey: hasTappedAddReviewPath)
	}
}

extension SKReviewManager {
	static func requestReview(venue: SKReviewVenue) {
        guard AppConstants.shared.developmentMode == .production else { return }

        guard RCValues.shared.bool(forKey: .isarAB3) == false || SKReviewManager.launchCount > 1 else {
            return
        }
        
		SKStoreReviewController.requestReview()
		AnalyticsManager.shared.trackRequestedAppReviewAutomatically(venue: venue)
		// Record for email opt-in 2-minute guardrail (skip during onboarding)
		if venue != .onboarding {
			EmailOptInUserDefaults.recordSKReviewRequest()
		}
	}
}

enum SKReviewVenue: String {
    case bookmarkPosition
    case savedBook
    case sharedBook
    case completedBook
    case onboarding
}

extension SKReviewManager {
    
    private static let fullScreenTappedNotNowPath = "fullScreenTappedNotNowPath"
    private static var fullScreenTappedNotNowCount: Int {
        return UserDefaults.standard.integer(forKey: fullScreenTappedNotNowPath)
    }
    static func incrementFullScreenTappedNotNowCount() {
        let newCount = fullScreenTappedNotNowCount + 1
        UserDefaults.standard.set(newCount, forKey: fullScreenTappedNotNowPath)
    }
    
    private static let hasTappedAddReviewPath = "hasTappedAddReviewPath"
    static var hasTappedAddReview: Bool {
        get {
            return UserDefaults.standard.bool(forKey: hasTappedAddReviewPath)
        } set {
            UserDefaults.standard.set(newValue, forKey: hasTappedAddReviewPath)
        }
    }
}
