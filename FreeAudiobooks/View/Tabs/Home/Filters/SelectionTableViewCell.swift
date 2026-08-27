//
//  SelectionTableViewCell.swift
//  FreeAudiobooks
//
//  Created by Claude on 03/11/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

class SelectionTableViewCell: UITableViewCell {

    private let titleLabel = UILabel()
    private let bottomBorderView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = Colours.surfaceCard
        contentView.backgroundColor = Colours.surfaceCard

        // Setup title label
        titleLabel.font = Fonts.regular16
        titleLabel.textColor = Colours.textPrimary

        contentView.addSubviewForConstraints(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])

        // Setup bottom border
        bottomBorderView.backgroundColor = Colours.separator
        contentView.addSubviewForConstraints(bottomBorderView)
        NSLayoutConstraint.activate([
            bottomBorderView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bottomBorderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomBorderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomBorderView.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    func configure(with text: String, isSelected: Bool) {
        titleLabel.text = text

        if isSelected {
            accessoryType = .checkmark
            tintColor = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
        } else {
            accessoryType = .none
        }
    }
}
