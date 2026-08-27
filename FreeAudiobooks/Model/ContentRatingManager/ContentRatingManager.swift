//
//  ContentRatingManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 13/10/2025.
//  Copyright © 2025 Kneady Technologies. All rights reserved.
//

import Foundation

struct SubmitBookReviewResponse: Decodable {
    let success: Bool
    let newRating: Double
    let newNumberOfRatings: Int
    let isUpdate: Bool
}

class ContentRatingManager {
    static let shared = ContentRatingManager()
    private init() {}
}

extension ContentRatingManager {
    func recordRating(_ rating: Double, content: ReadableContentMetadata, type: ReviewedContentType, comment: String? = nil, completion: @escaping (BookReviewResult) -> Void) {
        submitBookReview(bookUUID: content.contentUUID,
                         rating: rating,
                         comment: comment,
                         reviewedContentType: type,
                         completion: completion)
    }
}

// MARK: - Book Review Submission
extension ContentRatingManager {
    func submitBookReview(bookUUID: String, rating: Double, comment: String?, reviewedContentType: ReviewedContentType, completion: @escaping (BookReviewResult) -> Void) {
        // Route to correct endpoint based on content type
        let endpoint: GenerateEndpoint = reviewedContentType == .bookInternalAudiobook
            ? .submitAudiobookReview
            : .submitBookReview

        guard let url = endpoint.url else {
            return completion(.failed(.invalidURL))
        }

        guard let userUUID = AccountManager.shared.user?.uuid else {
            return completion(.failed(.userNotLoggedIn))
        }

        var requestBody: [String: Any] = [
            "bookUUID": bookUUID,
            "userUUID": userUUID,
            "rating": rating
        ]

        if let comment {
            requestBody["comment"] = comment
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failed(.invalidRequestData))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 60

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Book review submission failed: \(error)")
                    completion(.failed(.networkError(error)))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failed(.invalidResponse))
                    return
                }

                guard httpResponse.statusCode == 200 else {
                    // Try to parse error message from response
                    if let data = data,
                       let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorMessage = errorResponse["error"] as? String {
                        completion(.failed(.apiError(errorMessage)))
                    } else {
                        completion(.failed(.apiError("HTTP \(httpResponse.statusCode)")))
                    }
                    return
                }

                guard let data = data else {
                    completion(.failed(.noData))
                    return
                }

                // Parse JSON response
                guard let reviewResponse = try? JSONDecoder().decode(SubmitBookReviewResponse.self, from: data) else {
                    completion(.failed(.invalidResponse))
                    return
                }

                completion(.success(reviewResponse))
            }
        }

        task.resume()
    }

    enum BookReviewResult {
        case success(SubmitBookReviewResponse)
        case failed(BookReviewError)
    }

    enum BookReviewError {
        case invalidURL
        case invalidRequestData
        case networkError(Error)
        case invalidResponse
        case apiError(String)
        case noData
        case userNotLoggedIn
        case unsupportedContentType

        var localizedDescription: String {
            switch self {
            case .invalidURL:
                return "Invalid submission URL"
            case .invalidRequestData:
                return "Invalid request data"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .invalidResponse:
                return "Invalid server response"
            case .apiError(let message):
                return "Submission error: \(message)"
            case .noData:
                return "No response data received"
            case .userNotLoggedIn:
                return "User not logged in"
            case .unsupportedContentType:
                return "Rating not supported for this content type"
            }
        }
    }
}
