//
//  Array+ReadingTime.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation

extension Array where Element == String {
    /// Calculates the total word count for an array of text strings
    /// - Returns: Total number of words across all strings in the array
    func totalWordCount() -> Int {
        return self.reduce(0) { totalCount, text in
            return totalCount + text.wordCount()
        }
    }

    /// Calculates the estimated reading time in minutes (not rounded to 5-minute intervals)
    /// - Returns: Estimated reading time in minutes based on 225 WPM (minimum 1 minute)
    func estimatedReadingTimeMinutes() -> Int {
        let totalWords = self.totalWordCount()
        return Swift.max(1, Int(ceil(Double(totalWords) / 225.0)))
    }

    /// Calculates the estimated reading time for an array of text chapters
    /// - Returns: Reading time in minutes, rounded to the nearest 5 minutes (minimum 5 minutes)
    func calculateReadingTime() -> Int {
        // Get estimated minutes
        let estimatedMinutes = self.estimatedReadingTimeMinutes()

        // Round to nearest 5 minutes with a minimum of 5 minutes
        let roundedMinutes = Swift.max(5, Int((Double(estimatedMinutes) / 5.0).rounded()) * 5)

        return roundedMinutes
    }
}
