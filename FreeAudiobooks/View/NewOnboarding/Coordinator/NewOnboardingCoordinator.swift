//
//  NewOnboardingCoordinator.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import SuperwallKit
import FirebaseAuth
import FirebaseFirestore

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
    private(set) var steps: [NewOnboardingStep] = []
    private(set) var currentIndex: Int = 0

    /// Stores user selections throughout the flow
    let dataStore = NewOnboardingDataStore()

    // MARK: - Initialization

    init() {}

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
    /// Resumes the saved assignment, or uses OnboardingVariant.current for a new journey.
    func set(delegate: NewOnboardingCoordinatorDelegate) {
        self.delegate = delegate

        let activeVariant = Self.resolveVariant(
            persistedValue: NewOnboardingUserDefaults.getOnboardingVariant(),
            currentVariant: OnboardingVariant.current
        )
        configureFlow(variant: activeVariant,
                      isSubscribed: Superwall.shared.subscriptionStatus.isActive)
    }

    /// Resolve once at the start of a journey, before constructing steps or logging events.
    static func resolveVariant(persistedValue: String?, currentVariant: OnboardingVariant) -> OnboardingVariant {
        return persistedValue.flatMap(OnboardingVariant.init(rawValue:)) ?? currentVariant
    }

    /// Configure the resolved journey with a single assignment for navigation and analytics.
    func configureFlow(variant: OnboardingVariant, isSubscribed: Bool) {
        self.steps = variant.steps
        if isSubscribed {
            steps.removeAll { $0 == .paywall || (variant == .setupBeforePaywall && $0 == .settingEverythingUp) }
        }
        dataStore.reset()
        dataStore.variant = variant
        NewOnboardingUserDefaults.saveOnboardingVariant(variant.rawValue)

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
        EmailMarketingService.prefetchStorefront()
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

        repeat {
            currentIndex -= 1
        } while currentIndex > 0 && steps[currentIndex] == .settingEverythingUp
        let step = steps[currentIndex]
        containerVC?.transitionToStep(step, direction: OnboardingTransitionDirection.backward)
    }

    /// Whether the user can go back (not on first step)
    var canGoBack: Bool {
        return currentIndex > 0
    }

    var currentStep: NewOnboardingStep? {
        steps.indices.contains(currentIndex) ? steps[currentIndex] : nil
    }

    /// Ignore callbacks from a removed screen, including an earlier visit to the same step.
    @discardableResult
    func completeSetupScreen(_ screen: SettingEverythingUpVC) -> Bool {
        guard currentStep == .settingEverythingUp,
              containerVC?.isDisplaying(screen) == true else { return false }
        AnalyticsManager.shared.trackOnbSettingEverythingUpCompleted(variant: dataStore.variant.rawValue)
        goToNextScreen()
        return true
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

    /// Saves the app's onboarding once, then handles its email preference and exits.
    private func completeOnboarding() {
        let firstAppOnboarding = AccountManager.shared.user?.isFirstAppOnboarding == true
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
        showEmailOptInIfNeeded(isFirstAppOnboarding: firstAppOnboarding) { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.delegate?.didCompleteNewOnboarding(didSubscribe: self.dataStore.didSubscribe)
            }
        }
    }

    // MARK: - Email Marketing Opt-In

    /// Presents the email marketing opt-in bottom sheet at the end of the onboarding journey, if the user is eligible.
    private func showEmailOptInIfNeeded(isFirstAppOnboarding: Bool, completion: @escaping () -> Void) {
        if let user = AccountManager.shared.user {
            let autoEnrol = EmailMarketingService.shouldAutoEnrol(
                enabled: RCValues.shared.bool(forKey: .emailUSAutoEnrolEnabled),
                country: EmailMarketingService.storefrontCountryCode, email: user.emailAddress,
                isFirstAppOnboarding: isFirstAppOnboarding,
                isEmailSubscribed: user.marketingPermission, previouslyAnswered: user.marketingPromptAnswered,
                isEmailUnsubscribed: user.marketingUnsubscribedAt != nil,
                dismissed: user.marketingPromptDismissedAt != nil || EmailOptInUserDefaults.dismissCount > 0 || EmailOptInUserDefaults.isPermanentlySuppressed)
            if autoEnrol {
                EmailMarketingService().setPreference(subscribed: true, source: "us_auto_enrol")
                EmailOptInUserDefaults.recordOptIn()
                AnalyticsManager.shared.trackEmailAutoEnrolled()
                completion()
                return
            }
        }
        presentEmailOptInIfNeeded(completion: completion)
    }

    private func presentEmailOptInIfNeeded(completion: @escaping () -> Void) {
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

        let genre = dataStore.selectedGenres.first ?? .romance
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

        EmailOptInUserDefaults.recordOptIn()
        EmailMarketingService().subscribeUser(trigger: .newOnboarding, genre: genre) { _ in }
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
        // Persist the dismissal as well as the account-scoped cooldown.
        EmailOptInUserDefaults.recordDismissal()
    }

    // MARK: - Firestore Sync

    /// Syncs onboarding data to the user's Firestore document
    /// Called at completion to ensure data persists for users who authenticated early
    private func syncOnboardingDataToFirestore() {
        print("[Onboarding] Syncing onboarding data to Firestore")

        var data = EmailMarketingService.deviceProfile()
        if AccountManager.shared.user?.emailOnboardingCompletedAt == nil {
            data["emailOnboardingCompletedAt"] = FieldValue.serverTimestamp()
            AccountManager.shared.user?.emailOnboardingCompletedAt = Date()
            AccountManager.shared.user?.isFirstAppOnboarding = false
        }
        data["subscriptionStatusAtOnboarding"] = AccountManager.shared.knownUserIsSubscribed.map { $0 ? "active" : "inactive" } ?? "unknown"

        if !dataStore.selectedGenres.isEmpty {
            data[FirebaseUserVariables.favoriteGenres.rawValue] = dataStore.selectedGenres.map { $0.rawValue }
        }
        if let frequency = dataStore.readingFrequency {
            data[FirebaseUserVariables.readingFrequency.rawValue] = frequency
        }
        if let source = dataStore.howDidYouHear {
            data[FirebaseUserVariables.howDidYouHear.rawValue] = source
        }
        if !dataStore.previousApps.isEmpty {
            data[FirebaseUserVariables.previousApps.rawValue] = dataStore.previousApps
        }
        data["preferredFormat"] = "audio"
        if !dataStore.listeningOccasions.isEmpty {
            data[FirebaseUserVariables.listeningOccasions.rawValue] = dataStore.listeningOccasions
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
        // Keep existing shared preference screens working; campaign observations are app-specific.
        let answerKeys = ["favoriteGenres", "readingFrequency", "howDidYouHear", "previousApps",
                          "listeningOccasions", "listeningReasons", "readingBarriers", "dailyListeningGoal"]
        var update = data.filter { answerKeys.contains($0.key) }
        update.merge(EmailMarketingService.profileData(data)) { _, new in new }
        EmailMarketingService.saveEmailChange(update, completion: nil)
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
    }
}
