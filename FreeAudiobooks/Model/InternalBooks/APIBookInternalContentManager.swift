//
//  APIBookInternalContentManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 09/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation

class APIBookInternalContentManager {
    
    /// Downloads and caches short story content from Firestore sections subcollection
    static func downloadBookInternal(bookUUID: String, isTemporary: Bool = false, progress: @escaping (Double?) -> Void, completion: @escaping (_ newBookInternalContent: CDBookInternalContent?, Error?) -> Void) {
        progress(0.1) // Start progress
        
        APIBookInternalSectionManager.shared.fetchSectionsForBookUUID(bookUUID: bookUUID, isTemporary: isTemporary) { content, success in
            progress(0.7) // API call completed
            
            if success, let content = content {
                progress(1.0) // Completed
                print("APIBookInternalContentManager: Successfully stored story \(bookUUID) in Core Data")
                completion(content, nil)
            } else {
                print("APIBookInternalContentManager: Failed to download story \(bookUUID)")
                completion(nil, BookInternalContentError.networkError)
            }
        }
    }
    
    /// Retrieves cached short story content from Core Data
    static func getBookInternalContent(bookUUID: String) -> CDBookInternalContent? {
        if
            let content = CoreDataBookInternalContentManager.shared.getWithUUID(bookUUID: bookUUID),
            content.sectionCount > 0 {
            return content
        }
        return nil
    }
}

enum BookInternalContentError: Error {
    case persistenceFailed
    case networkError
    case invalidData
    
    var localizedDescription: String {
        switch self {
        case .persistenceFailed:
            return "Failed to save short story content"
        case .networkError:
            return "Network error while downloading short story"
        case .invalidData:
            return "Invalid short story data received"
        }
    }
}
