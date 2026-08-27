//
//  SessionTrackingManager.swift
//  FreeAudiobooks
//
//  Created by FreeAudiobooks on 15/11/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

class SessionTrackingManager {
    private init() {}
    static let shared = SessionTrackingManager()

    private struct DailyReadingRecord: Codable {
        let dayStart: Date
        var seconds: Int
    }

    private enum StorageKeys {
        static let dailyReadingRecords = "dailyReadingRecords"
    }

    private var sessionStartTime: Date?
    private var accumulatedSessionTime: TimeInterval = 0
    private var syncTimer: Timer?
    private var sectionsReadThisSession: Int = 0

    private let syncIntervalSeconds: TimeInterval = 60 // Sync every 60 seconds

    // MARK: - Session Lifecycle

    func startSession() {
        guard sessionStartTime == nil else {
            print("⚠️ Session already active - skipping start")
            return
        }

        sessionStartTime = Date()
        print("▶️ Started reading session at \(sessionStartTime!)")

        // Start periodic sync timer
        startSyncTimer()

        // Check if we need to reset weekly stats
        checkAndResetWeeklyStatsIfNeeded()
    }

    func endSession() {
        guard let startTime = sessionStartTime else {
            print("⚠️ No active session to end")
            return
        }

        // Calculate time elapsed in this session
        let elapsed = Date().timeIntervalSince(startTime)
        accumulatedSessionTime += elapsed

        let totalSessionTime = accumulatedSessionTime
        print("⏹️ Ending reading session - Total time: \(Int(round(totalSessionTime)))s")

        // Stop timer
        stopSyncTimer()

        // Final sync before session ends
        syncTimeToFirestore()

        // Reset session state (section counter persists across sessions)
        sessionStartTime = nil
        accumulatedSessionTime = 0
    }

    // MARK: - Section Tracking (for Interstitial Ads)

    func incrementSectionCount() {
        sectionsReadThisSession += 1
        print("📖 Section count: \(sectionsReadThisSession)")
    }

    func shouldShowInterstitialForSectionChange() -> Bool {
        let sectionGap = RCValues.shared.int(forKey: .readingVCInterstitialAdSectionGap) ?? 3
        guard sectionGap > 0 else { return false }
        return sectionsReadThisSession > 0 && sectionsReadThisSession % sectionGap == 0
    }

    // MARK: - Syncing

    private func startSyncTimer() {
        stopSyncTimer() // Ensure no duplicate timers

        syncTimer = Timer.scheduledTimer(withTimeInterval: syncIntervalSeconds, repeats: true) { [weak self] _ in
            self?.syncTimeToFirestore()
        }
    }

    private func stopSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    private func syncTimeToFirestore() {
        guard let user = AccountManager.shared.user else { return }

        // Calculate total time since session start
        let currentSessionTime: TimeInterval
        if let startTime = sessionStartTime {
            currentSessionTime = Date().timeIntervalSince(startTime) + accumulatedSessionTime
        } else {
            currentSessionTime = accumulatedSessionTime
        }

        guard currentSessionTime > 0 else { return }

        // Round to nearest second (not truncate)
        let secondsToAdd = Int(round(currentSessionTime))
        addReadingTimeToLocalStats(secondsToAdd)

        // Update local user object
        user.totalReadingTimeSeconds += secondsToAdd
        user.weeklyReadingTimeSeconds += secondsToAdd

        // Sync to Firestore using FieldValue.increment for atomic updates
        let data: [String: Any] = [
            FirebaseUserVariables.totalReadingTimeSeconds.rawValue: FieldValue.increment(Int64(secondsToAdd)),
            FirebaseUserVariables.weeklyReadingTimeSeconds.rawValue: FieldValue.increment(Int64(secondsToAdd))
        ]

        AccountManager.shared.updateUserWithData(data) { success in
            if success {
                print("✅ Synced \(secondsToAdd) seconds to Firestore")
            }
        }

        // Reset accumulated time after sync
        accumulatedSessionTime = 0
        sessionStartTime = Date() // Restart timer from now
    }

    private func addReadingTimeToLocalStats(_ seconds: Int) {
        guard seconds > 0 else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var records = Self.loadDailyReadingRecords()

        if let index = records.firstIndex(where: { calendar.isDate($0.dayStart, inSameDayAs: today) }) {
            records[index].seconds += seconds
        } else {
            records.append(DailyReadingRecord(dayStart: today, seconds: seconds))
        }

        records = records.filter {
            guard let age = calendar.dateComponents([.day], from: $0.dayStart, to: today).day else { return false }
            return age <= 14
        }

        Self.saveDailyReadingRecords(records)
    }

    private func currentUnpersistedSessionSeconds() -> Int {
        guard let startTime = sessionStartTime else {
            return Int(round(accumulatedSessionTime))
        }

        return Int(round(Date().timeIntervalSince(startTime) + accumulatedSessionTime))
    }

    // MARK: - Weekly Reset

    private func checkAndResetWeeklyStatsIfNeeded() {
        guard let user = AccountManager.shared.user else { return }

        let calendar = Calendar.current
        let now = Date()

        // Check if we're in a new week
        let lastWeekStart = user.weekStartDate
        let currentWeekStart = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now).date ?? now

        // If the week has changed, reset weekly stats
        if !calendar.isDate(lastWeekStart, equalTo: currentWeekStart, toGranularity: .weekOfYear) {
            resetWeeklyStats(newWeekStart: currentWeekStart)
        }
    }

    func resetWeeklyStats(newWeekStart: Date) {
        guard let user = AccountManager.shared.user else { return }

        print("🔄 Resetting weekly stats for new week")

        // Update local user object
        user.weeklyReadingTimeSeconds = 0
        user.weeklyBooksReadUUIDs = []
        user.weekStartDate = newWeekStart
        // weeklyBooksReadCount is computed from weeklyBooksReadUUIDs.count

        // Sync to Firestore
        let data: [String: Any] = [
            FirebaseUserVariables.weeklyReadingTimeSeconds.rawValue: 0,
            FirebaseUserVariables.weeklyBooksReadUUIDs.rawValue: [String](),
            FirebaseUserVariables.weekStartDate.rawValue: newWeekStart
        ]

        AccountManager.shared.updateUserWithData(data) { success in
            if success {
                print("✅ Weekly stats reset successfully")
            }
        }
    }
}

// MARK: - Helper Extensions

extension SessionTrackingManager {
    static func todayReadingSeconds() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let storedSeconds = loadDailyReadingRecords()
            .first(where: { calendar.isDate($0.dayStart, inSameDayAs: today) })?
            .seconds ?? 0
        return storedSeconds + max(0, shared.currentUnpersistedSessionSeconds())
    }

    static func daysSinceLastReadingActivity() -> Int? {
        let records = loadDailyReadingRecords()
        guard let latestDay = records.map(\.dayStart).max() else { return nil }
        let today = Calendar.current.startOfDay(for: Date())
        return Calendar.current.dateComponents([.day], from: latestDay, to: today).day
    }

    /// Format seconds into human-readable time (e.g., "2h 15m")
    static func formatReadingTime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(hours)h"
            }
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }

    private static func loadDailyReadingRecords() -> [DailyReadingRecord] {
        guard let data = UserDefaults.standard.data(forKey: StorageKeys.dailyReadingRecords),
              let records = try? JSONDecoder().decode([DailyReadingRecord].self, from: data) else {
            return []
        }
        return records
    }

    private static func saveDailyReadingRecords(_ records: [DailyReadingRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: StorageKeys.dailyReadingRecords)
    }
}
