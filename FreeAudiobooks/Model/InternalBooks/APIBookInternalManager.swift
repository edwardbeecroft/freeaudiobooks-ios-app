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
    
    private let fabLinksRefreshedKey = "catalogue.fabLinksV5Refreshed"
    private var catalogueSource: FirestoreSource {
        UserDefaults.standard.bool(forKey: fabLinksRefreshedKey) ? .default : .server
    }

    var allStories: [APIBookInternal] = []
}

extension APIBookInternalManager {
    func fetchAllShortStories(completion: @escaping (_ success: Bool, _ stories: [CDBookInternal]) ->()) {
        let shortStoriesRef = Firestore
            .firestore()
            .collection(FirebasePaths.booksInternal.rawValue)
            .whereField(APIBookInternalVariables.isHidden.rawValue, isEqualTo: false)
            .order(by: APIBookInternalVariables.datePublished.rawValue, descending: true)
        
        shortStoriesRef.getDocuments(source: catalogueSource) { snapshot, error in
            guard
                error == nil,
                let snapshot = snapshot else {
                return completion(false, [])
            }
            
            let shortStories = snapshot.documents.compactMap { APIBookInternal(data: $0.data()) }
            
            // Persist to CoreData synchronously for immediate availability
            let savedStories = CoreDataBookInternalManager.shared.persistSynchronously(shortStories)
            guard savedStories.count == shortStories.count else { return completion(false, []) }
            if !snapshot.metadata.isFromCache,
               snapshot.documents.allSatisfy({ ($0.data()["deeplinkURLFAB"] as? String)?.hasPrefix("https://links.freeaudiobooksapp.com/book-internal/") == true }) {
                UserDefaults.standard.set(true, forKey: self.fabLinksRefreshedKey)
            }

            completion(true, savedStories)
        }
    }
    
    func fetchStoriesWithIDs(uuids: [String], completion: @escaping (_ success: Bool) ->()) {
        let shortStoriesRef = Firestore
            .firestore()
            .collection(FirebasePaths.booksInternal.rawValue)
            .whereField(APIBookInternalVariables.uuid.rawValue, in: uuids)
            .order(by: APIBookInternalVariables.datePublished.rawValue, descending: true)
        
        shortStoriesRef.getDocuments(source: catalogueSource) { snapshot, error in
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
