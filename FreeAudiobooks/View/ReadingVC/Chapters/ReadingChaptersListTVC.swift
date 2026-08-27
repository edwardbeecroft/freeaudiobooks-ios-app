//
//  ReadingChaptersListTVC.swift
//  FreeAudiobooks
//
//  Copyright © 2024 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

final class ReadingChaptersListTVC: UITableViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "ReadingChaptersListTVC"
    private var isCurrentChapter = false

    // MARK: - UI Elements

    private let chapterLabel = UILabel()
    private let checkmarkImageView = UIImageView()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = Colours.surfacePrimary

        chapterLabel.font = Fonts.medium16
        chapterLabel.textColor = Colours.textPrimary

        checkmarkImageView.image = UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
        checkmarkImageView.tintColor = Colours.textPrimary
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.isHidden = true

        contentView.addSubviewForConstraints(chapterLabel)
        contentView.addSubviewForConstraints(checkmarkImageView)

        NSLayoutConstraint.activate([
            chapterLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UIConstants.shared.standardMargin),
            chapterLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            chapterLabel.trailingAnchor.constraint(equalTo: checkmarkImageView.leadingAnchor, constant: -8),
            chapterLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UIConstants.shared.standardMargin),

            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    // MARK: - Configure

    func configure(chapterIndex: Int, isCurrentChapter: Bool, contentType: ContentType) {
        self.isCurrentChapter = isCurrentChapter

        let label = contentType == .bookInternal ? "Chapter" : "Section"
        chapterLabel.text = "\(label) \(chapterIndex + 1)"

        applySelectionStyle()
    }

    private func applySelectionStyle() {
        if isCurrentChapter {
            let selectedBackgroundColor = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.surfaceSecondary)
            let selectedForegroundColor = UIColor.dynamic(light: .white, dark: Colours.textPrimary)
            contentView.backgroundColor = selectedBackgroundColor
            chapterLabel.textColor = selectedForegroundColor
            checkmarkImageView.tintColor = selectedForegroundColor
            checkmarkImageView.isHidden = false
        } else {
            contentView.backgroundColor = Colours.surfacePrimary
            chapterLabel.textColor = Colours.textPrimary
            checkmarkImageView.tintColor = Colours.textPrimary
            checkmarkImageView.isHidden = true
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        isCurrentChapter = false
        applySelectionStyle()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        applySelectionStyle()
    }
}
