//
//  ShortStoryManager.swift
//  FreeBooks
//
//  Created by Ed Beecroft on 07/09/2025.
//  Copyright © 2025 Kneady Technologies. All rights reserved.
//

import Foundation

class ShortStoryManager {
    private init() {}
    static let shared = ShortStoryManager()
    
    private let apiManager = APIShortStoryManager.shared
    private let coreDataManager = CoreDataShortStoryManager.shared
    
    var allShortStories: [CDShortStory] {
        return coreDataManager.getAll()
    }
    
    func shortStoryWithUUID(uuid: String) -> CDShortStory? {
        return coreDataManager.getWithUUID(uuid: uuid)
    }
    
    var featuredShortStories: [CDShortStory] {
        let featuredStoryUUIDs = BookCollectionManager.shared.collectionWithType(type: .modernShorts)?.bookUUIDs ?? []
        
        // Build a lookup dictionary for allShortStories
        let shortStoryDict = Dictionary(uniqueKeysWithValues: allShortStories.map { ($0.uuid, $0) })
        
        // Map featured UUIDs to stories using the dictionary
        return featuredStoryUUIDs.compactMap { shortStoryDict[$0] }
    }
}

// MARK: - Fetching Methods
extension ShortStoryManager {
    func fetchShortStories(completion: @escaping (_ success: Bool) -> Void) {
        apiManager.fetchAllShortStories { success, _ in
            completion(success)
        }
    }
}
