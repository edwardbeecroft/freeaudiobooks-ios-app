//
//  ReadableContent.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 09/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation

// Protocol for actual readable content objects.
protocol ReadableContent {
    var sectionsArray: [String] { get }
    var totalSections: Int { get }
}
