//
//  Double+Extensions.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 05/01/2019.
//  Copyright © 2019 Ed Beecroft. All rights reserved.
//

import Foundation

extension Double {
	/// Rounds the double to decimal places value
	func rounded(toPlaces places:Int) -> String {
		return String(format: "%.\(places)f", self)
	}
	
	func roundedDouble(toPlaces places:Int) -> Double {
		let divisor = pow(10.0, Double(places))
		return (self * divisor).rounded() / divisor
	}
    
    func toFormattedPriceString() -> String {
        return NumberFormatters.priceFormatter.string(from: NSNumber(value: self)) ?? ""
    }
}
