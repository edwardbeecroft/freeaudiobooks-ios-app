//
//  Locale+Extensions.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 02/11/2025.
//  Copyright © 2025 Kneady Technologies. All rights reserved.
//

import Foundation

extension Locale {
    static var isUS: Bool {
        return Locale.current.identifier == "en_US" || Locale.current.regionCode == "US"
    }
    static var isUK: Bool {
        return Locale.current.identifier == "en_GB" || Locale.current.regionCode == "GB"
    }
}
