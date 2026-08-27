//
//  RoadmapManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 06/03/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import FirebaseFunctions

class RoadmapManager {
    private init() {}
    static let shared = RoadmapManager()

    private lazy var functions = Functions.functions()
    var roadmapItems = [RoadmapItem]()
    
    func postWithUUID(_ uuid: String) -> RoadmapItem? {
        return roadmapItems.filter({$0.uuid == uuid}).first
    }
}

extension RoadmapManager {
    func fetchAllRoadmapItems(completion: @escaping (_ success: Bool) -> Void) {

        let roadmapItemsQuery: Query = Firestore
            .firestore()
            .collection(FirebasePaths.roadmap.rawValue)

        roadmapItemsQuery.getDocuments(source: .default) { [weak self] snapshot, error in
            guard
                let self = self,
                let snapshot = snapshot else {
                    return completion(false)
            }
            
            var newRoadmapItems = snapshot.documents.compactMap { RoadmapItem(data: $0.data()) }
            newRoadmapItems = newRoadmapItems.filter { $0.moderationStatus.isPublic }
            newRoadmapItems.sort(by: { $0.upvoteCount > $1.upvoteCount })
            self.roadmapItems = newRoadmapItems
            
            completion(true)
        }
    }
}

extension RoadmapManager {
    func adjustUpvoteCountForRoadmapItemWithUUID(_ roadmapItemUUID: String, wasUpvote: Bool) {
        // Optimistic local update
        if let roadmapItem = self.roadmapItems.first(where: { $0.uuid == roadmapItemUUID }) {
            roadmapItem.upvoteCount += wasUpvote ? 1 : -1
        }

        let data: [String: Any] = [
            "roadmapItemId": roadmapItemUUID,
            "isUpvote": wasUpvote
        ]

        functions.httpsCallable("updateUpvoteCount").call(data) { result, error in
            if let error = error {
                print("[RoadmapManager] updateUpvoteCount failed: \(error.localizedDescription)")
            }
        }
    }
}

extension RoadmapManager {
    func uploadNewRoadmapItem(title: String, completion: @escaping (Bool) -> Void) {

        let newUUID = UUID().uuidString
        var data: [String: Any] = [
            RoadmapItemVariables.uuid.rawValue: newUUID,
            RoadmapItemVariables.title.rawValue: title,
            RoadmapItemVariables.description.rawValue: "",
            RoadmapItemVariables.itemType.rawValue: RoadmapItemType.uncategorized.rawValue,
            RoadmapItemVariables.upvoteCount.rawValue: 1,
            RoadmapItemVariables.moderationStatus.rawValue: ModerationStatus.pending.rawValue,
            RoadmapItemVariables.status.rawValue: RoadmapItemStatus.requested.rawValue,
            RoadmapItemVariables.createdDate.rawValue: Date()
        ]

        if let userUUID = AccountManager.shared.user?.uuid {
            data[RoadmapItemVariables.userUUID.rawValue] = userUUID
        }
        
        let ref = Firestore.firestore()
            .collection(FirebasePaths.roadmap.rawValue)
            .document(newUUID)
        
        ref.setData(data, merge: true, completion: { error in
            if error != nil {
                completion(false)
                return
            }
            completion(true)
        })
    }
}
