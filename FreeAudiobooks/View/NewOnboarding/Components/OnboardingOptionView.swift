//
//  OnboardingOptionView.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

/// Row-based view for onboarding selection screens (Cal AI style)
/// Used in a stack view for easier cascade animations
class OnboardingOptionView: UIView {

    // MARK: - Properties

    private(set) var optionId: String = ""
    private(set) var isOptionSelected: Bool = false
    var onTap: ((String) -> Void)?

    // MARK: - Cal AI Colors

    private let calAISelectableBg = UIColor.dynamic(
        light: UIColor(red: 246/255, green: 246/255, blue: 251/255, alpha: 1),
        dark: Colours.surfaceSecondary
    )

    // MARK: - UI Elements

    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.backgroundColor = UIColor.dynamic(
            light: UIColor(red: 246/255, green: 246/255, blue: 251/255, alpha: 1),
            dark: Colours.surfaceSecondary
        )
        return view
    }()

    private let iconContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 22
        view.backgroundColor = Colours.surfacePrimary
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = Colours.textPrimary
        return imageView
    }()

    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 22)
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = Colours.textPrimary
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = Colours.subtext
        return label
    }()

    private let labelsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .leading
        return stack
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubviewForConstraints(containerView)
        containerView.addSubviewForConstraints(iconContainerView)
        iconContainerView.addSubviewForConstraints(iconImageView)
        iconContainerView.addSubviewForConstraints(emojiLabel)
        containerView.addSubviewForConstraints(labelsStackView)

        labelsStackView.addArrangedSubview(titleLabel)
        labelsStackView.addArrangedSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconContainerView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconContainerView.widthAnchor.constraint(equalToConstant: 44),
            iconContainerView.heightAnchor.constraint(equalToConstant: 44),

            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),

            emojiLabel.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),

            labelsStackView.leadingAnchor.constraint(equalTo: iconContainerView.trailingAnchor, constant: 16),
            labelsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            labelsStackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }

    private func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    // MARK: - Configuration

    func configure(with option: OnboardingOption, isSelected: Bool) {
        self.optionId = option.id
        self.isOptionSelected = isSelected

        titleLabel.text = option.title
        subtitleLabel.text = option.subtitle
        subtitleLabel.isHidden = option.subtitle == nil

        // Configure icon or emoji
        if let iconName = option.icon {
            iconImageView.isHidden = false
            emojiLabel.isHidden = true

            if let sfSymbol = UIImage(systemName: iconName) {
                iconImageView.image = sfSymbol
            } else if let assetImage = UIImage(named: iconName) {
                if option.iconIsTemplate {
                    iconImageView.image = assetImage.withRenderingMode(.alwaysTemplate)
                } else {
                    iconImageView.image = assetImage.withRenderingMode(.alwaysOriginal)
                }
            }
        } else if let emoji = option.emoji {
            iconImageView.isHidden = true
            emojiLabel.isHidden = false
            emojiLabel.text = emoji
        } else {
            iconImageView.isHidden = true
            emojiLabel.isHidden = true
        }

        updateSelectionStyle(isSelected: isSelected, animated: false)
    }

    func setSelected(_ selected: Bool, animated: Bool) {
        isOptionSelected = selected
        updateSelectionStyle(isSelected: selected, animated: animated)
    }

    private func updateSelectionStyle(isSelected: Bool, animated: Bool) {
        let changes = {
            if isSelected {
                self.containerView.backgroundColor = Colours.ctaBackground
                self.iconContainerView.backgroundColor = Colours.surfacePrimary
                self.iconImageView.tintColor = Colours.textPrimary
                self.titleLabel.textColor = Colours.ctaForeground
                self.subtitleLabel.textColor = Colours.ctaForeground.withAlphaComponent(0.7)
            } else {
                self.containerView.backgroundColor = self.calAISelectableBg
                self.iconContainerView.backgroundColor = Colours.surfacePrimary
                self.iconImageView.tintColor = Colours.textPrimary
                self.titleLabel.textColor = Colours.textPrimary
                self.subtitleLabel.textColor = Colours.textSecondary
            }
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: changes)
        } else {
            changes()
        }
    }

    // MARK: - Actions

    @objc private func handleTap() {
        HapticFeedbackHelper.shared.triggerLightImpactFeedback()
        animatePress()
        onTap?(optionId)
    }

    private func animatePress() {
        UIView.animate(withDuration: 0.1, delay: 0, options: [.allowUserInteraction, .curveEaseIn]) {
            self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        } completion: { _ in
            UIView.animate(withDuration: 0.1, delay: 0, options: [.allowUserInteraction, .curveEaseOut]) {
                self.transform = .identity
            }
        }
    }

    // MARK: - Touch Handling for Press Animation

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.1, delay: 0, options: [.allowUserInteraction, .curveEaseIn]) {
            self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.1, delay: 0, options: [.allowUserInteraction, .curveEaseOut]) {
            self.transform = .identity
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.1, delay: 0, options: [.allowUserInteraction, .curveEaseOut]) {
            self.transform = .identity
        }
    }
}
