//
//  ReadingBarriersVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 27/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

/// Reading barriers question screen
/// Asks "What usually stops you from listening more?"
class ReadingBarriersVC: BaseNewOnboardingVC {

    override var step: NewOnboardingStep { .readingBarriers }

    private var selectedBarriers: [String] = []
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

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()

    private let options: [OnboardingOption] = [
        OnboardingOption(id: ReadingBarrier.lackOfTime.rawValue, title: "Lack of time", icon: "clock.fill"),
        OnboardingOption(id: ReadingBarrier.tooManyChoices.rawValue, title: "Too many choices", icon: "square.stack.3d.up.fill"),
        OnboardingOption(id: ReadingBarrier.hardToStayMotivated.rawValue, title: "Hard to stay motivated", icon: "flame.fill")
    ]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Pre-populate with previously selected barriers
        selectedBarriers = coordinator.dataStore.readingBarriers
        setupUI()
        createOptionViews()
    }

    override func configureButtonState() {
        updateContinueButton()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        if parent != nil && !hasAnimatedEntrance {
            hasAnimatedEntrance = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.animateOptionsEntrance()
            }
        }
    }

    // MARK: - Setup

    private func setupUI() {
        titleLabel.text = RCValues.shared.string(forKey: .onbReadingBarriersTitleAB)
        subtitleLabel.text = RCValues.shared.string(forKey: .onbReadingBarriersSubtitle)

        contentView.addSubviewForConstraints(titleLabel)
        contentView.addSubviewForConstraints(subtitleLabel)
        contentView.addSubviewForConstraints(stackView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            stackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }

    private func createOptionViews() {
        for option in options {
            let optionView = OnboardingOptionView()
            let isSelected = selectedBarriers.contains(option.id)
            optionView.configure(with: option, isSelected: isSelected)

            optionView.translatesAutoresizingMaskIntoConstraints = false
            optionView.heightAnchor.constraint(equalToConstant: 72).isActive = true

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

    // MARK: - Animation

    private func animateOptionsEntrance() {
        for (index, optionView) in optionViews.enumerated() {
            let delay = Double(index) * 0.08
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

    // MARK: - Selection

    private func handleOptionTap(_ optionId: String) {
        if selectedBarriers.contains(optionId) {
            selectedBarriers.removeAll { $0 == optionId }
        } else {
            selectedBarriers.append(optionId)
        }

        // Update all option views
        for optionView in optionViews {
            let isSelected = selectedBarriers.contains(optionView.optionId)
            optionView.setSelected(isSelected, animated: true)
        }

        updateContinueButton()
    }

    private func updateContinueButton() {
        setContinueButtonEnabled(!selectedBarriers.isEmpty)
        setContinueButtonTitle(RCValues.shared.string(forKey: .onbContinueButtonTitle))
    }

    override func continueButtonTapped() {
        coordinator.dataStore.readingBarriers = selectedBarriers
        super.continueButtonTapped()
    }
}
