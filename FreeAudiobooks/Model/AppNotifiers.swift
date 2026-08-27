
//
//  AppNotifiers.swift
//  FreeAudiobooks
//
//  Created by Edward Beecroft on 09/10/2018.
//  Copyright © 2018 SnowDrift Labs. All rights reserved.
//

import UIKit

class AppNotifiers {
	private init() {}
	static let shared = AppNotifiers()

	var shouldReloadAccountVC: Bool = false
    
    var shouldReloadSavedStoriesVC: Bool = false
    var shouldReloadDiscoverVC: Bool = false
    var shouldReloadSearchResultsVC: Bool = false
    var shouldReloadHomeVC: Bool = false

	var tabBarHasLoaded: Bool = false
	var launchActionNeedsHandling: LaunchAction?
    
    // So far, we've always shown the review popup when a user taps on one of the action buttons, i.e. copy
    // There's quite a low conversion of users who actually review
    // This might be because it's very interruptive time to show the popup
    // This property is part of an experiment to see if showing the popup on the next generation following an action results in more responses
    var hasShownLikingFreeAudiobooksPopupThisSession: Bool = false
    
    var shouldHandleBookCompletion = false
    
	func setReloadAll() {
		shouldReloadAccountVC = true
	}
}
