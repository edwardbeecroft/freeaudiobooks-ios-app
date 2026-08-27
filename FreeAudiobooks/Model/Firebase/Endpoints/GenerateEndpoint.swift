//
//  GenerateEndpoint.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 07/01/2023.
//  Copyright © 2023 Radically Better Ltd. All rights reserved.
//

import Foundation

enum GenerateEndpoint: String {
    case generateTextResponses = "/generateTextResponses"
    case submitBookReview = "/submitBookReview"
    case submitAudiobookReview = "/submitAudiobookReview"
    case generateBookRecap = "/generateBookRecap"

    var url: URL! {
        return URL(string: Endpoint.base + self.rawValue)
    }
}
