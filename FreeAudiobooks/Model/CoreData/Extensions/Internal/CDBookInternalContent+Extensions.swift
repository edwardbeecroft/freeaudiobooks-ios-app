//
//  CDBookInternalContent+Extensions.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 08/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Helper Properties
extension CDBookInternalContent {
    var sectionsArray: [String] {
        return sections as? [String] ?? []
    }
    
    var sectionCount: Int {
        return sectionsArray.count
    }
    
    func section(at index: Int) -> String? {
        let sectionsArr = sectionsArray
        guard index >= 0 && index < sectionsArr.count else { return nil }
        return sectionsArr[index]
    }
}

extension CDBookInternalContent: ReadableContent {
    var totalSections: Int {
        return sectionsArray.count
    }
}
