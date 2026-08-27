//
//  ReadingVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 06/08/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import FirebaseFirestore
import FirebaseCore
import FirebaseAuth
import PopupDialog
import SuperwallKit
import GoogleMobileAds

private final class MinimumHitTargetButton: UIButton {
    var minimumHitSize = CGSize(width: 44, height: 56)

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let widthDelta = max(0, minimumHitSize.width - bounds.width)
        let heightDelta = max(0, minimumHitSize.height - bounds.height)
        let extendedBounds = bounds.insetBy(dx: -widthDelta / 2, dy: -heightDelta / 2)
        return extendedBounds.contains(point)
    }
}

class ReadingVC: UIViewController {
    private struct MenuPalette {
        let itemTextIconColor: UIColor
        let separatorColor: UIColor
        let actionButtonTintColor: UIColor
        let actionButtonBackgroundColor: UIColor
        let menuSurfaceTintColor: UIColor
    }

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let contentTextView = NoPaddingTextView()

    // Status bar backing (solid theme color behind status bar area)
    private let statusBarBackground = UIView()

    // Floating chrome elements
    private let titlePill = UIView()
    private var titlePillBlur: UIVisualEffectView!
    private var titlePillVibrancy: UIVisualEffectView!
    private let titlePillLabel = UILabel()
    private let closeButton = UIButton(type: .custom)
    private var closeButtonBlur: UIVisualEffectView!
    private var closeButtonVibrancy: UIVisualEffectView!
    private let closeButtonTint = UIView()
    private let closeButtonIcon = UIImageView()
    private let progressPill = UIView()
    private var progressPillBlur: UIVisualEffectView!
    private var progressPillVibrancy: UIVisualEffectView!
    private let progressPillLabel = UILabel()
    private let menuCircle = UIButton(type: .custom)
    private var menuCircleBlur: UIVisualEffectView!
    private var menuCircleVibrancy: UIVisualEffectView!
    private let menuCircleTint = UIView()
    private let menuCircleIcon = UIImageView()

    // Custom menu
    private let menuDimmingView = UIView()
    private var menuDimmingGradient: CAGradientLayer?
    private let menuContainerView = UIView()
    private var menuBlurView: UIVisualEffectView!
    private let menuSurfaceTintView = UIView()
    private let menuStackView = UIStackView()
    private var menuActions: [() -> Void] = []
    private var isMenuVisible = false

    // Section footer navigation (inside scroll content)
    private let sectionFooterContainer = UIView()
    private var sectionFooterBlur: UIVisualEffectView!
    private var sectionFooterVibrancy: UIVisualEffectView!
    private let prevButton = MinimumHitTargetButton(type: .system)
    private let nextButton = MinimumHitTargetButton(type: .system)

    // Chrome state
    private var isChromeVisible = false
    private var chromeAutoHideTimer: Timer?
    private let chromeAutoHideDuration: TimeInterval = 5.0

    // First-run onboarding for chrome discoverability
    private var autoRevealStartWorkItem: DispatchWorkItem?
    private let autoRevealDelay: TimeInterval = 0.35
    private let autoRevealVisibleDuration: TimeInterval = 2.2
    private var hasMarkedChromeRevealLearnedThisSession = false
    private let menuPulseAnimationKey = "readingMenuPulse"
    private let menuPulseDuration: CFTimeInterval = 0.45
    private let menuPulseScale: CGFloat = 1.06
    private let recapBelowTitleSpacing: CGFloat = 8
    
    var currentSection: Int = 0 {
        didSet {
            guard currentSection >= 0, currentSection < content.sectionsArray.count else {
                AnalyticsManager.shared.trackBookOffsetOutOfBounds()
                return
            }

            // Suppress recap visibility during the entire transition
            isSectionTransitioning = true

            // Hide recap button on any section change
            if isRecapButtonVisible {
                floatingRecapButton.animateOut()
                isRecapButtonVisible = false
            }
            upwardScrollDistance = 0

            contentTextView.attributedText = formattedContent(for: content.sectionsArray[currentSection])
            updateSectionFooter()
            scrollView.scrollToTop(animated: false)
            lastScrollOffset = 0

            isSectionTransitioning = false
        }
    }
    
    private var isReadingSessionActive: Bool = false

    private var isOnLastChapter: Bool {
        return currentSection == content.sectionsArray.count - 1
    }
    private var shouldShowPushPrePrompt: Bool {
        return currentSection == 0 && PushPrePromptUserDefaults.canShowPrompt
    }
    private var didReach100Percent: Bool = false

    // Reading activation tracking
    private var cumulativeScrollDistance: CGFloat = 0
    private var lastScrollOffset: CGFloat = 0
    private var hasAttemptedAutoLibraryAdd = false

    // Floating recap button
    private let floatingRecapButton = FloatingRecapButton()
    private var upwardScrollDistance: CGFloat = 0
    private var isRecapButtonVisible = false
    private var isSectionTransitioning = false
    private var hasHandledRecapOnViewDidAppear = false

    // Interstitial ads
    private var interstitial: InterstitialAd?
    private var shouldLoadNextInterstitialAd: Bool {
        guard RCValues.shared.bool(forKey: .isReadingVCInterstitialAdEnabled) == true else {
            return false
        }
        return !AccountManager.shared.userIsSubscribed
    }

    private let metadata: ReadableContentMetadata
    private let content: ReadableContent
    init(metadata: ReadableContentMetadata, content: ReadableContent) {
        self.metadata = metadata
        self.content = content
        super.init(nibName:nil, bundle:nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let theme = ReadingUserDefaults.theme
        view.backgroundColor = theme.backgroundColor
        navigationController?.view.backgroundColor = theme.backgroundColor

        setupScrollView()
        setupContentTextView()
        setupSectionFooter()
        setupFloatingChrome()
        setupMenuView()
        setupFloatingRecapButton()
        setupTapGesture()

        updateUIForReadingPreferences()

        if let offset = metadata.getReadingOffset(), offset.hasStartedReading {
            currentSection = offset.currentSection
            view.layoutIfNeeded()
            scrollView.setContentOffset(CGPoint(x: 0, y: offset.currentSectionYOffset), animated: false)
        } else {
            currentSection = 0
        }
        scrollView.isHidden = false

        if shouldLoadNextInterstitialAd {
            loadNewInterstitialAd()
        }

        APIBookInternalManager.shared.incrementReadCountForBookInternalWithUUID(metadata.contentUUID)
        guard let genre = (metadata as? CDBookInternal)?.genre else { return }
        AnalyticsManager.shared.trackBookInternalViewed(genre: genre)

        if SKReviewManager.launchCount == 1 {
            AnalyticsManager.shared.trackFirstLaunchBookViewed()
        }

        // Track reading started (once per user)
        if !FirstTimeManager.hasSeen(item: .readingStarted) {
            FirstTimeManager.markSeen(item: .readingStarted)
            AnalyticsManager.shared.trackReadingStarted()
            // Re-copy remaining retention nudges for the "startedNotActivated" segment
            OnboardingRetentionScheduler.refreshRemainingNudges()
        }

        // Listen for app lifecycle events to handle backgrounding while reading
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        // Ensure floating chrome and recap button are above scroll view
        view.bringSubviewToFront(statusBarBackground)
        view.bringSubviewToFront(titlePill)
        view.bringSubviewToFront(closeButton)
        view.bringSubviewToFront(progressPill)
        view.bringSubviewToFront(menuCircle)
        view.bringSubviewToFront(menuContainerView)
        view.bringSubviewToFront(floatingRecapButton)

        updateSectionFooter()

        // Start in immersive mode (chrome hidden)
        hideChrome(animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)

        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        UIApplication.shared.isIdleTimerDisabled = false

        // Restore nav bar for previous VC
        navigationController?.setNavigationBarHidden(false, animated: animated)

        cancelAutoRevealOnboarding()
        stopMenuCirclePulseHint()
        cancelAutoHideTimer()

        if isMovingFromParent {
            ReadingUserDefaults.clearResumeReading()
        }
    }
    
    // MARK: - Status Bar & Home Indicator

    override var prefersStatusBarHidden: Bool {
        return !isChromeVisible
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ReadingUserDefaults.theme.preferredStatusBarStyle
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return !isChromeVisible
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.delegate = self
        updateScrollViewInsets()
        menuDimmingGradient?.frame = menuDimmingView.bounds

        let progress = ReadingUserDefaults.progressForBookWithUUID(metadata.contentUUID) ?? 0
        updateProgressLabel(progress: progress)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Save resume reading state so we can restore on relaunch
        ReadingUserDefaults.setResumeReading(bookUUID: metadata.contentUUID, contentType: metadata.contentType)
        attemptAutoAddToLibraryIfNeeded()

        // Start tracking reading time
        startReadingSessionIfNeeded()

        maybeRunFirstRunChromeReveal()

        // Animate recap button in after brief delay (for users returning to a book they've already read)
        if RecapManager.shared.shouldShowRecapSection(for: metadata) &&
            !hasHandledRecapOnViewDidAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                guard let self else { return }
                self.floatingRecapButton.animateIn()
                self.isRecapButtonVisible = true
                self.hasHandledRecapOnViewDidAppear = true
            }
        } else {
            hasHandledRecapOnViewDidAppear = true
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // Stop tracking reading time
        endReadingSessionIfNeeded()

        // Notify Home/Library after the final session time has been flushed.
        if isMovingFromParent || isBeingDismissed {
            NotificationCenter.default.post(name: .didExitReadingVC, object: nil)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateOverlayTheme(ReadingUserDefaults.theme)
    }

    @objc private func appDidEnterBackground() {
        // Stop tracking when app backgrounds while user is reading
        endReadingSessionIfNeeded()
    }

    @objc private func appWillEnterForeground() {
        // Resume tracking when app returns to foreground (only if still on this screen)
        startReadingSessionIfNeeded()
    }

    // MARK: - Session Tracking Helpers

    private func startReadingSessionIfNeeded() {
        guard !isReadingSessionActive else { return }
        isReadingSessionActive = true
        SessionTrackingManager.shared.startSession()
    }

    private func endReadingSessionIfNeeded() {
        guard isReadingSessionActive else { return }
        isReadingSessionActive = false
        SessionTrackingManager.shared.endSession()

        // Track last read date for recap feature
        ReadingUserDefaults.setLastReadDate(for: metadata.contentUUID, mode: .text)
    }

    private func attemptAutoAddToLibraryIfNeeded() {
        guard !hasAttemptedAutoLibraryAdd else { return }
        guard AccountManager.shared.user != nil else { return }

        let completion: (Bool) -> Void = { [weak self] success in
            DispatchQueue.main.async {
                guard let self else { return }
                if !success {
                    self.hasAttemptedAutoLibraryAdd = false
                }
            }
        }

        let uuid = metadata.contentUUID
        guard !(AccountManager.shared.user?.savedBookInternalUUIDs.contains(uuid) ?? false) else { return }
        hasAttemptedAutoLibraryAdd = true
        AccountManager.shared.handleAutoSaveBookInternalWithUUIDIfNeeded(uuid, completion: completion)
    }

    deinit {
        cancelAutoRevealOnboarding()
        stopMenuCirclePulseHint()
        NotificationCenter.default.removeObserver(self)
    }
}


// MARK: - Chrome & Chapter Navigation Setup
extension ReadingVC {

    private func setupSectionFooter() {
        let theme = ReadingUserDefaults.theme
        let blurEffect = UIBlurEffect(style: theme.chromeBlurStyle)
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect, style: .label)

        sectionFooterContainer.translatesAutoresizingMaskIntoConstraints = false
        sectionFooterContainer.layer.cornerRadius = 28
        applyFloatingStyle(to: sectionFooterContainer, theme: theme)
        contentView.addSubview(sectionFooterContainer)

        sectionFooterBlur = UIVisualEffectView(effect: blurEffect)
        sectionFooterBlur.translatesAutoresizingMaskIntoConstraints = false
        sectionFooterBlur.layer.cornerRadius = 28
        sectionFooterBlur.clipsToBounds = true
        sectionFooterContainer.addSubview(sectionFooterBlur)

        sectionFooterVibrancy = UIVisualEffectView(effect: vibrancyEffect)
        sectionFooterVibrancy.translatesAutoresizingMaskIntoConstraints = false
        sectionFooterBlur.contentView.addSubview(sectionFooterVibrancy)

        // Prev button
        prevButton.translatesAutoresizingMaskIntoConstraints = false
        prevButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        let prevConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        prevButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: prevConfig), for: .normal)
        prevButton.setTitle(" Prev", for: .normal)
        prevButton.addTarget(self, action: #selector(sectionFooterPrevTapped), for: .touchUpInside)
        sectionFooterVibrancy.contentView.addSubview(prevButton)

        // Next button
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        nextButton.semanticContentAttribute = .forceRightToLeft
        nextButton.addTarget(self, action: #selector(sectionFooterNextTapped), for: .touchUpInside)
        sectionFooterVibrancy.contentView.addSubview(nextButton)

        NSLayoutConstraint.activate([
            sectionFooterBlur.topAnchor.constraint(equalTo: sectionFooterContainer.topAnchor),
            sectionFooterBlur.leadingAnchor.constraint(equalTo: sectionFooterContainer.leadingAnchor),
            sectionFooterBlur.trailingAnchor.constraint(equalTo: sectionFooterContainer.trailingAnchor),
            sectionFooterBlur.bottomAnchor.constraint(equalTo: sectionFooterContainer.bottomAnchor),

            sectionFooterVibrancy.topAnchor.constraint(equalTo: sectionFooterBlur.contentView.topAnchor),
            sectionFooterVibrancy.leadingAnchor.constraint(equalTo: sectionFooterBlur.contentView.leadingAnchor),
            sectionFooterVibrancy.trailingAnchor.constraint(equalTo: sectionFooterBlur.contentView.trailingAnchor),
            sectionFooterVibrancy.bottomAnchor.constraint(equalTo: sectionFooterBlur.contentView.bottomAnchor),

            prevButton.leadingAnchor.constraint(equalTo: sectionFooterVibrancy.contentView.leadingAnchor, constant: 20),
            prevButton.centerYAnchor.constraint(equalTo: sectionFooterVibrancy.contentView.centerYAnchor),

            nextButton.trailingAnchor.constraint(equalTo: sectionFooterVibrancy.contentView.trailingAnchor, constant: -20),
            nextButton.centerYAnchor.constraint(equalTo: sectionFooterVibrancy.contentView.centerYAnchor),

            sectionFooterContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            sectionFooterContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            sectionFooterContainer.topAnchor.constraint(equalTo: contentTextView.bottomAnchor, constant: 32),
            sectionFooterContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UIConstants.shared.standardMargin),
            sectionFooterContainer.heightAnchor.constraint(equalToConstant: 56)
        ])

        updateSectionFooter(theme: theme)
    }

    private func setupFloatingChrome() {
        let theme = ReadingUserDefaults.theme
        let blurEffect = UIBlurEffect(style: theme.chromeBlurStyle)
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect, style: .label)

        // === Status Bar Background (solid color behind status bar) ===
        statusBarBackground.translatesAutoresizingMaskIntoConstraints = false
        statusBarBackground.backgroundColor = theme.backgroundColor
        statusBarBackground.alpha = 0
        view.addSubview(statusBarBackground)

        NSLayoutConstraint.activate([
            statusBarBackground.topAnchor.constraint(equalTo: view.topAnchor),
            statusBarBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBarBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBarBackground.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])

        // === Title Pill (top-center) ===
        titlePill.translatesAutoresizingMaskIntoConstraints = false
        titlePill.layer.cornerRadius = 16
        applyFloatingStyle(to: titlePill, theme: theme)
        view.addSubview(titlePill)

        titlePillBlur = UIVisualEffectView(effect: blurEffect)
        titlePillBlur.translatesAutoresizingMaskIntoConstraints = false
        titlePillBlur.layer.cornerRadius = 16
        titlePillBlur.clipsToBounds = true
        titlePill.addSubview(titlePillBlur)

        titlePillVibrancy = UIVisualEffectView(effect: vibrancyEffect)
        titlePillVibrancy.translatesAutoresizingMaskIntoConstraints = false
        titlePillBlur.contentView.addSubview(titlePillVibrancy)

        titlePillLabel.text = metadata.title
        titlePillLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        titlePillLabel.numberOfLines = 1
        titlePillLabel.lineBreakMode = .byTruncatingTail
        titlePillLabel.translatesAutoresizingMaskIntoConstraints = false
        titlePillVibrancy.contentView.addSubview(titlePillLabel)

        NSLayoutConstraint.activate([
            titlePillBlur.topAnchor.constraint(equalTo: titlePill.topAnchor),
            titlePillBlur.leadingAnchor.constraint(equalTo: titlePill.leadingAnchor),
            titlePillBlur.trailingAnchor.constraint(equalTo: titlePill.trailingAnchor),
            titlePillBlur.bottomAnchor.constraint(equalTo: titlePill.bottomAnchor),

            titlePillVibrancy.topAnchor.constraint(equalTo: titlePillBlur.contentView.topAnchor),
            titlePillVibrancy.leadingAnchor.constraint(equalTo: titlePillBlur.contentView.leadingAnchor),
            titlePillVibrancy.trailingAnchor.constraint(equalTo: titlePillBlur.contentView.trailingAnchor),
            titlePillVibrancy.bottomAnchor.constraint(equalTo: titlePillBlur.contentView.bottomAnchor),

            titlePillLabel.topAnchor.constraint(equalTo: titlePillVibrancy.contentView.topAnchor, constant: 7),
            titlePillLabel.bottomAnchor.constraint(equalTo: titlePillVibrancy.contentView.bottomAnchor, constant: -7),
            titlePillLabel.leadingAnchor.constraint(equalTo: titlePillVibrancy.contentView.leadingAnchor, constant: 14),
            titlePillLabel.trailingAnchor.constraint(equalTo: titlePillVibrancy.contentView.trailingAnchor, constant: -14),

            titlePill.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titlePill.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            titlePill.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.6),
            titlePill.heightAnchor.constraint(equalToConstant: 32)
        ])

        // === Close Button (top-left) ===
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.layer.cornerRadius = 20
        applyFloatingStyle(to: closeButton, theme: theme)
        closeButton.addTarget(self, action: #selector(popVC), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(chromeButtonHighlight(_:)), for: [.touchDown, .touchDragEnter])
        closeButton.addTarget(self, action: #selector(chromeButtonUnhighlight(_:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit, .touchCancel])
        view.addSubview(closeButton)

        closeButtonBlur = UIVisualEffectView(effect: blurEffect)
        closeButtonBlur.translatesAutoresizingMaskIntoConstraints = false
        closeButtonBlur.layer.cornerRadius = 20
        closeButtonBlur.clipsToBounds = true
        closeButtonBlur.isUserInteractionEnabled = false
        closeButton.addSubview(closeButtonBlur)

        closeButtonTint.translatesAutoresizingMaskIntoConstraints = false
        closeButtonTint.backgroundColor = theme.isDark ? theme.chromeTintColor.withAlphaComponent(0.10) : UIColor.white.withAlphaComponent(0.35)
        closeButtonTint.isUserInteractionEnabled = false
        closeButtonBlur.contentView.addSubview(closeButtonTint)

        closeButtonVibrancy = UIVisualEffectView(effect: vibrancyEffect)
        closeButtonVibrancy.translatesAutoresizingMaskIntoConstraints = false
        closeButtonVibrancy.isUserInteractionEnabled = false
        closeButtonBlur.contentView.addSubview(closeButtonVibrancy)

        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        closeButtonIcon.image = UIImage(systemName: "chevron.left", withConfiguration: chevronConfig)
        closeButtonIcon.contentMode = .scaleAspectFit
        closeButtonIcon.translatesAutoresizingMaskIntoConstraints = false
        closeButtonIcon.isUserInteractionEnabled = false
        closeButtonVibrancy.contentView.addSubview(closeButtonIcon)

        NSLayoutConstraint.activate([
            closeButtonBlur.topAnchor.constraint(equalTo: closeButton.topAnchor),
            closeButtonBlur.leadingAnchor.constraint(equalTo: closeButton.leadingAnchor),
            closeButtonBlur.trailingAnchor.constraint(equalTo: closeButton.trailingAnchor),
            closeButtonBlur.bottomAnchor.constraint(equalTo: closeButton.bottomAnchor),

            closeButtonTint.topAnchor.constraint(equalTo: closeButtonBlur.contentView.topAnchor),
            closeButtonTint.leadingAnchor.constraint(equalTo: closeButtonBlur.contentView.leadingAnchor),
            closeButtonTint.trailingAnchor.constraint(equalTo: closeButtonBlur.contentView.trailingAnchor),
            closeButtonTint.bottomAnchor.constraint(equalTo: closeButtonBlur.contentView.bottomAnchor),

            closeButtonVibrancy.topAnchor.constraint(equalTo: closeButtonBlur.contentView.topAnchor),
            closeButtonVibrancy.leadingAnchor.constraint(equalTo: closeButtonBlur.contentView.leadingAnchor),
            closeButtonVibrancy.trailingAnchor.constraint(equalTo: closeButtonBlur.contentView.trailingAnchor),
            closeButtonVibrancy.bottomAnchor.constraint(equalTo: closeButtonBlur.contentView.bottomAnchor),

            closeButtonIcon.centerXAnchor.constraint(equalTo: closeButtonVibrancy.contentView.centerXAnchor),
            closeButtonIcon.centerYAnchor.constraint(equalTo: closeButtonVibrancy.contentView.centerYAnchor),

            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.centerYAnchor.constraint(equalTo: titlePill.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        // === Progress Pill (bottom-center) ===
        progressPill.translatesAutoresizingMaskIntoConstraints = false
        progressPill.layer.cornerRadius = 16
        applyFloatingStyle(to: progressPill, theme: theme)
        view.addSubview(progressPill)

        progressPillBlur = UIVisualEffectView(effect: blurEffect)
        progressPillBlur.translatesAutoresizingMaskIntoConstraints = false
        progressPillBlur.layer.cornerRadius = 16
        progressPillBlur.clipsToBounds = true
        progressPill.addSubview(progressPillBlur)

        progressPillVibrancy = UIVisualEffectView(effect: vibrancyEffect)
        progressPillVibrancy.translatesAutoresizingMaskIntoConstraints = false
        progressPillBlur.contentView.addSubview(progressPillVibrancy)

        progressPillLabel.text = "0%"
        progressPillLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        progressPillLabel.textAlignment = .center
        progressPillLabel.translatesAutoresizingMaskIntoConstraints = false
        progressPillVibrancy.contentView.addSubview(progressPillLabel)

        NSLayoutConstraint.activate([
            progressPillBlur.topAnchor.constraint(equalTo: progressPill.topAnchor),
            progressPillBlur.leadingAnchor.constraint(equalTo: progressPill.leadingAnchor),
            progressPillBlur.trailingAnchor.constraint(equalTo: progressPill.trailingAnchor),
            progressPillBlur.bottomAnchor.constraint(equalTo: progressPill.bottomAnchor),

            progressPillVibrancy.topAnchor.constraint(equalTo: progressPillBlur.contentView.topAnchor),
            progressPillVibrancy.leadingAnchor.constraint(equalTo: progressPillBlur.contentView.leadingAnchor),
            progressPillVibrancy.trailingAnchor.constraint(equalTo: progressPillBlur.contentView.trailingAnchor),
            progressPillVibrancy.bottomAnchor.constraint(equalTo: progressPillBlur.contentView.bottomAnchor),

            progressPillLabel.topAnchor.constraint(equalTo: progressPillVibrancy.contentView.topAnchor, constant: 7),
            progressPillLabel.bottomAnchor.constraint(equalTo: progressPillVibrancy.contentView.bottomAnchor, constant: -7),
            progressPillLabel.leadingAnchor.constraint(equalTo: progressPillVibrancy.contentView.leadingAnchor, constant: 14),
            progressPillLabel.trailingAnchor.constraint(equalTo: progressPillVibrancy.contentView.trailingAnchor, constant: -14),

            progressPill.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressPill.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            progressPill.heightAnchor.constraint(equalToConstant: 32)
        ])

        // === Menu Circle (bottom-right) ===
        menuCircle.translatesAutoresizingMaskIntoConstraints = false
        menuCircle.layer.cornerRadius = 25
        applyFloatingStyle(to: menuCircle, theme: theme)
        menuCircle.addTarget(self, action: #selector(menuCircleTapped), for: .touchUpInside)
        menuCircle.addTarget(self, action: #selector(chromeButtonHighlight(_:)), for: [.touchDown, .touchDragEnter])
        menuCircle.addTarget(self, action: #selector(chromeButtonUnhighlight(_:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit, .touchCancel])
        view.addSubview(menuCircle)

        menuCircleBlur = UIVisualEffectView(effect: blurEffect)
        menuCircleBlur.translatesAutoresizingMaskIntoConstraints = false
        menuCircleBlur.layer.cornerRadius = 25
        menuCircleBlur.clipsToBounds = true
        menuCircleBlur.isUserInteractionEnabled = false
        menuCircle.addSubview(menuCircleBlur)

        menuCircleTint.translatesAutoresizingMaskIntoConstraints = false
        menuCircleTint.backgroundColor = theme.isDark ? theme.chromeTintColor.withAlphaComponent(0.10) : UIColor.white.withAlphaComponent(0.35)
        menuCircleTint.isUserInteractionEnabled = false
        menuCircleBlur.contentView.addSubview(menuCircleTint)

        menuCircleVibrancy = UIVisualEffectView(effect: vibrancyEffect)
        menuCircleVibrancy.translatesAutoresizingMaskIntoConstraints = false
        menuCircleVibrancy.isUserInteractionEnabled = false
        menuCircleBlur.contentView.addSubview(menuCircleVibrancy)

        let menuIconConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .heavy)
        menuCircleIcon.image = UIImage(systemName: "list.bullet", withConfiguration: menuIconConfig)
        menuCircleIcon.contentMode = .scaleAspectFit
        menuCircleIcon.translatesAutoresizingMaskIntoConstraints = false
        menuCircleIcon.isUserInteractionEnabled = false
        menuCircleVibrancy.contentView.addSubview(menuCircleIcon)

        NSLayoutConstraint.activate([
            menuCircleBlur.topAnchor.constraint(equalTo: menuCircle.topAnchor),
            menuCircleBlur.leadingAnchor.constraint(equalTo: menuCircle.leadingAnchor),
            menuCircleBlur.trailingAnchor.constraint(equalTo: menuCircle.trailingAnchor),
            menuCircleBlur.bottomAnchor.constraint(equalTo: menuCircle.bottomAnchor),

            menuCircleTint.topAnchor.constraint(equalTo: menuCircleBlur.contentView.topAnchor),
            menuCircleTint.leadingAnchor.constraint(equalTo: menuCircleBlur.contentView.leadingAnchor),
            menuCircleTint.trailingAnchor.constraint(equalTo: menuCircleBlur.contentView.trailingAnchor),
            menuCircleTint.bottomAnchor.constraint(equalTo: menuCircleBlur.contentView.bottomAnchor),

            menuCircleVibrancy.topAnchor.constraint(equalTo: menuCircleBlur.contentView.topAnchor),
            menuCircleVibrancy.leadingAnchor.constraint(equalTo: menuCircleBlur.contentView.leadingAnchor),
            menuCircleVibrancy.trailingAnchor.constraint(equalTo: menuCircleBlur.contentView.trailingAnchor),
            menuCircleVibrancy.bottomAnchor.constraint(equalTo: menuCircleBlur.contentView.bottomAnchor),

            menuCircleIcon.centerXAnchor.constraint(equalTo: menuCircleVibrancy.contentView.centerXAnchor),
            menuCircleIcon.centerYAnchor.constraint(equalTo: menuCircleVibrancy.contentView.centerYAnchor),

            menuCircle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            menuCircle.centerYAnchor.constraint(equalTo: progressPill.centerYAnchor),
            menuCircle.widthAnchor.constraint(equalToConstant: 50),
            menuCircle.heightAnchor.constraint(equalToConstant: 50)
        ])

        // All floating elements start hidden
        titlePill.alpha = 0
        closeButton.alpha = 0
        progressPill.alpha = 0
        menuCircle.alpha = 0
    }

    /// Applies border + shadow styling to a floating chrome element.
    private func applyFloatingStyle(to element: UIView, theme: ReadingTheme) {
        element.layer.borderWidth = 0.5
        if theme.isDark {
            element.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
            element.layer.shadowOpacity = 0
        } else {
            element.layer.borderColor = UIColor.black.withAlphaComponent(0.10).cgColor
            element.layer.shadowColor = UIColor.black.cgColor
            element.layer.shadowOpacity = 0.10
            element.layer.shadowRadius = 8
            element.layer.shadowOffset = CGSize(width: 0, height: 4)
        }
    }

    private func resolvedMenuPalette(theme: ReadingTheme) -> MenuPalette {
        let isDarkAppearance = traitCollection.userInterfaceStyle == .dark
        if isDarkAppearance {
            return MenuPalette(
                itemTextIconColor: Colours.textPrimary,
                separatorColor: UIColor.separator.withAlphaComponent(0.40),
                actionButtonTintColor: Colours.textPrimary,
                actionButtonBackgroundColor: Colours.textPrimary.withAlphaComponent(0.16),
                menuSurfaceTintColor: UIColor.black.withAlphaComponent(0.14)
            )
        }

        return MenuPalette(
            itemTextIconColor: theme.chromeTintColor,
            separatorColor: theme.textColor.withAlphaComponent(0.15),
            actionButtonTintColor: theme.chromeTintColor,
            actionButtonBackgroundColor: theme.chromeTintColor.withAlphaComponent(theme.isDark ? 0.12 : 0.08),
            menuSurfaceTintColor: UIColor.white.withAlphaComponent(0.04)
        )
    }

    private func applyMenuSurfaceTint(theme: ReadingTheme) {
        let palette = resolvedMenuPalette(theme: theme)
        menuSurfaceTintView.backgroundColor = palette.menuSurfaceTintColor
    }

    private func setupMenuView() {
        let theme = ReadingUserDefaults.theme

        // Dimming gradient overlay behind menu (stronger at bottom, clear at top)
        menuDimmingView.backgroundColor = .clear
        menuDimmingView.alpha = 0
        menuDimmingView.translatesAutoresizingMaskIntoConstraints = false
        menuDimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped)))
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.black.withAlphaComponent(0).cgColor, UIColor.black.cgColor]
        gradient.locations = [0.35, 1.0]
        menuDimmingView.layer.addSublayer(gradient)
        menuDimmingGradient = gradient
        view.addSubview(menuDimmingView)
        NSLayoutConstraint.activate([
            menuDimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            menuDimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            menuDimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            menuDimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        menuContainerView.translatesAutoresizingMaskIntoConstraints = false
        menuContainerView.clipsToBounds = true
        menuContainerView.layer.cornerRadius = 16
        menuContainerView.alpha = 0
        view.addSubview(menuContainerView)

        menuBlurView = UIVisualEffectView(effect: UIBlurEffect(style: theme.chromeBlurStyle))
        menuBlurView.translatesAutoresizingMaskIntoConstraints = false
        menuContainerView.addSubview(menuBlurView)

        menuSurfaceTintView.translatesAutoresizingMaskIntoConstraints = false
        menuSurfaceTintView.isUserInteractionEnabled = false
        menuBlurView.contentView.addSubview(menuSurfaceTintView)

        menuStackView.axis = .vertical
        menuStackView.translatesAutoresizingMaskIntoConstraints = false
        menuContainerView.addSubview(menuStackView)

        NSLayoutConstraint.activate([
            menuBlurView.topAnchor.constraint(equalTo: menuContainerView.topAnchor),
            menuBlurView.leadingAnchor.constraint(equalTo: menuContainerView.leadingAnchor),
            menuBlurView.trailingAnchor.constraint(equalTo: menuContainerView.trailingAnchor),
            menuBlurView.bottomAnchor.constraint(equalTo: menuContainerView.bottomAnchor),

            menuSurfaceTintView.topAnchor.constraint(equalTo: menuBlurView.contentView.topAnchor),
            menuSurfaceTintView.leadingAnchor.constraint(equalTo: menuBlurView.contentView.leadingAnchor),
            menuSurfaceTintView.trailingAnchor.constraint(equalTo: menuBlurView.contentView.trailingAnchor),
            menuSurfaceTintView.bottomAnchor.constraint(equalTo: menuBlurView.contentView.bottomAnchor),

            menuStackView.topAnchor.constraint(equalTo: menuContainerView.topAnchor),
            menuStackView.leadingAnchor.constraint(equalTo: menuContainerView.leadingAnchor),
            menuStackView.trailingAnchor.constraint(equalTo: menuContainerView.trailingAnchor),
            menuStackView.bottomAnchor.constraint(equalTo: menuContainerView.bottomAnchor),

            menuContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            menuContainerView.bottomAnchor.constraint(equalTo: menuCircle.topAnchor, constant: -12),
            menuContainerView.widthAnchor.constraint(equalToConstant: 260)
        ])

        applyMenuSurfaceTint(theme: theme)
    }

    private func setupFloatingRecapButton() {
        view.addSubviewForConstraints(floatingRecapButton)
        NSLayoutConstraint.activate([
            floatingRecapButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            floatingRecapButton.topAnchor.constraint(equalTo: titlePill.bottomAnchor, constant: recapBelowTitleSpacing)
        ])

        floatingRecapButton.alpha = 0
        floatingRecapButton.transform = CGAffineTransform(translationX: 0, y: -60)

        floatingRecapButton.onTap = { [weak self] in
            self?.showRecapSheet()
        }
    }

    private func showRecapSheet() {
        floatingRecapButton.animateOut()
        isRecapButtonVisible = false

        let recapVC = RecapSheetVC(metadata: metadata, content: content)
        present(recapVC, animated: true)
    }
}

// MARK: - Chrome Toggle & Auto-Hide
extension ReadingVC {

    func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleReadingAreaTap(_:)))
        tapGesture.delegate = self
        tapGesture.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tapGesture)
    }

    @objc private func handleReadingAreaTap(_ gesture: UITapGestureRecognizer) {
        if isMenuVisible {
            dismissMenu()
            return
        }

        let wasChromeVisible = isChromeVisible
        toggleChrome()
        if !wasChromeVisible {
            markChromeRevealLearnedIfNeeded()
        }
    }

    private func toggleChrome() {
        isChromeVisible ? hideChrome(animated: true) : showChrome(animated: true)
    }

    func showChrome(animated: Bool) {
        isChromeVisible = true
        setNeedsStatusBarAppearanceUpdate()
        setNeedsUpdateOfHomeIndicatorAutoHidden()

        let duration = animated ? 0.3 : 0
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
            self.statusBarBackground.alpha = 1
            self.titlePill.alpha = 1
            self.closeButton.alpha = 1
            self.progressPill.alpha = 1
            self.menuCircle.alpha = 1
        }

        startAutoHideTimer()
    }

    func hideChrome(animated: Bool) {
        isChromeVisible = false
        isMenuVisible = false
        cancelAutoHideTimer()
        stopMenuCirclePulseHint()
        setNeedsStatusBarAppearanceUpdate()
        setNeedsUpdateOfHomeIndicatorAutoHidden()

        let duration = animated ? 0.25 : 0
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn) {
            self.statusBarBackground.alpha = 0
            self.titlePill.alpha = 0
            self.closeButton.alpha = 0
            self.progressPill.alpha = 0
            self.menuCircle.alpha = 0
            self.menuContainerView.alpha = 0
        }
    }

    private func startAutoHideTimer(duration: TimeInterval? = nil) {
        cancelAutoHideTimer()
        let resolvedDuration = duration ?? chromeAutoHideDuration
        chromeAutoHideTimer = Timer.scheduledTimer(withTimeInterval: resolvedDuration, repeats: false) { [weak self] _ in
            self?.hideChrome(animated: true)
        }
    }

    func cancelAutoHideTimer() {
        chromeAutoHideTimer?.invalidate()
        chromeAutoHideTimer = nil
    }

    @objc private func chromeButtonHighlight(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
            sender.alpha = 0.7
        }
    }

    @objc private func chromeButtonUnhighlight(_ sender: UIButton) {
        UIView.animate(withDuration: 0.15) {
            sender.transform = .identity
            sender.alpha = 1.0
        }
    }

    private func resetAutoHideTimer() {
        if isChromeVisible {
            startAutoHideTimer()
        }
    }

    private func maybeRunFirstRunChromeReveal() {
        guard !FirstTimeManager.hasSeen(item: .readingChromeRevealLearned) else { return }

        cancelAutoRevealOnboarding()
        let revealWorkItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.showChrome(animated: true)
            self.startAutoHideTimer(duration: self.autoRevealVisibleDuration)
            self.startMenuCirclePulseHint()
            AnalyticsManager.shared.trackReadingOnboardingAutoRevealShown()
        }

        autoRevealStartWorkItem = revealWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + autoRevealDelay, execute: revealWorkItem)
    }

    private func markChromeRevealLearnedIfNeeded() {
        guard !hasMarkedChromeRevealLearnedThisSession else { return }
        guard !FirstTimeManager.hasSeen(item: .readingChromeRevealLearned) else { return }

        hasMarkedChromeRevealLearnedThisSession = true
        FirstTimeManager.markSeen(item: .readingChromeRevealLearned)
        AnalyticsManager.shared.trackReadingOnboardingLearned()
        cancelAutoRevealOnboarding()
    }

    private func cancelAutoRevealOnboarding() {
        autoRevealStartWorkItem?.cancel()
        autoRevealStartWorkItem = nil
        stopMenuCirclePulseHint()
    }

    private func startMenuCirclePulseHint() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        guard menuCircle.layer.animation(forKey: menuPulseAnimationKey) == nil else { return }

        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.values = [1.0, menuPulseScale, 1.0]
        scaleAnimation.keyTimes = [0.0, 0.5, 1.0]
        scaleAnimation.duration = menuPulseDuration
        scaleAnimation.repeatCount = 2
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.values = [1.0, 0.86, 1.0]
        opacityAnimation.keyTimes = [0.0, 0.5, 1.0]
        opacityAnimation.duration = menuPulseDuration
        opacityAnimation.repeatCount = 2
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let pulseGroup = CAAnimationGroup()
        pulseGroup.animations = [scaleAnimation, opacityAnimation]
        pulseGroup.duration = menuPulseDuration
        pulseGroup.repeatCount = 2
        pulseGroup.isRemovedOnCompletion = true

        menuCircle.layer.add(pulseGroup, forKey: menuPulseAnimationKey)
    }

    private func stopMenuCirclePulseHint() {
        menuCircle.layer.removeAnimation(forKey: menuPulseAnimationKey)
    }
}

// MARK: - Navigation & Menu Actions
extension ReadingVC {

    @objc func popVC() {
        let progress = ReadingUserDefaults.progressForBookWithUUID(metadata.contentUUID) ?? 0
        let shouldPromptCompletion = isOnLastChapter &&
            !metadata.isCompleted() &&
            metadata.contentType == .bookInternal &&
            (progress > 98 || didReach100Percent)

        if shouldPromptCompletion {
            checkAndPromptForCompletion()
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    @objc private func dimmingViewTapped() {
        dismissMenu()
    }

    @objc private func menuCircleTapped() {
        stopMenuCirclePulseHint()
        if isMenuVisible {
            dismissMenu()
        } else {
            showMenu()
        }
    }

    private func showMenu() {
        guard !isMenuVisible else { return }
        isMenuVisible = true
        cancelAutoHideTimer()

        let theme = ReadingUserDefaults.theme
        rebuildMenuItems(theme: theme)

        // Dim background (higher values needed since gradient is transparent at top)
        let dimAlpha: CGFloat = theme.isDark ? 0.45 : 0.30
        UIView.animate(withDuration: 0.2) {
            self.menuDimmingView.alpha = dimAlpha
        }

        // Staggered row-by-row animation
        menuContainerView.alpha = 1
        menuContainerView.transform = .identity

        let rows = menuStackView.arrangedSubviews
        for row in rows {
            row.alpha = 0
            row.transform = CGAffineTransform(translationX: 0, y: 12)
        }

        for (index, row) in rows.enumerated() {
            let delay = Double(index) * 0.04
            UIView.animate(withDuration: 0.35, delay: delay, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
                row.alpha = 1
                row.transform = .identity
            }
        }
    }

    private func rebuildMenuItems(theme: ReadingTheme) {
        applyMenuSurfaceTint(theme: theme)

        // Clear previous menu items
        menuStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        menuActions.removeAll()

        // Contents (chapters list)
        if content.sectionsArray.count > 1 {
            addMenuItem(title: "Chapters", iconName: "list.bullet", theme: theme) { [weak self] in
                self?.tappedChaptersButton()
            }
        }

        // Themes & Settings
        let customiseText = Locale.isUK ? "Customise" : "Customize"
        addMenuItem(title: "\(customiseText) View", iconName: "textformat.size", theme: theme) { [weak self] in
            self?.tappedCustomizeReaderButton()
        }

        // Upgrade (non-subscribers only)
        if !AccountManager.shared.userIsSubscribed {
            addMenuItem(title: "Upgrade to Plus", iconName: "crown", theme: theme) { [weak self] in
                guard let self else { return }
                self.displayPaywall(placement: .readingUpgradeNavIcon, bookInternal: self.metadata as? CDBookInternal)
            }
        }

        // Restart Book
        addMenuItem(title: "Restart Book", iconName: "arrow.counterclockwise", theme: theme, isDestructive: true) { [weak self] in
            self?.showRestartAreYouSureAlert()
        }

        // Bottom action bar (Share + Bookmark)
        addMenuActionBar(theme: theme)
    }

    private func dismissMenu() {
        guard isMenuVisible else { return }
        isMenuVisible = false

        let rows = menuStackView.arrangedSubviews
        let totalRows = rows.count
        let totalDuration = Double(totalRows) * 0.03 + 0.25

        // Stagger rows out bottom-to-top
        for (index, row) in rows.reversed().enumerated() {
            let delay = Double(index) * 0.03
            UIView.animate(withDuration: 0.25, delay: delay, options: .curveEaseIn) {
                row.alpha = 0
                row.transform = CGAffineTransform(translationX: 0, y: 8)
            } completion: { _ in
                row.transform = .identity
            }
        }

        // Fade the blur container and dimming view out in parallel
        UIView.animate(withDuration: totalDuration, delay: 0, options: .curveEaseIn) {
            self.menuContainerView.alpha = 0
            self.menuDimmingView.alpha = 0
        }

        resetAutoHideTimer()
    }

    private func addMenuItem(title: String, iconName: String, theme: ReadingTheme, isDestructive: Bool = false, action: @escaping () -> Void) {
        let palette = resolvedMenuPalette(theme: theme)

        // Add separator if not first item
        if !menuStackView.arrangedSubviews.isEmpty {
            let separator = UIView()
            separator.backgroundColor = palette.separatorColor
            separator.translatesAutoresizingMaskIntoConstraints = false
            separator.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true
            menuStackView.addArrangedSubview(separator)
        }

        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = isDestructive ? .systemRed : palette.itemTextIconColor
        label.translatesAutoresizingMaskIntoConstraints = false

        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        let icon = UIImageView(image: UIImage(systemName: iconName, withConfiguration: config))
        icon.tintColor = isDestructive ? .systemRed : palette.itemTextIconColor
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(label)
        row.addSubview(icon)

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 48),
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            icon.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            icon.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 20),
            label.trailingAnchor.constraint(lessThanOrEqualTo: icon.leadingAnchor, constant: -8)
        ])

        row.tag = menuActions.count
        let tap = UITapGestureRecognizer(target: self, action: #selector(menuItemTapped(_:)))
        row.addGestureRecognizer(tap)
        row.isUserInteractionEnabled = true

        menuStackView.addArrangedSubview(row)
        menuActions.append(action)
    }

    @objc private func menuItemTapped(_ gesture: UITapGestureRecognizer) {
        guard let row = gesture.view else { return }
        let index = row.tag
        guard index >= 0, index < menuActions.count else { return }
        let action = menuActions[index]
        dismissMenu()
        action()
    }

    private func addMenuActionBar(theme: ReadingTheme) {
        let palette = resolvedMenuPalette(theme: theme)

        let separator = UIView()
        separator.backgroundColor = palette.separatorColor
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        menuStackView.addArrangedSubview(separator)

        let barContainer = UIView()
        barContainer.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        barContainer.addSubview(stack)

        func makeActionButton(iconName: String, tag: Int) -> UIButton {
            let btn = UIButton(type: .custom)
            btn.translatesAutoresizingMaskIntoConstraints = false
            let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
            btn.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
            btn.tintColor = palette.actionButtonTintColor
            btn.backgroundColor = palette.actionButtonBackgroundColor
            btn.layer.cornerRadius = 24
            btn.clipsToBounds = true
            btn.tag = tag
            btn.addTarget(self, action: #selector(menuActionBarTapped(_:)), for: .touchUpInside)
            NSLayoutConstraint.activate([
                btn.widthAnchor.constraint(equalToConstant: 48),
                btn.heightAnchor.constraint(equalToConstant: 48)
            ])
            return btn
        }

        let shareButton = makeActionButton(iconName: "square.and.arrow.up", tag: 0)
        let bookmarkButton = makeActionButton(iconName: "bookmark", tag: 1)

        stack.addArrangedSubview(shareButton)
        stack.addArrangedSubview(bookmarkButton)

        NSLayoutConstraint.activate([
            barContainer.heightAnchor.constraint(equalToConstant: 68),
            stack.centerXAnchor.constraint(equalTo: barContainer.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: barContainer.centerYAnchor)
        ])

        menuStackView.addArrangedSubview(barContainer)
    }

    @objc private func menuActionBarTapped(_ sender: UIButton) {
        dismissMenu()
        switch sender.tag {
        case 0: shareBookFromReader()
        case 1: tappedBookmarkButton()
        default: break
        }
    }

    private func shareBookFromReader() {
        guard let sharingURL = metadata.sharingDeeplinkURL else { return }
        var shareText = "Check out this story"
        if let title = metadata.title { shareText += ": \"\(title)\"" }
        shareText += " on FreeAudiobooks!\n\n\(sharingURL)"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        present(activityVC, animated: true)
    }

    @objc func showRestartAreYouSureAlert() {
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let restartAction = UIAlertAction(title: "Restart", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                ReadingUserDefaults.clearOffsetForBookWithUUID(self.metadata.contentUUID)
                self.currentSection = 0
            }
        }
        let alertController = UIAlertController(title: "Are you sure?", message: "Are you sure you wish to restart this book? This action cannot be undone.", preferredStyle: .alert)
        alertController.addAction(cancelAction)
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }

}

extension ReadingVC {
    func displayPaywall(placement: PaywallPlacement, bookInternal: CDBookInternal?) {
        let handler = PaywallPresentationHandler()
        handler.onPresent { _ in
            DispatchQueue.main.async {
                AnalyticsManager.shared.trackPaywallViewedForPlacement(placement)
            }
        }
        handler.onDismiss { [weak self] _, result in
            guard let self else { return }
            DispatchQueue.main.async {
                switch result {
                case .declined:
                    print("No purchased occurred.")
                    self.handleDidNotSubscribe(placement: placement)
                case .purchased(let product):
                    print("Purchased \(product.productIdentifier)")                    
                    AnalyticsManager.shared.trackPaywallUserSubscribed(placement: placement, cdBookInternal: bookInternal)
                    self.showSubscribeSuccessPopup()
                    self.handleSubscribed(placement: placement)
                case .restored:
                    print("Restored purchases.")
                    AnalyticsManager.shared.trackPaywallRestorePurchasesSuccess()
                    self.handleSubscribed(placement: placement)
                }
            }
        }
        Superwall.shared.register(placement: placement.rawValue, params: nil, handler: handler)
    }
    func handleSubscribed(placement: PaywallPlacement) {
        // Menu reads subscription state dynamically — no UI rebuild needed
    }
    func handleDidNotSubscribe(placement: PaywallPlacement) {
        // No action needed
    }
}

// MARK: - Reader Actions (Bookmark, Chapters, Font, Chevrons)
extension ReadingVC {
    @objc func tappedBookmarkButton() {

        let title = "Bookmark Added"
        let message = "We've saved your position in this book for when you next return!"
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default) { tappedYes in
            DispatchQueue.main.async {
                SKReviewManager.requestReview(venue: .bookmarkPosition)
            }
        }
        controller.addAction(okAction)
        controller.preferredAction = okAction
        self.present(controller, animated: true, completion: nil)

        updateReadingOffset()
    }
    @objc func tappedChaptersButton() {
        let chaptersVC = ReadingChaptersListVC(
            totalSections: content.sectionsArray.count,
            currentSection: currentSection,
            contentType: metadata.contentType
        )

        chaptersVC.selectChapterHandler = { [weak self] selectedIndex in
            guard let self else { return }
            DispatchQueue.main.async {
                self.dismiss(animated: true) {
                    if selectedIndex != self.currentSection {
                        let isMovingForward = selectedIndex > self.currentSection
                        let shouldShowPushPrePromptForSectionChange = self.shouldShowPushPrePrompt

                        self.currentSection = selectedIndex

                        if isMovingForward {
                            SessionTrackingManager.shared.incrementSectionCount()

                            if shouldShowPushPrePromptForSectionChange {
                                self.showPushPrePrompt()
                            } else {
                                self.presentInterstitialAdIfNecessary()
                            }
                        }

                        self.updateReadingOffset()
                    }
                }
            }
        }

        chaptersVC.dismissHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.dismiss(animated: true)
            }
        }

        chaptersVC.preferredSheetSizing = .medium
        self.present(chaptersVC, animated: true)
    }
    @objc func tappedCustomizeReaderButton() {
        upwardScrollDistance = 0

        let viewController = ReadingConfigPreferencesVC()

        // Store original settings to restore if user dismisses without applying
        let originalTheme = ReadingUserDefaults.theme
        let originalFont = ReadingUserDefaults.font
        let originalTextSize = ReadingUserDefaults.textSize
        let originalParagraphStyle = ReadingUserDefaults.paragraphStyle

        // Temporary preview values
        var previewTheme = originalTheme
        var previewFont = originalFont
        var previewTextSize = originalTextSize
        var previewParagraphStyle = originalParagraphStyle

        viewController.resetHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.dismiss(animated: true) {
                    self.showResetPreferencesPopup()
                }
            }
        }
        viewController.applyHandler = { [weak self] in
            guard let self else { return }
            // Save the preview values to UserDefaults
            ReadingUserDefaults.theme = previewTheme
            ReadingUserDefaults.font = previewFont
            ReadingUserDefaults.textSize = previewTextSize
            ReadingUserDefaults.paragraphStyle = previewParagraphStyle
            DispatchQueue.main.async {
                self.dismiss(animated: true)
            }
        }

        viewController.selectThemeHandler = { [weak self] theme in
            guard let self else { return }
            previewTheme = theme
            DispatchQueue.main.async {
                self.updateUIForReadingPreferences(previewTheme: previewTheme, previewFont: previewFont, previewTextSize: previewTextSize, previewParagraphStyle: previewParagraphStyle, persistReadingOffset: true)
            }
        }
        viewController.selectFontHandler = { [weak self] font in
            guard let self else { return }
            previewFont = font
            DispatchQueue.main.async {
                self.updateUIForReadingPreferences(previewTheme: previewTheme, previewFont: previewFont, previewTextSize: previewTextSize, previewParagraphStyle: previewParagraphStyle, persistReadingOffset: true)
            }
        }
        viewController.selectTextSizeHandler = { [weak self] textSize in
            guard let self else { return }
            previewTextSize = textSize
            DispatchQueue.main.async {
                self.updateUIForReadingPreferences(previewTheme: previewTheme, previewFont: previewFont, previewTextSize: previewTextSize, previewParagraphStyle: previewParagraphStyle, persistReadingOffset: true)
            }
        }
        viewController.selectParagraphStyleHandler = { [weak self] style in
            guard let self else { return }
            previewParagraphStyle = style
            DispatchQueue.main.async {
                self.updateUIForReadingPreferences(previewTheme: previewTheme, previewFont: previewFont, previewTextSize: previewTextSize, previewParagraphStyle: previewParagraphStyle, persistReadingOffset: true)
            }
        }

        // Reset to original settings if dismissed without applying
        viewController.dismissHandler = { [weak self] in
            guard let self else { return }
            // Restore original UI if user dismisses without applying
            DispatchQueue.main.async {
                self.updateUIForReadingPreferences(persistReadingOffset: true)
                self.dismiss(animated: true)
            }
        }

        viewController.preferredSheetSizing = .fill
        self.present(viewController, animated: true)
    }
    @objc func tappedChevronLeftButton() {
        resetAutoHideTimer()
        let nextChapter = currentSection - 1
        if nextChapter >= 0 {
            currentSection = nextChapter
        }
        updateReadingOffset()
    }
    @objc func tappedChevronRightButton() {
        resetAutoHideTimer()
        let nextChapter = currentSection + 1
        if nextChapter < content.sectionsArray.count {
            let shouldShowPushPrePromptForSectionChange = shouldShowPushPrePrompt
            currentSection = nextChapter

            SessionTrackingManager.shared.incrementSectionCount()

            if shouldShowPushPrePromptForSectionChange {
                DispatchQueue.main.async { [weak self] in
                    self?.showPushPrePrompt()
                }
            } else {
                presentInterstitialAdIfNecessary()
            }
        }
        updateReadingOffset()
    }
    func showBookCompletionPopup() {
        let reviewedContentType: ReviewedContentType = .bookInternal
        
        let dismissAction: () -> Void = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.dismiss(animated: true) {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }

        let popupVC = EnhancedBookCompletionPopupVC(metadata: metadata, reviewedContentType: reviewedContentType)
        popupVC.dismissHandler = dismissAction
        popupVC.preferredSheetSizing = .fit
        popupVC.panToDismissEnabled = false
        popupVC.tapToDismissEnabled = false

        self.present(popupVC, animated: true)
    }

    func checkAndPromptForCompletion() {
        let title = "Finish this book?"
        let message = "It looks like you've reached the end. Would you like to mark this book as completed?"
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let notYetAction = UIAlertAction(title: "Not Yet", style: .cancel) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }

        let finishedAction = UIAlertAction(title: "Yes, I Finished It", style: .default) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.markMetadataCompleted()
                self.showBookCompletionPopup()
            }
        }

        controller.addAction(notYetAction)
        controller.addAction(finishedAction)
        controller.preferredAction = finishedAction

        self.present(controller, animated: true, completion: nil)
    }

    func markMetadataCompleted() {
        metadata.markCompleted()
        ReadingUserDefaults.clearResumeReading()
        AppNotifiers.shared.shouldReloadSearchResultsVC = true
        AppNotifiers.shared.shouldReloadHomeVC = true
    }
    private func updateSectionFooter(theme: ReadingTheme? = nil) {
        let resolvedTheme = theme ?? ReadingUserDefaults.theme

        // Update blur + vibrancy effects
        let blurEffect = UIBlurEffect(style: resolvedTheme.chromeBlurStyle)
        sectionFooterBlur?.effect = blurEffect
        sectionFooterVibrancy?.effect = UIVibrancyEffect(blurEffect: blurEffect, style: .label)

        // Update border + shadow
        applyFloatingStyle(to: sectionFooterContainer, theme: resolvedTheme)

        // Prev button state
        prevButton.isHidden = currentSection == 0

        // Next button title + icon
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        if isOnLastChapter {
            nextButton.setTitle("Mark Completed ", for: .normal)
            nextButton.setImage(UIImage(systemName: "checkmark", withConfiguration: iconConfig), for: .normal)
        } else {
            nextButton.setTitle("Next Chapter ", for: .normal)
            nextButton.setImage(UIImage(systemName: "chevron.right", withConfiguration: iconConfig), for: .normal)
        }

        // Hide footer for single-section completed books
        if content.sectionsArray.count <= 1 && metadata.isCompleted() {
            sectionFooterContainer.isHidden = true
        } else {
            sectionFooterContainer.isHidden = false
        }
    }

    @objc private func sectionFooterNextTapped() {
        if isOnLastChapter {
            if !metadata.isCompleted() {
                markMetadataCompleted()
                showBookCompletionPopup()
            } else {
                // Should never be here, this is just a safety net.
                navigationController?.popViewController(animated: true)
            }
        } else {
            hideChrome(animated: true)
            tappedChevronRightButton()
        }
    }

    @objc private func sectionFooterPrevTapped() {
        hideChrome(animated: true)
        tappedChevronLeftButton()
    }
    func showResetPreferencesPopup() {
        let title = "Reset Preferences"
        let message = "Would you like to reset all reading preferences to their default values?"
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let noAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let yesAction = UIAlertAction(title: "Reset", style: .destructive) { [weak self] tappedYes in
            guard let self = self else { return }
            DispatchQueue.main.async {
                ReadingUserDefaults.resetReadingPreferencesToDefaults()
                self.updateUIForReadingPreferences(persistReadingOffset: true)
            }
        }
        controller.addAction(noAction)
        controller.addAction(yesAction)
        self.present(controller, animated: true, completion: nil)
    }
}

extension ReadingVC {
    func updateUIForReadingPreferences(previewTheme: ReadingTheme? = nil, previewFont: ReadingFont? = nil, previewTextSize: ReadingTextSize? = nil, previewParagraphStyle: ReadingParagraphStyle? = nil, persistReadingOffset: Bool = false) {
        let theme = previewTheme ?? ReadingUserDefaults.theme
        let font = previewFont ?? ReadingUserDefaults.font
        let textSize = previewTextSize ?? ReadingUserDefaults.textSize
        let paragraphStyle = previewParagraphStyle ?? ReadingUserDefaults.paragraphStyle

        // Full-screen background
        view.backgroundColor = theme.backgroundColor
        navigationController?.view.backgroundColor = theme.backgroundColor

        [scrollView, contentView, contentTextView].forEach {
            $0.backgroundColor = theme.backgroundColor
        }

        // Re-apply formatted content with new preferences
        guard currentSection >= 0, currentSection < content.sectionsArray.count else {
            return
        }
        let currentSectionText = content.sectionsArray[currentSection]
        // `persistReadingOffset` is true only during live preferences interactions.
        // Initial render uses the non-persisting path so existing resume position is not overwritten.
        if persistReadingOffset {
            // Capture position against the pre-change layout, then restore after reflow.
            let normalizedOffset = normalizedReadingOffsetY()
            contentTextView.attributedText = formattedContent(for: currentSectionText, theme: theme, font: font, textSize: textSize, paragraphStyle: paragraphStyle)

            // Recompute layout so content size/max offset are up to date for restoration.
            view.layoutIfNeeded()
            restoreReadingOffsetY(fromNormalized: normalizedOffset)

            // Persist only for user-driven preference changes (not initial screen setup).
            updateReadingOffset()
        } else {
            // Initial render path: apply styling only, without touching saved resume offset.
            contentTextView.attributedText = formattedContent(for: currentSectionText, theme: theme, font: font, textSize: textSize, paragraphStyle: paragraphStyle)
        }

        floatingRecapButton.updateTheme(theme)

        // Overlay theming
        updateOverlayTheme(theme)

        // Status bar style
        setNeedsStatusBarAppearanceUpdate()
    }

    private func readingOffsetBoundsY() -> (min: CGFloat, max: CGFloat) {
        let minOffsetY = -scrollView.contentInset.top
        let maxOffsetY = max(scrollView.maxContentOffset.y, minOffsetY)
        return (min: minOffsetY, max: maxOffsetY)
    }

    private func normalizedReadingOffsetY() -> CGFloat {
        let bounds = readingOffsetBoundsY()
        let denominator = max(bounds.max - bounds.min, 1)
        let normalized = (scrollView.contentOffset.y - bounds.min) / denominator
        return min(max(normalized, 0), 1)
    }

    private func restoreReadingOffsetY(fromNormalized normalized: CGFloat) {
        let clampedNormalized = min(max(normalized, 0), 1)
        let bounds = readingOffsetBoundsY()
        let restoredY = bounds.min + clampedNormalized * (bounds.max - bounds.min)
        let clampedY = min(max(restoredY, bounds.min), bounds.max)
        scrollView.setContentOffset(CGPoint(x: 0, y: clampedY), animated: false)
    }

    private func updateOverlayTheme(_ theme: ReadingTheme) {
        let blurEffect = UIBlurEffect(style: theme.chromeBlurStyle)
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect, style: .label)

        // Status bar background matches theme
        statusBarBackground.backgroundColor = theme.backgroundColor

        // Update blur effects on floating elements
        titlePillBlur?.effect = blurEffect
        closeButtonBlur?.effect = blurEffect
        progressPillBlur?.effect = blurEffect
        menuCircleBlur?.effect = blurEffect
        menuBlurView?.effect = blurEffect
        applyMenuSurfaceTint(theme: theme)

        // Update vibrancy effects (depend on blur effect)
        titlePillVibrancy?.effect = vibrancyEffect
        closeButtonVibrancy?.effect = vibrancyEffect
        progressPillVibrancy?.effect = vibrancyEffect
        menuCircleVibrancy?.effect = vibrancyEffect

        // Update border + shadow for all floating elements
        applyFloatingStyle(to: titlePill, theme: theme)
        applyFloatingStyle(to: closeButton, theme: theme)
        applyFloatingStyle(to: progressPill, theme: theme)
        applyFloatingStyle(to: menuCircle, theme: theme)

        // Update tint overlays on buttons
        if theme.isDark {
            closeButtonTint.backgroundColor = theme.chromeTintColor.withAlphaComponent(0.10)
            menuCircleTint.backgroundColor = theme.chromeTintColor.withAlphaComponent(0.10)
        } else {
            closeButtonTint.backgroundColor = UIColor.white.withAlphaComponent(0.35)
            menuCircleTint.backgroundColor = UIColor.white.withAlphaComponent(0.35)
        }

        if isMenuVisible {
            rebuildMenuItems(theme: theme)
        }

        // Theme chevrons in content
        updateSectionFooter(theme: theme)
    }
}

// MARK: - Push Pre-Permission Prompt
extension ReadingVC {
    private func showPushPrePrompt() {
        AccountManager.shared.pushNotificationsStatus { [weak self] status in
            guard let self else { return }
            DispatchQueue.main.async {
                if status == .notDetermined {
                    self.presentPushPrePromptBottomSheet()
                } else {
                    self.presentInterstitialAdIfNecessary()
                }
            }
        }
    }

    private func presentPushPrePromptBottomSheet() {
        let vc = PushPrePromptVC()

        vc.enableHandler = { [weak self] in
            AnalyticsManager.shared.trackPushPrePromptEnableTapped()
            self?.dismiss(animated: true) {
                self?.requestPushPermission()
            }
        }

        vc.dismissHandler = { [weak self] in
            PushPrePromptUserDefaults.recordDismissal()
            AnalyticsManager.shared.trackPushPrePromptNotNowTapped()
            self?.dismiss(animated: true)
        }

        AnalyticsManager.shared.trackPushPrePromptViewed()

        present(vc, animated: true)
    }

    private func requestPushPermission() {
        // Record for email opt-in guardrail when system prompt is shown
        EmailOptInUserDefaults.recordPushPromptShown()

        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { [weak self] granted, _ in
            DispatchQueue.main.async {
                if granted {
                    let appDelegate = UIApplication.shared.delegate as? AppDelegate
                    appDelegate?.registerForFreeAudiobooksRemoteNotifications()
                    AnalyticsManager.shared.trackPushPermissionGranted()

                    if let self {
                        let progress = ReadingUserDefaults.progressForBookWithUUID(self.metadata.contentUUID) ?? 0
                        EngagementEngine.recordBookProgress(
                            metadata: self.metadata,
                            progressPercentage: progress,
                            forceNotification: true
                        )
                    }
                } else {
                    AnalyticsManager.shared.trackPushPermissionDenied()
                }
            }
        }
    }

}

// MARK: - Interstitial Ads
extension ReadingVC: FullScreenContentDelegate {
    func presentInterstitialAdIfNecessary() {
        if SessionTrackingManager.shared.shouldShowInterstitialForSectionChange() {
            if interstitial != nil {
                interstitial?.present(from: self)
            }
        }
    }

    func loadNewInterstitialAd() {
        let prodInterstitialID = "ca-app-pub-6133550421853628/6946931731"
        let testInterstitialID = "ca-app-pub-3940256099942544/4411468910"
        let adUnitIDToUse = AppConstants.shared.adMode == .live ? prodInterstitialID : testInterstitialID

        let request = Request()
        InterstitialAd.load(with: adUnitIDToUse,
                               request: request,
                               completionHandler: { [self] ad, error in
            if let error = error {
                print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                return
            }
            interstitial = ad
            interstitial?.fullScreenContentDelegate = self
        })
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad did fail to present full screen content.")
    }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Ad will present full screen content.")
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Ad did dismiss full screen content.")
        if !AccountManager.shared.userIsSubscribed {
            DispatchQueue.main.async {
                self.displayPaywall(placement: .readingInterstitialAdDismissed, bookInternal: self.metadata as? CDBookInternal)
            }
        }
        loadNewInterstitialAd()
    }
}

extension ReadingVC: UIScrollViewDelegate {
    func setupScrollView() {
        scrollView.isHidden = true
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.contentInsetAdjustmentBehavior = .never

        view.addSubviewForConstraints(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            scrollView.rightAnchor.constraint(equalTo: view.rightAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        scrollView.addSubviewForConstraints(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
            contentView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func updateScrollViewInsets() {
        scrollView.contentInset = UIEdgeInsets(
            top: view.safeAreaInsets.top + 56,
            left: 0,
            bottom: view.safeAreaInsets.bottom + 60,
            right: 0
        )
        scrollView.scrollIndicatorInsets = UIEdgeInsets(
            top: view.safeAreaInsets.top,
            left: 0,
            bottom: view.safeAreaInsets.bottom,
            right: 0
        )
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateReadingOffset()
        trackReadingActivatedIfNeeded(scrollView: scrollView)
        updateFloatingRecapButtonVisibility(scrollView: scrollView)
        lastScrollOffset = scrollView.contentOffset.y
    }

    private func updateFloatingRecapButtonVisibility(scrollView: UIScrollView) {
        guard !isSectionTransitioning else { return }
        guard hasHandledRecapOnViewDidAppear else { return }
        guard scrollView.contentOffset.y >= 0 else { return }

        // Skip scroll logic if not eligible
        let isEligible = RecapManager.shared.shouldShowRecapSection(for: metadata)
        guard isEligible else { return }

        let currentOffset = scrollView.contentOffset.y
        let scrollDelta = currentOffset - lastScrollOffset
        let threshold = max(50, currentOffset * 0.10)  // 10% of current position, min 50pt

        if scrollDelta > 5 {
            // Scrolling down - hide button
            if isRecapButtonVisible {
                floatingRecapButton.animateOut()
                isRecapButtonVisible = false
            }
            upwardScrollDistance = 0
        } else if scrollDelta < -5 {
            // Scrolling up - track distance
            upwardScrollDistance += abs(scrollDelta)

            if upwardScrollDistance >= threshold && !isRecapButtonVisible {
                if presentedViewController is ReadingConfigPreferencesVC {
                    upwardScrollDistance = 0
                    return
                }
                floatingRecapButton.animateIn()
                isRecapButtonVisible = true
                upwardScrollDistance = 0
            }
        }
    }

    private func trackReadingActivatedIfNeeded(scrollView: UIScrollView) {
        
        // Trigger after scrolling 2 viewport heights
        let viewportHeight = scrollView.bounds.height
        let activationThreshold = viewportHeight * 2
        
        // print("Requirement: \(activationThreshold)")
        // print("Cumulative: \(cumulativeScrollDistance)")
        
        guard !FirstTimeManager.hasSeen(item: .readingActivated) else { return }

        let currentOffset = scrollView.contentOffset.y
        let scrollDelta = currentOffset - lastScrollOffset

        // Only count downward scrolling
        if scrollDelta > 0 {
            cumulativeScrollDistance += scrollDelta
        }

        if cumulativeScrollDistance >= activationThreshold {
            print("📖 readingActivated triggered - cumulative: \(cumulativeScrollDistance)px, threshold: \(activationThreshold)px")
            FirstTimeManager.markSeen(item: .readingActivated)
            AnalyticsManager.shared.trackReadingActivated()
            // User is hooked — cancel all pending onboarding retention nudges
            OnboardingRetentionScheduler.cancelAll(reason: "activated")
        }
    }
    func updateReadingOffset() {
        let newYOffset = scrollView.contentOffset.y

        let lastTotalYOffset = metadata.getReadingOffset()?.currentSectionTotalYOffset ?? 0
        var newTotalYOffset = scrollView.maxContentOffset.y
        if newTotalYOffset < 0 {
            newTotalYOffset = lastTotalYOffset
        }
        // print("Set new offset: Y Offset: \(newYOffset), totalYOffset: \(newTotalYOffset)")
        metadata.setReadingOffset(currentSection: currentSection,
                                  totalSections: content.sectionsArray.count,
                                  yOffset: newYOffset,
                                  totalYOffset: newTotalYOffset)

        let progress = ReadingUserDefaults.progressForBookWithUUID(metadata.contentUUID) ?? 0
        updateProgressLabel(progress: progress)

        if progress == 100 {
            didReach100Percent = true
        }

        // Track engagement milestones for push notification scheduling
        EngagementEngine.recordBookProgress(metadata: metadata, progressPercentage: progress)
    }

    private func updateProgressLabel(progress: Int) {
        progressPillLabel.text = "\(progress)%"
    }
}

extension ReadingVC: UITextViewDelegate {
    func setupContentTextView() {
        contentTextView.font = ReadingUserDefaults.getFont()
        contentTextView.textColor = ReadingUserDefaults.theme.textColor
        contentTextView.textAlignment = .left
        contentTextView.delegate = self
        contentTextView.isEditable = false
        contentTextView.isSelectable = false
        
        contentTextView.textContainerInset.top = 16
        
        contentView.addSubviewForConstraints(contentTextView)
        NSLayoutConstraint.activate([
            contentTextView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UIConstants.shared.standardMargin),
            contentTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            contentTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin)
            // Bottom constraint set by setupSectionFooter()
        ])
    }
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return false
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ReadingVC: UIGestureRecognizerDelegate {
    private func isInteractivelyHittable(_ view: UIView) -> Bool {
        return !view.isHidden && view.alpha > 0.01 && view.isUserInteractionEnabled
    }

    private func isTouch(_ touch: UITouch, insideInteractiveRegion rootView: UIView) -> Bool {
        guard isInteractivelyHittable(rootView) else { return false }
        let point = touch.location(in: rootView)
        return rootView.bounds.contains(point)
    }

    private func firstControlAncestor(from view: UIView?) -> UIControl? {
        var current = view
        while let node = current {
            if let control = node as? UIControl {
                return control
            }
            current = node.superview
        }
        return nil
    }

    private func logTapFiltered(_ reason: String) {
        #if DEBUG
        print("[DEBUG] ReadingVC tap filtered: \(reason)")
        #endif
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let location = touch.location(in: view)
        let hitView = view.hitTest(location, with: nil)

        if isTouch(touch, insideInteractiveRegion: menuContainerView) {
            logTapFiltered("menuContainerView")
            return false
        }

        if isTouch(touch, insideInteractiveRegion: menuCircle) {
            logTapFiltered("menuCircle")
            return false
        }

        if isTouch(touch, insideInteractiveRegion: closeButton) {
            logTapFiltered("closeButton")
            return false
        }

        if isTouch(touch, insideInteractiveRegion: sectionFooterContainer) {
            logTapFiltered("sectionFooterContainer")
            return false
        }

        if isTouch(touch, insideInteractiveRegion: floatingRecapButton) {
            logTapFiltered("floatingRecapButton")
            return false
        }

        if let control = firstControlAncestor(from: hitView), isInteractivelyHittable(control) {
            logTapFiltered("UIControl ancestor: \(type(of: control))")
            return false
        }

        return true
    }
}

// MARK: - Chapter Formatting
private extension ReadingVC {

    static let chapterPattern = #"^(?:chapter\s+(?:\d+|[ivxlcdm]+|[a-z]+(?:[-\s][a-z]+)*)\s*(?:[:.\-—]\s*.*)?|(?:prologue|epilogue)\s*(?:[:.\-—]\s*.*)?)$"#

    func formattedContent(
        for text: String,
        theme: ReadingTheme = ReadingUserDefaults.theme,
        font: ReadingFont = ReadingUserDefaults.font,
        textSize: ReadingTextSize = ReadingUserDefaults.textSize,
        paragraphStyle: ReadingParagraphStyle = ReadingUserDefaults.paragraphStyle
    ) -> NSAttributedString {
        let bodyFont = font.withSize(textSize)
        let boldFont = font.boldWithSize(textSize)
        let headingFont = boldFont.withSize(boldFont.pointSize * 1.15)

        let isIndented = paragraphStyle == .indented

        // Strip leading whitespace from each line (prevents stacking with indent)
        let cleanedText = text.replacingOccurrences(of: #"(?m)^[ \t]+"#, with: "", options: .regularExpression)

        // Collapse blank lines for indented style (indent replaces paragraph spacing)
        let displayText = isIndented
            ? cleanedText.replacingOccurrences(of: "\n\n+", with: "\n", options: .regularExpression)
            : cleanedText
        let nsText = displayText as NSString

        // Body paragraph style
        let bodyStyle = NSMutableParagraphStyle()
        bodyStyle.alignment = .natural
        if isIndented {
            bodyStyle.firstLineHeadIndent = min(18, max(10, bodyFont.pointSize))
            bodyStyle.paragraphSpacing = 2
        }

        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: theme.textColor,
            .paragraphStyle: bodyStyle
        ]

        let attributedString = NSMutableAttributedString(string: displayText, attributes: bodyAttributes)

        // Heading paragraph style
        let headingStyle = NSMutableParagraphStyle()
        headingStyle.alignment = .natural
        headingStyle.paragraphSpacingBefore = 16
        headingStyle.paragraphSpacing = isIndented ? (6 + bodyFont.lineHeight) : 6
        let headingAttributes: [NSAttributedString.Key: Any] = [
            .font: headingFont,
            .foregroundColor: theme.textColor,
            .paragraphStyle: headingStyle
        ]

        guard let regex = try? NSRegularExpression(pattern: Self.chapterPattern, options: [.anchorsMatchLines, .caseInsensitive]) else {
            return attributedString
        }

        let fullRange = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: displayText, range: fullRange)

        for match in matches {
            attributedString.addAttributes(headingAttributes, range: match.range)
        }

        // Remove indent from the first paragraph after each heading
        if isIndented {
            let noIndentStyle = bodyStyle.mutableCopy() as! NSMutableParagraphStyle
            noIndentStyle.firstLineHeadIndent = 0
            let noIndentAttributes: [NSAttributedString.Key: Any] = [
                .paragraphStyle: noIndentStyle
            ]

            for match in matches {
                // The heading paragraph includes the trailing \n, so skip past it
                let headingParaRange = nsText.paragraphRange(for: match.range)
                let nextParaStart = NSMaxRange(headingParaRange)
                if nextParaStart < nsText.length {
                    let nextParaRange = nsText.paragraphRange(for: NSRange(location: nextParaStart, length: 0))
                    attributedString.addAttributes(noIndentAttributes, range: nextParaRange)
                }
            }
        }

        return attributedString
    }
}
