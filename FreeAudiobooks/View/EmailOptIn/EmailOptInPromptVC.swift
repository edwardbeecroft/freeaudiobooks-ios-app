//
//  EmailOptInPromptVC.swift
//  FreeAudiobooks
//
//  Created by Claude on 29/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

/// Bottom sheet prompt for email opt-in with personalized cover stack
final class EmailOptInPromptVC: BottomSheetController {

    // MARK: - Handlers

    var optInHandler: (() -> Void)?
    var dismissHandler: (() -> Void)?

    // MARK: - Properties

    private let trigger: EmailOptInTrigger
    private let genre: BookInternalGenre
    private let isSubscriber: Bool

    // MARK: - UI Constants

    private struct Layout {
        static let coverHeight: CGFloat = 100
        static let coverOverlapOffset: CGFloat = 25
        static let coverRotationAngle: CGFloat = 0.08 // ~4.5 degrees
        static let horizontalPadding: CGFloat = 24
        static let verticalPadding: CGFloat = 24
        static let buttonHeight: CGFloat = 50
    }

    // Cover views for animation
    private var coverViews: [CoverImageView] = []

    // MARK: - Init

    init(trigger: EmailOptInTrigger, genre: BookInternalGenre, isSubscriber: Bool) {
        self.trigger = trigger
        self.genre = genre
        self.isSubscriber = isSubscriber
        super.init(nibName: nil, bundle: nil)
        self.preferredSheetSizing = .fit
        self.tapToDismissEnabled = false
        self.panToDismissEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateCoversFanOut()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // If dismissed by swipe/tap (not by button action), treat as "Not now"
        // This is handled by the presentation controller calling our dismiss handler
    }

    // MARK: - Setup

    private func setupUI() {
        // Cover Stack
        let coverStackView = createCoverStackView()

        // Title
        let titleLabel = UILabel()
        titleLabel.font = Fonts.semiBold18
        titleLabel.textColor = Colours.textPrimary
        titleLabel.text = trigger.title(forSubscriber: isSubscriber)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.font = Fonts.medium15
        subtitleLabel.textColor = Colours.textSecondary
        subtitleLabel.text = trigger.subtitle(forSubscriber: isSubscriber)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        // Subtitle container with side insets for readability
        let subtitleContainer = UIView()
        subtitleContainer.addSubviewForConstraints(subtitleLabel)
        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: subtitleContainer.topAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: subtitleContainer.bottomAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: subtitleContainer.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: subtitleContainer.trailingAnchor, constant: -20)
        ])

        // Primary CTA Button
        let primaryButton = Buttons.primaryCTA(buttonTitle: trigger.ctaText(forSubscriber: isSubscriber))
        primaryButton.addTarget(self, action: #selector(optInTapped), for: .touchUpInside)

        // Not now button (secondary)
        let notNowButton = UIButton(type: .system)
        notNowButton.setTitle("Not now", for: .normal)
        notNowButton.titleLabel?.font = Fonts.medium15
        notNowButton.setTitleColor(Colours.negativeButtonTitle, for: [])
        notNowButton.addTarget(self, action: #selector(notNowTapped), for: .touchUpInside)

        // Button container for consistent sizing
        let buttonContainer = UIView()
        buttonContainer.addSubviewForConstraints(primaryButton)
        NSLayoutConstraint.activate([
            primaryButton.centerXAnchor.constraint(equalTo: buttonContainer.centerXAnchor),
            primaryButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            primaryButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight),
            primaryButton.widthAnchor.constraint(equalTo: buttonContainer.widthAnchor)
        ])

        // Stack view
        let stackView = UIStackView(arrangedSubviews: [
            coverStackView,
            titleLabel,
            subtitleContainer,
            buttonContainer,
            notNowButton
        ])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 16
        stackView.setCustomSpacing(20, after: coverStackView)
        stackView.setCustomSpacing(8, after: titleLabel)
        stackView.setCustomSpacing(24, after: subtitleContainer)
        stackView.setCustomSpacing(8, after: buttonContainer)

        view.addSubviewForConstraints(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: Layout.verticalPadding),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalPadding),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalPadding),
            stackView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -Layout.verticalPadding),
            buttonContainer.heightAnchor.constraint(equalToConstant: Layout.buttonHeight)
        ])
    }

    private func createCoverStackView() -> UIView {
        let containerView = UIView()
        let coverWidth = Layout.coverHeight * UIConstants.shared.bookInternalCoverImageWidthToHeightRatio
        let coverCount = 3
        let placeholderNames = placeholderImageNames()

        let totalWidth = coverWidth + (CGFloat(coverCount - 1) * Layout.coverOverlapOffset)

        // Create a centered inner container for the covers
        let coversContainer = UIView()
        containerView.addSubviewForConstraints(coversContainer)

        NSLayoutConstraint.activate([
            coversContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            coversContainer.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            coversContainer.widthAnchor.constraint(equalToConstant: totalWidth + 20), // Extra padding for rotation
            coversContainer.heightAnchor.constraint(equalToConstant: Layout.coverHeight + 20)
        ])

        // Clear any previous cover views
        coverViews.removeAll()

        // Add covers with stacking effect (later books on top)
        for index in 0..<coverCount {
            let coverView = CoverImageView(height: Layout.coverHeight, parentVenue: .smallMetadataView)
            coverView.setLocalImage(named: placeholderNames[index])

            coversContainer.addSubviewForConstraints(coverView)
            coverViews.append(coverView)

            // Calculate final position for constraints
            // Middle book (index 1) is centered, others offset
            let xOffset: CGFloat
            switch index {
            case 0: xOffset = 0
            case 1: xOffset = Layout.coverOverlapOffset
            case 2: xOffset = Layout.coverOverlapOffset * 2
            default: xOffset = CGFloat(index) * Layout.coverOverlapOffset
            }

            NSLayoutConstraint.activate([
                coverView.leadingAnchor.constraint(equalTo: coversContainer.leadingAnchor, constant: xOffset + 10),
                coverView.centerYAnchor.constraint(equalTo: coversContainer.centerYAnchor)
            ])

            // Set initial state: centered, no rotation, scaled down, transparent
            coverView.alpha = 0
            coverView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }

        // Bring the middle cover to front (if we have at least 2 books)
        if coverCount >= 2 {
            let middleIndex = coverCount >= 3 ? 1 : 0
            if let middleCover = coversContainer.subviews[safe: middleIndex] {
                coversContainer.bringSubviewToFront(middleCover)
            }
        }

        // Container height constraint
        containerView.heightAnchor.constraint(equalToConstant: Layout.coverHeight + 20).isActive = true

        return containerView
    }

    // NOTE: Middle one is centered
    private func placeholderImageNames() -> [String] {
        switch genre {
        case .romance: return ["romance-10", "romance-15", "romance-3"]
        case .thriller: return ["thriller-17", "thriller-12", "thriller-5"]
        case .drama: return ["drama-15", "drama-12", "drama-11"]
        case .mystery: return ["mystery-1", "mystery-15", "mystery-16"]
        case .fantasy: return ["fantasy-1", "fantasy-13", "fantasy-12"]
        case .adventure: return ["adventure-14", "adventure-18", "adventure-17"]
        case .historical: return ["historical-17", "historical-15", "historical-16"]
        case .scienceFiction: return ["scifi-17", "scifi-15", "scifi-16"]
        case .horror: return ["horror-15", "horror-14", "horror-16"]
        case .comedy: return ["comedy-12", "comedy-4", "comedy-11"]
        case .kids: return ["kids-2", "kids-1", "kids-3"]
        }
    }

    // MARK: - Animation

    private func animateCoversFanOut() {
        let bookCount = coverViews.count
        guard bookCount > 0 else { return }

        for (index, coverView) in coverViews.enumerated() {
            // Calculate final rotation
            let rotation: CGFloat
            switch index {
            case 0: rotation = -Layout.coverRotationAngle
            case 1: rotation = 0
            case 2: rotation = Layout.coverRotationAngle
            default: rotation = 0
            }

            // Calculate scale (back books slightly smaller)
            let scale: CGFloat
            switch index {
            case 0: scale = 0.94
            case 1: scale = 1.0
            case 2: scale = 0.94
            default: scale = 1.0
            }

            // Staggered delay - middle book last for dramatic effect
            let delay: TimeInterval
            switch index {
            case 0: delay = 0.0
            case 2: delay = 0.1
            case 1: delay = 0.2
            default: delay = Double(index) * 0.1
            }

            UIView.animate(
                withDuration: 0.5,
                delay: delay,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 0,
                options: [],
                animations: {
                    coverView.alpha = 1
                    coverView.transform = CGAffineTransform(rotationAngle: rotation)
                        .scaledBy(x: scale, y: scale)
                }
            )
        }
    }

    // MARK: - Actions

    @objc private func optInTapped() {
        optInHandler?()
    }

    @objc private func notNowTapped() {
        dismissHandler?()
    }
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
