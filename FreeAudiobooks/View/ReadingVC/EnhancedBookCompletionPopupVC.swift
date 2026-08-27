//
//  EnhancedBookCompletionPopupVC.swift
//  FreeAudiobooks
//
//  Created by Claude on 24/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import Cosmos
import NVActivityIndicatorView
import Lottie
import Kingfisher

final class EnhancedBookCompletionPopupVC: BottomSheetController {

    // MARK: - Types

    private enum Stage {
        case main
        case share
    }

    // MARK: - Properties

    var dismissHandler: (() -> Void)?

    private let metadata: ReadableContentMetadata
    private let reviewedContentType: ReviewedContentType
    private let audioData: CDBookInternalAudio?

    private var currentStage: Stage = .main
    private var loadingIndicatorView: NVActivityIndicatorView?
    private var feedbackHeightConstraint: NSLayoutConstraint?
    private var shareTopSpacerMinHeightConstraint: NSLayoutConstraint?
    private var shareBottomSpacerMinHeightConstraint: NSLayoutConstraint?
    private var hasFeedbackFieldAppeared = false
    private let bookReviewVariant = BookReviewVariant.current

    private var shouldHideContinueUntilRating: Bool {
        bookReviewVariant == .originalRatingRequired
    }

    // MARK: - UI Elements - Main Stage (Celebration + Rating Combined)

    private let mainContainerView = UIView()

    private lazy var congratsAnimationView: LottieAnimationView = {
        let animationView = LottieAnimationView()
        animationView.loopMode = .playOnce
        animationView.backgroundColor = nil
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.contentMode = .scaleAspectFit

        animationView.setContentHuggingPriority(.defaultLow, for: .vertical)
        animationView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        animationView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        animationView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        Task {
            do {
                let dotLottie = try await DotLottieFile.named("congrats")
                await MainActor.run {
                    animationView.loadAnimation(from: dotLottie)
                }
            } catch {
                print("Failed to load congrats animation: \(error)")
            }
        }

        return animationView
    }()

    private let congratsTitleLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.semiBold18
        label.textColor = Colours.textPrimary
        label.text = RCValues.shared.string(forKey: .bookCompletionTitleLabel)
        label.textAlignment = .center
        return label
    }()

    private let bookTitleLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.medium16
        label.textColor = Colours.subtext
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private let ratingPromptLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.medium14
        label.textColor = Colours.subtext
        // Text set dynamically in setupMainStage() based on reviewedContentType
        label.textAlignment = .center
        return label
    }()

    private lazy var starRatingView: CosmosView = {
        let cosmosView = CosmosView()
        cosmosView.rating = 0
        cosmosView.settings.minTouchRating = 1
        cosmosView.settings.updateOnTouch = true
        cosmosView.settings.fillMode = .full
        cosmosView.settings.starSize = bookReviewVariant == .reviewStyle ? 32 : 40
        cosmosView.settings.starMargin = bookReviewVariant == .reviewStyle ? 6 : 8
        cosmosView.settings.emptyBorderWidth = 1
        updateStarRatingColors(for: cosmosView)
        cosmosView.didTouchCosmos = { [weak self] rating in
            self?.handleStarRatingChanged(rating)
        }
        return cosmosView
    }()

    private let feedbackContainer = UIView()
    private let reviewMetaContainer = UIView()

    private let ratingCardView: UIView = {
        let view = UIView()
        view.backgroundColor = Colours.surfaceSecondary
        view.layer.cornerRadius = UIConstants.shared.cardCornerRadius
        return view
    }()

    private lazy var feedbackTextView: UITextView = {
        let textView = UITextView()
        textView.font = Fonts.regular14
        textView.textColor = Colours.textPrimary
        textView.backgroundColor = Colours.surfacePrimary
        textView.layer.borderColor = Colours.inputBorder.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = UIConstants.shared.cardCornerRadius
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        textView.isScrollEnabled = true
        textView.delegate = self
        return textView
    }()

    private let feedbackPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.regular14
        label.textColor = Colours.subtext
        label.text = RCValues.shared.string(forKey: .bookCompletionReviewPlaceholderTextAB)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private let reviewIntroLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.medium13
        label.textColor = Colours.subtext
        label.text = RCValues.shared.string(forKey: .bookCompletionReviewIntroTextAB)
        label.numberOfLines = 0
        return label
    }()

    private let reviewAvatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        imageView.image = ReviewerAvatarPlaceholder.image(for: nil, diameter: 32, traitCollection: .current)
        return imageView
    }()

    private let reviewMetaLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.medium13
        label.textColor = Colours.textSecondary
        label.numberOfLines = 1
        return label
    }()

    private lazy var reviewMetaStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [reviewAvatarImageView, reviewMetaLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 10
        return stackView
    }()

    private lazy var continueButton: UIButton = {
        let button = Buttons.primaryCTA(buttonTitle: "Continue")
        button.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - UI Elements - Share Stage

    private let shareContainerView = UIView()
    private let shareCoverContainerView = UIView()

    private let shareCoverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = Colours.surfaceSecondary
        return imageView
    }()

    private let completionBadgeView: UIView = {
        let badgeSize: CGFloat = 28
        let badge = UIView()
        badge.backgroundColor = Colours.positiveGreen
        badge.layer.cornerRadius = badgeSize / 2
        badge.layer.borderWidth = 2
        badge.layer.borderColor = UIColor.dynamic(light: Colours.surfacePrimary, dark: Colours.ctaBackground).cgColor

        let checkmark = UIImageView(image: UIImage(systemName: "checkmark"))
        checkmark.tintColor = .white
        checkmark.contentMode = .scaleAspectFit
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(checkmark)

        NSLayoutConstraint.activate([
            checkmark.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            checkmark.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            checkmark.widthAnchor.constraint(equalToConstant: 14),
            checkmark.heightAnchor.constraint(equalToConstant: 14)
        ])

        return badge
    }()

    private let shareTitleLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.semiBold18
        label.textColor = Colours.textPrimary
        label.text = "Loved it? Send it to a friend"
        label.textAlignment = .center
        return label
    }()

    private let shareSubtitleLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.medium15
        label.textColor = Colours.subtext
        label.textAlignment = .center
        label.text = "We’ll draft a message you can edit."
        return label
    }()

    private lazy var shareButton: UIButton = {
        let button = Buttons.transparentButtonWithBorder(
            borderColor: Colours.ctaBackground.cgColor,
            buttonTitle: RCValues.shared.string(forKey: .bookCompletionShareButtonTitle),
            titleColor: Colours.ctaBackground
        )
        button.layer.cornerRadius = UIConstants.shared.fullButtonCornerRadius
        button.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        return button
    }()

    private lazy var shareStageContinueButton: UIButton = {
        let button = Buttons.primaryCTA(buttonTitle: "Continue")
        button.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Init

    init(metadata: ReadableContentMetadata, reviewedContentType: ReviewedContentType, audioData: CDBookInternalAudio? = nil) {
        self.metadata = metadata
        self.reviewedContentType = reviewedContentType
        self.audioData = audioData
        super.init(nibName: nil, bundle: nil)

        AnalyticsManager.shared.trackEnhancedBookCompletionViewed()
        
        HapticFeedbackHelper.shared.prepareSuccessFeedbackGenerator()
        createView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupKeyboardObservers()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        congratsAnimationView.play()
        HapticFeedbackHelper.shared.triggerSuccessHaptic()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardObservers()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateAppearanceColors()
        if AccountManager.shared.user?.profileImageURLString.flatMap(URL.init(string:)) == nil {
            reviewAvatarImageView.image = ReviewerAvatarPlaceholder.image(
                for: AccountManager.shared.user?.displayName,
                diameter: 32,
                traitCollection: traitCollection
            )
        }
    }

    // MARK: - Keyboard Handling

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        let keyboardHeight = keyboardFrame.height
        UIView.animate(withDuration: duration) {
            self.view.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight + self.view.safeAreaInsets.bottom)
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        UIView.animate(withDuration: duration) {
            self.view.transform = .identity
        }
    }

    // MARK: - Setup

    private func createView() {
        view = UIView()
        view.backgroundColor = .systemBackground

        setupMainStage()
        setupShareStage()

        view.addSubviewForConstraints(mainContainerView)
        view.addSubviewForConstraints(shareContainerView)

        NSLayoutConstraint.activate([
            mainContainerView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            mainContainerView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            mainContainerView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            mainContainerView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),

            shareContainerView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            shareContainerView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            shareContainerView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            shareContainerView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor)
        ])

        showStage(.main, animated: false)
        updateAppearanceColors()
    }

    private func setupMainStage() {
        let typeText = reviewedContentType == .bookInternalAudiobook ? "audiobook" : "book"

        let key: RCKeys = reviewedContentType == .bookInternalAudiobook ? .bookCompletionRatingPromptLabelAB : .bookCompletionRatingPromptLabelBookAB
        ratingPromptLabel.text = RCValues.shared.string(forKey: key)

        // Build attributed string with italic title if available
        let mediumFont = Fonts.medium16
        let italicFont = Fonts.mediumItalic16

        let attributedText = NSMutableAttributedString()
        attributedText.append(NSAttributedString(
            string: "You finished ",
            attributes: [.font: mediumFont]
        ))

        if let title = metadata.title {
            // Use italic for actual book title (no quotes)
            attributedText.append(NSAttributedString(
                string: title,
                attributes: [.font: italicFont]
            ))
        } else {
            // Use regular medium for fallback text (with quotes)
            attributedText.append(NSAttributedString(
                string: "\"this \(typeText)\"",
                attributes: [.font: mediumFont]
            ))
        }

        bookTitleLabel.attributedText = attributedText

        // Tap gesture to dismiss keyboard (delegate prevents it from blocking button taps)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToDismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        mainContainerView.addGestureRecognizer(tapGesture)

        // Animation container - centered, 120pt size
        let animationContainer = UIView()
        animationContainer.addSubviewForConstraints(congratsAnimationView)
        NSLayoutConstraint.activate([
            congratsAnimationView.centerXAnchor.constraint(equalTo: animationContainer.centerXAnchor),
            congratsAnimationView.topAnchor.constraint(equalTo: animationContainer.topAnchor),
            congratsAnimationView.bottomAnchor.constraint(equalTo: animationContainer.bottomAnchor),
            congratsAnimationView.heightAnchor.constraint(equalToConstant: 130),
            congratsAnimationView.widthAnchor.constraint(equalTo: congratsAnimationView.heightAnchor)
        ])

        // Star rating container - centered
        let starContainer = UIView()
        starContainer.addSubviewForConstraints(starRatingView)
        if bookReviewVariant == .reviewStyle {
            NSLayoutConstraint.activate([
                starRatingView.centerXAnchor.constraint(equalTo: starContainer.centerXAnchor),
                starRatingView.topAnchor.constraint(equalTo: starContainer.topAnchor),
                starRatingView.bottomAnchor.constraint(equalTo: starContainer.bottomAnchor),
                starRatingView.leadingAnchor.constraint(greaterThanOrEqualTo: starContainer.leadingAnchor),
                starRatingView.trailingAnchor.constraint(lessThanOrEqualTo: starContainer.trailingAnchor),
                starRatingView.heightAnchor.constraint(equalToConstant: 32)
            ])
        } else {
            NSLayoutConstraint.activate([
                starRatingView.centerXAnchor.constraint(equalTo: starContainer.centerXAnchor),
                starRatingView.topAnchor.constraint(equalTo: starContainer.topAnchor),
                starRatingView.bottomAnchor.constraint(equalTo: starContainer.bottomAnchor),
                starRatingView.heightAnchor.constraint(equalToConstant: 40)
            ])
        }

        if bookReviewVariant == .reviewStyle {
            reviewMetaContainer.addSubviewForConstraints(reviewMetaStackView)

            NSLayoutConstraint.activate([
                reviewAvatarImageView.widthAnchor.constraint(equalToConstant: 32),
                reviewAvatarImageView.heightAnchor.constraint(equalToConstant: 32),
                reviewMetaStackView.topAnchor.constraint(equalTo: reviewMetaContainer.topAnchor),
                reviewMetaStackView.bottomAnchor.constraint(equalTo: reviewMetaContainer.bottomAnchor),
                reviewMetaStackView.centerXAnchor.constraint(equalTo: reviewMetaContainer.centerXAnchor),
                reviewMetaStackView.leadingAnchor.constraint(greaterThanOrEqualTo: reviewMetaContainer.leadingAnchor),
                reviewMetaStackView.trailingAnchor.constraint(lessThanOrEqualTo: reviewMetaContainer.trailingAnchor)
            ])

            configureReviewMetaPreview()
        }

        // Feedback container - starts hidden, animates in
        feedbackContainer.addSubviewForConstraints(feedbackTextView)
        feedbackContainer.addSubviewForConstraints(feedbackPlaceholderLabel)

        feedbackHeightConstraint = feedbackContainer.heightAnchor.constraint(equalToConstant: 0)
        feedbackHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            feedbackTextView.topAnchor.constraint(equalTo: feedbackContainer.topAnchor),
            feedbackTextView.leadingAnchor.constraint(equalTo: feedbackContainer.leadingAnchor),
            feedbackTextView.trailingAnchor.constraint(equalTo: feedbackContainer.trailingAnchor),
            feedbackTextView.bottomAnchor.constraint(equalTo: feedbackContainer.bottomAnchor),

            feedbackPlaceholderLabel.topAnchor.constraint(equalTo: feedbackTextView.topAnchor, constant: 12),
            feedbackPlaceholderLabel.leadingAnchor.constraint(equalTo: feedbackTextView.leadingAnchor, constant: 13),
            feedbackPlaceholderLabel.trailingAnchor.constraint(equalTo: feedbackTextView.trailingAnchor, constant: -13)
        ])

        feedbackContainer.clipsToBounds = true
        feedbackContainer.alpha = 0

        // Rating card - contains prompt, stars, and feedback
        let ratingCardArrangedSubviews: [UIView]
        if bookReviewVariant == .reviewStyle {
            ratingCardArrangedSubviews = [
                reviewIntroLabel,
                starContainer,
                reviewMetaContainer,
                feedbackContainer
            ]
        } else {
            ratingCardArrangedSubviews = [
                ratingPromptLabel,
                starContainer,
                feedbackContainer
            ]
        }

        let ratingCardStack = UIStackView(arrangedSubviews: ratingCardArrangedSubviews)
        ratingCardStack.axis = .vertical
        ratingCardStack.distribution = .fill
        ratingCardStack.alignment = .fill
        ratingCardStack.spacing = 12
        if bookReviewVariant == .reviewStyle {
            ratingCardStack.setCustomSpacing(10, after: reviewIntroLabel)
            ratingCardStack.setCustomSpacing(10, after: starContainer)
            ratingCardStack.setCustomSpacing(10, after: reviewMetaContainer)
        } else {
            ratingCardStack.setCustomSpacing(12, after: ratingPromptLabel)
            ratingCardStack.setCustomSpacing(16, after: starContainer)
        }

        ratingCardView.addSubviewForConstraints(ratingCardStack)
        NSLayoutConstraint.activate([
            ratingCardStack.topAnchor.constraint(equalTo: ratingCardView.topAnchor, constant: 16),
            ratingCardStack.leadingAnchor.constraint(equalTo: ratingCardView.leadingAnchor, constant: 16),
            ratingCardStack.trailingAnchor.constraint(equalTo: ratingCardView.trailingAnchor, constant: -16),
            ratingCardStack.bottomAnchor.constraint(equalTo: ratingCardView.bottomAnchor, constant: -16)
        ])

        // Continue button
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight).isActive = true
        continueButton.alpha = shouldHideContinueUntilRating ? 0 : 1
        continueButton.isUserInteractionEnabled = !shouldHideContinueUntilRating

        applyBookReviewVariantStyling()

        // Stack view with all elements
        let stackView = UIStackView(arrangedSubviews: [
            animationContainer,
            congratsTitleLabel,
            bookTitleLabel,
            ratingCardView,
            continueButton
        ])
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 8

        // Custom spacing for visual hierarchy
        stackView.setCustomSpacing(4, after: congratsTitleLabel)
        stackView.setCustomSpacing(24, after: bookTitleLabel)
        stackView.setCustomSpacing(24, after: ratingCardView)

        mainContainerView.addSubviewForConstraints(stackView)
        let stackTopConstraint = stackView.topAnchor.constraint(equalTo: mainContainerView.topAnchor, constant: 12)
        let stackLeadingConstraint = stackView.leadingAnchor.constraint(equalTo: mainContainerView.leadingAnchor, constant: 20)
        let stackTrailingConstraint = stackView.trailingAnchor.constraint(equalTo: mainContainerView.trailingAnchor, constant: -20)
        let stackBottomConstraint = stackView.bottomAnchor.constraint(equalTo: mainContainerView.bottomAnchor, constant: -16)
        let collapseCompatiblePriority = UILayoutPriority(999)
        stackTopConstraint.priority = collapseCompatiblePriority
        stackLeadingConstraint.priority = collapseCompatiblePriority
        stackTrailingConstraint.priority = collapseCompatiblePriority
        stackBottomConstraint.priority = collapseCompatiblePriority

        NSLayoutConstraint.activate([
            stackTopConstraint,
            stackLeadingConstraint,
            stackTrailingConstraint,
            stackBottomConstraint
        ])
    }

    private func setupShareStage() {
        // Cover image container (for shadow effect)
        shareCoverContainerView.layer.shadowColor = Colours.shadowBase.cgColor
        shareCoverContainerView.layer.shadowOpacity = 0.25
        shareCoverContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        shareCoverContainerView.layer.shadowRadius = 4

        shareCoverContainerView.addSubviewForConstraints(shareCoverImageView)
        shareCoverContainerView.addSubviewForConstraints(completionBadgeView)

        // Cover image size - larger for better visual presence
        let coverWidth: CGFloat = 156
        let coverHeight: CGFloat = 234

        NSLayoutConstraint.activate([
            shareCoverImageView.topAnchor.constraint(equalTo: shareCoverContainerView.topAnchor),
            shareCoverImageView.bottomAnchor.constraint(equalTo: shareCoverContainerView.bottomAnchor),
            shareCoverImageView.leadingAnchor.constraint(equalTo: shareCoverContainerView.leadingAnchor),
            shareCoverImageView.trailingAnchor.constraint(equalTo: shareCoverContainerView.trailingAnchor),
            shareCoverImageView.widthAnchor.constraint(equalToConstant: coverWidth),
            shareCoverImageView.heightAnchor.constraint(equalToConstant: coverHeight),

            // Badge positioned at top-right, slightly overlapping
            completionBadgeView.widthAnchor.constraint(equalToConstant: 28),
            completionBadgeView.heightAnchor.constraint(equalToConstant: 28),
            completionBadgeView.topAnchor.constraint(equalTo: shareCoverImageView.topAnchor, constant: -8),
            completionBadgeView.trailingAnchor.constraint(equalTo: shareCoverImageView.trailingAnchor, constant: 8)
        ])

        // Load cover image
        if let urlString = metadata.coverImageURLString, let url = URL(string: urlString) {
            shareCoverImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        }

        // Center the cover container
        let coverCenteringContainer = UIView()
        coverCenteringContainer.addSubviewForConstraints(shareCoverContainerView)
        NSLayoutConstraint.activate([
            shareCoverContainerView.centerXAnchor.constraint(equalTo: coverCenteringContainer.centerXAnchor),
            shareCoverContainerView.topAnchor.constraint(equalTo: coverCenteringContainer.topAnchor),
            shareCoverContainerView.bottomAnchor.constraint(equalTo: coverCenteringContainer.bottomAnchor)
        ])

        // Spacer views for vertical centering
        let topSpacer = UIView()
        let bottomSpacer = UIView()
        let minimumShareSpacerHeight: CGFloat = 40

        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight).isActive = true

        shareStageContinueButton.translatesAutoresizingMaskIntoConstraints = false
        shareStageContinueButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight).isActive = true

        let stackView = UIStackView(arrangedSubviews: [
            shareTitleLabel,
            shareSubtitleLabel,
            topSpacer,
            coverCenteringContainer,
            bottomSpacer,
            shareButton,
            shareStageContinueButton
        ])
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.setCustomSpacing(4, after: shareTitleLabel)
        stackView.setCustomSpacing(8, after: shareButton)

        // Make spacers equal height to center the cover + share button group
        topSpacer.heightAnchor.constraint(equalTo: bottomSpacer.heightAnchor).isActive = true
        shareTopSpacerMinHeightConstraint = topSpacer.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumShareSpacerHeight)
        shareBottomSpacerMinHeightConstraint = bottomSpacer.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumShareSpacerHeight)
        shareTopSpacerMinHeightConstraint?.isActive = false
        shareBottomSpacerMinHeightConstraint?.isActive = false

        shareContainerView.addSubviewForConstraints(stackView)
        let stackTopConstraint = stackView.topAnchor.constraint(equalTo: shareContainerView.topAnchor, constant: 16)
        let stackLeadingConstraint = stackView.leadingAnchor.constraint(equalTo: shareContainerView.leadingAnchor, constant: 20)
        let stackTrailingConstraint = stackView.trailingAnchor.constraint(equalTo: shareContainerView.trailingAnchor, constant: -20)
        let stackBottomConstraint = stackView.bottomAnchor.constraint(equalTo: shareContainerView.bottomAnchor, constant: -16)
        let collapseCompatiblePriority = UILayoutPriority(999)
        stackTopConstraint.priority = collapseCompatiblePriority
        stackLeadingConstraint.priority = collapseCompatiblePriority
        stackTrailingConstraint.priority = collapseCompatiblePriority
        stackBottomConstraint.priority = collapseCompatiblePriority

        NSLayoutConstraint.activate([
            stackTopConstraint,
            stackLeadingConstraint,
            stackTrailingConstraint,
            stackBottomConstraint
        ])

        // Start badge hidden for animation
        completionBadgeView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        completionBadgeView.alpha = 0
    }

    // MARK: - Stage Transitions

    private func showStage(_ stage: Stage, animated: Bool) {
        currentStage = stage

        let isShareStage = stage == .share
        shareTopSpacerMinHeightConstraint?.isActive = isShareStage
        shareBottomSpacerMinHeightConstraint?.isActive = isShareStage

        let applyStageVisibility: () -> Void = {
            self.mainContainerView.alpha = stage == .main ? 1 : 0
            self.shareContainerView.alpha = stage == .share ? 1 : 0
        }

        guard animated, view.window != nil else {
            applyStageVisibility()
            if view.window != nil {
                preferredSheetSizing = .fit
            }

            mainContainerView.isUserInteractionEnabled = stage == .main
            shareContainerView.isUserInteractionEnabled = stage == .share

            if stage == .share {
                AnalyticsManager.shared.trackEnhancedBookCompletionShareViewed()
                if animated {
                    animateCoverEntrance()
                }
            }
            return
        }

        view.setNeedsLayout()
        view.layoutIfNeeded()

        UIView.animate(withDuration: 0.3) {
            applyStageVisibility()
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.preferredSheetSizing = .fit
        }

        mainContainerView.isUserInteractionEnabled = stage == .main
        shareContainerView.isUserInteractionEnabled = stage == .share

        // Animate badge/cover and track analytics when entering share stage
        if stage == .share {
            AnalyticsManager.shared.trackEnhancedBookCompletionShareViewed()
            if animated {
                animateCoverEntrance()
            }
        }

    }

    private func animateCompletionBadge() {
        // Reset to hidden state
        completionBadgeView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        completionBadgeView.alpha = 0

        // Pop in with spring animation
        UIView.animate(
            withDuration: 0.45,
            delay: 0.1,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.8,
            options: []
        ) {
            self.completionBadgeView.transform = .identity
            self.completionBadgeView.alpha = 1
        }
    }

    private func animateCoverEntrance() {
        guard !UIAccessibility.isReduceMotionEnabled else {
            animateCompletionBadge()
            return
        }

        shareCoverImageView.transform = .identity

        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.shareCoverImageView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.shareCoverImageView.transform = .identity
            } completion: { _ in
                self.animateCompletionBadge()
            }
        }
    }

    // MARK: - Actions

    @objc private func handleTapToDismissKeyboard() {
        view.endEditing(true)
    }

    private func handleStarRatingChanged(_ rating: Double) {
        guard rating > 0 else { return }

        feedbackPlaceholderLabel.text = RCValues.shared.string(forKey: .bookCompletionReviewPlaceholderTextAB)

        if shouldHideContinueUntilRating && continueButton.alpha == 0 {
            continueButton.isUserInteractionEnabled = true
            UIView.animate(withDuration: 0.2) {
                self.continueButton.alpha = 1
            }
        }

        // Animate feedback field appearing (only once)
        guard !hasFeedbackFieldAppeared else { return }
        hasFeedbackFieldAppeared = true

        feedbackHeightConstraint?.constant = 80

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.feedbackContainer.alpha = 1
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.preferredSheetSizing = .fit
        }
    }

    @objc private func continueTapped() {
        view.endEditing(true)

        let rating = starRatingView.rating

        if rating > 0 {
            showLoadingIndicator(show: true)

            // Track analytics
            switch reviewedContentType {
            case .bookInternal:
                guard let genre = (metadata as? CDBookInternal)?.genre else { return }
                AnalyticsManager.shared.trackBookInternalRatingSubmitted(rating: rating, genre: genre)
            case .bookInternalAudiobook:
                guard let genre = (metadata as? CDBookInternal)?.genre else { return }
                AnalyticsManager.shared.trackBookInternalAudiobookRatingSubmitted(rating: rating, genre: genre)
            }

            let comment: String? = feedbackTextView.text.isEmpty ? nil : feedbackTextView.text

            // This will only work for internal books/audiobooks, but that's fine
            if comment != nil, let genre = (metadata as? CDBookInternal)?.genre {
                AnalyticsManager.shared.trackBookRatingSubmittedWithComment(rating: rating, genre: genre)
            }

            ContentRatingManager.shared.recordRating(rating, content: metadata, type: reviewedContentType, comment: comment) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success(let response):
                    print("✅ Successfully submitted rating. New rating: \(response.newRating), Total ratings: \(response.newNumberOfRatings)")

                    // Update local CoreData with new ratings based on content type
                    switch self.reviewedContentType {
                    case .bookInternal:
                        if let bookInternal = self.metadata as? CDBookInternal {
                            let context = CoreDataBookInternalManager.shared.getContext()
                            context.perform {
                                bookInternal.rating = response.newRating
                                bookInternal.numberOfRatings = Int32(response.newNumberOfRatings)
                                CoreDataBookInternalManager.shared.saveContext()
                            }
                        }
                    case .bookInternalAudiobook:
                        if let audioData = self.audioData {
                            let context = CoreDataBookInternalAudioManager.shared.getContext()
                            context.perform {
                                audioData.rating = response.newRating
                                audioData.numberOfRatings = Int32(response.newNumberOfRatings)
                                CoreDataBookInternalAudioManager.shared.saveContext()
                            }
                        }
                    }

                case .failed(let error):
                    print("⚠️ Failed to submit rating: \(error.localizedDescription)")
                }

                DispatchQueue.main.async {
                    self.showLoadingIndicator(show: false)
                    if rating >= 4 {
                        AppNotifiers.shared.shouldHandleBookCompletion = true
                        self.showStage(.share, animated: true)
                    } else {
                        self.dismissHandler?()
                    }
                }
            }
        } else {
            // No rating selected, go to share stage
            showStage(.share, animated: true)
        }
    }

    @objc private func shareTapped() {
        AnalyticsManager.shared.trackEnhancedBookCompletionShareTapped()

        let bookTitle = metadata.title ?? "a great story"
        let shareText: String
        if Int(starRatingView.rating) == 5 {
            shareText = "I loved \(bookTitle) — free on FreeAudiobooks."
        } else {
            shareText = "I really enjoyed \(bookTitle) — free on FreeAudiobooks."
        }

        // Use deeplink if available, otherwise fall back to App Store URL
        let urlString = metadata.sharingDeeplinkURL ?? RCValues.shared.string(forKey: .appStoreURLAB)
        guard let url = URL(string: urlString) else { return }

        // Pass URL as separate item for rich link previews
        let activityVC = UIActivityViewController(activityItems: [shareText, url], applicationActivities: nil)
        activityVC.completionWithItemsHandler = { [weak self] (activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
            if completed {
                AnalyticsManager.shared.trackEnhancedBookCompletionShareCompleted()
            }
            self?.dismissHandler?()
        }

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = shareButton
            popover.sourceRect = shareButton.bounds
        }

        present(activityVC, animated: true)
    }

    @objc private func skipTapped() {
        AnalyticsManager.shared.trackEnhancedBookCompletionShareSkipped()
        dismissHandler?()
    }

    // MARK: - Loading Indicator

    private func showLoadingIndicator(show: Bool) {
        if show {
            guard loadingIndicatorView == nil else { return }

            continueButton.alpha = 0

            loadingIndicatorView = NVActivityIndicatorView(
                frame: CGRect.zero,
                type: NVActivityIndicatorType.circleStrokeSpin,
                color: Colours.textPrimary,
                padding: 0
            )
            guard let indicatorView = loadingIndicatorView else { return }

            indicatorView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(indicatorView)
            NSLayoutConstraint.activate([
                indicatorView.centerYAnchor.constraint(equalTo: continueButton.centerYAnchor),
                indicatorView.centerXAnchor.constraint(equalTo: continueButton.centerXAnchor),
                indicatorView.widthAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight),
                indicatorView.heightAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight)
            ])
            indicatorView.startAnimating()
        } else {
            loadingIndicatorView?.stopAnimating()
            loadingIndicatorView?.removeFromSuperview()
            loadingIndicatorView = nil

            continueButton.alpha = 1
        }
    }

    private func updateStarRatingColors(for cosmosView: CosmosView) {
        let selectedStarColor = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
        let unselectedStarBorderColor = UIColor.dynamic(
            light: Colours.veryLightUI,
            dark: Colours.textSecondary.withAlphaComponent(0.7)
        )
        cosmosView.settings.filledColor = selectedStarColor
        cosmosView.settings.filledBorderColor = selectedStarColor
        cosmosView.settings.emptyBorderColor = unselectedStarBorderColor
        cosmosView.settings.emptyBorderWidth = 1
    }

    private func updateAppearanceColors() {
        view.backgroundColor = Colours.surfacePrimary
        congratsTitleLabel.textColor = Colours.textPrimary
        ratingCardView.backgroundColor = Colours.surfaceSecondary
        updateStarRatingColors(for: starRatingView)
        feedbackTextView.textColor = Colours.textPrimary
        feedbackTextView.backgroundColor = Colours.surfacePrimary
        feedbackTextView.layer.borderColor = Colours.inputBorder.cgColor
        feedbackPlaceholderLabel.textColor = Colours.subtext
        reviewIntroLabel.textColor = Colours.subtext
        reviewIntroLabel.textAlignment = .center
        ratingPromptLabel.textColor = Colours.subtext
        reviewMetaLabel.textColor = Colours.textSecondary
        shareCoverImageView.backgroundColor = Colours.surfaceSecondary
        shareCoverContainerView.layer.shadowColor = Colours.shadowBase.cgColor
        completionBadgeView.layer.borderColor = UIColor.dynamic(light: Colours.surfacePrimary, dark: .white).cgColor
        shareTitleLabel.textColor = Colours.textPrimary
        let shareCTAColor = Colours.ctaBackground
        shareButton.setTitleColor(shareCTAColor, for: .normal)
        shareButton.layer.borderColor = shareCTAColor.cgColor
        shareButton.layer.borderWidth = 1
    }

    private func applyBookReviewVariantStyling() {
        guard bookReviewVariant == .reviewStyle else { return }

        ratingCardView.layer.cornerRadius = 20
        ratingCardView.layer.cornerCurve = .continuous
        ratingCardView.layer.shadowColor = Colours.shadowBase.cgColor
        ratingCardView.layer.shadowOpacity = 0.08
        ratingCardView.layer.shadowRadius = 14
        ratingCardView.layer.shadowOffset = CGSize(width: 0, height: 6)
        ratingCardView.layer.masksToBounds = false

        feedbackTextView.layer.borderWidth = 1
        feedbackTextView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        feedbackTextView.font = Fonts.medium15
        reviewMetaLabel.textAlignment = .center
    }

    private func configureReviewMetaPreview() {
        let rawReviewerName = AccountManager.shared.user?.displayName
        let reviewerName = rawReviewerName ?? "FreeAudiobooks Listener"
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        let reviewDateText = formatter.string(from: Date())
        reviewMetaLabel.text = "\(reviewerName) · \(reviewDateText)"

        let placeholderImage = ReviewerAvatarPlaceholder.image(
            for: rawReviewerName,
            diameter: 32,
            traitCollection: traitCollection
        )

        if
            let urlString = AccountManager.shared.user?.profileImageURLString,
            let imageURL = URL(string: urlString) {
            reviewAvatarImageView.kf.indicatorType = .activity
            reviewAvatarImageView.kf.setImage(
                with: imageURL,
                placeholder: placeholderImage,
                options: [.transition(.fade(0.2))]
            )
        } else {
            reviewAvatarImageView.image = placeholderImage
        }
    }
}

// MARK: - UITextViewDelegate

extension EnhancedBookCompletionPopupVC: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        feedbackPlaceholderLabel.isHidden = !textView.text.isEmpty
    }
}

// MARK: - UIGestureRecognizerDelegate

extension EnhancedBookCompletionPopupVC: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Don't recognize tap if it's on a button (let the button handle it)
        if touch.view is UIButton {
            return false
        }
        return true
    }
}
