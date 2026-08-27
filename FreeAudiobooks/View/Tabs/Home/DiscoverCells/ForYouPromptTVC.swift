//
//  ForYouPromptTVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 04/11/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

class ForYouPromptTVC: UITableViewCell {

    // MARK: - Properties

    var selectGenresTappedHandler: (() -> Void)?

    // MARK: - UI Elements

    private let containerView = UIView()
    private let iconBackgroundView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private lazy var selectGenresButton: UIButton = {
        let favoriteText = Locale.isUK ? "favourite" : "favorite"
        return Buttons.primaryCTA(buttonTitle: "Select \(favoriteText) genres")
    }()
    
    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = Colours.surfacePrimary
        selectionStyle = .none

        setupContainerView()
        setupIconBackgroundView()
        setupIconImageView()
        setupTitleLabel()
        setupSubtitleLabel()
        setupSelectGenresButton()
        setupConstraints()
    }

    private func setupContainerView() {
        containerView.backgroundColor = Colours.backgroundGrey
        containerView.layer.cornerRadius = UIConstants.shared.cornerRadius
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = Colours.inputBorder.cgColor

        contentView.addSubviewForConstraints(containerView)
    }

    private func setupIconImageView() {
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)
        iconImageView.image = UIImage(systemName: "sparkles", withConfiguration: config)
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit

        iconBackgroundView.addSubviewForConstraints(iconImageView)
    }

    private func setupIconBackgroundView() {
        iconBackgroundView.backgroundColor = Colours.themeAccentDark
        iconBackgroundView.layer.cornerRadius = 25
        iconBackgroundView.clipsToBounds = true

        containerView.addSubviewForConstraints(iconBackgroundView)
    }

    private func setupTitleLabel() {
        let personaliseText = Locale.isUK ? "personalised" : "personalized"
        titleLabel.text = "Get \(personaliseText) recommendations"
        titleLabel.font = Fonts.semiBold18
        titleLabel.textColor = Colours.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1

        containerView.addSubviewForConstraints(titleLabel)
    }

    private func setupSubtitleLabel() {
        let favoriteText = Locale.isUK ? "favourite" : "favorite"
        subtitleLabel.text = "Select your \(favoriteText) genres and\nwe’ll tailor suggestions for you."
        subtitleLabel.font = Fonts.medium15
        subtitleLabel.textColor = Colours.subtext
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        containerView.addSubviewForConstraints(subtitleLabel)
    }

    private func setupSelectGenresButton() {
        selectGenresButton.translatesAutoresizingMaskIntoConstraints = false
        selectGenresButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        selectGenresButton.addTarget(self, action: #selector(selectGenresTapped), for: .touchUpInside)

        containerView.addSubviewForConstraints(selectGenresButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            // Icon
            iconBackgroundView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            iconBackgroundView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconBackgroundView.widthAnchor.constraint(equalToConstant: 50),
            iconBackgroundView.heightAnchor.constraint(equalToConstant: 50),

            iconImageView.centerXAnchor.constraint(equalTo: iconBackgroundView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconBackgroundView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 28),
            iconImageView.heightAnchor.constraint(equalToConstant: 28),

            // Title
            titleLabel.topAnchor.constraint(equalTo: iconBackgroundView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            // Button
            selectGenresButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            selectGenresButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            selectGenresButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            selectGenresButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24)
        ])
    }

    // MARK: - Actions

    @objc private func selectGenresTapped() {
        selectGenresTappedHandler?()
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        selectGenresTappedHandler = nil
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        containerView.layer.borderColor = Colours.inputBorder.cgColor
    }
}
