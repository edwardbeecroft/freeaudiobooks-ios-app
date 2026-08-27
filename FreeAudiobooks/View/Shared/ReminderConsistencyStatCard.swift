//
//  ReminderConsistencyStatCard.swift
//  FreeAudiobooks
//
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

/// Compact social-proof card that reinforces the value of enabling reminders.
final class ReminderConsistencyStatCard: UIView {

    private let iconView: UIImageView = {
        let configuration = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let imageView = UIImageView(image: UIImage(systemName: "lightbulb.fill", withConfiguration: configuration))
        imageView.tintColor = .systemYellow
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = Colours.textPrimary
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    init(text: String) {
        super.init(frame: .zero)
        setupUI()
        configureMessage(text)

        isAccessibilityElement = true
        accessibilityLabel = text
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = Colours.surfaceCard
        layer.cornerRadius = 18
        layer.borderWidth = 1
        layer.borderColor = Colours.inputBorder.cgColor

        addSubviewForConstraints(iconView)
        addSubviewForConstraints(messageLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 26),
            iconView.heightAnchor.constraint(equalToConstant: 30),

            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            messageLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ])
    }

    private func configureMessage(_ text: String) {
        let baseFont = UIFont.preferredFont(forTextStyle: .subheadline)
        let attributedText = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: baseFont,
                .foregroundColor: Colours.textPrimary
            ]
        )

        let emphasisRange = (text as NSString).range(of: "2x more consistently", options: .caseInsensitive)
        if emphasisRange.location != NSNotFound {
            let emphasizedFont = UIFont.systemFont(ofSize: baseFont.pointSize, weight: .semibold)
            attributedText.addAttribute(.font, value: emphasizedFont, range: emphasisRange)
        }

        messageLabel.attributedText = attributedText
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        layer.borderColor = Colours.inputBorder.cgColor
    }
}
