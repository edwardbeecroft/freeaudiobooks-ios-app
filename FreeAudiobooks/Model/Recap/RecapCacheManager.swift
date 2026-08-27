//
//  RecapCacheManager.swift
//  FreeAudiobooks
//
//  Created by Claude on 28/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation

final class RecapCacheManager {

    static let shared = RecapCacheManager()
    private init() {}

    private let cacheKey = "recapCacheKey"
    private let maxCacheEntries = 50
    private let cacheTTLDays: TimeInterval = 7 * 24 * 60 * 60  // 7 days

    // MARK: - Public Methods

    func getCachedRecap(for bookUUID: String, cacheKey: String) -> CachedRecap? {
        let allRecaps = getAllCachedRecaps()
        guard let cached = allRecaps.first(where: { $0.bookUUID == bookUUID && $0.cacheKey == cacheKey }) else {
            return nil
        }

        // Check if expired
        if cached.isExpired {
            removeCachedRecap(for: bookUUID)
            return nil
        }

        return cached
    }

    func getCachedRecap(for bookUUID: String) -> CachedRecap? {
        let allRecaps = getAllCachedRecaps()
        guard let cached = allRecaps.first(where: { $0.bookUUID == bookUUID }) else {
            return nil
        }

        // Check if expired
        if cached.isExpired {
            removeCachedRecap(for: bookUUID)
            return nil
        }

        return cached
    }

    func cacheRecap(_ response: RecapResponse) {
        let cachedRecap = CachedRecap(
            recap: response.recap,
            bookUUID: response.bookUUID,
            cacheKey: response.cacheKey,
            cachedAt: Date(),
            sectionsCovered: response.sectionsCovered
        )

        var allRecaps = getAllCachedRecaps()

        // Remove existing entry for this book
        allRecaps.removeAll { $0.bookUUID == response.bookUUID }

        // Add new entry
        allRecaps.append(cachedRecap)

        // Enforce max entries
        if allRecaps.count > maxCacheEntries {
            // Sort by date and keep most recent
            allRecaps.sort { $0.cachedAt > $1.cachedAt }
            allRecaps = Array(allRecaps.prefix(maxCacheEntries))
        }

        saveCachedRecaps(allRecaps)
    }

    func removeCachedRecap(for bookUUID: String) {
        var allRecaps = getAllCachedRecaps()
        allRecaps.removeAll { $0.bookUUID == bookUUID }
        saveCachedRecaps(allRecaps)
    }

    func clearAllCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
    }

    func cleanExpiredCache() {
        var allRecaps = getAllCachedRecaps()
        let initialCount = allRecaps.count
        allRecaps.removeAll { $0.isExpired }

        if allRecaps.count != initialCount {
            saveCachedRecaps(allRecaps)
        }
    }

    // MARK: - Private Methods

    private func getAllCachedRecaps() -> [CachedRecap] {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let recaps = try? JSONDecoder().decode([CachedRecap].self, from: data) else {
            return []
        }
        return recaps
    }

    private func saveCachedRecaps(_ recaps: [CachedRecap]) {
        if let data = try? JSONEncoder().encode(recaps) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }
}
