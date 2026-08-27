//
//  ListeningQuotaPillView.swift
//  FreeAudiobooks
//
//  Created by Codex on 20/05/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

final class ListeningQuotaPillView: UIControl {

    private let stackView = UIStackView()
    private let iconImageView = UIImageView(image: UIImage(systemName: "headphones"))
    private let countBackgroundView = UIView()
    private let countLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = UIColor.dynamic(
            light: Colours.orangePrimary.withAlphaComponent(0.10),
            dark: Colours.orangePrimary.withAlphaComponent(0.18)
        )
        layer.cornerRadius = 16
        layer.masksToBounds = true

        iconImageView.tintColor = Colours.orangePrimary
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.setContentHuggingPriority(.required, for: .horizontal)

        countBackgroundView.backgroundColor = UIColor.dynamic(
            light: Colours.orangePrimary.withAlphaComponent(0.20),
            dark: Colours.orangePrimary.withAlphaComponent(0.36)
        )
        countBackgroundView.layer.cornerRadius = 11
        countBackgroundView.layer.masksToBounds = true

        countLabel.font = Fonts.semiBold13
        countLabel.textColor = Colours.orangePrimary
        countLabel.textAlignment = .center
        countBackgroundView.addSubviewForConstraints(countLabel)

        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 6
        stackView.isUserInteractionEnabled = false
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(countBackgroundView)
        addSubviewForConstraints(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),

            iconImageView.widthAnchor.constraint(equalToConstant: 14),
            iconImageView.heightAnchor.constraint(equalToConstant: 14),

            countLabel.topAnchor.constraint(equalTo: countBackgroundView.topAnchor, constant: 3),
            countLabel.bottomAnchor.constraint(equalTo: countBackgroundView.bottomAnchor, constant: -3),
            countLabel.leadingAnchor.constraint(equalTo: countBackgroundView.leadingAnchor, constant: 8),
            countLabel.trailingAnchor.constraint(equalTo: countBackgroundView.trailingAnchor, constant: -8),

            heightAnchor.constraint(equalToConstant: 32)
        ])

        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    func configure(remaining: Int, limit: Int) {
        let attributed = NSMutableAttributedString(
            string: "\(remaining)",
            attributes: [
                .font: Fonts.semiBold13,
                .foregroundColor: Colours.orangePrimary
            ]
        )
        attributed.append(NSAttributedString(
            string: "/\(limit)",
            attributes: [
                .font: Fonts.medium13,
                .foregroundColor: Colours.orangePrimary
            ]
        ))
        countLabel.attributedText = attributed
        accessibilityLabel = "\(remaining) of \(limit) weekly audiobooks remaining"
    }

    override var intrinsicContentSize: CGSize {
        let target = stackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return CGSize(width: target.width + 18, height: 32)
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        UIView.animate(withDuration: 0.08) { self.alpha = 0.6 }
        return super.beginTracking(touch, with: event)
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        UIView.animate(withDuration: 0.12) { self.alpha = 1.0 }
        super.endTracking(touch, with: event)
    }

    override func cancelTracking(with event: UIEvent?) {
        UIView.animate(withDuration: 0.12) { self.alpha = 1.0 }
        super.cancelTracking(with: event)
    }
}
