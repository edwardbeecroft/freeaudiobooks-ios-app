//
//  APIBookInternalContent.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 08/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import FirebaseFirestore

enum APIBookInternalSectionVariables: String {
    case uuid
    case position
    case content
}

class APIBookInternalSection {
    let uuid: String
    let position: Int
    let content: String
    
    init?(data: [String: Any]) {
        guard
            let uuid = data[APIBookInternalSectionVariables.uuid.rawValue] as? String,
            let position = data[APIBookInternalSectionVariables.position.rawValue] as? Int,
            let content = data[APIBookInternalSectionVariables.content.rawValue] as? String else {
                return nil
        }
        
        self.uuid = uuid
        self.position = position
        self.content = content
    }
    init(uuid: String,
         position: Int,
         content: String) {
        self.uuid = uuid
        self.position = position
        self.content = content
    }
}

extension APIBookInternalSection {
    func toData() -> [String: Any] {
        return [
            APIBookInternalSectionVariables.uuid.rawValue: uuid,
            APIBookInternalSectionVariables.position.rawValue: position,
            APIBookInternalSectionVariables.content.rawValue: content
        ]
    }
}
