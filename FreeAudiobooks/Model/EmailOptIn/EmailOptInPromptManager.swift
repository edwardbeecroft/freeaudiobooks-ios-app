//
//  EmailOptInPromptManager.swift
//  FreeAudiobooks
//
//  Created by Claude on 29/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import FirebaseAuth

/// Manages the email opt-in prompt system including eligibility checks, trigger handling, and prompt presentation.
class EmailOptInPromptManager {

    // MARK: - Singleton

    static let shared = EmailOptInPromptManager()
    private init() {}

    // MARK: - Properties

    private let emailMarketingService = EmailMarketingService()

    // MARK: - Eligibility Check

    /// Quick check for permanent eligibility conditions (use before setting pending flags).
    /// Returns true if user could ever be eligible - doesn't check transient conditions like
    /// guardrails, cooldowns, or session state.
    var isEverEligible: Bool {
        // Must be authenticated with email
        guard
            AccountManager.shared.userIsLoggedInToFirebase(),
            let user = AccountManager.shared.user,
            !user.emailAddress.isEmpty else {
            return false
        }

        // Already subscribed to marketing (from Brevo check)
        if user.marketingPermission {
            return false
        }

        // Permanently suppressed (opted in or dismissed twice)
        if EmailOptInUserDefaults.isPermanentlySuppressed {
            return false
        }

        return true
    }

    /// Checks if the email opt-in prompt can be shown
    private func canShowPrompt() -> (eligible: Bool, reason: EmailOptInSuppressionReason?) {
        // Already shown this session (first-eligible-trigger-wins)
        if EmailOptInUserDefaults.hasShownThisSession {
            return (false, .shownThisSession)
        }

        // User is authenticated with email
        guard AccountManager.shared.userIsLoggedInToFirebase(),
              let user = AccountManager.shared.user,
              !user.emailAddress.isEmpty else {
            return (false, .notAuthenticated)
        }

        // Already subscribed to marketing (from Brevo check)
        if user.marketingPermission {
            return (false, .alreadySubscribed)
        }

        // NOT permanently suppressed (opted in OR dismissed twice)
        if EmailOptInUserDefaults.isPermanentlySuppressed {
            return (false, .permanentlySuppressed)
        }

        // NOT in 30-day cooldown
        if !EmailOptInUserDefaults.canShowPrompt {
            return (false, .inCooldown)
        }

        // Guardrail: NOT within 2 minutes of push prompt (same session)
        if EmailOptInUserDefaults.isWithinPushGuardrail {
            return (false, .recentPushPrompt)
        }

        // Guardrail: NOT within 2 minutes of SKReview request
        if EmailOptInUserDefaults.isWithinSKReviewGuardrail {
            return (false, .recentSKReview)
        }

        return (true, nil)
    }

    // MARK: - Trigger Handlers

    /// Handles a trigger event, checking eligibility and presenting prompt if eligible
    /// - Parameters:
    ///   - trigger: The trigger that initiated this check
    ///   - genre: Genre for personalization
    ///   - viewController: The view controller to present from
    ///   - completion: Called with `true` if prompt was shown, `false` otherwise
    func handleTrigger(
        _ trigger: EmailOptInTrigger,
        genre: BookInternalGenre,
        from viewController: UIViewController,
        completion: ((Bool) -> Void)? = nil
    ) {
        print("[EmailOptIn] Trigger fired: \(trigger.rawValue), genre: \(genre.rawValue)")

        let (isEligible, suppressionReason) = canShowPrompt()

        if let reason = suppressionReason {
            print("[EmailOptIn] Suppressed: \(reason.rawValue)")
            printDebugState()
            AnalyticsManager.shared.trackEmailOptInPromptSuppressed(reason: reason)
            completion?(false)
            return
        }

        guard isEligible else {
            print("[EmailOptIn] Not eligible (no specific reason)")
            completion?(false)
            return
        }

        print("[EmailOptIn] Showing prompt")
        DispatchQueue.main.async { [weak self] in
            self?.presentPrompt(trigger: trigger, genre: genre, from: viewController)
            completion?(true)
        }
    }

    private func printDebugState() {
        print("[EmailOptIn] Debug state:")
        print("  - hasShownThisSession: \(EmailOptInUserDefaults.hasShownThisSession)")
        print("  - isPermanentlySuppressed: \(EmailOptInUserDefaults.isPermanentlySuppressed)")
        print("  - dismissCount: \(EmailOptInUserDefaults.dismissCount)")
        print("  - canShowPrompt (cooldown): \(EmailOptInUserDefaults.canShowPrompt)")
        print("  - isWithinPushGuardrail: \(EmailOptInUserDefaults.isWithinPushGuardrail)")
        print("  - isWithinSKReviewGuardrail: \(EmailOptInUserDefaults.isWithinSKReviewGuardrail)")
    }

    // MARK: - Present Prompt

    private func presentPrompt(
        trigger: EmailOptInTrigger,
        genre: BookInternalGenre,
        from viewController: UIViewController
    ) {
        // Mark as shown this session
        EmailOptInUserDefaults.hasShownThisSession = true

        let dismissCount = EmailOptInUserDefaults.dismissCount

        // Track prompt shown
        AnalyticsManager.shared.trackEmailOptInPromptShown(
            trigger: trigger,
            genre: genre,
            dismissCount: dismissCount
        )

        // Create and present the bottom sheet
        let isSubscriber = AccountManager.shared.userIsSubscribed
        let promptVC = EmailOptInPromptVC(
            trigger: trigger,
            genre: genre,
            isSubscriber: isSubscriber
        )

        promptVC.optInHandler = { [weak self, weak viewController] in
            viewController?.dismiss(animated: true) {
                self?.handleOptIn(trigger: trigger, genre: genre, dismissCount: dismissCount)
            }
        }

        promptVC.dismissHandler = { [weak self, weak viewController] in
            viewController?.dismiss(animated: true) {
                self?.handleNotNow(trigger: trigger, genre: genre, dismissCount: dismissCount)
            }
        }

        viewController.present(promptVC, animated: true)
    }

    // MARK: - Action Handlers

    private func handleOptIn(
        trigger: EmailOptInTrigger,
        genre: BookInternalGenre,
        dismissCount: Int
    ) {
        // Track analytics
        AnalyticsManager.shared.trackEmailOptInOptedIn(
            trigger: trigger,
            genre: genre,
            dismissCount: dismissCount
        )

        // Subscribe user via EmailMarketingService with segmentation data
        emailMarketingService.subscribeUser(
            trigger: trigger,
            genre: genre
        ) { [weak self] success in
            if success {
                // Mark as opted in locally
                EmailOptInUserDefaults.recordOptIn()

                // Update Firebase user variables
                self?.updateFirebaseMarketingConsent(permission: true, trigger: trigger)
            }
        }
    }

    private func handleNotNow(
        trigger: EmailOptInTrigger,
        genre: BookInternalGenre,
        dismissCount: Int
    ) {
        // Track analytics
        AnalyticsManager.shared.trackEmailOptInPromptNotNow(
            trigger: trigger,
            genre: genre,
            dismissCount: dismissCount
        )

        // Record dismissal (handles cooldown and permanent suppression)
        EmailOptInUserDefaults.recordDismissal()
    }

    private func updateFirebaseMarketingConsent(permission: Bool, trigger: EmailOptInTrigger) {
        let date = Date()
        let data: [String: Any] = [
            FirebaseUserVariables.marketingPromptAnswered.rawValue: true,
            FirebaseUserVariables.marketingPermission.rawValue: permission,
            FirebaseUserVariables.marketingConsentAmendedDate.rawValue: date
        ]
        AccountManager.shared.updateUserWithData(data, completion: nil)
        AccountManager.shared.setMarketingPermission(permission, amendedDate: date)
    }
}
