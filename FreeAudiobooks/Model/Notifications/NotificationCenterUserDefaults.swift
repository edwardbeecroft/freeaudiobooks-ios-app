//
//  NotificationCenterUserDefaults.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 07/07/2019.
//  Copyright © 2020 Radically Better Ltd. All rights reserved.
//

import Foundation

struct NotificationCenterUserDefaults {
	
	// User View Counting
	
	private static let didExitForNotificationsPath = "didExitForNotificationsPath"
	static var didExitForNotifications: Bool {
		return UserDefaults.standard.value(forKey: didExitForNotificationsPath) as? Bool ?? false
	}
	static func setDidExitForNotifications(didExit: Bool) {
		UserDefaults.standard.set(didExit, forKey: didExitForNotificationsPath)
	}
}
