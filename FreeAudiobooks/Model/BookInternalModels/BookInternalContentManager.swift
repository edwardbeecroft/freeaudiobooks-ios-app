//
//  BookInternalContentManager.swift
//  FreeBooks
//
//  Created by Ed Beecroft on 09/09/2025.
//  Copyright © 2025 Kneady Technologies. All rights reserved.
//

import Foundation

class BookInternalContentManager {
    
    /// Downloads and caches internal book content from Firestore sections subcollection
    static func downloadInternalBook(bookUUID: String, progress: @escaping (Double?) -> Void, completion: @escaping (_ newBookInternalContent: CDShortStoryContent?, Error?) -> Void) {
        progress(0.1) // Start progress
        
        APIBookInternalSectionManager.shared.fetchSectionsForBookUUID(bookUUID: bookUUID) { content, success in
            progress(0.7) // API call completed
            
            if success, let content = content {
                progress(1.0) // Completed
                print("BookInternalContentManager: Successfully stored book \(bookUUID) in Core Data")
                completion(content, nil)
            } else {
                print("BookInternalContentManager: Failed to download book \(bookUUID)")
                completion(nil, BookInternalContentError.networkError)
            }
        }
    }
    
    /// Retrieves cached internal book content from Core Data
    static func getInternalBookContent(bookUUID: String) -> CDShortStoryContent? {
        return CoreDataBookInternalContentManager.shared.getWithUUID(bookUUID: bookUUID)
    }
    
}

enum BookInternalContentError: Error {
    case persistenceFailed
    case networkError
    case invalidData
    
    var localizedDescription: String {
        switch self {
        case .persistenceFailed:
            return "Failed to save internal book content"
        case .networkError:
            return "Network error while downloading internal book"
        case .invalidData:
            return "Invalid internal book data received"
        }
    }
}