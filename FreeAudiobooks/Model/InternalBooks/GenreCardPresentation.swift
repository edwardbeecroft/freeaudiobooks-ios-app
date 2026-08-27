//
//  GenreCardPresentation.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 22/03/2026.
//  Copyright © 2026 Kneady Technologies. All rights reserved.
//

import Foundation

struct GenreCardPresentation {
    let genre: BookInternalGenre
    let previewImageURLStrings: [String]
    let symbolName: String
    let localBackgroundImageName: String?
    let localBackgroundImageExtension: String?
}

extension GenreCardPresentation {
    static func buildAll(from stories: [CDBookInternal]) -> [GenreCardPresentation] {
        let groupedStories = Dictionary(grouping: stories, by: \.genre)
        return BookInternalGenre.allCases.map { genre in
            let previewStories = (groupedStories[genre] ?? [])
                .filter { !($0.coverImageURLThumbnail?.isEmpty ?? true) || !($0.coverImageURL?.isEmpty ?? true) }
                .prefix(4)
            // Prefer full-size covers for the crisp hero image on the right side of the card.
            let previewURLs = previewStories.compactMap { story -> String? in
                if let cover = story.coverImageURL, !cover.isEmpty {
                    return cover
                }
                if let thumbnail = story.coverImageURLThumbnail, !thumbnail.isEmpty {
                    return thumbnail
                }
                return nil
            }
            return GenreCardPresentation(
                genre: genre,
                previewImageURLStrings: previewURLs,
                symbolName: genre.searchSymbolName,
                localBackgroundImageName: genre.searchImageName,
                localBackgroundImageExtension: "jpg"
            )
        }
    }
}
