//
//  StatsCardView.swift
//  FreeAudiobooks
//
//  Created by FreeAudiobooks on 15/11/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

class StatsCardView: UIView {

    private let containerView = UIView()
    private let titleIconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let suffixLabel = UILabel()
    private let percentileBadge = PercentileBadgeView()
    private let infoButton = UIButton(type: .system)
    private let titleStack = UIStackView()

    var onInfoTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        // Container with border and corner radius
        addSubviewForConstraints(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        containerView.layer.cornerRadius = UIConstants.shared.cardCornerRadius
//        containerView.layer.borderWidth = 1
//        containerView.layer.borderColor = Colours.charcoal.withAlphaComponent(0.1).cgColor
        containerView.backgroundColor = Colours.surfaceCard

        // Title icon
        titleIconImageView.contentMode = .scaleAspectFit
        titleIconImageView.tintColor = Colours.textSecondary
        titleIconImageView.isHidden = true
        NSLayoutConstraint.activate([
            titleIconImageView.widthAnchor.constraint(equalToConstant: 16),
            titleIconImageView.heightAnchor.constraint(equalToConstant: 16)
        ])

        // Title
        titleLabel.font = Fonts.regular14
        titleLabel.textColor = Colours.textSecondary
        titleLabel.numberOfLines = 0

        // Title stack (icon + label)
        titleStack.axis = .horizontal
        titleStack.spacing = 6
        titleStack.alignment = .center
        titleStack.addArrangedSubview(titleIconImageView)
        titleStack.addArrangedSubview(titleLabel)

        // Info button
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        let iconImage = UIImage(systemName: "info.circle", withConfiguration: iconConfig)
        infoButton.setImage(iconImage, for: .normal)
        infoButton.tintColor = Colours.veryLightUI
        infoButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        infoButton.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        infoButton.isHidden = true

        // Add title stack and info button directly to container
        containerView.addSubviewForConstraints(titleStack)
        containerView.addSubviewForConstraints(infoButton)

        // Value and suffix stack
        valueLabel.font = Fonts.semiBold23
        valueLabel.textColor = Colours.textPrimary
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)

        suffixLabel.font = Fonts.regular17
        suffixLabel.textColor = Colours.textSecondary
        suffixLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let valueStack = UIStackView(arrangedSubviews: [valueLabel, suffixLabel])
        valueStack.axis = .horizontal
        valueStack.spacing = 8
        valueStack.alignment = .lastBaseline

        // Main stack (without title, since it's positioned separately)
        let mainStack = UIStackView(arrangedSubviews: [valueStack, percentileBadge])
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.alignment = .leading

        containerView.addSubviewForConstraints(mainStack)

        NSLayoutConstraint.activate([
            // Title stack: left-aligned with same inset
            titleStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleStack.trailingAnchor.constraint(lessThanOrEqualTo: infoButton.leadingAnchor, constant: -8),

            // Info button: right-aligned with same inset, vertically centered with title
            infoButton.centerYAnchor.constraint(equalTo: titleStack.centerYAnchor),
            infoButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            // Main stack: positioned below title
            mainStack.topAnchor.constraint(equalTo: titleStack.bottomAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }

    func configure(
        title: String,
        value: String,
        suffix: String,
        percentile: Int?,
        infoText: String? = nil,
        titleIconName: String? = nil
    ) {
        titleLabel.text = title
        valueLabel.text = value
        suffixLabel.text = suffix
        suffixLabel.isHidden = suffix.isEmpty

        if let percentile = percentile {
            percentileBadge.isHidden = false
            percentileBadge.configure(percentile: percentile)
        } else {
            percentileBadge.isHidden = true
        }

        // Show/hide info button based on infoText
        infoButton.isHidden = infoText == nil

        // Show/hide title icon based on titleIconName
        if let iconName = titleIconName {
            titleIconImageView.image = UIImage(named: iconName)
            titleIconImageView.isHidden = false
        } else {
            titleIconImageView.isHidden = true
        }
    }

    @objc private func infoButtonTapped() {
        onInfoTapped?()
    }

    func updatePercentile(_ percentile: Int?) {
        if let percentile = percentile {
            percentileBadge.configure(percentile: percentile)
            if percentileBadge.isHidden {
                // Start small and invisible
                percentileBadge.alpha = 0
                percentileBadge.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
                percentileBadge.isHidden = false

                // Spring animation for a celebratory pop effect
                UIView.animate(
                    withDuration: 0.8,
                    delay: 0,
                    usingSpringWithDamping: 0.6,
                    initialSpringVelocity: 0.5,
                    options: [.curveEaseOut, .allowUserInteraction]
                ) {
                    self.percentileBadge.alpha = 1
                    self.percentileBadge.transform = .identity
                }
            }
        } else {
            percentileBadge.isHidden = true
        }
    }
}
