//
//  AudioPreferencesVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 26/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

final class AudioPreferencesVC: BottomSheetController {

    var dismissHandler: (() -> Void)?
    var downloadHandler: ((_ language: AudiobookLanguage) -> Void)?
    var playHandler: (() -> Void)?
    var deleteHandler: (() -> Void)?

    private let languagesStackView = UIStackView()
    private let bookInternal: CDBookInternal

    init(bookInternal: CDBookInternal) {
        self.bookInternal = bookInternal
        super.init(nibName: nil, bundle: nil)
        self.preferredSheetSizing = .fit
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()

        let titleLabel = UILabel()
        titleLabel.font = Fonts.semiBold16
        titleLabel.textColor = Colours.textPrimary
        titleLabel.text = "Audiobook Options"
        titleLabel.textAlignment = .center

        let borderView = SplitterView()
        NSLayoutConstraint.activate([
            borderView.heightAnchor.constraint(equalToConstant: 1)
        ])

        // Setup languages section
        setupLanguagesSection()

        // Setup downloaded audio section if available
        let downloadedSection = setupDownloadedAudioSection()

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 20

        // Add components to stack
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(borderView)

        if bookInternal.hasDownloadedAudio {
            stackView.addArrangedSubview(downloadedSection)

            let downloadedBorderView = SplitterView()
            NSLayoutConstraint.activate([
                downloadedBorderView.heightAnchor.constraint(equalToConstant: 1)
            ])
            stackView.addArrangedSubview(downloadedBorderView)
        }

        if bookInternal.hasAnyAudiobook {
            let availableLabel = UILabel()
            availableLabel.font = Fonts.semiBold15
            availableLabel.textColor = Colours.textPrimary
            availableLabel.text = "Available Languages"
            availableLabel.textAlignment = .left

            stackView.addArrangedSubview(availableLabel)
            stackView.addArrangedSubview(languagesStackView)
            stackView.setCustomSpacing(8, after: availableLabel)
        } else {
            let noAudioLabel = UILabel()
            noAudioLabel.font = Fonts.medium15
            noAudioLabel.textColor = Colours.textSecondary
            noAudioLabel.text = "No audiobook versions are available for this story."
            noAudioLabel.textAlignment = .center
            noAudioLabel.numberOfLines = 0

            stackView.addArrangedSubview(noAudioLabel)
        }

        stackView.setCustomSpacing(20, after: titleLabel)
        stackView.setCustomSpacing(20, after: borderView)

        view.addSubviewForConstraints(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -16)
        ])

        view.backgroundColor = Colours.surfacePrimary

        // Add dismiss button
        let dismissButton = UIButton()
        dismissButton.setImage(UIImage(named: "dismissIcon")?.withRenderingMode(.alwaysTemplate), for: [])
        dismissButton.tintColor = Colours.textSecondary
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        view.addSubviewForConstraints(dismissButton)
        NSLayoutConstraint.activate([
            dismissButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            dismissButton.heightAnchor.constraint(equalToConstant: 32),
            dismissButton.widthAnchor.constraint(equalToConstant: 32),
            dismissButton.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -UIConstants.shared.standardMargin)
        ])
    }

    private func setupLanguagesSection() {
        languagesStackView.axis = .vertical
        languagesStackView.distribution = .fill
        languagesStackView.alignment = .fill
        languagesStackView.spacing = 12

        for language in bookInternal.availableAudioLanguages {
            let languageView = AudioLanguageView(language: language, bookInternal: bookInternal)
            languageView.downloadHandler = { [weak self] language in
                self?.downloadHandler?(language)
            }
            languagesStackView.addArrangedSubview(languageView)
        }
    }

    private func setupDownloadedAudioSection() -> UIView {
        let containerView = UIView()

        let titleLabel = UILabel()
        titleLabel.font = Fonts.semiBold15
        titleLabel.textColor = Colours.textPrimary
        titleLabel.text = "Downloaded Audio"
        titleLabel.textAlignment = .left

        let languageLabel = UILabel()
        languageLabel.font = Fonts.medium15
        languageLabel.textColor = Colours.textSecondary
        languageLabel.text = bookInternal.downloadedAudio?.languageDisplayName ?? "Unknown"

        let sizeLabel = UILabel()
        sizeLabel.font = Fonts.medium13
        sizeLabel.textColor = Colours.textTertiary
        sizeLabel.text = bookInternal.downloadedAudioFileSize

        let playButton = Buttons.gradientButton(buttonTitle: "Play Audio")
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)

        let deleteButton = Buttons.transparentButtonWithBorder(
            borderColor: UIColor.systemRed.cgColor,
            buttonTitle: "Delete Download",
            titleColor: .systemRed
        )
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

        let buttonStackView = UIStackView(arrangedSubviews: [playButton, deleteButton])
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 12

        [titleLabel, languageLabel, sizeLabel, buttonStackView].forEach {
            containerView.addSubviewForConstraints($0)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            languageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            languageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            languageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            sizeLabel.topAnchor.constraint(equalTo: languageLabel.bottomAnchor, constant: 4),
            sizeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            sizeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            buttonStackView.topAnchor.constraint(equalTo: sizeLabel.bottomAnchor, constant: 16),
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            buttonStackView.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight)
        ])

        playButton.layer.cornerRadius = UIConstants.shared.fullButtonCornerRadius
        deleteButton.layer.cornerRadius = UIConstants.shared.fullButtonCornerRadius

        return containerView
    }

    @objc private func dismissTapped() {
        dismissHandler?()
    }

    @objc private func playTapped() {
        playHandler?()
        dismissHandler?()
    }

    @objc private func deleteTapped() {
        deleteHandler?()
        dismissHandler?()
    }
}

// MARK: - AudioLanguageView
class AudioLanguageView: UIView {

    var downloadHandler: ((_ language: AudiobookLanguage) -> Void)?

    private let language: AudiobookLanguage
    private let bookInternal: CDBookInternal
    private var isDownloadedLanguage: Bool {
        bookInternal.hasDownloadedAudio &&
        bookInternal.downloadedAudio?.language == language.rawValue
    }

    init(language: AudiobookLanguage, bookInternal: CDBookInternal) {
        self.language = language
        self.bookInternal = bookInternal
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = Colours.surfaceSecondary
        layer.cornerRadius = UIConstants.shared.cardCornerRadius
        layer.borderWidth = 1
        layer.borderColor = Colours.inputBorder.cgColor

        let languageLabel = UILabel()
        languageLabel.font = Fonts.semiBold15
        languageLabel.textColor = Colours.textPrimary
        languageLabel.text = language.displayString

        let statusLabel = UILabel()
        statusLabel.font = Fonts.medium13
        statusLabel.textColor = Colours.textSecondary

        let downloadButton = UIButton(type: .system)
        downloadButton.titleLabel?.font = Fonts.semiBold14
        downloadButton.layer.cornerRadius = 8
        downloadButton.addTarget(self, action: #selector(downloadTapped), for: .touchUpInside)

        // Check if this language is already downloaded
        let isDownloaded = isDownloadedLanguage

        if isDownloaded {
            statusLabel.text = "Downloaded · \(bookInternal.downloadedAudioFileSize ?? "")"
            downloadButton.setTitle("Downloaded", for: .normal)
            downloadButton.setTitleColor(.systemGreen, for: .normal)
            downloadButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
            downloadButton.isEnabled = false
        } else {
            statusLabel.text = "Available for download"
            downloadButton.setTitle("Download", for: .normal)
            downloadButton.setTitleColor(.white, for: .normal)
            downloadButton.backgroundColor = Colours.ctaBackground
        }

        [languageLabel, statusLabel, downloadButton].forEach {
            addSubviewForConstraints($0)
        }

        NSLayoutConstraint.activate([
            languageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            languageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            languageLabel.trailingAnchor.constraint(lessThanOrEqualTo: downloadButton.leadingAnchor, constant: -12),

            statusLabel.topAnchor.constraint(equalTo: languageLabel.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: downloadButton.leadingAnchor, constant: -12),
            statusLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),

            downloadButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            downloadButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            downloadButton.widthAnchor.constraint(equalToConstant: 100),
            downloadButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    @objc private func downloadTapped() {
        downloadHandler?(language)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        layer.borderColor = Colours.inputBorder.cgColor
    }
}
