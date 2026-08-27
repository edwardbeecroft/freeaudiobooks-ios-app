//
//  DiscoverSection.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 03/11/2025.
//  Copyright © 2025 Kneady Technologies. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

enum DiscoverSectionVariables: String {
    case uuid
    case position
    case title
    case subtitle
    case showReaderCount
    case type
    case isHidden
    
    case bookIDs
    case genre
}

class DiscoverSection: Hashable, Equatable {
    let uuid: String
    var position: Int // var to allow position updates during drag-reorder
    let title: String
    let subtitle: String?
    let showReaderCount: Bool
    let type: DiscoverSectionType
    let isHidden: Bool

    var bookIDs: [String]? // Only non-nil for Top 10 section
    let genre: BookInternalGenre? // Only non-nil when the type is genre

    var stories: [CDBookInternal] = [] // Set after fetching
    var dynamicTitle: String? // Used for becauseYouRead section to show the source book title

    init(uuid: String = UUID().uuidString,
         position: Int,
         title: String,
         subtitle: String? = nil,
         showReaderCount: Bool = false,
         type: DiscoverSectionType,
         isHidden: Bool = false,
         bookIDs: [String]? = nil,
         genre: BookInternalGenre? = nil) {
        self.uuid = uuid
        self.position = position
        self.title = title
        self.subtitle = subtitle
        self.showReaderCount = showReaderCount
        self.type = type
        self.isHidden = isHidden
        self.bookIDs = bookIDs
        self.genre = genre
    }
    
    init?(data: [String: Any]) {
        guard
            let uuid = data[DiscoverSectionVariables.uuid.rawValue] as? String,
            let position = data[DiscoverSectionVariables.position.rawValue] as? Int,
            let title = data[DiscoverSectionVariables.title.rawValue] as? String,
            let typeString = data[DiscoverSectionVariables.type.rawValue] as? String,
            let typeEnum = DiscoverSectionType(rawValue: typeString),
            let isHidden = data[DiscoverSectionVariables.isHidden.rawValue] as? Bool else {
                print("🔥 Unable to init DiscoverSection with uuid: \(data[DiscoverSectionVariables.uuid.rawValue] as? String ?? "Unknown")")
                return nil
        }
        
        self.uuid = uuid
        self.position = position
        self.title = title
        self.subtitle = data[DiscoverSectionVariables.subtitle.rawValue] as? String
        self.showReaderCount = data[DiscoverSectionVariables.showReaderCount.rawValue] as? Bool ?? false
        self.type = typeEnum
        self.isHidden = isHidden
        
        self.bookIDs = data[DiscoverSectionVariables.bookIDs.rawValue] as? [String]
        if
            let genreString = data[DiscoverSectionVariables.genre.rawValue] as? String,
            let genre = BookInternalGenre(rawValue: genreString) {
            self.genre = genre
        } else {
            self.genre = nil
        }
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }

    // MARK: - Equatable

    static func == (lhs: DiscoverSection, rhs: DiscoverSection) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    // MARK: - Firebase Serialization

    func toData() -> [String: Any] {
        var data: [String: Any] = [
            DiscoverSectionVariables.uuid.rawValue: uuid,
            DiscoverSectionVariables.position.rawValue: position,
            DiscoverSectionVariables.title.rawValue: title,
            DiscoverSectionVariables.type.rawValue: type.rawValue,
            DiscoverSectionVariables.isHidden.rawValue: isHidden
        ]

        if showReaderCount {
            data[DiscoverSectionVariables.showReaderCount.rawValue] = showReaderCount
        } else {
            data[DiscoverSectionVariables.showReaderCount.rawValue] = FieldValue.delete()
        }

        let trimmedSubtitle = subtitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if type.supportsSubtitle, !trimmedSubtitle.isEmpty {
            data[DiscoverSectionVariables.subtitle.rawValue] = trimmedSubtitle
        } else {
            data[DiscoverSectionVariables.subtitle.rawValue] = FieldValue.delete()
        }

        // Add optional fields if present
        if let bookIDs = bookIDs {
            data[DiscoverSectionVariables.bookIDs.rawValue] = bookIDs
        }

        if let genre = genre {
            data[DiscoverSectionVariables.genre.rawValue] = genre.rawValue
        }

        return data
    }
}
