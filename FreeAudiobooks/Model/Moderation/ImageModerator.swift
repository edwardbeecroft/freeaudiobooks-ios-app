//
//  ImageModerator.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 07/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import Foundation

struct ImageModerator {
    
    private static let visionAPIKey = AppConstants.shared.googleAPIKey
    
    static func performExplicitContentCheckOn(imageData: Data,
                                              completion: @escaping (GoogleImageContentResult) -> Void) {
        
        let base64Image = imageData.base64EncodedString(options: .endLineWithCarriageReturn)
        guard let requestURL = URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(visionAPIKey)") else {
            completion(.error)
            return
        }
        var scanImageRequest = URLRequest(url: requestURL)
        let parameters = [
            "requests": [
                "image": [
                    "content": base64Image
                ],
                "features": [
                    [
                        "type": "SAFE_SEARCH_DETECTION",
                        "maxResults": 10
                    ]
                ]
            ]
        ]
        guard let postData = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            completion(.error)
            return
        }
        
        scanImageRequest.httpMethod = "POST"
        scanImageRequest.httpBody = postData
        scanImageRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        scanImageRequest.addValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        
        let session = URLSession.shared
        session.dataTask(with: scanImageRequest) { (data, response, error) in
            
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                    completion(.error)
                    return
            }
            
            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let googleResponses = json["responses"] as? [[String: Any]],
                let firstResponse = googleResponses.first,
                let safeSearchJSON = firstResponse["safeSearchAnnotation"] as? [String: Any],
                let safeSearchParsed = SafeSearchResponse(json: safeSearchJSON) else {
                completion(.error)
                return
            }
            
            if safeSearchParsed.isInappropriate {
                completion(.explicit)
                return
            } else {
                completion(.notExplicit)
                return
            }
        }.resume()
    }
}

enum GoogleImageContentResult {
    case notExplicit
    case explicit
    case error
}

struct SafeSearchResponse {
    
    let adult: SafeSearchGrade
    let violence: SafeSearchGrade
    var racy: SafeSearchGrade?
    var spoof: SafeSearchGrade?
    var medical: SafeSearchGrade?

    init?(json: [String: Any]) {
        guard
            let adultString = json["adult"] as? String,
            let adultEnum = SafeSearchGrade(rawValue: adultString),
            let violenceString = json["violence"] as? String,
            let violenceEnum = SafeSearchGrade(rawValue: violenceString) else {
                return nil
        }
        adult = adultEnum
        violence = violenceEnum
        
        if
            let racyString = json["racy"] as? String,
            let racyEnum = SafeSearchGrade(rawValue: racyString) {
            racy = racyEnum
        }
        if
            let spoofString = json["spoof"] as? String,
            let spoofEnum = SafeSearchGrade(rawValue: spoofString) {
            spoof = spoofEnum
        }
        if
            let medicalString = json["medical"] as? String,
            let medicalEnum = SafeSearchGrade(rawValue: medicalString) {
            medical = medicalEnum
        }
    }
    
    var isInappropriate: Bool {
        guard
            adult != .likely,
            adult != .veryLikely,
            violence != .likely,
            violence != .veryLikely else {
                return true
        }
        return false
    }
}

enum SafeSearchGrade: String {
    case unknown = "UNKNOWN"
    case veryUnlikely = "VERY_UNLIKELY"
    case unlikely = "UNLIKELY"
    case possible = "POSSIBLE"
    case likely = "LIKELY"
    case veryLikely = "VERY_LIKELY"
}
