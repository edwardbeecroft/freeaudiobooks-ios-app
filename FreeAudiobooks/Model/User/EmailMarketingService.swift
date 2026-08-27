//
//  EmailMarketingService.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 26/09/2020.
//  Copyright © 2020 Radically Better Ltd. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseFunctions

class EmailMarketingService {
    private lazy var functions = Functions.functions()
}

extension EmailMarketingService {
    func getSubscriptionStatus(completion: @escaping (Bool?) -> Void) {
        print("[EmailMarketing] Checking Brevo subscription status...")

        functions.httpsCallable("getMarketingSubscriptionStatusAB").call { result, error in
            if let error = error {
                print("[EmailMarketing] Brevo check failed: \(error.localizedDescription)")
                completion(nil)
                return
            }

            if let data = result?.data as? [String: Any],
               let subscribed = data["subscribed"] as? Bool {
                print("[EmailMarketing] Brevo check success: subscribed=\(subscribed)")
                completion(subscribed)
            } else {
                print("[EmailMarketing] Brevo check returned unexpected data")
                completion(nil)
            }
        }
    }
}

extension EmailMarketingService {
    /// Subscribes user to marketing emails with segmentation data for Brevo
    /// - Parameters:
    ///   - trigger: The trigger that prompted the opt-in (for attribution)
    ///   - genre: The genre context (for personalization)
    ///   - completion: Called with success/failure
    func subscribeUser(
        trigger: EmailOptInTrigger,
        genre: BookInternalGenre,
        completion: @escaping (Bool) -> Void
    ) {
        let isSubscriber = AccountManager.shared.userIsSubscribed
        let userId = AccountManager.shared.user?.uuid

        var data: [String: Any] = [
            "trigger": trigger.rawValue,
            "planStatusAtOptIn": isSubscriber ? "paid" : "free",
            "genre": genre.rawValue
        ]

        if let userId = userId {
            data["extId"] = userId
        }

        functions.httpsCallable("subscribeToMarketingAB").call(data) { result, error in
            if let error = error {
                print("Error subscribing to marketing: \(error.localizedDescription)")
                completion(false)
                return
            }

            if let data = result?.data as? [String: Any],
               let success = data["success"] as? Bool {
                completion(success)
            } else {
                completion(false)
            }
        }
    }
}

extension EmailMarketingService {
    func unsubscribeUser(completion: @escaping (Bool) -> Void) {
        functions.httpsCallable("unsubscribeFromMarketingAB").call { result, error in
            if let error = error {
                print("Error unsubscribing from marketing: \(error.localizedDescription)")
                completion(false)
                return
            }

            if let data = result?.data as? [String: Any],
               let success = data["success"] as? Bool {
                completion(success)
            } else {
                completion(false)
            }
        }
    }
}
