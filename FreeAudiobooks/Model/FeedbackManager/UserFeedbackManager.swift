//
//  FeedbackManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 19/11/2025.
//  Copyright © 2025 Kneady Technologies. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseFirestore

class UserFeedbackManager {
    private init() {}
    static let shared = UserFeedbackManager()
}

extension UserFeedbackManager {
    func submitFeedback(userFeedback: UserFeedback, completion: @escaping (_ success: Bool) ->()) {
        let userFeedbackRef = Firestore
            .firestore()
            .collection(FirebasePaths.feedback.rawValue)
            .document(userFeedback.uuid)
        
        userFeedbackRef.setData(userFeedback.toData(), merge: true, completion: { (error) in
            if error != nil {
                completion(false)
                return
            }
            completion(true)
        })
    }
}
