//
//  NewOnboardingCoordinator.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import SuperwallKit

// MARK: - Delegate Protocol

protocol NewOnboardingCoordinatorDelegate: AnyObject {
    /// Called when onboarding flow completes (user reached the end)
    func didCompleteNewOnboarding(didSubscribe: Bool)

    /// Called when user exits onboarding early (e.g., skip)
    func didExitNewOnboarding()
}

// MARK: - Coordinator

class NewOnboardingCoordinator {

    // MARK: - Singleton

    static let shared = NewOnboardingCoordinator()

    // MARK: - Properties

    weak var delegate: NewOnboardingCoordinatorDelegate?
    private(set) var containerVC: NewOnboardingContainerVC?
    private var steps: [NewOnboardingStep] = []
    private(set) var currentIndex: Int = 0

    /// Stores user selections throughout the flow
    let dataStore = NewOnboardingDataStore()

    // MARK: - Initialization

    private init() {}

    // MARK: - Reset

    /// Resets all onboarding state (both in-memory dataStore and persisted UserDefaults)
    /// Call this on sign-out to ensure a fresh start for the next user
    func reset() {
        dataStore.reset()
        NewOnboardingUserDefaults.clearAll()
        currentIndex = 0
    }

    // MARK: - Setup

    /// Configures the coordinator before starting
    /// - Parameters:
    ///   - delegate: Receives completion callbacks
    ///   - variant: Optional variant override (defaults to RemoteConfig value)
    func set(delegate: NewOnboardingCoordinatorDelegate,
             variant: OnboardingVariant? = nil) {
        self.delegate = delegate

        let activeVariant = variant ?? OnboardingVariant.current
        self.steps = activeVariant.steps

        // Remove paywall step if user is already subscribed (e.g. from a previous onboarding attempt)
        if Superwall.shared.subscriptionStatus.isActive {
            self.steps.removeAll(where: { $0 == .paywall })
        }

        // Reset dataStore before restoring to clear any stale in-memory values
        dataStore.reset()
        dataStore.variant = activeVariant

        // Restore dataStore from UserDefaults
        restoreDataStoreFromUserDefaults()

        // Find the first incomplete step based on dataStore
        self.currentIndex = findFirstIncompleteStepIndex()
    }

    /// Finds the first step that hasn't been completed based on dataStore
    /// Returns 0 if all steps are complete (shouldn't happen normally)
    private func findFirstIncompleteStepIndex() -> Int {
        for (index, step) in steps.enumerated() {
            if !step.isComplete(dataStore: dataStore) {
                return index
            }
        }
        // All steps complete - start from beginning (edge case)
        return 0
    }

    // MARK: - Flow Control

    /// Creates and returns the container VC to present
    func createContainerVC() -> NewOnboardingContainerVC {
        let container = NewOnboardingContainerVC(coordinator: self)
        self.containerVC = container
        return container
    }

    /// Starts the onboarding flow from the current step
    func start() {
        guard !steps.isEmpty else {
            delegate?.didCompleteNewOnboarding(didSubscribe: false)
            return
        }

        // Set Superwall attributes early so has_completed_onboarding is explicitly false
        AccountManager.shared.updateSuperwallUserAttributes()

        AnalyticsManager.shared.trackNewOnboardingStarted(variant: dataStore.variant.rawValue)

        // Show the current step (may be restored from persistence)
        let step = steps[currentIndex]
        containerVC?.transitionToStep(step, direction: OnboardingTransitionDirection.none)
    }

    /// Advances to the next screen in the flow
    func goToNextScreen() {
        // Mark stat screens as viewed when advancing from them
        let currentStep = steps[currentIndex]
        if currentStep == .buildsHabitsLineChart {
            dataStore.didViewBuildsHabitsLineChart = true
        } else if currentStep == .readingBarrierResolution {
            dataStore.didViewReadingBarrierResolution = true
        }

        // Save current data before advancing (enables crash recovery/resume)
        dataStore.saveToUserDefaults()

        if currentIndex < steps.count - 1 {
            currentIndex += 1
            let step = steps[currentIndex]

            // Skip saveProgressAuth if user already authenticated (e.g. via SignInBottomSheetVC)
            if step == .saveProgressAuth && dataStore.authMethod != nil {
                goToNextScreen()
                return
            }

            containerVC?.transitionToStep(step, direction: OnboardingTransitionDirection.forward)
        } else {
            completeOnboarding()
        }
    }

    /// Goes back to the previous screen
    func goToPreviousScreen() {
        guard currentIndex > 0 else { return }

        currentIndex -= 1
        let step = steps[currentIndex]
        containerVC?.transitionToStep(step, direction: OnboardingTransitionDirection.backward)
    }

    /// Whether the user can go back (not on first step)
    var canGoBack: Bool {
        return currentIndex > 0
    }

    // MARK: - Progress

    /// Current progress as a float from 0.0 to 1.0
    var currentProgress: Float {
        let progressSteps = steps.filter { $0.includesInProgressBar }
        let currentStep = steps[currentIndex]

        guard let currentProgressIndex = progressSteps.firstIndex(of: currentStep) else {
            // Current step doesn't contribute to progress bar
            // Find the last progress step before current
            for i in stride(from: currentIndex - 1, through: 0, by: -1) {
                if let idx = progressSteps.firstIndex(of: steps[i]) {
                    return Float(idx + 1) / Float(progressSteps.count)
                }
            }
            return 0
        }

        return Float(currentProgressIndex + 1) / Float(progressSteps.count)
    }

    /// Total number of steps that show in progress bar
    var totalProgressSteps: Int {
        return steps.filter { $0.includesInProgressBar }.count
    }

    /// Current step index among progress-contributing steps
    var currentProgressStepIndex: Int {
        let progressSteps = steps.filter { $0.includesInProgressBar }
        let currentStep = steps[currentIndex]
        return progressSteps.firstIndex(of: currentStep) ?? 0
    }

    // MARK: - Private Methods

    /// Completes the onboarding flow: saves data, syncs to Firestore, updates Superwall,
    /// shows email opt-in if eligible, and notifies delegate.
    /// Called automatically by goToNextScreen() when the user finishes the final step.
    private func completeOnboarding() {
        // Mark that onboarding completed this session (for first-launch optimizations)
        NewOnboardingUserDefaults.markOnboardingCompletedThisSession()

        // Clear step persistence - onboarding is complete
        NewOnboardingUserDefaults.clearCurrentStepIndex()

        // Mark onboarding as completed and save final data
        NewOnboardingUserDefaults.markOnboardingCompleted()
        dataStore.saveToUserDefaults()

        // Sync onboarding data to Firestore for authenticated users
        if AccountManager.shared.userIsLoggedInToFirebase() {
            syncOnboardingDataToFirestore()
        }

        // Update Superwall attributes so paywalls know onboarding is complete
        AccountManager.shared.updateSuperwallUserAttributes()

        AnalyticsManager.shared.trackNewOnboardingCompleted(
            variant: dataStore.variant.rawValue,
            didSubscribe: dataStore.didSubscribe,
            paywallName: dataStore.superwallPaywallName,
            paywallIdentifier: dataStore.superwallPaywallIdentifier,
            experimentId: dataStore.superwallExperimentId,
            variantId: dataStore.superwallVariantId,
            variantType: dataStore.superwallVariantType
        )

        // Show email opt-in epilogue if eligible, then notify delegate
        showEmailOptInIfNeeded { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.delegate?.didCompleteNewOnboarding(didSubscribe: self.dataStore.didSubscribe)
            }
        }
    }

    // MARK: - Email Marketing Opt-In

    /// Presents the email marketing opt-in bottom sheet at the end of the onboarding journey, if the user is eligible.
    /// User is already authenticated at this point, so Brevo subscription can happen immediately.
    private func showEmailOptInIfNeeded(completion: @escaping () -> Void) {
        // Must be authenticated with an email address
        guard AccountManager.shared.userIsLoggedInToFirebase(),
              let user = AccountManager.shared.user,
              !user.emailAddress.isEmpty,
              // Not already subscribed to marketing
              !user.marketingPermission,
              // Respects 30-day cooldown + max dismissals + permanent suppression
              EmailOptInUserDefaults.canShowPrompt
        else {
            completion()
            return
        }

        guard let containerVC = containerVC else {
            completion()
            return
        }

        guard let genre = dataStore.selectedGenres.first else {
            completion()
            return
        }
        let isSubscriber = dataStore.didSubscribe

        // Track prompt shown
        AnalyticsManager.shared.trackEmailOptInPromptShown(
            trigger: .newOnboarding,
            genre: genre,
            dismissCount: EmailOptInUserDefaults.dismissCount
        )

        let promptVC = EmailOptInPromptVC(
            trigger: .newOnboarding,
            genre: genre,
            isSubscriber: isSubscriber
        )

        promptVC.optInHandler = { [weak self, weak containerVC] in
            containerVC?.dismiss(animated: true) {
                self?.handleEmailOptIn(genre: genre)
                completion()
            }
        }

        promptVC.dismissHandler = { [weak self, weak containerVC] in
            containerVC?.dismiss(animated: true) {
                self?.handleEmailNotNow(genre: genre)
                completion()
            }
        }

        // Prevent other triggers from showing the prompt again this session
        EmailOptInUserDefaults.hasShownThisSession = true

        containerVC.present(promptVC, animated: true)
    }

    private func handleEmailOptIn(genre: BookInternalGenre) {
        AnalyticsManager.shared.trackEmailOptInOptedIn(
            trigger: .newOnboarding,
            genre: genre,
            dismissCount: EmailOptInUserDefaults.dismissCount
        )

        // Subscribe to Brevo
        EmailMarketingService().subscribeUser(trigger: .newOnboarding, genre: genre) { success in
            if success {
                EmailOptInUserDefaults.recordOptIn()
            }
        }

        // Update Firestore marketing consent
        let date = Date()
        let data: [String: Any] = [
            FirebaseUserVariables.marketingPromptAnswered.rawValue: true,
            FirebaseUserVariables.marketingPermission.rawValue: true,
            FirebaseUserVariables.marketingConsentAmendedDate.rawValue: date
        ]
        AccountManager.shared.updateUserWithData(data, completion: nil)
        AccountManager.shared.setMarketingPermission(true, amendedDate: date)
    }

    private func handleEmailNotNow(genre: BookInternalGenre) {
        AnalyticsManager.shared.trackEmailOptInPromptNotNow(
            trigger: .newOnboarding,
            genre: genre,
            dismissCount: EmailOptInUserDefaults.dismissCount
        )

        // Record dismissal — uses existing escalation logic:
        //   dismiss 1 → 30-day cooldown (bookSaved/accountSettings triggers can re-ask later)
        //   dismiss 2 → permanent suppression
        // Does NOT write consent fields — "Not now" ≠ explicit opt-out
        EmailOptInUserDefaults.recordDismissal()
    }

    // MARK: - Firestore Sync

    /// Syncs onboarding data to the user's Firestore document
    /// Called at completion to ensure data persists for users who authenticated early
    private func syncOnboardingDataToFirestore() {
        print("[Onboarding] Syncing onboarding data to Firestore")

        var data: [String: Any] = [:]

        if !dataStore.selectedGenres.isEmpty {
            data[FirebaseUserVariables.favoriteGenres.rawValue] = dataStore.selectedGenres.map { $0.rawValue }
        }
        if let frequency = dataStore.readingFrequency {
            data[FirebaseUserVariables.readingFrequency.rawValue] = frequency
        }
        if !dataStore.listeningOccasions.isEmpty {
            data[FirebaseUserVariables.listeningOccasions.rawValue] = dataStore.listeningOccasions
        }
        if let source = dataStore.howDidYouHear {
            data[FirebaseUserVariables.howDidYouHear.rawValue] = source
        }
        if !dataStore.previousApps.isEmpty {
            data[FirebaseUserVariables.previousApps.rawValue] = dataStore.previousApps
        }
        if !dataStore.listeningReasons.isEmpty {
            data[FirebaseUserVariables.listeningReasons.rawValue] = dataStore.listeningReasons
        }
        if !dataStore.readingBarriers.isEmpty {
            data[FirebaseUserVariables.readingBarriers.rawValue] = dataStore.readingBarriers
        }
        if let goal = dataStore.dailyListeningGoal {
            data[FirebaseUserVariables.dailyListeningGoal.rawValue] = goal
        }

        guard !data.isEmpty else { return }
        AccountManager.shared.updateUserWithData(data, completion: nil)
    }

    /// Restores dataStore from UserDefaults when resuming
    private func restoreDataStoreFromUserDefaults() {
        if let genres = NewOnboardingUserDefaults.getSelectedGenres() {
            dataStore.selectedGenres = genres
        }
        if let frequency = NewOnboardingUserDefaults.getReadingFrequency() {
            dataStore.readingFrequency = frequency
        }
        if let occasions = NewOnboardingUserDefaults.getListeningOccasions() {
            dataStore.listeningOccasions = occasions
        }
        if let source = NewOnboardingUserDefaults.getHowDidYouHear() {
            dataStore.howDidYouHear = source
        }
        if let apps = NewOnboardingUserDefaults.getPreviousApps() {
            dataStore.previousApps = apps
        }
        if let reasons = NewOnboardingUserDefaults.getListeningReasons() {
            dataStore.listeningReasons = reasons
        }
        if let barriers = NewOnboardingUserDefaults.getReadingBarriers() {
            dataStore.readingBarriers = barriers
        }
        if let goal = NewOnboardingUserDefaults.getDailyListeningGoal() {
            dataStore.dailyListeningGoal = goal
        }
        if let reminderTimeString = NewOnboardingUserDefaults.getSelectedReminderTime(),
           let reminderTime = ReminderTime(rawValue: reminderTimeString) {
            dataStore.selectedReminderTime = reminderTime
        }
        dataStore.didRequestPushPermission = NewOnboardingUserDefaults.getDidRequestPushPermission()
        if let granted = NewOnboardingUserDefaults.getDidGrantPushPermission() {
            dataStore.didGrantPushPermission = granted
        }
        dataStore.didViewBuildsHabitsLineChart = NewOnboardingUserDefaults.getDidViewBuildsHabitsLineChart()
        dataStore.didViewReadingBarrierResolution = NewOnboardingUserDefaults.getDidViewReadingBarrierResolution()
        dataStore.didCompletePaywall = NewOnboardingUserDefaults.hasCompletedPaywall()
        if let variantString = NewOnboardingUserDefaults.getOnboardingVariant(),
           let variant = OnboardingVariant(rawValue: variantString) {
            dataStore.variant = variant
        }
    }
}
