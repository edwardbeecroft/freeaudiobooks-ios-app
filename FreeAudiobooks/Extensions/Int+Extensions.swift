//
//  Int+Extensions.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 19/01/2019.
//  Copyright © 2019 Ed Beecroft. All rights reserved.
//

import UIKit

extension Int {
	func minutesToHoursMinutes() -> (hours: Int, remainingMinutes: Int) {
		return (self / 60, (self % 60))
	}
}

extension Int {
    var roundedWithAbbreviations: String {
        let number = Double(self)
        let thousand = number / 1000
        let million = number / 1000000
        if million >= 1.0 {
            return "\(round(million*10)/10)M"
        }
        else if thousand >= 1.0 {
            return "\(round(thousand*10)/10)k"
        }
        else {
            return "\(self)"
        }
    }
}
