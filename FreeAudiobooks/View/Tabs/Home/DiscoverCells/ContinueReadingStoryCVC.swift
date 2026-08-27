//
//  ContinueReadingStoryCVC.swift
//  FreeAudiobooks
//
//  Created by Codex on 20/02/2026.
//

import UIKit

final class ContinueReadingStoryCVC: UICollectionViewCell {

    struct Layout {
        static let horizontalTextPadding: CGFloat = 8
        static let bottomPadding: CGFloat = 8
        static let baseCoverWidth: CGFloat = 70
        static let iPadCoverScale: CGFloat = 1.5
        static var coverWidth: CGFloat {
            UIDevice().iPad ? (baseCoverWidth * iPadCoverScale) : baseCoverWidth
        }
        static var coverHeight: CGFloat {
            coverWidth / UIConstants.shared.bookInternalCoverImageWidthToHeightRatio
        }
        static let coverToTextSpacing: CGFloat = 8
        static let textLineSpacing: CGFloat = 2

        static let continueLabelHeight: CGFloat = 16
        static let progressLabelHeight: CGFloat = 17

        static var cardHeight: CGFloat {
            coverHeight +
            coverToTextSpacing +
            continueLabelHeight +
            textLineSpacing +
            progressLabelHeight +
            bottomPadding
        }
    }

    private let containerView = UIView()
    private let coverImageView = CoverImageView(
        widthMultiplier: 1,
        parentVenue: .home
    )
    private let continueLabel = UILabel()
    private let progressLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        containerView.backgroundColor = Colours.surfaceCard
        containerView.layer.cornerRadius = UIConstants.shared.bookCoverCornerRadius
        containerView.layer.masksToBounds = true

        continueLabel.font = Fonts.medium12
        continueLabel.textColor = Colours.textSecondary
        continueLabel.textAlignment = .left
        continueLabel.text = "Continue"

        progressLabel.font = Fonts.medium12
        progressLabel.textColor = Colours.textPrimary
        progressLabel.textAlignment = .left

        contentView.addSubviewForConstraints(containerView)
        containerView.addSubviewForConstraints(coverImageView)
        containerView.addSubviewForConstraints(continueLabel)
        containerView.addSubviewForConstraints(progressLabel)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ContinueReadingCarouselTVC.Layout.cellHorizontalPadding),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ContinueReadingCarouselTVC.Layout.cellHorizontalPadding),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            coverImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            coverImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            coverImageView.widthAnchor.constraint(equalToConstant: Layout.coverWidth),
            coverImageView.heightAnchor.constraint(equalToConstant: Layout.coverHeight),

            continueLabel.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: Layout.coverToTextSpacing),
            continueLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Layout.horizontalTextPadding),
            continueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Layout.horizontalTextPadding),
            continueLabel.heightAnchor.constraint(equalToConstant: Layout.continueLabelHeight),

            progressLabel.topAnchor.constraint(equalTo: continueLabel.bottomAnchor, constant: Layout.textLineSpacing),
            progressLabel.leadingAnchor.constraint(equalTo: continueLabel.leadingAnchor),
            progressLabel.trailingAnchor.constraint(equalTo: continueLabel.trailingAnchor),
            progressLabel.heightAnchor.constraint(equalToConstant: Layout.progressLabelHeight),
            progressLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Layout.bottomPadding)
        ])
    }

    func configure(with story: CDBookInternal,
                   continueText: String = "Continue",
                   isCompleted: Bool,
                   progressPercentage: Int?) {
        coverImageView.setContentMode(.scaleAspectFill)
        coverImageView.setImage(urlString: story.coverImageURLThumbnail,
                                isBookCompleted: isCompleted,
                                progressPercentage: progressPercentage)
        continueLabel.text = continueText

        if isCompleted {
            progressLabel.text = "Completed"
        } else if let progressPercentage {
            progressLabel.text = "\(progressPercentage)%"
        } else {
            progressLabel.text = "Not started"
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        continueLabel.text = "Continue"
        progressLabel.text = nil
    }
}
