//
//  BookInternalManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 06/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseStorage
import FirebaseFirestore

class APIBookInternalManager {
    private init() {}
    static let shared = APIBookInternalManager()
    
    var allStories: [APIBookInternal] = []
}

extension APIBookInternalManager {
    func fetchAllShortStories(completion: @escaping (_ success: Bool, _ stories: [CDBookInternal]) ->()) {
        let shortStoriesRef = Firestore
            .firestore()
            .collection(FirebasePaths.booksInternal.rawValue)
            .whereField(APIBookInternalVariables.isHidden.rawValue, isEqualTo: false)
            .order(by: APIBookInternalVariables.datePublished.rawValue, descending: true)
        
        shortStoriesRef.getDocuments(source: .default) { snapshot, error in
            guard
                error == nil,
                let snapshot = snapshot else {
                return completion(false, [])
            }
            
            let shortStories = snapshot.documents.compactMap { APIBookInternal(data: $0.data()) }
            
            // Persist to CoreData synchronously for immediate availability
            let savedStories = CoreDataBookInternalManager.shared.persistSynchronously(shortStories)
       
            //logShortStoryData(shortStories: shortStories)
            
            completion(true, savedStories)
        }
    }
    
    func fetchStoriesWithIDs(uuids: [String], completion: @escaping (_ success: Bool) ->()) {
        let shortStoriesRef = Firestore
            .firestore()
            .collection(FirebasePaths.booksInternal.rawValue)
            .whereField(APIBookInternalVariables.uuid.rawValue, in: uuids)
            .order(by: APIBookInternalVariables.datePublished.rawValue, descending: true)
        
        shortStoriesRef.getDocuments(source: .default) { snapshot, error in
            guard
                error == nil,
                let snapshot = snapshot else {
                return completion(false)
            }
            
            let shortStories = snapshot.documents.compactMap { APIBookInternal(data: $0.data()) }
            
            print("FB | API: Received \(shortStories.count) short stories")
            
            // Persist to CoreData synchronously for immediate availability
            _ = CoreDataBookInternalManager.shared.persistSynchronously(shortStories)
            
            completion(true)
        }
    }
}

extension APIBookInternalManager {
    func incrementReadCountForBookInternalWithUUID(_ bookUUID: String) {
        
        let storyData: [String: Any] = [
            APIBookInternalVariables.readerCount.rawValue: FieldValue.increment(Double(1))
        ]
        
        let bookInternalRef = Firestore
            .firestore()
            .collection(FirebasePaths.booksInternal.rawValue)
            .document(bookUUID)
        
        bookInternalRef.setData(storyData, merge: true)
        
        let storiesToUpdate = self.allStories.filter { $0.uuid == bookUUID }
        storiesToUpdate.forEach { story in
            story.readerCount += 1
        }
        
        CoreDataBookInternalManager.shared.increaseReaderCountForBookInternalWithUUID(bookUUID)
    }
}

extension APIBookInternalManager {
    func logShortStoryData(shortStories: [APIBookInternal]) {
        // REGULAR
        print("*** [StoryData] All Books ***")
        print("[StoryData] Total Books: \(shortStories.count)")
        var genreCounts = BookInternalGenre.allCases.reduce(into: [BookInternalGenre: Int]()) { dict, genre in
            dict[genre] = 0
        }
        for shortStory in shortStories {
            genreCounts[shortStory.genre]! += 1
        }
        genreCounts.forEach { genreCount in
            print("[StoryData] \(genreCount.key.displayString) - Count: \(genreCount.value)")
        }
        
        
        // EARLY ACCESS
        print("*** [StoryData] Early Access Books ***")
        let eaStories = shortStories.filter({ $0.isEarlyAccess })
        print("[StoryData] Total Early Access Books: \(eaStories.count)")
        
        var eaGenreCounts = BookInternalGenre.allCases.reduce(into: [BookInternalGenre: Int]()) { dict, genre in
            dict[genre] = 0
        }
        for eaShortStory in eaStories {
            eaGenreCounts[eaShortStory.genre]! += 1
        }
        eaGenreCounts.forEach { eaGenreCount in
            print("[StoryData] \(eaGenreCount.key.displayString) - Count: \(eaGenreCount.value)")
        }
        
        print("*** [StoryData] Early Access Book Data - For Featuring ***")
        for story in eaStories {
            guard
                let availableForAllDateString = story.availableForAllDateString,
                let unlockDate = DateFormatters.earlyAccessDateFormatter.date(from: availableForAllDateString) else { continue }
            print("[StoryData] \(story.title) - \(story.genre) - \(unlockDate.localizedDateString)")
        }
        
        print("[StoryData] Books without tags: \(shortStories.filter { $0.tags.isEmpty }.count)")
    }
}
