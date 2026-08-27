//
//  GenrePillView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 12/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

class GenrePillView: UIView {

    private let label = UILabel()
    private let neutralAccentTextColor = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPill()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPill()
    }

    private func setupPill() {
        layer.cornerRadius = 11
        layer.masksToBounds = true
        layer.borderWidth = 1
        updateAppearanceColors()

        label.font = Fonts.medium13
        label.textColor = neutralAccentTextColor
        label.textAlignment = .center
        addSubviewForConstraints(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: 22)
        ])

        // Disable user interaction so taps pass through to parent stack view
        isUserInteractionEnabled = false
    }

    private func updateAppearanceColors() {
        backgroundColor = Colours.surfaceCard
        layer.borderColor = Colours.inputBorder.cgColor
        label.textColor = neutralAccentTextColor
    }

    func configure(with genre: String) {
        label.text = genre
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateAppearanceColors()
    }

    override var forFirstBaselineLayout: UIView {
        return label
    }

    override var forLastBaselineLayout: UIView {
        return label
    }
}
