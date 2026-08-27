//
//  ListeningQuotaManager.swift
//  FreeAudiobooks
//
//  Created by Codex on 20/05/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct ListeningQuotaState {
    static let windowDuration: TimeInterval = 7 * 24 * 60 * 60

    let bookUUIDs: [String]
    let weekStartedAt: Date?
    let now: Date

    var normalisedBookUUIDs: [String] {
        guard let weekStartedAt else { return [] }
        return now.timeIntervalSince(weekStartedAt) >= Self.windowDuration ? [] : bookUUIDs
    }

    var resetsAt: Date? {
        weekStartedAt.map { $0.addingTimeInterval(Self.windowDuration) }
    }

    func hasConsumed(_ contentUUID: String) -> Bool {
        normalisedBookUUIDs.contains(contentUUID)
    }

    func remaining(limit: Int) -> Int {
        max(0, limit - normalisedBookUUIDs.count)
    }

    func canListen(contentUUID: String, limit: Int) -> Bool {
        hasConsumed(contentUUID) || normalisedBookUUIDs.count < limit
    }

    func nextRecordedState(consuming contentUUID: String) -> (bookUUIDs: [String], weekStartedAt: Date) {
        if hasConsumed(contentUUID), let weekStartedAt {
            return (normalisedBookUUIDs, weekStartedAt)
        }

        if let weekStartedAt,
           now.timeIntervalSince(weekStartedAt) < Self.windowDuration {
            return (normalisedBookUUIDs + [contentUUID], weekStartedAt)
        }

        return ([contentUUID], now)
    }
}

struct AudiobookAccessPolicy {
    /// Free users can't start in-app playback while offline (RC-flagged) -
    /// online listening requires a connection; offline listening is a subscriber feature.
    static func shouldBlockInAppPlaybackStart() -> Bool {
        guard RCValues.shared.bool(forKey: .checkConnectivityOnAudioPlaybackAB) else {
            return false
        }

        guard NetworkMonitor.shared.isConnectedNow == false else {
            return false
        }

        guard AccountManager.shared.userIsSubscribed == false else {
            return false
        }

        return true
    }
}

final class ListeningQuotaManager {

    static let shared = ListeningQuotaManager()

    private(set) var listeningQuotaBookUUIDsThisWeek: [String] = []
    private(set) var listeningQuotaWeekStartedAt: Date?

    private init() {}

    var weeklyLimit: Int {
        let configuredLimit = RCValues.shared.int(forKey: .weeklyListeningQuotaLimitAB) ?? 3
        return max(configuredLimit, 1)
    }

    var isEnabledForCurrentUser: Bool {
        !AccountManager.shared.userIsSubscribed
    }

    var isUnlimited: Bool {
        AccountManager.shared.userIsSubscribed
    }

    private var currentState: ListeningQuotaState {
        ListeningQuotaState(
            bookUUIDs: listeningQuotaBookUUIDsThisWeek,
            weekStartedAt: listeningQuotaWeekStartedAt,
            now: Date()
        )
    }

    var normalisedBookUUIDs: [String] {
        currentState.normalisedBookUUIDs
    }

    var remaining: Int {
        currentState.remaining(limit: weeklyLimit)
    }

    var resetsAt: Date? {
        currentState.resetsAt
    }

    var daysUntilReset: Int {
        guard let resetsAt else { return 7 }
        let interval = resetsAt.timeIntervalSinceNow
        if interval <= 0 { return 0 }
        return max(1, Int(ceil(interval / 86_400)))
    }

    func refresh(from user: User) {
        listeningQuotaBookUUIDsThisWeek = user.listeningQuotaBookUUIDsThisWeek
        listeningQuotaWeekStartedAt = user.listeningQuotaWeekStartedAt
        NotificationCenter.default.post(name: .listeningQuotaDidChange, object: nil)
    }

    func hasConsumed(contentUUID: String) -> Bool {
        if isUnlimited { return true }
        return currentState.hasConsumed(contentUUID)
    }

    func canListen(contentUUID: String) -> Bool {
        if isUnlimited { return true }
        return currentState.canListen(contentUUID: contentUUID, limit: weeklyLimit)
    }

    func recordSuccessfulListen(contentUUID: String, completion: @escaping (Bool) -> Void) {
        guard !isUnlimited else {
            completion(true)
            return
        }

        let state = currentState
        if state.hasConsumed(contentUUID) {
            completion(true)
            return
        }

        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        let next = state.nextRecordedState(consuming: contentUUID)
        let previousUUIDs = listeningQuotaBookUUIDsThisWeek
        let previousStart = listeningQuotaWeekStartedAt

        listeningQuotaBookUUIDsThisWeek = next.bookUUIDs
        listeningQuotaWeekStartedAt = next.weekStartedAt
        AccountManager.shared.user?.listeningQuotaBookUUIDsThisWeek = next.bookUUIDs
        AccountManager.shared.user?.listeningQuotaWeekStartedAt = next.weekStartedAt
        NotificationCenter.default.post(name: .listeningQuotaDidChange, object: nil)

        let data: [String: Any] = [
            FirebaseUserVariables.listeningQuotaBookUUIDsThisWeek.rawValue: next.bookUUIDs,
            FirebaseUserVariables.listeningQuotaWeekStartedAt.rawValue: Timestamp(date: next.weekStartedAt)
        ]

        Firestore.firestore()
            .collection(FirebasePaths.users.rawValue)
            .document(uid)
            .setData(data, merge: true) { [weak self] error in
                DispatchQueue.main.async {
                    if error != nil {
                        self?.listeningQuotaBookUUIDsThisWeek = previousUUIDs
                        self?.listeningQuotaWeekStartedAt = previousStart
                        AccountManager.shared.user?.listeningQuotaBookUUIDsThisWeek = previousUUIDs
                        AccountManager.shared.user?.listeningQuotaWeekStartedAt = previousStart
                        NotificationCenter.default.post(name: .listeningQuotaDidChange, object: nil)
                        completion(false)
                    } else {
                        AnalyticsManager.shared.trackListeningQuotaBookConsumed()
                        completion(true)
                    }
                }
            }
    }
}

extension Notification.Name {
    static let listeningQuotaDidChange = Notification.Name("listeningQuotaDidChange")
}
