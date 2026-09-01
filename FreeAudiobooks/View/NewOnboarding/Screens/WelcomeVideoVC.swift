//
//  WelcomeVideoVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import AVKit

/// Defines how the welcome screen (Screen 1) presents its hero content.
/// The variant is controlled via RemoteConfig's `welcomeVideoVariant` key.
enum WelcomeVideoVariant: String {
    case video
    case image

    /// Gets the current variant from RemoteConfig
    static var current: WelcomeVideoVariant {
        let variantString = RCValues.shared.string(forKey: .welcomeVideoVariantAB)
        return WelcomeVideoVariant(rawValue: variantString) ?? .video
    }
}

/// A view whose backing layer is a `CAGradientLayer`, so it resizes with Auto Layout
/// without any manual frame management.
private final class GradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }
    var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }
}

/// Welcome screen with looping video (Screen 1)
class WelcomeVideoVC: BaseNewOnboardingVC {

    // MARK: - Properties

    #if DEBUG
    private enum DebugEmailOptInPreview {
        static let isEnabled = true
        static let genre: BookInternalGenre = .adventure
        static let isSubscriber = false
        static let advanceAfterDismiss = false
    }
    #endif

    override var step: NewOnboardingStep { .welcomeVideo }
    override var showsProgressBar: Bool { false }
    override var showsBackButton: Bool { false }
    override var showsCTATopDivider: Bool { false }
    override var contentTopInsetWithoutChrome: CGFloat { 0 }
    override var showsSignInOption: Bool {
        coordinator.dataStore.authMethod == nil
    }

    private let variant = WelcomeVideoVariant.current

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerLooper: AVPlayerLooper?
    private var queuePlayer: AVQueuePlayer?
    private var hasSetupVideo = false
    private var playerStatusObserver: NSKeyValueObservation?
    private var currentVideoResourceName: String?

    /// Top constraint for the image variant, offset upward to bleed under the status bar.
    private var welcomeImageTopConstraint: NSLayoutConstraint?

    // MARK: - UI Elements

    private let videoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.alpha = 0 // Hidden until video is ready
        return view
    }()

    private let welcomeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = UIImage(named: UIDevice().iPad ? "HomeScreenStatic_iPad.jpeg" : "HomeScreenStatic_iPhone.jpeg")
        return imageView
    }()

    /// Fades the bottom ~25% of the image into the onboarding background so it
    /// blends into the title area. Sized to the image's bottom quarter via Auto
    /// Layout; the gradient runs transparent (top) → opaque background (bottom).
    /// Colours are resolved against the current appearance in `updateScrimColors()`.
    private let imageScrimView: GradientView = {
        let view = GradientView()
        view.isUserInteractionEnabled = false
        view.gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        view.gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 27, weight: .bold)
        label.textColor = Colours.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()


    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWelcomeUI()
    }

    override func configureButtonState() {
        setContinueButtonEnabled(true)
        setContinueButtonTitle(RCValues.shared.string(forKey: .onbWelcomeButtonTitle))
    }

    override func continueButtonTapped() {
        #if DEBUG
        if DebugEmailOptInPreview.isEnabled {
            trackContinueTapped()
            presentDebugEmailOptInPreview()
            return
        }
        #endif
        super.continueButtonTapped()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoContainerView.bounds
        updateWelcomeImageTopInset()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        // Setup video when added to container
        if variant == .video && parent != nil && !hasSetupVideo {
            hasSetupVideo = true
            // Dispatch to next run loop to ensure layout is complete
            DispatchQueue.main.async { [weak self] in
                self?.view.layoutIfNeeded()
                self?.setupVideoPlayer()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        queuePlayer?.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        queuePlayer?.pause()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        if variant == .image {
            updateScrimColors()
        }
        guard hasSetupVideo else { return }
        setupVideoPlayer()
    }

    // MARK: - Setup

    private func setupWelcomeUI() {
        var title = RCValues.shared.string(forKey: .onbWelcomeTitleAB)
        if Locale.isUK {
            title = title.replacingOccurrences(of: "personalized", with: "personalised")
        }
        titleLabel.text = title
        contentView.addSubviewForConstraints(titleLabel)

        NSLayoutConstraint.activate([
            // Position title at the bottom of content area
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30)
        ])

        switch variant {
        case .video:
            setupVideoLayout()
        case .image:
            setupImageLayout()
        }
    }

    /// Hero looping video filling the space above the title (default variant).
    private func setupVideoLayout() {
        contentView.addSubviewForConstraints(videoContainerView)

        // Create a layout guide representing the available space above the title
        let availableSpaceGuide = UILayoutGuide()
        contentView.addLayoutGuide(availableSpaceGuide)

        NSLayoutConstraint.activate([
            // Layout guide fills the space from top to title
            availableSpaceGuide.topAnchor.constraint(equalTo: contentView.topAnchor),
            availableSpaceGuide.bottomAnchor.constraint(equalTo: titleLabel.topAnchor),
            availableSpaceGuide.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            availableSpaceGuide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Video container: 90% of available space height, pinned to top
            videoContainerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            videoContainerView.topAnchor.constraint(equalTo: availableSpaceGuide.topAnchor),
            videoContainerView.heightAnchor.constraint(equalTo: availableSpaceGuide.heightAnchor),
            // Width derived from height using video aspect ratio (1206x2622)
            videoContainerView.widthAnchor.constraint(equalTo: videoContainerView.heightAnchor, multiplier: 1206.0/2622.0)
        ])
    }

    /// Static home-screen image bleeding to the top/side edges above the title.
    private func setupImageLayout() {
        contentView.addSubviewForConstraints(welcomeImageView)
        contentView.addSubviewForConstraints(imageScrimView)

        // The onboarding content area is pinned below the safe-area top, so the
        // top constraint's constant is offset upward by the status bar / notch
        // height in `updateWelcomeImageTopInset()` to bleed under the status bar.
        let topConstraint = welcomeImageView.topAnchor.constraint(equalTo: contentView.topAnchor)
        welcomeImageTopConstraint = topConstraint

        NSLayoutConstraint.activate([
            topConstraint,
            welcomeImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            welcomeImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            welcomeImageView.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -56),

            // Scrim covers the bottom 25% of the image, fading it to the background
            imageScrimView.leadingAnchor.constraint(equalTo: welcomeImageView.leadingAnchor),
            imageScrimView.trailingAnchor.constraint(equalTo: welcomeImageView.trailingAnchor),
            imageScrimView.bottomAnchor.constraint(equalTo: welcomeImageView.bottomAnchor),
            imageScrimView.heightAnchor.constraint(equalTo: welcomeImageView.heightAnchor, multiplier: 0.25)
        ])

        updateScrimColors()
    }

    /// Resolves the scrim gradient against the current appearance so it fades into
    /// the onboarding background colour (`Colours.surfacePrimary`) in both light and
    /// dark mode. `CGColor`s are static snapshots, so this is re-run on appearance
    /// changes (see `traitCollectionDidChange`).
    private func updateScrimColors() {
        let background = Colours.surfacePrimary.resolvedColor(with: traitCollection)
        imageScrimView.gradientLayer.colors = [
            background.withAlphaComponent(0).cgColor,
            background.cgColor
        ]
    }

    /// Extends the welcome image up under the status bar. The onboarding content
    /// area is pinned below the safe-area top, so offset the image's top by the
    /// window's top safe-area inset (status bar / notch / Dynamic Island height).
    private func updateWelcomeImageTopInset() {
        guard let topConstraint = welcomeImageTopConstraint else { return }
        let topInset = view.window?.safeAreaInsets.top ?? view.safeAreaInsets.top
        let newConstant = -topInset
        if topConstraint.constant != newConstant {
            topConstraint.constant = newConstant
        }
    }

    private func setupVideoPlayer() {
        let resolvedResourceName = resolvedWelcomeVideoName(for: traitCollection.userInterfaceStyle)
        if currentVideoResourceName == resolvedResourceName, queuePlayer != nil {
            return
        }

        teardownVideoPlayer()
        videoContainerView.alpha = 0

        guard let videoURL = Bundle.main.url(forResource: resolvedResourceName, withExtension: "mp4") else {
            print("WelcomeVideoVC: Could not find \(resolvedResourceName).mp4 in bundle")
            return
        }

        let playerItem = AVPlayerItem(url: videoURL)
        queuePlayer = AVQueuePlayer(playerItem: playerItem)
        queuePlayer?.isMuted = true
        player = queuePlayer

        // Create looper for seamless looping
        if let queuePlayer {
            playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        }

        playerLayer = AVPlayerLayer(player: queuePlayer)
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.frame = videoContainerView.bounds

        if let playerLayer {
            videoContainerView.layer.addSublayer(playerLayer)
        }

        // Observe player status to fade in when ready
        playerStatusObserver = queuePlayer?.observe(\.status, options: [.new]) { [weak self] player, _ in
            DispatchQueue.main.async {
                if player.status == .readyToPlay {
                    self?.queuePlayer?.play()
                    UIView.animate(withDuration: 0.3) {
                        self?.videoContainerView.alpha = 1
                    }
                }
            }
        }
        currentVideoResourceName = resolvedResourceName
    }

    private func resolvedWelcomeVideoName(for style: UIUserInterfaceStyle) -> String {
        switch style {
        case .dark:
            return "welcome-hero-vid-dark"
        case .light, .unspecified:
            return "welcome-hero-vid-light"
        @unknown default:
            return "welcome-hero-vid-light"
        }
    }

    private func teardownVideoPlayer() {
        playerStatusObserver?.invalidate()
        playerStatusObserver = nil
        queuePlayer?.pause()
        playerLooper?.disableLooping()
        playerLayer?.removeFromSuperlayer()
        player = nil
        queuePlayer = nil
        playerLooper = nil
        playerLayer = nil
        currentVideoResourceName = nil
    }

    #if DEBUG
    private func presentDebugEmailOptInPreview() {
        guard presentedViewController == nil else { return }

        let promptVC = EmailOptInPromptVC(
            trigger: .newOnboarding,
            genre: DebugEmailOptInPreview.genre,
            isSubscriber: DebugEmailOptInPreview.isSubscriber
        )

        let dismissAndMaybeAdvance: () -> Void = { [weak self, weak promptVC] in
            promptVC?.dismiss(animated: true) {
                guard let self else { return }
                if DebugEmailOptInPreview.advanceAfterDismiss {
                    self.coordinator.goToNextScreen()
                }
            }
        }

        promptVC.optInHandler = dismissAndMaybeAdvance
        promptVC.dismissHandler = dismissAndMaybeAdvance

        present(promptVC, animated: true)
    }
    #endif

    deinit {
        teardownVideoPlayer()
    }
}
