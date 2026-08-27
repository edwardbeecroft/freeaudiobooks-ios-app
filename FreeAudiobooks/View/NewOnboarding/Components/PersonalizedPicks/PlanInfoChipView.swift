//
//  PlanInfoChipView.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 28/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

/// A simple info chip displaying an icon and text (non-interactive)
/// Used in PersonalizedPicksVC to show "Your plan" summary
class PlanInfoChipView: UIView {

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = Colours.orangePrimary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let label: UILabel = {
        let label = UILabel()
        label.font = Fonts.medium14
        label.textColor = Colours.textPrimary
        return label
    }()

    init(icon: String, text: String) {
        super.init(frame: .zero)
        setupUI()
        configure(icon: icon, text: text)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = Colours.orangePrimary.withAlphaComponent(0.1)
        layer.cornerRadius = 16

        let stack = UIStackView(arrangedSubviews: [iconImageView, label])
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        addSubviewForConstraints(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            iconImageView.widthAnchor.constraint(equalToConstant: 16),
            iconImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    func configure(icon: String, text: String) {
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        iconImageView.image = UIImage(systemName: icon, withConfiguration: config)
        label.text = text
    }
}
