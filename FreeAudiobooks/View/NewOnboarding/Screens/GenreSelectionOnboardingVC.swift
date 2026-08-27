//
//  GenreSelectionOnboardingVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

/// Genre selection screen (Screen 2)
class GenreSelectionOnboardingVC: SelectionOnboardingVC {

    // MARK: - Properties

    override var step: NewOnboardingStep { .genreSelection }
    override var allowsMultipleSelection: Bool { true }
    override var minimumSelections: Int { 1 }

    override var options: [OnboardingOption] {
        return BookInternalGenre.allCases.map { genre in
            if useSFSymbols {
                return OnboardingOption(
                    id: genre.rawValue,
                    title: genre.displayString,
                    icon: genreIcon(for: genre)
                )
            } else {
                return OnboardingOption(
                    id: genre.rawValue,
                    title: genre.displayString,
                    emoji: genreEmoji(for: genre)
                )
            }
        }
    }

    // MARK: - Configuration

    override func getTitle() -> String {
        var title = RCValues.shared.string(forKey: .onbGenreSelectionTitle)
        if Locale.isUK {
            title = title.replacingOccurrences(of: "favorite", with: "favourite")
        }
        return title
    }

    override func getSubtitle() -> String {
        var subtitle = RCValues.shared.string(forKey: .onbGenreSelectionSubtitle)
        if Locale.isUK {
            subtitle = subtitle.replacingOccurrences(of: "personalize", with: "personalise")
        }
        return subtitle
    }

    override func handleSelections(_ selectedIds: [String]) {
        let genres = selectedIds.compactMap { BookInternalGenre(rawValue: $0) }
        coordinator.dataStore.selectedGenres = genres
    }

    override func getInitialSelections() -> [String] {
        return coordinator.dataStore.selectedGenres.map { $0.rawValue }
    }

    // MARK: - Helpers

    private var useSFSymbols: Bool {
        RCValues.shared.bool(forKey: .onbGenreSelectionUseSFSymbols)
    }

    private func genreEmoji(for genre: BookInternalGenre) -> String {
        switch genre {
        case .thriller: return "🔪"
        case .mystery: return "🔍"
        case .romance: return "💕"
        case .fantasy: return "🐉"
        case .adventure: return "🗺️"
        case .scienceFiction: return "🚀"
        case .comedy: return "😄"
        case .historical: return "⏳"
        case .drama: return "🎭"
        case .horror: return "👻"
        case .kids: return "🧒"
        }
    }

    private func genreIcon(for genre: BookInternalGenre) -> String {
        switch genre {
        case .thriller: return "bolt.fill"
        case .mystery: return "magnifyingglass"
        case .romance: return "heart.fill"
        case .fantasy: return "wand.and.stars"
        case .adventure: return "map.fill"
        case .scienceFiction: return "sparkles"
        case .comedy: return "face.smiling.fill"
        case .historical: return "clock.fill"
        case .drama: return "theatermasks.fill"
        case .horror: return "moon.stars.fill"
        case .kids: return "figure.and.child.holdinghands"
        }
    }
}
