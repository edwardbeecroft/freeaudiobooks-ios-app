//
//  EmailOptInUserDefaults.swift
//  FreeAudiobooks
//
//  Created by Claude on 29/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation

/// Manages state persistence for email opt-in prompts.
///
/// Schedule:
/// - 0 dismissals → show immediately (if eligible)
/// - 1 dismissal  → wait 30 days
/// - 2 dismissals → never show again
///
/// Guardrails (2-minute anti-stacking):
/// - Don't show within 2 minutes of push prompt
/// - Don't show within 2 minutes of SKReview request
struct EmailOptInUserDefaults {

    // MARK: - Keys

    private static let dismissCountKey = "emailOptInDismissCount"
    private static let lastDismissedAtKey = "emailOptInLastDismissedAt"
    private static let permanentlySuppressedKey = "emailOptInPermanentlySuppressed"
    private static let bookDetailViewsKey = "emailOptInBookDetailViews"
    private static let hasFiredDetailViewTriggerKey = "emailOptInHasFiredDetailViewTrigger"
    private static let lastSKReviewRequestKey = "emailOptInLastSKReviewRequest"
    private static let pendingBookCompletedKey = "emailOptInPendingBookCompleted"
    private static let pendingBookCompletedGenreKey = "emailOptInPendingBookCompletedGenre"
    private static let pendingBookCompletedSetAtKey = "emailOptInPendingBookCompletedSetAt"

    // MARK: - Constants

    private static let cooldownDays = 30
    private static let maxDismissals = 2
    private static let guardrailMinutes = 2  // Both push and SKReview use same window
    private static let bookDetailViewThreshold = 5
    private static let bookDetailViewWindowDays = 7
    private static let pendingExpiryDays = 7  // Pending book completion expires after 7 days
    private static let bookDetailViewDedupeMinutes = 30
    private static let bookDetailViewMaxEntries = 100  // Cap storage for heavy browsers

    // MARK: - Session State (in-memory, resets on app launch)

    private static var _hasShownThisSession: Bool = false
    static var hasShownThisSession: Bool {
        get { _hasShownThisSession }
        set { _hasShownThisSession = newValue }
    }

    private static var _lastPushPromptThisSession: Date? = nil
    static var lastPushPromptThisSession: Date? {
        get { _lastPushPromptThisSession }
        set { _lastPushPromptThisSession = newValue }
    }

    // MARK: - Pending Book Completion (persisted to survive app termination)

    /// Set when book completes - show email opt-in at next safe moment (DiscoverVC)
    /// Automatically expires after 7 days to avoid showing stale completion prompts
    static var hasPendingBookCompletedTrigger: Bool {
        get {
            guard UserDefaults.standard.bool(forKey: pendingBookCompletedKey) else { return false }
            // Check if pending state has expired
            if let setAt = pendingBookCompletedSetAt,
               let expiryDate = Calendar.current.date(byAdding: .day, value: pendingExpiryDays, to: setAt),
               Date() > expiryDate {
                // Expired - clear the pending state
                clearPendingBookCompleted()
                return false
            }
            return true
        }
        set {
            if newValue {
                UserDefaults.standard.set(true, forKey: pendingBookCompletedKey)
                pendingBookCompletedSetAt = Date()
            } else {
                clearPendingBookCompleted()
            }
        }
    }

    /// Genre of the completed book (for personalized prompt copy)
    static var pendingBookCompletedGenre: BookInternalGenre? {
        get {
            guard let raw = UserDefaults.standard.string(forKey: pendingBookCompletedGenreKey) else { return nil }
            return BookInternalGenre(rawValue: raw)
        }
        set { UserDefaults.standard.set(newValue?.rawValue, forKey: pendingBookCompletedGenreKey) }
    }

    /// When the pending state was set (for expiry calculation)
    private static var pendingBookCompletedSetAt: Date? {
        get { UserDefaults.standard.object(forKey: pendingBookCompletedSetAtKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: pendingBookCompletedSetAtKey) }
    }

    /// Clears all pending book completion state
    static func clearPendingBookCompleted() {
        UserDefaults.standard.set(false, forKey: pendingBookCompletedKey)
        UserDefaults.standard.removeObject(forKey: pendingBookCompletedGenreKey)
        UserDefaults.standard.removeObject(forKey: pendingBookCompletedSetAtKey)
    }

    // MARK: - Dismiss Count

    static var dismissCount: Int {
        get { UserDefaults.standard.integer(forKey: dismissCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: dismissCountKey) }
    }

    // MARK: - Last Dismissed At

    static var lastDismissedAt: Date? {
        get { UserDefaults.standard.object(forKey: lastDismissedAtKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastDismissedAtKey) }
    }

    // MARK: - Permanent Suppression

    static var isPermanentlySuppressed: Bool {
        get { UserDefaults.standard.bool(forKey: permanentlySuppressedKey) }
        set { UserDefaults.standard.set(newValue, forKey: permanentlySuppressedKey) }
    }

    // MARK: - Guardrails

    /// Returns true if push prompt was shown within the last 2 minutes this session
    static var isWithinPushGuardrail: Bool {
        guard let lastPush = lastPushPromptThisSession else { return false }
        let minutesSince = Date().timeIntervalSince(lastPush) / 60
        return minutesSince < Double(guardrailMinutes)
    }

    /// Records when push prompt was shown (call this from push prompt presentation)
    static func recordPushPromptShown() {
        lastPushPromptThisSession = Date()
    }

    /// Last SKReview request date (persisted, but only matters for 2 minutes)
    static var lastSKReviewRequest: Date? {
        get { UserDefaults.standard.object(forKey: lastSKReviewRequestKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastSKReviewRequestKey) }
    }

    /// Returns true if SKReview was requested within the last 2 minutes
    static var isWithinSKReviewGuardrail: Bool {
        guard let lastReview = lastSKReviewRequest else { return false }
        let minutesSince = Date().timeIntervalSince(lastReview) / 60
        return minutesSince < Double(guardrailMinutes)
    }

    /// Records when SKReview was requested (call this from SKReviewManager)
    static func recordSKReviewRequest() {
        lastSKReviewRequest = Date()
    }

    // MARK: - Book Detail View Tracking

    /// Dictionary mapping bookUUID to lastViewedDate
    private static var bookDetailViews: [String: Date] {
        get {
            guard let data = UserDefaults.standard.data(forKey: bookDetailViewsKey),
                  let dict = try? JSONDecoder().decode([String: Date].self, from: data) else {
                return [:]
            }
            return dict
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: bookDetailViewsKey)
            }
        }
    }

    /// Records a book detail view with 30-minute deduplication per book
    static func recordBookDetailView(bookUUID: String) {
        var views = bookDetailViews

        // Check if this book was viewed recently (within dedupe window)
        if let lastViewed = views[bookUUID] {
            let minutesSince = Date().timeIntervalSince(lastViewed) / 60
            if minutesSince < Double(bookDetailViewDedupeMinutes) {
                return
            }
        }

        views[bookUUID] = Date()

        // Prune entries older than the window
        let windowStart = Calendar.current.date(byAdding: .day, value: -bookDetailViewWindowDays, to: Date()) ?? Date()
        views = views.filter { $0.value > windowStart }

        // Cap max entries for heavy browsers (keep most recent)
        if views.count > bookDetailViewMaxEntries {
            let sorted = views.sorted { $0.value > $1.value }
            let trimmed = sorted.prefix(bookDetailViewMaxEntries).map { ($0.key, $0.value) }
            views = Dictionary(uniqueKeysWithValues: trimmed)
        }

        bookDetailViews = views
    }

    /// Count of distinct books viewed within the rolling 7-day window
    static var distinctBookViewCountInWindow: Int {
        let windowStart = Calendar.current.date(byAdding: .day, value: -bookDetailViewWindowDays, to: Date()) ?? Date()
        return bookDetailViews.filter { $0.value > windowStart }.count
    }

    // MARK: - Detail View Trigger

    /// Last time the detail view trigger was fired (shown to user)
    static var lastDetailViewTriggerAt: Date? {
        get { UserDefaults.standard.object(forKey: hasFiredDetailViewTriggerKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: hasFiredDetailViewTriggerKey) }
    }

    /// Check if threshold is reached AND trigger hasn't been fired recently
    /// Allows re-firing after 30-day cooldown expires
    static var hasReachedBookDetailViewThreshold: Bool {
        guard distinctBookViewCountInWindow >= bookDetailViewThreshold else { return false }

        // Never fired before = can fire
        guard let lastFired = lastDetailViewTriggerAt else { return true }

        // Allow re-firing after cooldown period (30 days)
        guard let eligibleDate = Calendar.current.date(byAdding: .day, value: cooldownDays, to: lastFired) else {
            return false
        }
        return Date() >= eligibleDate
    }

    static func markDetailViewTriggerFired() {
        lastDetailViewTriggerAt = Date()
    }

    // MARK: - Cooldown Logic

    static var canShowPrompt: Bool {
        // Permanently suppressed = never show
        if isPermanentlySuppressed {
            return false
        }

        let currentDismissCount = dismissCount

        // Never dismissed = can show
        if currentDismissCount == 0 {
            return true
        }

        // Max dismissals reached = never show
        if currentDismissCount >= maxDismissals {
            return false
        }

        // Check 30-day cooldown
        guard let lastDismissed = lastDismissedAt,
              let eligibleDate = Calendar.current.date(byAdding: .day, value: cooldownDays, to: lastDismissed) else {
            return false
        }

        return Date() >= eligibleDate
    }

    // MARK: - Public Methods

    /// Records a dismissal (user tapped "Not now" or swiped to dismiss)
    static func recordDismissal() {
        dismissCount += 1
        lastDismissedAt = Date()

        if dismissCount >= maxDismissals {
            isPermanentlySuppressed = true
        }
    }

    /// Records an opt-in (user subscribed) - suppresses future prompts
    static func recordOptIn() {
        isPermanentlySuppressed = true
    }

    /// Resets all state (for testing/debugging)
    static func reset() {
        UserDefaults.standard.removeObject(forKey: dismissCountKey)
        UserDefaults.standard.removeObject(forKey: lastDismissedAtKey)
        UserDefaults.standard.removeObject(forKey: permanentlySuppressedKey)
        UserDefaults.standard.removeObject(forKey: bookDetailViewsKey)
        UserDefaults.standard.removeObject(forKey: hasFiredDetailViewTriggerKey)
        UserDefaults.standard.removeObject(forKey: lastSKReviewRequestKey)
        UserDefaults.standard.removeObject(forKey: pendingBookCompletedKey)
        UserDefaults.standard.removeObject(forKey: pendingBookCompletedGenreKey)
        UserDefaults.standard.removeObject(forKey: pendingBookCompletedSetAtKey)
        _hasShownThisSession = false
        _lastPushPromptThisSession = nil
    }
}
