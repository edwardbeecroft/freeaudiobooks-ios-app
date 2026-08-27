//
//  Notification+Extensions.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 07/07/2019.
//  Copyright © 2020 Radically Better Ltd. All rights reserved.
//

import Foundation

extension Notification.Name {
	static let didEnterAfterExitingForNotifications = Notification.Name("didEnterAfterExitingForNotifications")
	static let didUpdateSubscriberStatus = Notification.Name("didUpdateSubscriberStatus")
    static let didExitReadingVC = Notification.Name("didExitReadingVC")
}
