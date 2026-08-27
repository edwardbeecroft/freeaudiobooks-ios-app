//
//  AIResponseGenerator.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 13/10/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import UIKit

enum ResponseGeneratorError: Error {
    case statusCode
    case statusCodeWithError(String)
    case noData
    case unparsable
    case noVariations
    case firestoreSave
    case unknown
    
    var firebaseAnalyticsString: String {
        switch self {
        case .statusCode, .statusCodeWithError: return "Status Code"
        case .noData: return "No Data"
        case .unparsable: return "Unparsable"
        case .noVariations: return "No Variations"
        case .firestoreSave: return L10n.networkError
        case .unknown: return "Unknown"
        }
    }
}

enum AIQueryType {
    case synopsis
    case criticsReviews
}

struct AIResponseGenerator {
    static func generateTextResponses(prompt: String, completion: @escaping (_ gptResponse: GPTResponse?, _ error: ResponseGeneratorError?) -> Void) {
        
        var promptContent: [String: Any] = [
            "prompt": prompt,
            "isSubscribed": AccountManager.shared.userIsSubscribed
        ]
        if let user = AccountManager.shared.user {
            promptContent["userUUID"] = user.uuid
        }
        
        var request = URLRequest(url: GenerateEndpoint.generateTextResponses.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: promptContent)
        
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            guard
                let response = response as? HTTPURLResponse,
                response.statusCode == 200 else {
                return completion(nil, .statusCode)
            }
            guard let data = data else {
                return completion(nil, .noData)
            }
            guard
                let gptResponse = try? JSONDecoder().decode(GPTResponse.self, from: data) else {
                return completion(nil, .unparsable)
            }
            
            return completion(gptResponse, nil)
        }).resume()
    }
}

// MOCKS - used for screenshots & testing
extension AIResponseGenerator {
    static func getMockConversationalResponse() -> GPTResponse {
        let prompt = "As a professional dog trainer, write an email to a client with a 3-month-old Corgi, about the activities they should do to house train their puppy."
        let iPhoneOutput = "Subject: How to House Train Your Puppy\n\nDear [Client],\n\nCongratulations on your new 3-month-old Corgi puppy! I know house training can be a challenge, but you can do it! Here are a few tips that can help you establish a successful house-training routine:\n\n1. Create A Schedule - Create a schedule around your pup's needs. Try to take them out after right after meals and waking up.\n\n2. Use Positive Reinforcement - Always reward your pup for doing the right thing. Praise them and give them treats when they go to the toilet outside.\n\n3. Be Consistent - Make sure you're consistent with the house-training routine. If your pup has an accident, don't get angry. Just clean it up and move on.\n\nI hope these tips are helpful. If you have any questions, please don't hesitate to reach out\n\nGood luck!\n[Your Name] - Professional Dog Trainer"
        let iPadOutput = "Subject: How to House Train Your Puppy\n\nDear [Client],\n\nCongratulations on your new 3-month-old Corgi puppy! I know house training can be a challenge, but you can do it! Here are a few tips that can help you establish a successful house-training routine:\n\n1. Supervise Your Puppy - Make sure you watch your puppy closely when they're inside or outside. This will help you pick up on their cues when nature calls!\n\n2. Create A Schedule - Create a schedule around your pup's needs to ensure they get out to the toilet in time. Try to take them out after meals and right after waking up.\n\n3. Use Positive Reinforcement - Always reward your pup for doing the right thing. Praise them and give them treats when they go to the toilet outside.\n\n4. Be Consistent - Make sure you're consistent with the house-training routine. If your pup has an accident, don't get angry. Just clean it up and move on.\n\nI hope these tips are helpful. If you have any questions, please don't hesitate to reach out. Good luck!\n\nThanks,\n[Your Name] - Professional Dog Trainer"
        let variation1 = GPTVariation(outputText: iPhoneOutput,
                                      variationIndex: 0)
        return GPTResponse(inputPrompt: prompt,
                           completionTokensUsed: 100,
                           variations: [variation1])
    }
}

struct GPTResponse: Decodable {
    let inputPrompt: String
    let completionTokensUsed: Int
    let variations: [GPTVariation]
}

struct GPTVariation: Decodable {
    let uuid = UUID().uuidString
    let outputText: String
    let variationIndex: Int
    
    private enum CodingKeys: String, CodingKey { case outputText, variationIndex }
}

struct GenerateImageResponse: Decodable {
    let inputPrompt: String
    let imageURLs: [String]
}
