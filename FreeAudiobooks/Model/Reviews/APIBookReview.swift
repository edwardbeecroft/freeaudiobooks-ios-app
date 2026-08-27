//
//  APIBookReview.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 13/10/2025.
//  Copyright © 2025 Kneady Technologies. All rights reserved.
//

import Foundation
import FirebaseFirestore

enum APIBookInternalReviewVariables: String {
    case uuid
    case createdDate
    case reviewedContentType
    case userUUID
    case displayName
    case profileImageURLString
    case displayableState
    case isDisplayed
    case rating
    case comment
}

enum ReviewedContentType: String {
    case bookInternal
    case bookInternalAudiobook
}

enum ReviewDisplayableState: String {
    case pendingReview
    case displayed
    case hidden
}

class APIBookReview {
    let uuid: String
    let createdDate: Date
    let reviewedContentType: ReviewedContentType
    let userUUID: String
    let displayName: String
    let profileImageURLString: String?
    let displayableState: ReviewDisplayableState
    let rating: Double
    let comment: String?

    var trimmedComment: String? {
        guard let comment else { return nil }
        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedComment.isEmpty ? nil : trimmedComment
    }

    var hasWrittenComment: Bool {
        trimmedComment != nil
    }
    
    init?(data: [String: Any]) {
        guard
            let uuid = data[APIBookInternalReviewVariables.uuid.rawValue] as? String,
            let createdDateTimestamp = data[APIBookInternalReviewVariables.createdDate.rawValue] as? Timestamp,
            let reviewedContentTypeString = data[APIBookInternalReviewVariables.reviewedContentType.rawValue] as? String,
            let reviewedContentType = ReviewedContentType(rawValue: reviewedContentTypeString),
            let userUUID = data[APIBookInternalReviewVariables.userUUID.rawValue] as? String,
            let displayName = data[APIBookInternalReviewVariables.displayName.rawValue] as? String,
            let rating = data[APIBookInternalReviewVariables.rating.rawValue] as? Double else {
            return nil
        }
        self.uuid = uuid
        self.createdDate = createdDateTimestamp.dateValue()
        self.reviewedContentType = reviewedContentType
        self.userUUID = userUUID
        self.displayName = displayName
        self.profileImageURLString = APIBookReview.resolveProfileImageURLString(from: data)
        self.displayableState = APIBookReview.resolveDisplayableState(from: data)
        self.rating = rating
        self.comment = data[APIBookInternalReviewVariables.comment.rawValue] as? String
    }
}

private extension APIBookReview {
    static func resolveDisplayableState(from data: [String: Any]) -> ReviewDisplayableState {
        
        if
            let displayableStateString = data[APIBookInternalReviewVariables.displayableState.rawValue] as? String,
            let displayableState = ReviewDisplayableState(rawValue: displayableStateString) {
            return displayableState
        }

        let isDisplayed = data[APIBookInternalReviewVariables.isDisplayed.rawValue] as? Bool ?? false
        return isDisplayed ? .displayed : .pendingReview
    }

    static func resolveProfileImageURLString(from data: [String: Any]) -> String? {
        guard let profileImageURLString = data[APIBookInternalReviewVariables.profileImageURLString.rawValue] as? String else {
            return nil
        }

        let trimmedURLString = profileImageURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURLString.isEmpty, URL(string: trimmedURLString) != nil else {
            return nil
        }

        return trimmedURLString
    }
}
