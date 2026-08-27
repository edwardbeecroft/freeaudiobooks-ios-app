//
//  RecapSheetVC.swift
//  FreeAudiobooks
//
//  Created by Claude on 28/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import Lottie
import BetterSegmentedControl

final class RecapSheetVC: BottomSheetController {

    // MARK: - State

    private enum State {
        case loading
        case content(String)
        case error(RecapError)
    }

    private var currentState: State = .loading {
        didSet {
            updateUI()
        }
    }

    // MARK: - Properties

    private let metadata: ReadableContentMetadata
    private let content: ReadableContent

    // MARK: - UI Elements

    private let mainStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.distribution = .fill
        sv.alignment = .fill
        sv.spacing = 0
        return sv
    }()

    // Header
    private let headerView = UIView()

    private let headerTitleLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.medium15
        label.textColor = Colours.textPrimary
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = Colours.textSecondary
        return button
    }()

    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = Colours.grey220
        return view
    }()

    // Content Container (holds loading, content, error views)
    private let contentContainerView = UIView()

    // Loading View
    private let loadingView: UIView = {
        let view = UIView()
        view.isHidden = false
        return view
    }()

    private lazy var loadingAnimationView: LottieAnimationView = {
        let animationView = LottieAnimationView(name: "sparkles")
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        return animationView
    }()

    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.text = "Generating your recap..."
        label.font = Fonts.medium16
        label.textColor = Colours.subtext
        label.textAlignment = .center
        return label
    }()

    // Content View (success state)
    private let contentView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private lazy var lengthSegmentedControl: BetterSegmentedControl = {
        let sc = BetterSegmentedControl(
            frame: .zero,
            segments: LabelSegment.segments(
                withTitles: ["Short", "Medium", "Long"],
                normalFont: Fonts.medium14,
                normalTextColor: .white,
                selectedFont: Fonts.semiBold14,
                selectedTextColor: Colours.textPrimary),
            index: 1,
            options: [.backgroundColor(Colours.ctaBackground),
                      .indicatorViewBackgroundColor(.white),
                      .cornerRadius(16),
                      .animationSpringDamping(1.0)])
        sc.isEnabled = false
        sc.alpha = 0.5
        sc.addTarget(self, action: #selector(recapLengthChanged), for: .valueChanged)
        return sc
    }()

    private let recapContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = Colours.surfaceSecondary
        view.layer.cornerRadius = UIConstants.shared.cardCornerRadius
        view.clipsToBounds = true
        return view
    }()

    private let recapTextView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.isScrollEnabled = true
        tv.font = ReadingUserDefaults.getFont()
        tv.textColor = Colours.textPrimary
        tv.backgroundColor = .clear
        tv.showsVerticalScrollIndicator = true
        tv.verticalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -4)
        return tv
    }()

    private let continueReadingButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue Listening", for: .normal)
        button.titleLabel?.font = Fonts.semiBold16
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = Colours.ctaBackground
        button.layer.cornerRadius = 25
        return button
    }()

    // Error View
    private let errorView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private let errorIconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
        iv.image = UIImage(systemName: "exclamationmark.triangle", withConfiguration: config)
        iv.tintColor = Colours.subtext
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.medium15
        label.textColor = Colours.subtext
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Retry", for: .normal)
        button.titleLabel?.font = Fonts.semiBold16
        button.setTitleColor(Colours.textPrimary, for: .normal)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 25
        button.layer.borderWidth = 1
        button.layer.borderColor = Colours.inputBorder.cgColor
        return button
    }()

    private let errorDismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Dismiss", for: .normal)
        button.titleLabel?.font = Fonts.medium15
        button.setTitleColor(Colours.negativeButtonTitle, for: .normal)
        return button
    }()

    private let errorContinueReadingButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue Listening", for: .normal)
        button.titleLabel?.font = Fonts.semiBold16
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = Colours.brandBlack
        button.layer.cornerRadius = 25
        button.isHidden = true
        return button
    }()

    // MARK: - Init

    init(metadata: ReadableContentMetadata, content: ReadableContent) {
        self.metadata = metadata
        self.content = content
        super.init(nibName: nil, bundle: nil)

        preferredSheetSizing = .large
        preferredSheetCornerRadius = 16
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupActions()
        applyTheme()
        fetchRecap()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        applyTheme()
    }

    // MARK: - Setup

    private func setupViews() {
        // Add main stack to view
        view.addSubview(mainStackView)
        mainStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: view.topAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Setup header
        setupHeader()

        // Soft hairline divider
        mainStackView.addArrangedSubview(dividerView)
        dividerView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true

        // Setup segmented control (between header and content, always visible)
        setupLengthSegmentedControl()

        // Setup content container
        setupContentContainer()
    }

    private func setupHeader() {
        mainStackView.addArrangedSubview(headerView)
        headerView.heightAnchor.constraint(equalToConstant: 56).isActive = true

        headerView.addSubview(headerTitleLabel)
        headerTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerTitleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            headerTitleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
    }

    private func setupLengthSegmentedControl() {
        let wrapper = UIView()
        wrapper.addSubview(lengthSegmentedControl)
        lengthSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lengthSegmentedControl.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 12),
            lengthSegmentedControl.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 20),
            lengthSegmentedControl.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -20),
            lengthSegmentedControl.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -12),
            lengthSegmentedControl.heightAnchor.constraint(equalToConstant: 32)
        ])
        mainStackView.addArrangedSubview(wrapper)
    }

    private func setupContentContainer() {
        mainStackView.addArrangedSubview(contentContainerView)

        // Add all state views to container
        contentContainerView.addSubview(loadingView)
        contentContainerView.addSubview(contentView)
        contentContainerView.addSubview(errorView)

        loadingView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        errorView.translatesAutoresizingMaskIntoConstraints = false

        // All state views fill the container
        for stateView in [loadingView, contentView, errorView] {
            NSLayoutConstraint.activate([
                stateView.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
                stateView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
                stateView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
                stateView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor)
            ])
        }

        setupLoadingView()
        setupContentView()
        setupErrorView()
    }

    private func setupLoadingView() {
        let loadingStack = UIStackView(arrangedSubviews: [loadingAnimationView, loadingLabel])
        loadingStack.axis = .vertical
        loadingStack.spacing = 12
        loadingStack.alignment = .center

        loadingView.addSubview(loadingStack)
        loadingStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            loadingStack.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            loadingStack.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor),
            loadingAnimationView.widthAnchor.constraint(equalToConstant: 64),
            loadingAnimationView.heightAnchor.constraint(equalToConstant: 64)
        ])

        loadingAnimationView.play()
    }

    private func setupContentView() {
        let contentStack = UIStackView(arrangedSubviews: [recapContainerView, continueReadingButton])
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.alignment = .fill

        contentView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])

        // Recap container expands to fill available space
        recapContainerView.setContentHuggingPriority(.defaultLow, for: .vertical)
        recapContainerView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        // Text view inside recap container
        recapContainerView.addSubview(recapTextView)
        recapTextView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            recapTextView.topAnchor.constraint(equalTo: recapContainerView.topAnchor, constant: 16),
            recapTextView.leadingAnchor.constraint(equalTo: recapContainerView.leadingAnchor, constant: 16),
            recapTextView.trailingAnchor.constraint(equalTo: recapContainerView.trailingAnchor, constant: -16),
            recapTextView.bottomAnchor.constraint(equalTo: recapContainerView.bottomAnchor, constant: -16)
        ])

        // Button height
        continueReadingButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

        // Set header title with book name and progress
        let title = metadata.title ?? "Recap"
        let progress = metadata.progressPercentageString
        headerTitleLabel.text = "\(title) · \(progress)"
    }

    private func setupErrorView() {
        let errorStack = UIStackView(arrangedSubviews: [errorIconImageView, errorLabel, retryButton, errorDismissButton, errorContinueReadingButton])
        errorStack.axis = .vertical
        errorStack.spacing = 24
        errorStack.alignment = .fill

        errorView.addSubview(errorStack)
        errorStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            errorStack.centerYAnchor.constraint(equalTo: errorView.centerYAnchor),
            errorStack.leadingAnchor.constraint(equalTo: errorView.leadingAnchor, constant: 20),
            errorStack.trailingAnchor.constraint(equalTo: errorView.trailingAnchor, constant: -20)
        ])

        // Icon centering
        errorIconImageView.heightAnchor.constraint(equalToConstant: 48).isActive = true

        // Button heights
        retryButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        errorDismissButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        errorContinueReadingButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }

    private func setupActions() {
        continueReadingButton.addTarget(self, action: #selector(continueReadingTapped), for: .touchUpInside)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        errorDismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        errorContinueReadingButton.addTarget(self, action: #selector(continueReadingTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func continueReadingTapped() {
        AnalyticsManager.shared.trackRecapContinueReadingTapped()
        dismiss(animated: true)
    }

    @objc private func dismissTapped() {
        AnalyticsManager.shared.trackRecapDismissed()
        dismiss(animated: true)
    }

    @objc private func retryTapped() {
        AnalyticsManager.shared.trackRecapRetryTapped()
        currentState = .loading
        fetchRecap()
    }

    @objc private func recapLengthChanged() {
        currentState = .loading
        fetchRecap()
    }

    private var selectedRecapLength: String {
        switch lengthSegmentedControl.index {
        case 0: return "short"
        case 2: return "long"
        default: return "medium"
        }
    }

    // MARK: - State Management

    private func updateUI() {
        switch currentState {
        case .loading:
            loadingView.isHidden = false
            contentView.isHidden = true
            errorView.isHidden = true
            lengthSegmentedControl.isEnabled = false
            lengthSegmentedControl.alpha = 0.5
            loadingAnimationView.play()

        case .content(let recap):
            loadingView.isHidden = true
            errorView.isHidden = true
            loadingAnimationView.stop()
            HapticFeedbackHelper.shared.triggerLightImpactFeedback()
            recapTextView.text = recap
            recapTextView.setContentOffset(.zero, animated: false)

            // Animate content in: text first, then button
            contentView.isHidden = false
            recapContainerView.alpha = 0
            recapContainerView.transform = CGAffineTransform(translationX: 0, y: 12)
            continueReadingButton.alpha = 0
            continueReadingButton.transform = CGAffineTransform(translationX: 0, y: 12)

            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0, options: .curveEaseOut) {
                self.recapContainerView.alpha = 1
                self.recapContainerView.transform = .identity
            }

            UIView.animate(withDuration: 0.4, delay: 0.15, usingSpringWithDamping: 0.85, initialSpringVelocity: 0, options: .curveEaseOut) {
                self.continueReadingButton.alpha = 1
                self.continueReadingButton.transform = .identity
            }

            // Enable segmented control with fade
            UIView.animate(withDuration: 0.3, delay: 0) {
                self.lengthSegmentedControl.alpha = 1.0
            }
            lengthSegmentedControl.isEnabled = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.recapTextView.flashScrollIndicators()
            }

        case .error(let error):
            loadingView.isHidden = true
            contentView.isHidden = true
            errorView.isHidden = false
            loadingAnimationView.stop()
            errorLabel.text = error.localizedDescription

            // Show different UI based on error type
            let isNeedsMoreReadingError = if case .needsMoreReading = error { true } else { false }
            retryButton.isHidden = isNeedsMoreReadingError
            errorDismissButton.isHidden = isNeedsMoreReadingError
            errorContinueReadingButton.isHidden = !isNeedsMoreReadingError

            // Use appropriate icon
            let iconName = isNeedsMoreReadingError ? "book.pages" : "exclamationmark.triangle"
            let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
            errorIconImageView.image = UIImage(systemName: iconName, withConfiguration: config)
        }

        // Force layout update for sheet sizing
        view.layoutIfNeeded()
    }

    // MARK: - Theme

    private func applyTheme() {
        let theme = ReadingUserDefaults.theme
        let textColor = theme.textColor
        let secondaryText = textColor.withAlphaComponent(0.6)
        let subtleFill = textColor.withAlphaComponent(0.08)
        let buttonBg = theme.buttonBackgroundColor
        let buttonTitle = theme.buttonTitleColor
        let dismissColor = textColor.withAlphaComponent(0.5)
        let selectedIndex = (0...2).contains(lengthSegmentedControl.index) ? lengthSegmentedControl.index : 1

        // Sheet background
        view.backgroundColor = theme.backgroundColor

        // Header
        headerTitleLabel.textColor = textColor
        dividerView.backgroundColor = textColor.withAlphaComponent(theme.isDark ? 0.30 : 0.25)

        // Loading state
        loadingLabel.textColor = secondaryText

        // Segmented control
        lengthSegmentedControl.indicatorViewBackgroundColor = buttonBg
        lengthSegmentedControl.backgroundColor = subtleFill
        lengthSegmentedControl.segments = LabelSegment.segments(
            withTitles: ["Short", "Medium", "Long"],
            normalFont: Fonts.medium14,
            normalTextColor: secondaryText,
            selectedFont: Fonts.semiBold14,
            selectedTextColor: buttonTitle)
        lengthSegmentedControl.setIndex(selectedIndex, animated: false)

        // Content state
        recapContainerView.backgroundColor = subtleFill
        recapTextView.font = ReadingUserDefaults.getFont()
        recapTextView.textColor = textColor
        recapTextView.indicatorStyle = theme.isDark ? .white : .default

        // Continue listening button
        continueReadingButton.backgroundColor = buttonBg
        continueReadingButton.setTitleColor(buttonTitle, for: .normal)

        // Error state
        errorIconImageView.tintColor = secondaryText
        errorLabel.textColor = secondaryText
        retryButton.setTitleColor(buttonBg, for: .normal)
        retryButton.layer.borderColor = buttonBg.cgColor
        errorDismissButton.setTitleColor(dismissColor, for: .normal)
        errorContinueReadingButton.backgroundColor = buttonBg
        errorContinueReadingButton.setTitleColor(buttonTitle, for: .normal)
    }

    // MARK: - Fetch Recap

    private func fetchRecap() {
        HapticFeedbackHelper.shared.prepareLightFeedbackGenerator()
        AnalyticsManager.shared.trackRecapViewed(genre: (metadata as? CDBookInternal)?.genre)

        RecapManager.shared.generateRecap(for: metadata, content: content, recapLength: selectedRecapLength) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    AnalyticsManager.shared.trackRecapGenerated(genre: (self?.metadata as? CDBookInternal)?.genre)
                    self?.currentState = .content(response.recap)

                case .failure(let error):
                    AnalyticsManager.shared.trackRecapError(error: error.localizedDescription)
                    self?.currentState = .error(error)
                }
            }
        }
    }
}
