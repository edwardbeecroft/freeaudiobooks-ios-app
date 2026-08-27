//
//  OnboardingOptionCell.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

/// Row-based cell for onboarding selection screens (Cal AI style)
class OnboardingOptionCell: UICollectionViewCell {

    static let reuseIdentifier = "OnboardingOptionCell"

    // MARK: - UI Elements

    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        return view
    }()

    private let iconContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 22
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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.addSubviewForConstraints(containerView)
        containerView.addSubviewForConstraints(iconContainerView)
        iconContainerView.addSubviewForConstraints(iconImageView)
        iconContainerView.addSubviewForConstraints(emojiLabel)
        containerView.addSubviewForConstraints(labelsStackView)

        labelsStackView.addArrangedSubview(titleLabel)
        labelsStackView.addArrangedSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

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

    // MARK: - Configuration

    func configure(with option: OnboardingOption, isSelected: Bool) {
        titleLabel.text = option.title
        subtitleLabel.text = option.subtitle
        subtitleLabel.isHidden = option.subtitle == nil

        // Configure icon or emoji
        if let iconName = option.icon {
            iconImageView.isHidden = false
            emojiLabel.isHidden = true

            if let sfSymbol = UIImage(systemName: iconName) {
                // SF Symbols are always template
                iconImageView.image = sfSymbol
            } else if let assetImage = UIImage(named: iconName) {
                // Asset images use specified rendering mode
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

        // Apply selected/unselected styling
        if isSelected {
            containerView.backgroundColor = Colours.ctaBackground
            iconContainerView.backgroundColor = .white
            iconImageView.tintColor = Colours.textPrimary
            titleLabel.textColor = .white
            subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        } else {
            containerView.backgroundColor = Colours.surfaceCard
            iconContainerView.backgroundColor = Colours.surfacePrimary
            iconImageView.tintColor = Colours.textPrimary
            titleLabel.textColor = Colours.textPrimary
            subtitleLabel.textColor = Colours.textSecondary
        }
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        subtitleLabel.text = nil
        subtitleLabel.isHidden = true
        iconImageView.image = nil
        emojiLabel.text = nil
    }

    // MARK: - Press Animation

    /// Animates a quick press and release for selection feedback
    func animateSelection() {
        UIView.animate(withDuration: 0.08, delay: 0, options: [.allowUserInteraction, .curveEaseIn]) {
            self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        } completion: { _ in
            UIView.animate(withDuration: 0.08, delay: 0, options: [.allowUserInteraction, .curveEaseOut]) {
                self.transform = .identity
            }
        }
    }

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                UIView.animate(withDuration: 0.08, delay: 0, options: [.allowUserInteraction, .curveEaseIn]) {
                    self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
                }
            } else {
                UIView.animate(withDuration: 0.08, delay: 0, options: [.allowUserInteraction, .curveEaseOut]) {
                    self.transform = .identity
                }
            }
        }
    }
}
