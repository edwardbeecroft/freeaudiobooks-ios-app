//
//  DownloadTimestampManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 10/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation

class DownloadTimestampManager {
    private init() {}
    static let shared = DownloadTimestampManager()
    
    private let userDefaults = UserDefaults.standard
    private let downloadTimestampsKey = "downloadTimestamps"
    private let audioDownloadTimestampsKey = "audioDownloadTimestamps"
    
    // MARK: - Public Methods

    /// Records the download timestamp for a given content UUID (for text downloads)
    func recordDownload(uuid: String) {
        var timestamps = getDownloadTimestamps()
        timestamps[uuid] = Date()
        saveDownloadTimestamps(timestamps)
    }
    
    /// Gets the download timestamp for a given content UUID (text downloads)
    func getDownloadTimestamp(uuid: String) -> Date? {
        let timestamps = getDownloadTimestamps()
        return timestamps[uuid]
    }

    /// Removes the download timestamp for a given content UUID (text downloads)
    func removeTimestamp(uuid: String) {
        var timestamps = getDownloadTimestamps()
        timestamps.removeValue(forKey: uuid)
        saveDownloadTimestamps(timestamps)
    }
    
    /// Gets all download timestamps for sorting purposes
    func getAllDownloadTimestamps() -> [String: Date] {
        return getDownloadTimestamps()
    }
    
    /// Assigns current date as fallback timestamp for existing downloads (migration)
    func assignFallbackTimestamp(uuid: String) {
        guard getDownloadTimestamp(uuid: uuid) == nil else { return }
        recordDownload(uuid: uuid)
    }

    // MARK: - Private Methods

    private func getDownloadTimestamps() -> [String: Date] {
        guard let data = userDefaults.data(forKey: downloadTimestampsKey) else {
            return [:]
        }

        do {
            let timestamps = try JSONDecoder().decode([String: Date].self, from: data)
            return timestamps
        } catch {
            print("Failed to decode download timestamps: \(error)")
            return [:]
        }
    }

    private func saveDownloadTimestamps(_ timestamps: [String: Date]) {
        do {
            let data = try JSONEncoder().encode(timestamps)
            userDefaults.set(data, forKey: downloadTimestampsKey)
        } catch {
            print("Failed to encode download timestamps: \(error)")
        }
    }
}

extension DownloadTimestampManager {
    /// Records the audio download timestamp for a given content UUID
    func recordAudioDownload(uuid: String) {
        var timestamps = getAudioDownloadTimestamps()
        timestamps[uuid] = Date()
        saveAudioDownloadTimestamps(timestamps)
    }
    
    /// Gets the audio download timestamp for a given content UUID
    func getAudioDownloadTimestamp(uuid: String) -> Date? {
        let timestamps = getAudioDownloadTimestamps()
        return timestamps[uuid]
    }
    
    /// Removes the audio download timestamp for a given content UUID
    func removeAudioTimestamp(uuid: String) {
        var timestamps = getAudioDownloadTimestamps()
        timestamps.removeValue(forKey: uuid)
        saveAudioDownloadTimestamps(timestamps)
    }

    private func getAudioDownloadTimestamps() -> [String: Date] {
        guard let data = userDefaults.data(forKey: audioDownloadTimestampsKey) else {
            return [:]
        }

        do {
            let timestamps = try JSONDecoder().decode([String: Date].self, from: data)
            return timestamps
        } catch {
            print("Failed to decode audio download timestamps: \(error)")
            return [:]
        }
    }

    private func saveAudioDownloadTimestamps(_ timestamps: [String: Date]) {
        do {
            let data = try JSONEncoder().encode(timestamps)
            userDefaults.set(data, forKey: audioDownloadTimestampsKey)
        } catch {
            print("Failed to encode audio download timestamps: \(error)")
        }
    }
}
