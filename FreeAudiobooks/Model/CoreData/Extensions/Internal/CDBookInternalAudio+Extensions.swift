//
//  CDBookInternalAudio+Extensions.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 26/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import CoreData
import AVFoundation

// MARK: - Helper Properties
extension CDBookInternalAudio {
    var fileSizeMB: Double {
        return Double(fileSize) / (1024.0 * 1024.0)
    }

    var fileSizeString: String {
        let mb = fileSizeMB
        if mb < 1.0 {
            let kb = Double(fileSize) / 1024.0
            return String(format: "%.1f KB", kb)
        } else {
            return String(format: "%.1f MB", mb)
        }
    }

    var languageDisplayName: String {
        guard
            let language,
            let audiobookLanguage = AudiobookLanguage(rawValue: language) else { return "Unknown" }
        return audiobookLanguage.displayString
    }

    var ageString: String {
        guard let datePersisted = datePersisted else { return "Unknown" }

        let now = Date()
        let timeInterval = now.timeIntervalSince(datePersisted)
        let days = Int(timeInterval / (24 * 60 * 60))

        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else if days < 7 {
            return "\(days) days ago"
        } else if days < 30 {
            let weeks = days / 7
            return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
        } else if days < 365 {
            let months = days / 30
            return months == 1 ? "1 month ago" : "\(months) months ago"
        } else {
            let years = days / 365
            return years == 1 ? "1 year ago" : "\(years) years ago"
        }
    }

    var durationTimeInterval: TimeInterval {
        return TimeInterval(duration)
    }
}


// MARK: - Storage Limits
extension CDBookInternalAudio {
    static let maxFileSizeBytes: Int64 = 100 * 1024 * 1024 // 100MB
    static let maxFileSizeMB: Double = 100.0

    var exceedsMaxSize: Bool {
        return fileSize > CDBookInternalAudio.maxFileSizeBytes
    }

    static func isFileSizeValid(_ data: Data) -> Bool {
        return Int64(data.count) <= maxFileSizeBytes
    }
}
