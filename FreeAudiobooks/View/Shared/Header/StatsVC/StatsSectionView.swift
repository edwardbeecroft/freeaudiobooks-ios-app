//
//  StatsSectionView.swift
//  FreeAudiobooks
//
//  Created by FreeAudiobooks on 15/11/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

class StatsSectionView: UIView {

    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        // Icon image view
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = Colours.themeAccentDark

        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 18),
            iconImageView.heightAnchor.constraint(equalToConstant: 18)
        ])

        // Title label
        titleLabel.font = Fonts.semiBold19
        titleLabel.textColor = Colours.textPrimary
        titleLabel.numberOfLines = 0

        // Subtitle label
        subtitleLabel.font = Fonts.regular15
        subtitleLabel.textColor = Colours.textSecondary
        subtitleLabel.numberOfLines = 0

        // Horizontal stack for icon + title (first row)
        let titleRowStack = UIStackView(arrangedSubviews: [iconImageView, titleLabel])
        titleRowStack.axis = .horizontal
        titleRowStack.spacing = 8
        titleRowStack.alignment = .center

        // Vertical stack for title row + subtitle
        let mainStack = UIStackView(arrangedSubviews: [titleRowStack, subtitleLabel])
        mainStack.axis = .vertical
        mainStack.spacing = 4
        mainStack.alignment = .leading

        addSubviewForConstraints(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(imageName: String, title: String, subtitle: String) {
        iconImageView.image = UIImage(named: imageName)
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
}
