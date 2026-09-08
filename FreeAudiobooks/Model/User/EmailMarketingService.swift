import Foundation
import FirebaseAuth
import FirebaseFirestore
import StoreKit

/// Saves preferences with Firestore's built-in offline persistence. The server owns sending.
final class EmailMarketingService {
    static let appID = "freeaudiobooks"

    /// setData(merge: true) merges nested maps, preserving the other app's fields.
    static func profileData(_ values: [String: Any]) -> [String: Any] {
        ["apps": [appID: values]]
    }

    static func profile(from userData: [String: Any]) -> [String: Any] {
        (userData["apps"] as? [String: [String: Any]])?[appID] ?? [:]
    }

    /// A real new registration or another recorded app onboarding identifies a new app join.
    /// Missing fields alone on a legacy account do not.
    static func isFirstAppOnboarding(in userData: [String: Any]) -> Bool {
        let current = profile(from: userData)
        guard current["emailOnboardingCompletedAt"] == nil else { return false }
        let apps = userData["apps"] as? [String: [String: Any]] ?? [:]
        return current["marketingPromptAnswered"] as? Bool == false ||
            apps.values.contains { $0["emailOnboardingCompletedAt"] is Timestamp }
    }

    static func updateProfile(_ values: [String: Any], completion: ((Bool) -> Void)? = nil) {
        AccountManager.shared.updateUserWithData(profileData(values), completion: completion)
    }

    static var storefrontCountryCode: String {
        let defaults = UserDefaults.standard
        if AppConstants.shared.developmentMode != .production,
           let override = defaults.string(forKey: "emailLifecycle.debugStorefront") { return override }
        guard let fetched = defaults.object(forKey: "emailLifecycle.storefrontFetchedAt") as? Date,
              Date().timeIntervalSince(fetched) < 86400 else { return "" }
        return defaults.string(forKey: "emailLifecycle.storefront") ?? ""
    }

    static func prefetchStorefront(syncProfile: Bool = false) {
        let uid = Auth.auth().currentUser?.uid
        Task { @MainActor in
            if let storefront = await StoreKit.Storefront.current {
                UserDefaults.standard.set(storefront.countryCode, forKey: "emailLifecycle.storefront")
                UserDefaults.standard.set(Date(), forKey: "emailLifecycle.storefrontFetchedAt")
            }
            if syncProfile, let uid, Auth.auth().currentUser?.uid == uid {
                let profile = deviceProfile()
                let snapshotKey = "emailLifecycle.deviceProfile.\(appID).\(uid)"
                if let snapshot = UserDefaults.standard.dictionary(forKey: snapshotKey),
                   NSDictionary(dictionary: profile).isEqual(to: snapshot) { return }
                updateProfile(profile) { success in
                    // Pending offline writes and failures must remain eligible for retry.
                    if success, Auth.auth().currentUser?.uid == uid {
                        UserDefaults.standard.set(profile, forKey: snapshotKey)
                    }
                }
            }
        }
    }

    static func deviceProfile() -> [String: Any] {
        let data: [String: Any] = [
            "storefrontCountryCode": storefrontCountryCode,
            "timeZoneIdentifier": TimeZone.current.identifier,
            "platform": "ios",
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        ]
        return data
    }

    static func shouldAutoEnrol(country: String, email: String, isFirstAppOnboarding: Bool,
                               isEmailSubscribed: Bool, previouslyAnswered: Bool,
                               isEmailUnsubscribed: Bool, dismissed: Bool) -> Bool {
        country == "USA" && !email.isEmpty && isFirstAppOnboarding && !isEmailSubscribed &&
            !previouslyAnswered && !isEmailUnsubscribed && !dismissed
    }

    func getSubscriptionStatus(completion: @escaping (Bool?) -> Void) {
        completion(AccountManager.shared.user?.marketingPermission)
    }

    func subscribeUser(trigger: EmailOptInTrigger, genre: BookInternalGenre, completion: @escaping (Bool) -> Void) {
        setPreference(subscribed: true, source: trigger.rawValue, completion: completion)
    }

    func unsubscribeUser(completion: @escaping (Bool) -> Void) {
        setPreference(subscribed: false, source: "app_settings", completion: completion)
    }

    func recordDismissal() {
        guard let user = AccountManager.shared.user else { return }
        user.marketingPromptDismissedAt = Date()
        Self.updateProfile([
            "marketingPromptDismissedAt": FieldValue.serverTimestamp()
        ], completion: nil)
    }

    func setPreference(subscribed: Bool, source: String, completion: ((Bool) -> Void)? = nil) {
        guard let uid = Auth.auth().currentUser?.uid, let user = AccountManager.shared.user else {
            completion?(false); return
        }
        let previous = (user.marketingPermission, user.marketingPromptAnswered, user.marketingConsentAmendedDate, user.marketingUnsubscribedAt)
        user.marketingPermission = subscribed
        user.marketingPromptAnswered = true
        let now = Date()
        user.marketingConsentAmendedDate = now
        if !subscribed { user.marketingUnsubscribedAt = now }
        var data: [String: Any] = [
            "marketingPermission": subscribed, "marketingPromptAnswered": true,
            "marketingConsentSource": source, "marketingCountryCode": Self.storefrontCountryCode,
            "marketingConsentVersion": "onboarding_v1",
            "marketingConsentAmendedDate": FieldValue.serverTimestamp()
        ]
        if !subscribed {
            data["marketingUnsubscribedAt"] = FieldValue.serverTimestamp()
            data["marketingUnsubscribeSource"] = source
        }
        // Completion means acknowledged by Firestore; the UI need not wait to continue.
        Self.updateProfile(data) { success in
            guard Auth.auth().currentUser?.uid == uid else { return }
            if !success, user.marketingConsentAmendedDate == now {
                user.marketingPermission = previous.0
                user.marketingPromptAnswered = previous.1
                user.marketingConsentAmendedDate = previous.2
                user.marketingUnsubscribedAt = previous.3
            }
            completion?(success)
        }
    }
}
