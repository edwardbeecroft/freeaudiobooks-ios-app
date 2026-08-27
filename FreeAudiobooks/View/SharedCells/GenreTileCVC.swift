//
//  GenreTileCVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 22/03/2026.
//  Copyright © 2026 Kneady Technologies. All rights reserved.
//

import UIKit
import Kingfisher

final class GenreTileCVC: UICollectionViewCell {
    static let reuseIdentifier = "GenreTileCVC"

    private let backgroundImageView = UIImageView()
    private let blurOverlayView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let darkOverlayView = UIView()
    private let globalTintGradientLayer = CAGradientLayer()
    private let leftTextSafeGradientLayer = CAGradientLayer()
    private let symbolContainerView = UIView()
    private let symbolImageView = UIImageView()
    private let titleLabel = UILabel()
    private let heroCoverImageView = UIImageView()
    private var isGenreTileSelected = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = .clear
        contentView.layer.cornerRadius = UIConstants.shared.cardCornerRadius
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = Colours.inputBorder.cgColor

        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.backgroundColor = Colours.grey220
        contentView.addSubviewForConstraints(backgroundImageView)
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        blurOverlayView.alpha = 0.32
        contentView.addSubviewForConstraints(blurOverlayView)
        NSLayoutConstraint.activate([
            blurOverlayView.topAnchor.constraint(equalTo: contentView.topAnchor),
            blurOverlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            blurOverlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            blurOverlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        darkOverlayView.backgroundColor = .clear
        darkOverlayView.layer.addSublayer(globalTintGradientLayer)
        darkOverlayView.layer.addSublayer(leftTextSafeGradientLayer)
        globalTintGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        globalTintGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        leftTextSafeGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        leftTextSafeGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)

        symbolContainerView.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        symbolContainerView.layer.cornerRadius = 14
        symbolContainerView.layer.masksToBounds = true

        symbolImageView.tintColor = .white
        symbolImageView.contentMode = .scaleAspectFit

        titleLabel.font = Fonts.semiBold16
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.88
        titleLabel.textAlignment = .left

        heroCoverImageView.contentMode = .scaleAspectFill
        heroCoverImageView.clipsToBounds = true
        heroCoverImageView.backgroundColor = Colours.grey220
        heroCoverImageView.layer.cornerRadius = UIConstants.shared.bookCoverCornerRadius
        heroCoverImageView.layer.borderWidth = 1
        heroCoverImageView.layer.borderColor = UIColor.white.withAlphaComponent(0.45).cgColor

        contentView.addSubviewForConstraints(darkOverlayView)
        contentView.addSubviewForConstraints(symbolContainerView)
        contentView.addSubviewForConstraints(heroCoverImageView)
        symbolContainerView.addSubviewForConstraints(symbolImageView)
        contentView.addSubviewForConstraints(titleLabel)

        NSLayoutConstraint.activate([
            darkOverlayView.topAnchor.constraint(equalTo: contentView.topAnchor),
            darkOverlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            darkOverlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            darkOverlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            heroCoverImageView.heightAnchor.constraint(equalToConstant: 78),
            heroCoverImageView.widthAnchor.constraint(
                equalTo: heroCoverImageView.heightAnchor,
                multiplier: UIConstants.shared.bookInternalCoverImageWidthToHeightRatio
            ),
            heroCoverImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            heroCoverImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -9),

            symbolContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            symbolContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            symbolContainerView.widthAnchor.constraint(equalToConstant: 28),
            symbolContainerView.heightAnchor.constraint(equalToConstant: 28),

            symbolImageView.centerXAnchor.constraint(equalTo: symbolContainerView.centerXAnchor),
            symbolImageView.centerYAnchor.constraint(equalTo: symbolContainerView.centerYAnchor),
            symbolImageView.widthAnchor.constraint(equalToConstant: 14),
            symbolImageView.heightAnchor.constraint(equalToConstant: 14),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: heroCoverImageView.leadingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        globalTintGradientLayer.frame = darkOverlayView.bounds
        leftTextSafeGradientLayer.frame = darkOverlayView.bounds
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateSelectionBorder()
        heroCoverImageView.layer.borderColor = UIColor.white.withAlphaComponent(0.45).cgColor
    }

    func configure(with presentation: GenreCardPresentation, isSelected: Bool) {
        isGenreTileSelected = isSelected
        titleLabel.text = presentation.genre.displayString
        symbolImageView.image = UIImage(systemName: presentation.symbolName)

        let globalDarkAlpha: CGFloat = 0.08
        let leftDarkAlpha: CGFloat = 0.42

        globalTintGradientLayer.colors = [
            UIColor.black.withAlphaComponent(globalDarkAlpha).cgColor,
            UIColor.black.withAlphaComponent(globalDarkAlpha * 0.6).cgColor
        ]
        leftTextSafeGradientLayer.colors = [
            UIColor.black.withAlphaComponent(leftDarkAlpha).cgColor,
            UIColor.black.withAlphaComponent(leftDarkAlpha * 0.45).cgColor,
            UIColor.clear.cgColor
        ]
        leftTextSafeGradientLayer.locations = [0.0, 0.45, 0.82]

        backgroundImageView.image = nil
        if let localName = presentation.localBackgroundImageName {
            let imageNameWithExtension: String
            if let localExtension = presentation.localBackgroundImageExtension, !localExtension.isEmpty {
                imageNameWithExtension = "\(localName).\(localExtension)"
            } else {
                imageNameWithExtension = localName
            }

            if let namedImage = UIImage(named: imageNameWithExtension) ?? UIImage(named: localName) {
                backgroundImageView.image = namedImage
            } else if let localExtension = presentation.localBackgroundImageExtension,
                      let localURL = Bundle.main.url(forResource: localName, withExtension: localExtension),
                      let localImage = UIImage(contentsOfFile: localURL.path) {
                backgroundImageView.image = localImage
            }
        }

        if let heroURLString = presentation.previewImageURLStrings.first, let heroURL = URL(string: heroURLString) {
            heroCoverImageView.isHidden = false
            heroCoverImageView.kf.setImage(with: heroURL, options: [.transition(.fade(0.2))])
        } else {
            heroCoverImageView.isHidden = true
            heroCoverImageView.kf.cancelDownloadTask()
            heroCoverImageView.image = nil
        }

        updateSelectionBorder()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        isGenreTileSelected = false
        titleLabel.text = nil
        backgroundImageView.image = nil
        heroCoverImageView.kf.cancelDownloadTask()
        heroCoverImageView.image = nil
        heroCoverImageView.isHidden = false
    }

    private func updateSelectionBorder() {
        contentView.layer.borderWidth = isGenreTileSelected ? 2 : 1
        contentView.layer.borderColor = (isGenreTileSelected ? Colours.orangePrimary : Colours.inputBorder).cgColor
    }
}
