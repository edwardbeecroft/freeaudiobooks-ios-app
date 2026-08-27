//
//  ReadableContentMetadata.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 09/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation

enum ContentType: String, Codable {
    case bookInternal
}

protocol ReadableContentMetadata {
    // Common properties
    var contentType: ContentType { get }
    var contentUUID: String { get }
    var title: String? { get }
    var coverImageXLURLString: String? { get }
    var coverImageURLString: String? { get }
    var coverImageThumbnailURLString: String? { get }
    var readerCountInt: Int { get }
    
    // Author/Genre display
    var subtitleText: String { get }
    var authorsString: String { get }
    var genreDisplayString: String? { get }
    var tags: [String] { get }
    
    // Synopsis/Description
    var synopsis: String? { get }
    var needsAISynopsis: Bool { get }

    // Collections/Bookshelves
    var collectionsText: String? { get }
    var lengthDisplayText: String? { get }

    // Audio support
    var hasAnyAudiobook: Bool { get }
    var hasDownloadedAudio: Bool { get }
    
    var hasDownloadedText: Bool { get }
    
    // Progress tracking (display)
    var progressPercentageString: String { get }
    var isContentStored: Bool { get }
    
    // Reading progress methods (from ReadableForReading)
    func getReadingOffset() -> ReadingOffset?
    func setReadingOffset(currentSection: Int, totalSections: Int, yOffset: CGFloat, totalYOffset: CGFloat)
    
    // Completion tracking (from ReadableForReading)
    func markCompleted()
    func isCompleted() -> Bool
    
    var sharingDeeplinkURL: String? { get }
}
