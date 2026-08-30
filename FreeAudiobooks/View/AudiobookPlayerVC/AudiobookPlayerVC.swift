//
//  AudiobookPlayerVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 26/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import AVFoundation
import SuperwallKit

class AudiobookPlayerVC: UIViewController {

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Cover and title
    private let coverImageView = CoverImageView(widthMultiplier: 0.50, parentVenue: .book)
    private let titleLabel = UILabel()
    private let authorLabel = UILabel()

    // Progress section
    private let progressSlider = UISlider()
    private let currentTimeLabel = UILabel()
    private let totalTimeLabel = UILabel()

    // Control buttons
    private let skipBackButton = UIButton(type: .system)
    private let playPauseButton = CircularNonGradientButton(type: .system)
    private let skipForwardButton = UIButton(type: .system)
    private let sleepTimerButton = UIButton(type: .system)

    // Speed control
    private let speedControl = UISegmentedControl(items: ["0.5×", "1×", "1.25×", "1.5×", "2×"])

    // Data
    private let bookInternal: CDBookInternal
    private let audioData: CDBookInternalAudio

    // State
    private var isLoadingAudio = false
    private var isUserScrubbingSlider = false
    private var lastTrackedEngagementTime: TimeInterval = 0
    private var isTrackingListeningSession = false
    private var shouldResumeAfterOfflinePlaybackSubscription = false
    private var listeningActivationElapsedTime: TimeInterval = 0
    private var listeningActivationStartedAt: TimeInterval?

    private static let listeningActivationThreshold: TimeInterval = 60

    init(bookInternal: CDBookInternal, audioData: CDBookInternalAudio) {
        self.bookInternal = bookInternal
        self.audioData = audioData
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupNavBar()
        setupScrollView()
        setupUI()
        applyAppearanceColors()
        setupAudioPlayer()
        loadAudioContent()
        
        AnalyticsManager.shared.trackBookInternalAudioViewed(genre: bookInternal.genre)

        APIBookInternalManager.shared.incrementReadCountForBookInternalWithUUID(bookInternal.contentUUID)

        // Listen for app lifecycle events to handle backgrounding while listening
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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        setupNavBar()
        applyAppearanceColors()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        ReadingUserDefaults.setResumeReading(bookUUID: bookInternal.contentUUID, contentType: bookInternal.contentType)

        if AudioPlayerManager.shared.isPlaying {
            startListeningStatsSessionIfNeeded()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Ensure an active listening session is flushed when leaving the player.
        endListeningStatsSessionIfNeeded()

        // Save current position when leaving
        saveCurrentPosition()

        // Match ReadingVC behavior so Home can refresh immediately on audiobook exit.
        if isMovingFromParent || isBeingDismissed {
            AudioPlayerManager.shared.cancelSleepTimer()
            ReadingUserDefaults.clearResumeReading()
            NotificationCenter.default.post(name: .didExitReadingVC, object: nil)
        }
    }

    @objc private func appDidEnterBackground() {
        saveCurrentPosition()
    }

    @objc private func appWillEnterForeground() {
        if AudioPlayerManager.shared.isPlaying {
            startListeningStatsSessionIfNeeded()
        }
    }

    @objc private func appWillTerminate() {
        saveCurrentPosition()
        endListeningStatsSessionIfNeeded()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UI Setup
private extension AudiobookPlayerVC {

    func setupNavBar() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        navigationBar.tintColor = Colours.textPrimary
        navigationBar.barTintColor = Colours.chromeBackground
        navigationController?.view.backgroundColor = Colours.chromeBackground

        // Back button
        let backButton = UIButton(type: .system)
        let backImage = UIImage(named: "backButtonNavIcon")?.withRenderingMode(.alwaysTemplate)
        backButton.setImage(backImage, for: .normal)
        backButton.tintColor = Colours.textPrimary
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)

        // Sleep timer button
        let timerConfiguration = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        sleepTimerButton.setImage(UIImage(systemName: "timer", withConfiguration: timerConfiguration), for: .normal)
        sleepTimerButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        sleepTimerButton.showsMenuAsPrimaryAction = true
        sleepTimerButton.accessibilityIdentifier = "audiobookSleepTimerButton"
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: sleepTimerButton)
        updateSleepTimerButton()

        // Custom title view
        setupCustomTitleView()

        // Appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Colours.chromeBackground
        appearance.titleTextAttributes = Fonts.navBarTitleTextAttributes
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = navigationBar.standardAppearance
    }

    func setupCustomTitleView() {
        let titleLabel = UILabel()
        titleLabel.text = bookInternal.title
        titleLabel.font = Fonts.navBarTitleTextAttributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = Fonts.navBarTitleTextAttributes[.foregroundColor] as? UIColor ?? Colours.textPrimary
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.textAlignment = .center

        navigationItem.titleView = titleLabel
    }

    func updateSleepTimerButton() {
        let activeDuration = AudioPlayerManager.shared.activeSleepTimerDuration
        sleepTimerButton.tintColor = activeDuration == nil ? Colours.textPrimary : Colours.orangePrimary
        sleepTimerButton.accessibilityLabel = "Sleep timer"

        if let activeDuration {
            let minutes = Int(activeDuration / 60)
            sleepTimerButton.accessibilityValue = "On, \(minutes) minutes"
        } else {
            sleepTimerButton.accessibilityValue = "Off"
        }

        sleepTimerButton.menu = makeSleepTimerMenu(activeDuration: activeDuration)
    }

    func makeSleepTimerMenu(activeDuration: TimeInterval?) -> UIMenu {
        let presetMinutes = [5, 10, 15, 30, 45, 60]
        let durationActions = presetMinutes.map { minutes in
            let duration = TimeInterval(minutes * 60)
            return UIAction(
                title: "\(minutes) minutes",
                state: activeDuration == duration ? .on : .off
            ) { [weak self] _ in
                AudioPlayerManager.shared.setSleepTimer(duration: duration)
                self?.updateSleepTimerButton()
            }
        }

        var children: [UIMenuElement] = [
            UIMenu(options: .displayInline, children: durationActions)
        ]

        if activeDuration != nil {
            let cancelAction = UIAction(title: "Cancel Timer", attributes: .destructive) { [weak self] _ in
                AudioPlayerManager.shared.cancelSleepTimer()
                self?.updateSleepTimerButton()
            }
            children.append(cancelAction)
        }

        return UIMenu(title: "Sleep Timer", children: children)
    }

    func setupScrollView() {
        scrollView.alwaysBounceVertical = true
        view.addSubviewForConstraints(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        scrollView.addSubviewForConstraints(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    func setupUI() {
        setupCoverImageSection()
        setupProgressSection()
        setupControlsSection()
        setupSpeedSection()
    }

    func setupCoverImageSection() {
        // Cover image
        coverImageView.coverCornerRadiusOverride = 12
        coverImageView.setContentMode(.scaleAspectFill)

        // Title
        titleLabel.font = Fonts.semiBold20
        titleLabel.textColor = Colours.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.text = bookInternal.title

        // Author
        authorLabel.font = Fonts.medium16
        authorLabel.textColor = Colours.textSecondary
        authorLabel.textAlignment = .center
        authorLabel.text = bookInternal.authorsString.isEmpty ? "FreeAudiobooks" : bookInternal.authorsString

        [coverImageView, titleLabel, authorLabel].forEach {
            contentView.addSubviewForConstraints($0)
        }

        NSLayoutConstraint.activate([
            coverImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            coverImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            coverImageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: coverImageView.getWidthMultiplier() ?? 0.50),

            titleLabel.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),

            authorLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            authorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            authorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32)
        ])

        // Load cover image without the detail-screen progress/completion extras.
        // Use the XL cover to match BookDetailVC (the player renders the cover large),
        // falling back to the regular cover when no XL URL is available.
        coverImageView.setImage(urlString: bookInternal.coverImageXLURLString ?? bookInternal.coverImageURL,
                                isBookCompleted: false,
                                progressPercentage: nil)
    }

    func setupProgressSection() {
        // Progress slider
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1
        progressSlider.value = 0
        progressSlider.tintColor = Colours.orangePrimary
        progressSlider.addTarget(self, action: #selector(progressSliderTouchBegan), for: .touchDown)
        progressSlider.addTarget(self, action: #selector(progressSliderChanged), for: .valueChanged)
        progressSlider.addTarget(self, action: #selector(progressSliderTouchEnded), for: [.touchUpInside, .touchUpOutside])

        // Time labels
        [currentTimeLabel, totalTimeLabel].forEach {
            $0.font = Fonts.medium14
            $0.textColor = Colours.textSecondary
        }
        currentTimeLabel.text = "0:00"
        totalTimeLabel.text = "0:00"
        currentTimeLabel.textAlignment = .left
        totalTimeLabel.textAlignment = .right

        [progressSlider, currentTimeLabel, totalTimeLabel].forEach {
            contentView.addSubviewForConstraints($0)
        }

        NSLayoutConstraint.activate([
            currentTimeLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 40),
            currentTimeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            currentTimeLabel.widthAnchor.constraint(equalToConstant: 60),

            totalTimeLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 40),
            totalTimeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            totalTimeLabel.widthAnchor.constraint(equalToConstant: 60),

            progressSlider.centerYAnchor.constraint(equalTo: currentTimeLabel.centerYAnchor),
            progressSlider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 16),
            progressSlider.trailingAnchor.constraint(equalTo: totalTimeLabel.leadingAnchor, constant: -16)
        ])
    }

    func setupControlsSection() {
        let playPauseButtonSize: CGFloat = 96
        let skipButtonSize: CGFloat = 44

        // Skip back button
        skipBackButton.setImage(UIImage(systemName: "gobackward.15"), for: .normal)
        skipBackButton.tintColor = Colours.textPrimary
        skipBackButton.addTarget(self, action: #selector(skipBackTapped), for: .touchUpInside)

        // Play/pause button
        playPauseButton.setImage(playbackIcon(named: "play.fill"), for: .normal)
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)

        // Skip forward button
        skipForwardButton.setImage(UIImage(systemName: "goforward.15"), for: .normal)
        skipForwardButton.tintColor = Colours.textPrimary
        skipForwardButton.addTarget(self, action: #selector(skipForwardTapped), for: .touchUpInside)

        [skipBackButton, playPauseButton, skipForwardButton].forEach {
            contentView.addSubviewForConstraints($0)
        }

        NSLayoutConstraint.activate([
            playPauseButton.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 40),
            playPauseButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: playPauseButtonSize),
            playPauseButton.heightAnchor.constraint(equalToConstant: playPauseButtonSize),

            skipBackButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            skipBackButton.trailingAnchor.constraint(equalTo: playPauseButton.leadingAnchor, constant: -40),
            skipBackButton.widthAnchor.constraint(equalToConstant: skipButtonSize),
            skipBackButton.heightAnchor.constraint(equalToConstant: skipButtonSize),

            skipForwardButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            skipForwardButton.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 40),
            skipForwardButton.widthAnchor.constraint(equalToConstant: skipButtonSize),
            skipForwardButton.heightAnchor.constraint(equalToConstant: skipButtonSize)
        ])
    }

    func setupSpeedSection() {
        speedControl.selectedSegmentIndex = 1 // Default to 1x
        speedControl.addTarget(self, action: #selector(speedChanged), for: .valueChanged)

        contentView.addSubviewForConstraints(speedControl)
        NSLayoutConstraint.activate([
            speedControl.topAnchor.constraint(equalTo: playPauseButton.bottomAnchor, constant: 40),
            speedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            speedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            speedControl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    func playbackIcon(named systemName: String) -> UIImage? {
        let configuration = UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)
        return UIImage(systemName: systemName, withConfiguration: configuration)
    }
}

// MARK: - Audio Setup
private extension AudiobookPlayerVC {

    func setupAudioPlayer() {
        AudioPlayerManager.shared.delegate = self
    }

    func loadAudioContent() {
        guard let audioData = audioData.audioData else {
            showErrorAlert(message: "Audio data not available")
            return
        }

        isLoadingAudio = true
        playPauseButton.startLoadingAnimation()

        // Get saved position for this book
        let savedPosition = getSavedAudioPosition()

        do {
            try AudioPlayerManager.shared.loadAudio(
                data: audioData,
                bookTitle: bookInternal.title ?? "",
                coverImageURL: bookInternal.coverImageXLURLString ?? bookInternal.coverImageURL ?? "",
                bookUUID: bookInternal.contentUUID,
                savedPosition: savedPosition
            )
            isLoadingAudio = false
            playPauseButton.stopLoadingAnimation()

            // Show resume toast if there's a saved position
//            if savedPosition > 30 { // Only show if more than 30 seconds in
//                showResumeToast(position: savedPosition)
//            }
        } catch {
            isLoadingAudio = false
            playPauseButton.stopLoadingAnimation()
            showErrorAlert(message: "Failed to load audio: \(error.localizedDescription)")
        }
    }

    func getSavedAudioPosition() -> TimeInterval {
        return bookInternal.audioPosition
    }

    func saveCurrentPosition() {
        let currentPosition = AudioPlayerManager.shared.getCurrentPosition()
        bookInternal.audioPosition = currentPosition
        if currentPosition > 0 {
            recordAudioEngagement(at: currentPosition)
        }
    }
}

// MARK: - In-App Playback Gate
private extension AudiobookPlayerVC {

    func allowPlaybackOrShowOfflineGate() -> Bool {
        guard !AudiobookAccessPolicy.shouldBlockInAppPlaybackStart() else {
            shouldResumeAfterOfflinePlaybackSubscription = true
            showListenOfflineUpsell()
            return false
        }

        return true
    }

    func showListenOfflineUpsell() {
        guard presentedViewController == nil else { return }

        AnalyticsManager.shared.trackListenOfflineUpsellShown()

        let viewController = ListenOfflineUpsellVC()
        viewController.subscribeHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                AnalyticsManager.shared.trackListenOfflineUpsellSubscribeTapped()
                self.displayPaywall(placement: .downloadOfflineAudioConnection)
            }
        }
        viewController.dismissHandler = {
            DispatchQueue.main.async {
                AnalyticsManager.shared.trackListenOfflineUpsellDismissed()
            }
        }
        present(viewController, animated: false)
    }

    func displayPaywall(placement: PaywallPlacement) {
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
                case .purchased(let product):
                    print("Purchased \(product.productIdentifier)")
                    AnalyticsManager.shared.trackPaywallUserSubscribed(placement: placement, cdBookInternal: self.bookInternal)
                    self.showSubscribeSuccessPopup()
                    self.handleSubscribedForOfflinePlayback()
                case .restored:
                    print("Restored purchases.")
                    AnalyticsManager.shared.trackPaywallRestorePurchasesSuccess()
                    self.handleSubscribedForOfflinePlayback()
                }
            }
        }
        Superwall.shared.register(placement: placement.rawValue, params: nil, handler: handler)
    }

    func handleSubscribedForOfflinePlayback() {
        if audioData.isTemporaryDownload {
            CoreDataBookInternalAudioManager.shared.promoteTemporaryDownload(bookUUID: bookInternal.contentUUID)
        }

        if shouldResumeAfterOfflinePlaybackSubscription {
            shouldResumeAfterOfflinePlaybackSubscription = false
            AudioPlayerManager.shared.play()
        }
    }
}

// MARK: - Actions
private extension AudiobookPlayerVC {

    @objc func backTapped() {
        saveCurrentPosition()
        AudioPlayerManager.shared.stopPlayback()
        navigationController?.popViewController(animated: true)
    }

    @objc func playPauseTapped() {
        if !AudioPlayerManager.shared.isPlaying, !allowPlaybackOrShowOfflineGate() {
            return
        }
        AudioPlayerManager.shared.togglePlayPause()
    }

    @objc func skipBackTapped() {
        AudioPlayerManager.shared.skipBackward(15)
    }

    @objc func skipForwardTapped() {
        AudioPlayerManager.shared.skipForward(15)
    }

    @objc func progressSliderTouchBegan() {
        isUserScrubbingSlider = true
    }

    @objc func progressSliderChanged() {
        let value = progressSlider.value
        let duration = AudioPlayerManager.shared.duration
        let newTime = TimeInterval(value) * duration
        currentTimeLabel.text = formatTime(newTime)
    }

    @objc func progressSliderTouchEnded() {
        isUserScrubbingSlider = false

        let value = progressSlider.value
        let duration = AudioPlayerManager.shared.duration
        let newTime = TimeInterval(value) * duration
        AudioPlayerManager.shared.seekTo(newTime)
    }

    @objc func speedChanged() {
        let speeds: [Float] = [0.5, 1.0, 1.25, 1.5, 2.0]
        let selectedSpeed = speeds[speedControl.selectedSegmentIndex]
        AudioPlayerManager.shared.setPlaybackRate(selectedSpeed)
    }
}

// MARK: - AudioPlayerManagerDelegate
extension AudiobookPlayerVC: AudioPlayerManagerDelegate {

    func audioPlayerDidUpdateTime(_ currentTime: TimeInterval, duration: TimeInterval) {
        DispatchQueue.main.async {
            self.trackListeningActivatedIfNeeded(isPlaying: AudioPlayerManager.shared.isPlaying)

            // Only update time labels if user isn't scrubbing (always show current scrub position)
            if !self.isUserScrubbingSlider {
                self.currentTimeLabel.text = self.formatTime(currentTime)
            }
            self.totalTimeLabel.text = self.formatTime(duration)

            // Only update slider position if user isn't actively scrubbing
            if !self.isUserScrubbingSlider && duration > 0 {
                self.progressSlider.value = Float(currentTime / duration)
            }

            if currentTime >= 15, currentTime - self.lastTrackedEngagementTime >= 30 {
                self.recordAudioEngagement(at: currentTime)
            }
        }
    }

    func audioPlayerDidChangePlaybackState(_ isPlaying: Bool) {
        DispatchQueue.main.async {
            self.trackListeningActivatedIfNeeded(isPlaying: isPlaying)

            if isPlaying {
                self.startListeningStatsSessionIfNeeded()
            } else {
                self.endListeningStatsSessionIfNeeded()
            }

            let iconName = isPlaying ? "pause.fill" : "play.fill"
            let icon = self.playbackIcon(named: iconName)
            self.playPauseButton.setImage(icon, for: .normal)
        }
    }

    func audioPlayerSleepTimerDidChange(_ selectedDuration: TimeInterval?) {
        DispatchQueue.main.async {
            self.updateSleepTimerButton()
        }
    }

    func audioPlayerDidFinishPlaying() {
        DispatchQueue.main.async {
            // Will also update the text.
            // Makes sure it says the full time even if technically it ends a sec/two short
            self.progressSlider.value = 1
            self.progressSliderChanged()
            
            // Mark book as completed
            self.markMetadataCompleted()

            // Show completion popup with rating
            self.showBookCompletionPopup()
        }
    }

    func audioPlayerDidFail(with error: Error) {
        DispatchQueue.main.async {
            self.showErrorAlert(message: "Playback error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Helper Methods
private extension AudiobookPlayerVC {

    func recordAudioEngagement(at currentTime: TimeInterval, forceNotification: Bool = false) {
        guard forceNotification || currentTime > 0 else { return }

        if currentTime > 0 {
            lastTrackedEngagementTime = max(lastTrackedEngagementTime, currentTime)
            ReadingUserDefaults.setLastReadDate(for: bookInternal.contentUUID, mode: .audio)
        }

        let duration = AudioPlayerManager.shared.duration
        let progressPercentage: Int
        if duration > 0 {
            progressPercentage = min(100, max(0, Int((currentTime / duration) * 100)))
        } else {
            progressPercentage = 0
        }

        EngagementEngine.recordBookProgress(
            metadata: bookInternal,
            progressPercentage: progressPercentage,
            mode: .audio,
            forceNotification: forceNotification
        )
    }

    func trackListeningActivatedIfNeeded(
        isPlaying: Bool,
        now: TimeInterval = ProcessInfo.processInfo.systemUptime
    ) {
        guard !FirstTimeManager.hasSeen(item: .listeningActivated) else {
            listeningActivationStartedAt = nil
            return
        }

        if isPlaying {
            if listeningActivationStartedAt == nil {
                listeningActivationStartedAt = now
            }
        } else if let startedAt = listeningActivationStartedAt {
            listeningActivationElapsedTime += max(0, now - startedAt)
            listeningActivationStartedAt = nil
        }

        let currentPlaybackTime = listeningActivationStartedAt.map { max(0, now - $0) } ?? 0
        guard listeningActivationElapsedTime + currentPlaybackTime >= Self.listeningActivationThreshold else {
            return
        }

        listeningActivationStartedAt = nil
        FirstTimeManager.markSeen(item: .listeningActivated)
        AnalyticsManager.shared.trackListeningActivated()
        recordAudioEngagement(
            at: AudioPlayerManager.shared.getCurrentPosition(),
            forceNotification: true
        )
        OnboardingRetentionScheduler.cancelAll(reason: "activated")
    }

    func startListeningStatsSessionIfNeeded() {
        guard !isTrackingListeningSession else { return }
        isTrackingListeningSession = true
        // print("Audio stats started counting")
        SessionTrackingManager.shared.startSession()
    }

    func endListeningStatsSessionIfNeeded() {
        guard isTrackingListeningSession else { return }
        isTrackingListeningSession = false
        // print("Audio stats stopped counting")
        SessionTrackingManager.shared.endSession()
    }

    func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Audio Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func markMetadataCompleted() {
        bookInternal.markCompleted()
        ReadingUserDefaults.clearResumeReading()
        AnalyticsManager.shared.trackBookInternalAudioCompleted(cdBookInternal: bookInternal)
        AppNotifiers.shared.shouldReloadHomeVC = true
    }

    func showBookCompletionPopup() {
        let dismissAction: () -> Void = { [weak self] in
            guard let self else { return }
            // Stop playback and navigate back
            AudioPlayerManager.shared.stopPlayback()
            DispatchQueue.main.async {
                self.dismiss(animated: true) {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }

        let popupVC = EnhancedBookCompletionPopupVC(metadata: bookInternal, reviewedContentType: .bookInternalAudiobook)
        popupVC.dismissHandler = dismissAction
        popupVC.preferredSheetSizing = .fit
        popupVC.panToDismissEnabled = false
        popupVC.tapToDismissEnabled = false

        self.present(popupVC, animated: true)
    }

    func applyAppearanceColors() {
        view.backgroundColor = Colours.surfacePrimary
        titleLabel.textColor = Colours.textPrimary
        authorLabel.textColor = Colours.textSecondary
        [currentTimeLabel, totalTimeLabel].forEach { $0.textColor = Colours.textSecondary }
        skipBackButton.tintColor = Colours.textPrimary
        skipForwardButton.tintColor = Colours.textPrimary
    }
}
