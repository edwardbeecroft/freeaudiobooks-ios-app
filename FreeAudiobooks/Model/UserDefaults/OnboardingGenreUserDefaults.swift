//
//  OnboardingGenreUserDefaults.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 23/12/2024.
//  Copyright © 2024 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation

/// LEGACY: This class is kept for backward compatibility with users who
/// completed the old onboarding flow. New code should use
/// NewOnboardingUserDefaults instead.
///
/// For genre retrieval, check NewOnboardingUserDefaults first, then fall
/// back to this class.
struct OnboardingGenreUserDefaults {

    // MARK: - Keys
    private static let selectedGenresBeforeRegistrationPath = "selectedGenresBeforeRegistrationPath"

    // MARK: - Selected Genres (Guest User Support)

    /// Saves selected genres to UserDefaults for guest users (before registration)
    static func saveSelectedGenres(_ genres: [BookInternalGenre]) {
        let genreStrings = genres.map { $0.rawValue }
        UserDefaults.standard.set(genreStrings, forKey: selectedGenresBeforeRegistrationPath)
    }

    /// Retrieves selected genres from UserDefaults
    static func getSelectedGenres() -> [BookInternalGenre]? {
        guard let genreStrings = UserDefaults.standard.stringArray(forKey: selectedGenresBeforeRegistrationPath) else {
            return nil
        }
        return genreStrings.compactMap { BookInternalGenre(rawValue: $0) }
    }

    /// Clears saved genres (call after successful migration to Firebase)
    static func clearSelectedGenres() {
        UserDefaults.standard.removeObject(forKey: selectedGenresBeforeRegistrationPath)
    }

    // MARK: - Clear All

    /// Clears all onboarding genre-related UserDefaults
    static func clearAll() {
        clearSelectedGenres()
    }
}
