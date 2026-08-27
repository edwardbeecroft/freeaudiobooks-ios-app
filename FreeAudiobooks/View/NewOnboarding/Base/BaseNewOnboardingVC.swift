//
//  BaseNewOnboardingVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

/// Base view controller for all new onboarding screens
/// Provides common configuration and content area
/// Chrome elements (progress bar, back button, CTA) are managed by NewOnboardingContainerVC
class BaseNewOnboardingVC: UIViewController {

    // MARK: - Properties

    weak var coordinator: NewOnboardingCoordinator!

    /// Override this in subclasses to specify the screen type
    var step: NewOnboardingStep {
        fatalError("Subclasses must override step")
    }

    /// Whether this screen shows the progress bar (in container)
    /// Hidden if there's only one step (no progress to show)
    var showsProgressBar: Bool {
        return step.includesInProgressBar && coordinator.totalProgressSteps > 1
    }

    /// Whether this screen shows the back button (in container)
    var showsBackButton: Bool {
        return true
    }

    /// Whether this screen shows the continue button (in container)
    var showsContinueButton: Bool {
        return true
    }

    /// Whether this screen shows the sign-in option below the continue button
    var showsSignInOption: Bool {
        return false
    }

    /// Whether this screen shows a secondary action below the continue button
    var showsSecondaryAction: Bool {
        return false
    }

    /// Whether this screen shows the divider above the CTA area (in container)
    var showsCTATopDivider: Bool {
        return true
    }

    /// Top inset used when neither progress bar nor back button are shown.
    /// Allows screen-specific control of vertical space in chrome-free layouts.
    var contentTopInsetWithoutChrome: CGFloat {
        return 20
    }

    /// Title for the secondary action button (e.g., "Not now", "Skip")
    var secondaryActionTitle: String? {
        return nil
    }

    /// Reference to the container for button state management
    private var containerVC: NewOnboardingContainerVC? {
        return parent as? NewOnboardingContainerVC
    }

    // MARK: - UI Elements

    /// Container for screen-specific content - fills the entire view
    let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Initialization

    init(coordinator: NewOnboardingCoordinator) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupContentView()
        trackScreenViewed()
    }

    // MARK: - Setup

    private func setupContentView() {
        view.backgroundColor = .clear // Container handles background

        view.addSubviewForConstraints(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Actions

    /// Called when continue button is tapped (from container)
    @objc func continueButtonTapped() {
        trackContinueTapped()
        coordinator.goToNextScreen()
    }

    /// Called when secondary action is tapped (from container)
    /// Override in subclasses to handle (e.g., "Not now", "Skip")
    @objc func secondaryActionTapped() {
        // Default: do nothing. Subclasses should override.
    }

    // MARK: - Button State

    /// Updates continue button enabled state (delegates to container)
    func setContinueButtonEnabled(_ enabled: Bool) {
        containerVC?.setContinueButtonEnabled(enabled)
    }

    /// Updates continue button title (delegates to container)
    func setContinueButtonTitle(_ title: String) {
        containerVC?.setContinueButtonTitle(title)
    }

    /// Called by container during transitions to configure button state
    /// Override in subclasses to set enabled state and custom title
    func configureButtonState() {
        // Default: enabled with standard "Continue" title
        // Screens with conditional enabling (e.g. SelectionOnboardingVC) override this
        setContinueButtonEnabled(true)
        setContinueButtonTitle(RCValues.shared.string(forKey: .onbContinueButtonTitle))
    }

    // MARK: - Analytics

    func trackScreenViewed() {
        switch step {
        case .welcomeVideo: AnalyticsManager.shared.trackOnbWelcomeVideoScreenViewed()
        case .genreSelection: AnalyticsManager.shared.trackOnbGenreSelectionScreenViewed()
        case .listeningOccasion: AnalyticsManager.shared.trackOnbListeningOccasionScreenViewed()
        case .readingFrequency: AnalyticsManager.shared.trackOnbReadingFrequencyScreenViewed()
        case .howDidYouHear: AnalyticsManager.shared.trackOnbHowDidYouHearScreenViewed()
        case .previousApps: AnalyticsManager.shared.trackOnbPreviousAppsScreenViewed()
        case .buildsHabitsLineChart: AnalyticsManager.shared.trackOnbBuildsHabitsLineChartScreenViewed()
        case .whyDoYouListen: AnalyticsManager.shared.trackOnbWhyDoYouListenScreenViewed()
        case .readingBarriers: AnalyticsManager.shared.trackOnbReadingBarriersScreenViewed()
        case .readingBarrierResolution: AnalyticsManager.shared.trackOnbReadingBarrierResolutionScreenViewed()
        case .dailyListeningGoal: AnalyticsManager.shared.trackOnbDailyListeningGoalScreenViewed()
        case .pushNotification: AnalyticsManager.shared.trackOnbPushNotificationScreenViewed()
        case .credibilityReviews: AnalyticsManager.shared.trackOnbCredibilityReviewsScreenViewed()
        case .personalizedPicks: AnalyticsManager.shared.trackOnbPersonalizedPicksScreenViewed()
        case .saveProgressAuth: AnalyticsManager.shared.trackOnbSaveProgressAuthScreenViewed()
        case .paywall: AnalyticsManager.shared.trackOnbPaywallScreenViewed()
        }
    }

    func trackContinueTapped() {
        switch step {
        case .welcomeVideo: AnalyticsManager.shared.trackOnbWelcomeVideoContinueTapped()
        case .genreSelection: AnalyticsManager.shared.trackOnbGenreSelectionContinueTapped(genres: coordinator.dataStore.selectedGenres)
        case .listeningOccasion: AnalyticsManager.shared.trackOnbListeningOccasionContinueTapped(occasions: coordinator.dataStore.listeningOccasions)
        case .readingFrequency: AnalyticsManager.shared.trackOnbReadingFrequencyContinueTapped(frequency: coordinator.dataStore.readingFrequency ?? "none")
        case .howDidYouHear: AnalyticsManager.shared.trackOnbHowDidYouHearContinueTapped(source: coordinator.dataStore.howDidYouHear ?? "none")
        case .previousApps: AnalyticsManager.shared.trackOnbPreviousAppsContinueTapped(apps: coordinator.dataStore.previousApps)
        case .buildsHabitsLineChart: AnalyticsManager.shared.trackOnbBuildsHabitsLineChartContinueTapped()
        case .whyDoYouListen: AnalyticsManager.shared.trackOnbWhyDoYouListenContinueTapped(listeningReasons: coordinator.dataStore.listeningReasons)
        case .readingBarriers: AnalyticsManager.shared.trackOnbReadingBarriersContinueTapped(barriers: coordinator.dataStore.readingBarriers)
        case .readingBarrierResolution: AnalyticsManager.shared.trackOnbReadingBarrierResolutionContinueTapped()
        case .dailyListeningGoal: AnalyticsManager.shared.trackOnbDailyListeningGoalContinueTapped(goal: coordinator.dataStore.dailyListeningGoal ?? 0)
        case .pushNotification: AnalyticsManager.shared.trackOnbPushNotificationContinueTapped()
        case .credibilityReviews: AnalyticsManager.shared.trackOnbCredibilityReviewsContinueTapped()
        case .personalizedPicks: AnalyticsManager.shared.trackOnbPersonalizedPicksContinueTapped()
        case .saveProgressAuth: break // Custom auth buttons
        case .paywall: break // Handled by Superwall
        }
    }
}
