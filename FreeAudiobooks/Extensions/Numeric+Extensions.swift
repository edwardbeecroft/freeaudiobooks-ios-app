//
//  Numeric+Extensions.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 11/09/2020.
//  Copyright © 2020 Radically Better Ltd. All rights reserved.
//

import Foundation

extension Formatter {
    static let number = NumberFormatter()
}

extension Numeric {
	func thousandsFormatted(style: NumberFormatter.Style = .decimal) -> String? {
		Formatter.number.locale = Locale.current
        Formatter.number.numberStyle = style
		Formatter.number.groupingSeparator = Locale.current.groupingSeparator ?? ","
        return Formatter.number.string(for: self)
    }
}

class NumberFormatters {
    static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}
