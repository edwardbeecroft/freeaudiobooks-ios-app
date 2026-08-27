//
//  FavoriteGenresCTATVC.swift
//  FreeAudiobooks
//
//  Created by OpenAI Codex on 31/03/2026.
//

import UIKit

final class FavoriteGenresCTATVC: UITableViewCell {

    static let reuseIdentifier = "FavoriteGenresCTATVC"

    private enum Layout {
        static let outerTop: CGFloat = 16
        static let outerBottom: CGFloat = 10
        static let innerPadding: CGFloat = 16
        static let iconSize: CGFloat = 20
        static let titleSpacing: CGFloat = 10
        static let subtitleTop: CGFloat = 4
        static let buttonHeight: CGFloat = 28
    }

    private let containerView = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let editButton = UIButton(type: .system)

    var tappedHandler: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        containerView.layer.borderColor = Colours.inputBorder.cgColor
    }

    func configure(title: String, subtitle: String?) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubviewForConstraints(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Layout.outerTop),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Layout.outerBottom)
        ])

        containerView.backgroundColor = Colours.backgroundGrey
        containerView.layer.cornerRadius = UIConstants.shared.cornerRadius
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = Colours.inputBorder.cgColor

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true

        iconView.image = UIImage(systemName: "sparkles")
        iconView.tintColor = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
        iconView.contentMode = .scaleAspectFit

        titleLabel.font = UIConstants.shared.carouselTitleFont
        titleLabel.textColor = Colours.textPrimary
        titleLabel.numberOfLines = 1

        subtitleLabel.font = UIConstants.shared.carouselSubtitleKickerFont
        subtitleLabel.textColor = Colours.subtext
        subtitleLabel.numberOfLines = 2
        subtitleLabel.lineBreakMode = .byTruncatingTail

        editButton.setTitle("Edit", for: .normal)
        editButton.setTitleColor(Colours.ctaForeground, for: .normal)
        editButton.titleLabel?.font = Fonts.semiBold14
        editButton.backgroundColor = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.ctaBackground)
        editButton.layer.cornerRadius = 14
        editButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        editButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        containerView.addSubviewForConstraints(iconView)
        containerView.addSubviewForConstraints(titleLabel)
        containerView.addSubviewForConstraints(subtitleLabel)
        containerView.addSubviewForConstraints(editButton)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Layout.innerPadding),
            iconView.widthAnchor.constraint(equalToConstant: Layout.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Layout.iconSize),

            editButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Layout.innerPadding),
            editButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Layout.innerPadding),
            editButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight),

            titleLabel.centerYAnchor.constraint(equalTo: editButton.centerYAnchor),
            iconView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: Layout.titleSpacing),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: editButton.leadingAnchor, constant: -12),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Layout.subtitleTop),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Layout.innerPadding),
            subtitleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Layout.innerPadding)
        ])
    }

    @objc private func handleTap() {
        tappedHandler?()
    }
}
