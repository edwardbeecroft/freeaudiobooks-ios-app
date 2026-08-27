//
//  UserFeedback.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 19/11/2025.
//  Copyright © 2025 Kneady Technologies. All rights reserved.
//

import Foundation
import FirebaseFirestore

enum UserFeedbackVariables: String {
    case uuid
    case createdDate
    case userUUID
    case userEmail
    case comment
    case contactConsent
}

class UserFeedback {
    let uuid: String
    let createdDate: Date
    let userUUID: String?
    let userEmail: String?
    let comment: String
    let contactConsent: Bool

    init(comment: String, user: User?, contactConsent: Bool) {
        self.uuid = UUID().uuidString
        self.createdDate = Date()
        self.comment = comment
        self.userUUID = user?.uuid
        self.userEmail = user?.emailAddress
        self.contactConsent = contactConsent
    }

    init?(data: [String: Any]) {
        guard
            let uuid = data[UserFeedbackVariables.uuid.rawValue] as? String,
            let createdDateTimestamp = data[UserFeedbackVariables.createdDate.rawValue] as? Timestamp,
            let comment = data[UserFeedbackVariables.comment.rawValue] as? String else {
            return nil
        }
        self.uuid = uuid
        self.createdDate = createdDateTimestamp.dateValue()
        self.comment = comment
        self.userUUID = data[UserFeedbackVariables.userUUID.rawValue] as? String
        self.userEmail = data[UserFeedbackVariables.userEmail.rawValue] as? String
        self.contactConsent = data[UserFeedbackVariables.contactConsent.rawValue] as? Bool ?? false
    }

    func toData() -> [String: Any] {
        var data: [String: Any] = [
            UserFeedbackVariables.uuid.rawValue: uuid,
            UserFeedbackVariables.createdDate.rawValue: createdDate,
            UserFeedbackVariables.comment.rawValue: comment,
            UserFeedbackVariables.contactConsent.rawValue: contactConsent
        ]
        if
            let userUUID,
            let userEmail {
            data[UserFeedbackVariables.userEmail.rawValue] = userEmail
            data[UserFeedbackVariables.userUUID.rawValue] = userUUID
        }
        return data
    }
}
