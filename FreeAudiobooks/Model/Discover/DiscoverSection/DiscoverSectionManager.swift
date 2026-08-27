//
//  DiscoverSectionManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 03/11/2025.
//  Copyright © 2025 Kneady Technologies. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseFirestore

class DiscoverSectionManager {
    private init() {}
    static let shared = DiscoverSectionManager()
    
    var allSections: [DiscoverSection] = []
    
    func collectionWithType(type: DiscoverSectionType) -> DiscoverSection? {
        return allSections.first(where: { $0.type == type })
    }
}

extension DiscoverSectionManager {
    func fetchAllSections(completion: @escaping (_ success: Bool) ->()) {
        let discoverSectionsRef = Firestore
            .firestore()
            .collection(FirebasePaths.discoverSections.rawValue)
            .whereField(DiscoverSectionVariables.isHidden.rawValue, isEqualTo: false)

        discoverSectionsRef.getDocuments(source: .default) { snapshot, error in
            guard
                error == nil,
                let snapshot = snapshot else {
                return completion(false)
            }

            var sections = snapshot.documents.compactMap { DiscoverSection(data: $0.data()) }
            sections.sort(by: { $0.position < $1.position })

            // Leave always (for both testing and live)
            self.allSections = sections

            completion(true)
        }
    }
}
