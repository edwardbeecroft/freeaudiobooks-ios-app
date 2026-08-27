//
//  AudioPositionManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 26/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation

struct AudioPlaybackProgress: Codable, Equatable {
    let bookUUID: String
    let position: TimeInterval
    let duration: TimeInterval
    let updatedAt: Date
}

final class AudioPlaybackProgressManager {

    static let shared = AudioPlaybackProgressManager()

    private let userDefaults: UserDefaults
    private let now: () -> Date
    private let progressKeyPrefix = "audiobook_playback_progress_"
    private let legacyPositionKeyPrefix = "audiobook_position_"

    init(userDefaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.userDefaults = userDefaults
        self.now = now
    }

    func getProgress(for bookUUID: String) -> AudioPlaybackProgress? {
        if let data = userDefaults.data(forKey: progressKey(for: bookUUID)),
           let progress = try? JSONDecoder().decode(AudioPlaybackProgress.self, from: data) {
            return progress
        }

        let legacyPosition = userDefaults.double(forKey: legacyPositionKey(for: bookUUID))
        guard legacyPosition > 0 else { return nil }

        return AudioPlaybackProgress(
            bookUUID: bookUUID,
            position: legacyPosition,
            duration: 0,
            updatedAt: .distantPast
        )
    }

    func savePosition(_ position: TimeInterval, for bookUUID: String) {
        let existing = getProgress(for: bookUUID)
        saveProgress(
            bookUUID: bookUUID,
            position: position,
            duration: existing?.duration ?? 0
        )
    }

    func saveDuration(_ duration: TimeInterval, for bookUUID: String) {
        let existing = getProgress(for: bookUUID)
        saveProgress(
            bookUUID: bookUUID,
            position: existing?.position ?? 0,
            duration: duration
        )
    }

    func clearProgress(for bookUUID: String) {
        userDefaults.removeObject(forKey: progressKey(for: bookUUID))
        userDefaults.removeObject(forKey: legacyPositionKey(for: bookUUID))
    }

    func clearAllProgress() {
        let keys = userDefaults.dictionaryRepresentation().keys
        let progressKeys = keys.filter {
            $0.hasPrefix(progressKeyPrefix) || $0.hasPrefix(legacyPositionKeyPrefix)
        }

        for key in progressKeys {
            userDefaults.removeObject(forKey: key)
        }

        userDefaults.synchronize()
    }

    func getBookUUIDsWithSavedProgress() -> [String] {
        let keys = userDefaults.dictionaryRepresentation().keys
        var uuids = Set<String>()

        for key in keys where key.hasPrefix(progressKeyPrefix) {
            let bookUUID = String(key.dropFirst(progressKeyPrefix.count))
            guard let progress = getProgress(for: bookUUID) else { continue }
            if progress.position > 0 || progress.duration > 0 {
                uuids.insert(bookUUID)
            }
        }

        for key in keys where key.hasPrefix(legacyPositionKeyPrefix) {
            let bookUUID = String(key.dropFirst(legacyPositionKeyPrefix.count))
            if userDefaults.double(forKey: key) > 0 {
                uuids.insert(bookUUID)
            }
        }

        return Array(uuids)
    }

    private func saveProgress(bookUUID: String, position: TimeInterval, duration: TimeInterval) {
        let progress = AudioPlaybackProgress(
            bookUUID: bookUUID,
            position: position,
            duration: duration,
            updatedAt: now()
        )

        guard let data = try? JSONEncoder().encode(progress) else { return }
        userDefaults.set(data, forKey: progressKey(for: bookUUID))
        userDefaults.removeObject(forKey: legacyPositionKey(for: bookUUID))
    }

    private func progressKey(for bookUUID: String) -> String {
        return progressKeyPrefix + bookUUID
    }

    private func legacyPositionKey(for bookUUID: String) -> String {
        return legacyPositionKeyPrefix + bookUUID
    }
}

final class AudioPositionManager {

    static let shared = AudioPositionManager()

    private let playbackProgressManager: AudioPlaybackProgressManager

    init(playbackProgressManager: AudioPlaybackProgressManager = .shared) {
        self.playbackProgressManager = playbackProgressManager
    }

    // MARK: - Public Interface

    func savePosition(_ position: TimeInterval, for bookUUID: String) {
        playbackProgressManager.savePosition(position, for: bookUUID)
        print("📍 Saved audio position \(formatTime(position)) for book: \(bookUUID)")
    }

    func getPosition(for bookUUID: String) -> TimeInterval {
        return playbackProgressManager.getProgress(for: bookUUID)?.position ?? 0
    }

    func clearPosition(for bookUUID: String) {
        playbackProgressManager.clearProgress(for: bookUUID)
        print("📍 Cleared audio position for book: \(bookUUID)")
    }

    func hasPosition(for bookUUID: String) -> Bool {
        let position = getPosition(for: bookUUID)
        return position > 0
    }

    func getBookUUIDsWithSavedPositions() -> [String] {
        return playbackProgressManager.getBookUUIDsWithSavedProgress()
            .filter { getPosition(for: $0) > 0 }
    }

    func clearAllPositions() {
        playbackProgressManager.clearAllProgress()
        print("📍 Cleared all audio positions")
    }

    // MARK: - Private Helpers

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - CDBookInternal Extension
extension CDBookInternal {

    var audioPosition: TimeInterval {
        get {
            return AudioPositionManager.shared.getPosition(for: self.contentUUID)
        }
        set {
            AudioPositionManager.shared.savePosition(newValue, for: self.contentUUID)
        }
    }

    var hasAudioPosition: Bool {
        return AudioPositionManager.shared.hasPosition(for: self.contentUUID)
    }
}
