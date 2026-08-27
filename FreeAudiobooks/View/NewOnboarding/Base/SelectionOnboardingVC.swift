//
//  SelectionOnboardingVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

/// Represents an option in a selection screen
struct OnboardingOption {
    let id: String
    let title: String
    let subtitle: String?
    let emoji: String?
    let icon: String?  // SF Symbol name or image asset name
    let iconIsTemplate: Bool  // If true, renders as template with tint color

    init(id: String, title: String, subtitle: String? = nil, emoji: String? = nil, icon: String? = nil, iconIsTemplate: Bool = true) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.emoji = emoji
        self.icon = icon
        self.iconIsTemplate = iconIsTemplate
    }
}

/// Base view controller for selection screens in onboarding
/// Uses a stack view for easier cascade animations
class SelectionOnboardingVC: BaseNewOnboardingVC {

    // MARK: - Configuration (Override in subclasses)

    /// Whether multiple options can be selected
    var allowsMultipleSelection: Bool { true }

    /// Minimum number of selections required to continue
    var minimumSelections: Int { 1 }

    /// Available options to display
    var options: [OnboardingOption] { [] }

    /// Title text for the screen
    func getTitle() -> String {
        fatalError("Subclasses must override getTitle()")
    }

    /// Subtitle text for the screen
    func getSubtitle() -> String {
        fatalError("Subclasses must override getSubtitle()")
    }

    /// Called when selections are confirmed (before navigating)
    /// - Parameter selectedIds: Array of selected IDs in the order they were tapped
    func handleSelections(_ selectedIds: [String]) {
        // Override in subclasses to save to dataStore
    }

    /// Override to return previously selected IDs from dataStore (for back navigation)
    func getInitialSelections() -> [String] {
        return []
    }

    // MARK: - Properties

    private(set) var selectedIds: [String] = []
    private var optionViews: [OnboardingOptionView] = []
    private var hasAnimatedEntrance = false

    // MARK: - UI Elements

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = Colours.textPrimary
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = Colours.textSecondary
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = true
        sv.alwaysBounceVertical = true
        sv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        return sv
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        selectedIds = getInitialSelections()
        setupSelectionUI()
        createOptionViews()
        updateContinueButtonState()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        titleLabel.textColor = Colours.textPrimary
        subtitleLabel.textColor = Colours.textSecondary
    }

    override func configureButtonState() {
        updateContinueButtonState()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        if parent != nil && !hasAnimatedEntrance {
            hasAnimatedEntrance = true
            // Small delay to ensure views are laid out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.animateCellsEntrance()
            }
        }
    }

    // MARK: - Entrance Animation

    private func animateCellsEntrance() {
        // Animate each option view with staggered delay
        for (index, optionView) in optionViews.enumerated() {
            let delay = Double(index) * 0.08  // 80ms stagger between each
            UIView.animate(
                withDuration: 0.4,
                delay: delay,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.3,
                options: [.curveEaseOut],
                animations: {
                    optionView.alpha = 1
                    optionView.transform = .identity
                }
            )
        }
    }

    // MARK: - Setup

    private func setupSelectionUI() {
        titleLabel.text = getTitle()

        let subtitle = getSubtitle()
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle.isEmpty

        contentView.addSubviewForConstraints(titleLabel)
        contentView.addSubviewForConstraints(subtitleLabel)
        contentView.addSubviewForConstraints(scrollView)
        scrollView.addSubviewForConstraints(stackView)

        // Dynamic top constraint for scroll view based on subtitle visibility
        let scrollTopAnchor = subtitle.isEmpty
            ? scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30)
            : scrollView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),

            scrollTopAnchor,
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func createOptionViews() {
        for option in options {
            let optionView = OnboardingOptionView()
            let isSelected = selectedIds.contains(option.id)
            optionView.configure(with: option, isSelected: isSelected)

            // Set height based on whether there's a subtitle
            let height: CGFloat = option.subtitle != nil ? 84 : 72
            optionView.translatesAutoresizingMaskIntoConstraints = false
            optionView.heightAnchor.constraint(equalToConstant: height).isActive = true

            // Start hidden for animation
            optionView.alpha = 0
            optionView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)

            optionView.onTap = { [weak self] optionId in
                self?.handleOptionTap(optionId)
            }

            stackView.addArrangedSubview(optionView)
            optionViews.append(optionView)
        }
    }

    // MARK: - Selection Management

    private func handleOptionTap(_ optionId: String) {
        if allowsMultipleSelection {
            if selectedIds.contains(optionId) {
                selectedIds.removeAll { $0 == optionId }
            } else {
                selectedIds.append(optionId)
            }
        } else {
            let wasSelected = selectedIds.contains(optionId)
            selectedIds = wasSelected ? [] : [optionId]
        }

        // Update all option views
        for optionView in optionViews {
            let isSelected = selectedIds.contains(optionView.optionId)
            optionView.setSelected(isSelected, animated: true)
        }

        updateContinueButtonState()
    }

    private func updateContinueButtonState() {
        let isEnabled = selectedIds.count >= minimumSelections
        setContinueButtonEnabled(isEnabled)

        if selectedIds.isEmpty {
            setContinueButtonTitle(RCValues.shared.string(forKey: .onbContinueButtonTitle))
        } else if selectedIds.count < minimumSelections {
            let remaining = minimumSelections - selectedIds.count
            setContinueButtonTitle("Select \(remaining) More")
        } else {
            setContinueButtonTitle(RCValues.shared.string(forKey: .onbContinueButtonTitle))
        }
    }

    // MARK: - Actions

    override func continueButtonTapped() {
        handleSelections(selectedIds)
        super.continueButtonTapped()
    }
}
