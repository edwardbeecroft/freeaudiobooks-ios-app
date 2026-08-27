//
//  RecapModels.swift
//  FreeAudiobooks
//
//  Created by Claude on 28/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation

// MARK: - Request

struct RecapRequest: Codable {
    let bookUUID: String
    let bookTitle: String
    let sectionsRead: [String]
    let currentSectionIndex: Int
    let totalSections: Int
    let readingProgressPercent: Int
    let wordsRead: Int
    let recapLength: String
}

// MARK: - Response

struct RecapResponse: Codable {
    let recap: String
    let bookUUID: String
    let sectionsCovered: Int
    let cacheKey: String
}

// MARK: - Error

enum RecapError: Error, LocalizedError {
    case networkError(Error)
    case invalidResponse
    case needsMoreReading
    case offline
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .needsMoreReading:
            return "Recap available soon. Listen a little more to unlock your recap and pick up where you left off."
        case .offline:
            return "You appear to be offline. Please check your connection."
        case .serverError(let message):
            return message
        }
    }
}

// MARK: - Cached Recap

struct CachedRecap: Codable {
    let recap: String
    let bookUUID: String
    let cacheKey: String
    let cachedAt: Date
    let sectionsCovered: Int

    var isExpired: Bool {
        let expirationInterval: TimeInterval = 7 * 24 * 60 * 60 // 7 days
        return Date().timeIntervalSince(cachedAt) > expirationInterval
    }
}
