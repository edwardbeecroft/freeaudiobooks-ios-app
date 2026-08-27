//
//  NewOnboardingContainerVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

/// Direction for onboarding screen transitions
enum OnboardingTransitionDirection {
    case forward
    case backward
    case none
}

/// Container view controller for the new onboarding flow.
/// Manages progress bar, back button, and continue button while
/// swapping child content VCs with smooth crossfade transitions.
class NewOnboardingContainerVC: UIViewController {

    // MARK: - Properties

    weak var coordinator: NewOnboardingCoordinator!
    private var currentChildVC: BaseNewOnboardingVC?

    // MARK: - UI Elements

    // Cal AI colors
    private let calAIBorderColor = Colours.separator
    private let calAIBackButtonBg = UIColor.dynamic(
        light: UIColor(red: 248/255, green: 248/255, blue: 253/255, alpha: 1),
        dark: Colours.surfaceCard
    )
    private let calAICTAAreaBg = Colours.surfacePrimary

    private lazy var progressBar: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progressTintColor = Colours.textPrimary
        progressView.trackTintColor = UIColor.dynamic(
            light: UIColor(red: 234/255, green: 234/255, blue: 235/255, alpha: 1),
            dark: UIColor.systemGray5
        )
        progressView.layer.cornerRadius = 0
        progressView.clipsToBounds = true
        progressView.subviews.forEach { $0.layer.cornerRadius = 0 }
        progressView.alpha = 0 // Start hidden, shown based on current step
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()

    private lazy var backButtonContainer: UIView = {
        let view = UIView()
        view.backgroundColor = calAIBackButtonBg
        view.layer.cornerRadius = 20
        view.alpha = 0 // Start hidden, shown based on current step
        view.isUserInteractionEnabled = true
        view.translatesAutoresizingMaskIntoConstraints = false
        let tap = UITapGestureRecognizer(target: self, action: #selector(backButtonTapped))
        view.addGestureRecognizer(tap)
        return view
    }()

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "back-arrow-full"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    /// Container for the child view controller content
    private let contentContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var bottomContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = calAICTAAreaBg
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var topBorderView: UIView = {
        let view = UIView()
        view.backgroundColor = calAIBorderColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var continueButton: UIButton = {
        let button = Buttons.primaryCTA(buttonTitle: RCValues.shared.string(forKey: .onbWelcomeButtonTitle))
        button.layer.cornerRadius = UIConstants.shared.onboardingButtonCornerRadius
        button.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var signInLabel: UILabel = {
        let label = UILabel()
        let fullText = "Already have an account? Sign In"
        let attributedString = NSMutableAttributedString(string: fullText)

        // Regular style for first part
        let regularRange = (fullText as NSString).range(of: "Already have an account? ")
        attributedString.addAttributes([
            .font: Fonts.medium14,
            .foregroundColor: Colours.textSecondary
        ], range: regularRange)

        // Bold style for "Sign In"
        let signInRange = (fullText as NSString).range(of: "Sign In")
        attributedString.addAttributes([
            .font: Fonts.semiBold14,
            .foregroundColor: Colours.textPrimary
        ], range: signInRange)

        label.attributedText = attributedString
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        label.alpha = 0 // Start hidden
        return label
    }()

    private lazy var secondaryActionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(Colours.textSecondary, for: .normal)
        button.addTarget(self, action: #selector(secondaryActionTapped), for: .touchUpInside)
        button.alpha = 0 // Start hidden
        return button
    }()

    // Constraint references for dynamic updates
    private var progressBarLeadingWithBackButton: NSLayoutConstraint!
    private var progressBarLeadingWithoutBackButton: NSLayoutConstraint!
    private var contentTopWithProgressBar: NSLayoutConstraint!
    private var contentTopWithBackButton: NSLayoutConstraint!
    private var contentTopWithNeither: NSLayoutConstraint!
    private var contentBottomWithCTA: NSLayoutConstraint!
    private var contentBottomWithoutCTA: NSLayoutConstraint!
    private var continueButtonBottomWithSignIn: NSLayoutConstraint!
    private var continueButtonBottomWithoutSignIn: NSLayoutConstraint!
    private var continueButtonBottomWithSecondaryAction: NSLayoutConstraint!

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
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = Colours.surfacePrimary

        // Add all subviews
        view.addSubview(backButtonContainer)
        backButtonContainer.addSubviewForConstraints(backButton)
        view.addSubviewForConstraints(progressBar)
        view.addSubviewForConstraints(contentContainerView)
        view.addSubview(bottomContainerView)
        bottomContainerView.addSubviewForConstraints(topBorderView)
        bottomContainerView.addSubviewForConstraints(continueButton)
        bottomContainerView.addSubviewForConstraints(signInLabel)
        bottomContainerView.addSubviewForConstraints(secondaryActionButton)

        // Setup sign-in label tap gesture
        let signInTap = UITapGestureRecognizer(target: self, action: #selector(signInLabelTapped))
        signInLabel.addGestureRecognizer(signInTap)

        // Back button constraints
        NSLayoutConstraint.activate([
            backButtonContainer.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: UIConstants.shared.standardMargin),
            backButtonContainer.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 16),
            backButtonContainer.widthAnchor.constraint(equalToConstant: 40),
            backButtonContainer.heightAnchor.constraint(equalToConstant: 40),

            backButton.centerXAnchor.constraint(equalTo: backButtonContainer.centerXAnchor),
            backButton.centerYAnchor.constraint(equalTo: backButtonContainer.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 20),
            backButton.heightAnchor.constraint(equalToConstant: 20)
        ])

        // Progress bar constraints
        progressBarLeadingWithBackButton = progressBar.leadingAnchor.constraint(
            equalTo: view.safeLeadingAnchor,
            constant: UIConstants.shared.standardMargin + 40 + 12
        )
        progressBarLeadingWithoutBackButton = progressBar.leadingAnchor.constraint(
            equalTo: view.safeLeadingAnchor,
            constant: UIConstants.shared.standardMargin
        )

        NSLayoutConstraint.activate([
            progressBar.centerYAnchor.constraint(equalTo: backButtonContainer.centerYAnchor),
            progressBar.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -UIConstants.shared.standardMargin),
            progressBar.heightAnchor.constraint(equalToConstant: 4)
        ])

        // Continue button bottom constraint variants
        continueButtonBottomWithSignIn = continueButton.bottomAnchor.constraint(equalTo: signInLabel.topAnchor, constant: -12)
        continueButtonBottomWithoutSignIn = continueButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -UIConstants.shared.standardMargin)
        continueButtonBottomWithSecondaryAction = continueButton.bottomAnchor.constraint(equalTo: secondaryActionButton.topAnchor, constant: -8)

        // Bottom container constraints
        NSLayoutConstraint.activate([
            bottomContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            topBorderView.topAnchor.constraint(equalTo: bottomContainerView.topAnchor),
            topBorderView.leadingAnchor.constraint(equalTo: bottomContainerView.leadingAnchor),
            topBorderView.trailingAnchor.constraint(equalTo: bottomContainerView.trailingAnchor),
            topBorderView.heightAnchor.constraint(equalToConstant: 1),

            continueButton.topAnchor.constraint(equalTo: bottomContainerView.topAnchor, constant: 16),
            continueButton.leadingAnchor.constraint(equalTo: bottomContainerView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            continueButton.trailingAnchor.constraint(equalTo: bottomContainerView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            continueButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.onboardingButtonHeight),

            // Sign-in label constraints
            signInLabel.centerXAnchor.constraint(equalTo: bottomContainerView.centerXAnchor),
            signInLabel.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -UIConstants.shared.standardMargin),

            // Secondary action button constraints
            secondaryActionButton.centerXAnchor.constraint(equalTo: bottomContainerView.centerXAnchor),
            secondaryActionButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -UIConstants.shared.standardMargin),
            secondaryActionButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        // Content container constraints - create all variants
        contentTopWithProgressBar = contentContainerView.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 24)
        contentTopWithBackButton = contentContainerView.topAnchor.constraint(equalTo: backButtonContainer.bottomAnchor, constant: 16)
        contentTopWithNeither = contentContainerView.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 20)

        contentBottomWithCTA = contentContainerView.bottomAnchor.constraint(equalTo: bottomContainerView.topAnchor)
        contentBottomWithoutCTA = contentContainerView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -UIConstants.shared.standardMargin)

        NSLayoutConstraint.activate([
            contentContainerView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor)
        ])
    }

    // MARK: - Transition

    /// Transitions to a new step with crossfade animation
    func transitionToStep(_ step: NewOnboardingStep, direction: OnboardingTransitionDirection) {
        let newVC = step.makeViewController(coordinator: coordinator) as! BaseNewOnboardingVC

        // Update chrome visibility based on new VC's preferences
        updateChromeVisibility(for: newVC, animated: direction != .none)

        // Update progress bar (animated for forward/backward, instant for initial)
        let animateProgress = direction != .none
        progressBar.setProgress(coordinator.currentProgress, animated: animateProgress)

        // Add new child VC
        addChild(newVC)

        // Add view to hierarchy first (triggers viewDidLoad, which loads data from dataStore)
        newVC.view.frame = contentContainerView.bounds
        newVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentContainerView.addSubview(newVC.view)

        // Configure button state AFTER view is loaded so VC has its data ready
        newVC.configureButtonState()

        if direction == .none {
            // No animation for initial display
            currentChildVC?.willMove(toParent: nil)
            currentChildVC?.view.removeFromSuperview()
            currentChildVC?.removeFromParent()
            newVC.didMove(toParent: self)
            currentChildVC = newVC
        } else {
            // Crossfade animation
            newVC.view.alpha = 0

            UIView.animate(withDuration: 0.25, animations: {
                self.currentChildVC?.view.alpha = 0
                newVC.view.alpha = 1
            }) { _ in
                self.currentChildVC?.willMove(toParent: nil)
                self.currentChildVC?.view.removeFromSuperview()
                self.currentChildVC?.removeFromParent()
                newVC.didMove(toParent: self)
                self.currentChildVC = newVC
            }
        }
    }

    /// Updates the visibility of progress bar, back button, and continue button
    private func updateChromeVisibility(for childVC: BaseNewOnboardingVC, animated: Bool) {
        let showsProgressBar = childVC.showsProgressBar
        let showsBackButton = childVC.showsBackButton && coordinator.canGoBack
        let showsContinueButton = childVC.showsContinueButton
        let showsCTATopDivider = showsContinueButton && childVC.showsCTATopDivider
        let showsSignInOption = childVC.showsSignInOption
        let showsSecondaryAction = childVC.showsSecondaryAction

        // Update secondary action button title if needed
        if showsSecondaryAction, let title = childVC.secondaryActionTitle {
            secondaryActionButton.setTitle(title, for: .normal)
        }

        // Deactivate all top/bottom constraints
        contentTopWithProgressBar.isActive = false
        contentTopWithBackButton.isActive = false
        contentTopWithNeither.isActive = false
        contentBottomWithCTA.isActive = false
        contentBottomWithoutCTA.isActive = false
        progressBarLeadingWithBackButton.isActive = false
        progressBarLeadingWithoutBackButton.isActive = false
        continueButtonBottomWithSignIn.isActive = false
        continueButtonBottomWithoutSignIn.isActive = false
        continueButtonBottomWithSecondaryAction.isActive = false

        // Activate appropriate constraints
        if showsProgressBar {
            contentTopWithProgressBar.isActive = true
            if showsBackButton {
                progressBarLeadingWithBackButton.isActive = true
            } else {
                progressBarLeadingWithoutBackButton.isActive = true
            }
        } else if showsBackButton {
            contentTopWithBackButton.isActive = true
        } else {
            contentTopWithNeither.constant = childVC.contentTopInsetWithoutChrome
            contentTopWithNeither.isActive = true
        }

        if showsContinueButton {
            contentBottomWithCTA.isActive = true
            // Activate appropriate continue button bottom constraint
            if showsSignInOption {
                continueButtonBottomWithSignIn.isActive = true
            } else if showsSecondaryAction {
                continueButtonBottomWithSecondaryAction.isActive = true
            } else {
                continueButtonBottomWithoutSignIn.isActive = true
            }
        } else {
            contentBottomWithoutCTA.isActive = true
        }

        let updateBlock = {
            self.progressBar.alpha = showsProgressBar ? 1 : 0
            self.backButtonContainer.alpha = showsBackButton ? 1 : 0
            self.bottomContainerView.alpha = showsContinueButton ? 1 : 0
            self.topBorderView.alpha = showsCTATopDivider ? 1 : 0
            self.signInLabel.alpha = showsSignInOption ? 1 : 0
            self.secondaryActionButton.alpha = showsSecondaryAction ? 1 : 0
            self.view.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.25, animations: updateBlock)
        } else {
            updateBlock()
        }
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        coordinator.goToPreviousScreen()
    }

    @objc private func continueButtonTapped() {
        HapticFeedbackHelper.shared.triggerLightImpactFeedback()
        currentChildVC?.continueButtonTapped()
    }

    @objc private func signInLabelTapped() {
        HapticFeedbackHelper.shared.triggerLightImpactFeedback()
        showSignInBottomSheet()
    }

    @objc private func secondaryActionTapped() {
        HapticFeedbackHelper.shared.triggerLightImpactFeedback()
        currentChildVC?.secondaryActionTapped()
    }

    private func showSignInBottomSheet() {
        let signInVC = SignInBottomSheetVC(coordinator: coordinator)
        signInVC.signInSuccessHandler = { [weak self] in
            // Existing user signed in - complete onboarding
            self?.coordinator.delegate?.didCompleteNewOnboarding(didSubscribe: false)
        }
        signInVC.modalPresentationStyle = .overFullScreen
        signInVC.preferredSheetSizing = .fit
        self.present(signInVC, animated: true)
    }

    // MARK: - Public Methods

    /// Updates continue button enabled state
    func setContinueButtonEnabled(_ enabled: Bool) {
        continueButton.isEnabled = enabled
        continueButton.alpha = enabled ? 1.0 : 0.5
    }

    /// Updates continue button title
    func setContinueButtonTitle(_ title: String) {
        continueButton.setTitle(title, for: .normal)
    }

    /// Refreshes the chrome visibility (call after coordinator state changes)
    func refreshChromeVisibility() {
        guard let childVC = currentChildVC else { return }
        updateChromeVisibility(for: childVC, animated: true)
    }
}
