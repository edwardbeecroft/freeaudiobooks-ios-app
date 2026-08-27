import Foundation

/// Manages exponential backoff for push notification pre-prompt.
///
/// Schedule:
/// - 0 dismissals → show immediately
/// - 1 dismissal  → wait 14 days
/// - 2 dismissals → wait 28 days
/// - 3 dismissals → wait 90 days
/// - 4+ dismissals → never show again
struct PushPrePromptUserDefaults {
    private static let dismissCountKey = "pushPrePromptDismissCount"
    private static let lastDismissedAtKey = "pushPrePromptLastDismissedAt"

    /// Backoff days: index 0 = after 1st dismiss, index 1 = after 2nd, etc.
    private static let backoffDays = [14, 28, 90]
    private static let maxDismissals = 4

    static var canShowPrompt: Bool {
        let dismissCount = UserDefaults.standard.integer(forKey: dismissCountKey)

        // Never shown before = show immediately
        if dismissCount == 0 {
            return true
        }

        // Max dismissals reached = never ask again
        if dismissCount >= maxDismissals {
            return false
        }

        // Must have a last dismissed date if dismissCount > 0
        guard let lastDismissed = UserDefaults.standard.object(forKey: lastDismissedAtKey) as? Date else {
            // Data inconsistency - dismissCount > 0 but no date. Don't show.
            return false
        }

        // Calculate days to wait based on dismiss count
        let backoffIndex = min(dismissCount - 1, backoffDays.count - 1)
        let daysToWait = backoffDays[backoffIndex]

        guard let eligibleDate = Calendar.current.date(byAdding: .day, value: daysToWait, to: lastDismissed) else {
            return false
        }

        return Date() >= eligibleDate
    }

    static func recordDismissal() {
        let currentCount = UserDefaults.standard.integer(forKey: dismissCountKey)
        UserDefaults.standard.set(currentCount + 1, forKey: dismissCountKey)
        UserDefaults.standard.set(Date(), forKey: lastDismissedAtKey)
    }

    /// For testing/debugging
    static func reset() {
        UserDefaults.standard.removeObject(forKey: dismissCountKey)
        UserDefaults.standard.removeObject(forKey: lastDismissedAtKey)
    }

    /// Current dismiss count (for analytics if needed)
    static var dismissCount: Int {
        UserDefaults.standard.integer(forKey: dismissCountKey)
    }
}
