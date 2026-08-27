//
//  PercentileService.swift
//  FreeAudiobooks
//
//  Created by FreeAudiobooks on 15/11/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseFunctions

class PercentileService {
    private init() {}
    static let shared = PercentileService()

    private let functions = Functions.functions()

    // MARK: - Fetch Percentiles

    func fetchUserPercentiles(completion: @escaping (UserPercentiles?) -> Void) {
        guard let userId = AccountManager.shared.user?.uuid else {
            completion(nil)
            return
        }

        print("🌐 Fetching percentiles from server...")

        let data = ["userId": userId]

        functions.httpsCallable("getUserPercentiles").call(data) { result, error in
            if let error = error {
                print("❌ Error fetching percentiles: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard
                let resultData = result?.data as? [String: Any],
                let totalTimePercentile = resultData["totalTimePercentile"] as? Int,
                let weeklyTimePercentile = resultData["weeklyTimePercentile"] as? Int,
                let totalBooksPercentile = resultData["totalBooksPercentile"] as? Int,
                let weeklyBooksPercentile = resultData["weeklyBooksPercentile"] as? Int
            else {
                print("❌ Invalid response format")
                completion(nil)
                return
            }

            let percentiles = UserPercentiles(
                totalTimePercentile: totalTimePercentile,
                weeklyTimePercentile: weeklyTimePercentile,
                totalBooksPercentile: totalBooksPercentile,
                weeklyBooksPercentile: weeklyBooksPercentile
            )

            print("✅ Percentiles fetched successfully")
            completion(percentiles)
        }
    }
}
