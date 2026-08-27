//
//  EarlyAccessShortStoryCVC.swift
//  FreeAudiobooks
//
//  Reference implementation based on main-branch pre-edit card structure.
//

import UIKit
import Kingfisher

extension EarlyAccessShortStoryCVC {
    struct Layout {
        static let containerTopBottomPadding: CGFloat = 8
        static let coverImageHeight: CGFloat = UIConstants.shared.discoverCardCoverHeight
        static let coverWidthToHeightRatio: CGFloat = UIConstants.shared.bookInternalCoverImageWidthToHeightRatio
        static let coverToMetaSpacing: CGFloat = 8
        static let releaseLabelHeight: CGFloat = 16
        static let releaseToDateSpacing: CGFloat = 4
        static let releaseDateLabelHeight: CGFloat = 16

        static var coverImageWidth: CGFloat {
            coverImageHeight * coverWidthToHeightRatio
        }

        static var coverHeightToWidthMultiplier: CGFloat {
            1 / coverWidthToHeightRatio
        }

        static func cardHeight(forCoverWidth coverWidth: CGFloat) -> CGFloat {
            let computedCoverHeight = coverWidth * coverHeightToWidthMultiplier
            return containerTopBottomPadding +
            computedCoverHeight +
            coverToMetaSpacing +
            releaseLabelHeight +
            releaseToDateSpacing +
            releaseDateLabelHeight +
            containerTopBottomPadding
        }

        static var cardHeight: CGFloat {
            cardHeight(forCoverWidth: coverImageWidth)
        }
    }
}

final class EarlyAccessShortStoryCVC: UICollectionViewCell {

    var contentMetadata: ReadableContentMetadata?

    private let containerView = UIView()
    private let coverImageView = UIImageView()
    private let releaseLabel = UILabel()
    private let releaseDateLabel = UILabel()
    private let completionOverlayView = UIView()
    private let completionTickImageView = UIImageView()
    private let adultContentBadge = AdultContentBadge()
    private let progressView = UIProgressView(progressViewStyle: .bar)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        releaseLabel.font = Fonts.medium14
        releaseLabel.textColor = Colours.lightUI
        releaseLabel.numberOfLines = 1
        releaseLabel.textAlignment = .left

        releaseDateLabel.font = Fonts.regular14
        releaseDateLabel.textColor = Colours.lightUI
        releaseDateLabel.numberOfLines = 1
        releaseDateLabel.textAlignment = .left

        coverImageView.contentMode = .scaleAspectFill
        coverImageView.backgroundColor = .systemGray6

        completionOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        completionOverlayView.isHidden = true

        completionTickImageView.image = UIImage(systemName: "checkmark.circle.fill")
        completionTickImageView.tintColor = .white
        completionTickImageView.contentMode = .scaleAspectFit

        adultContentBadge.isHidden = true

        progressView.progressTintColor = Colours.orangePrimary
        progressView.trackTintColor = .systemGray5
        progressView.isHidden = true

        contentView.addSubviewForConstraints(containerView)
        containerView.addSubviewForConstraints(coverImageView)
        containerView.addSubviewForConstraints(releaseLabel)
        containerView.addSubviewForConstraints(releaseDateLabel)
        coverImageView.addSubviewForConstraints(completionOverlayView)
        completionOverlayView.addSubviewForConstraints(completionTickImageView)
        coverImageView.addSubviewForConstraints(adultContentBadge)
        coverImageView.addSubviewForConstraints(progressView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            coverImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Layout.containerTopBottomPadding),
            coverImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            coverImageView.heightAnchor.constraint(equalTo: coverImageView.widthAnchor, multiplier: Layout.coverHeightToWidthMultiplier),

            releaseLabel.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: Layout.coverToMetaSpacing),
            releaseLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            releaseLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            releaseLabel.heightAnchor.constraint(equalToConstant: Layout.releaseLabelHeight),

            releaseDateLabel.topAnchor.constraint(equalTo: releaseLabel.bottomAnchor, constant: Layout.releaseToDateSpacing),
            releaseDateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            releaseDateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            releaseDateLabel.heightAnchor.constraint(equalToConstant: Layout.releaseDateLabelHeight),
            releaseDateLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Layout.containerTopBottomPadding),

            completionOverlayView.topAnchor.constraint(equalTo: coverImageView.topAnchor),
            completionOverlayView.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor),
            completionOverlayView.trailingAnchor.constraint(equalTo: coverImageView.trailingAnchor),
            completionOverlayView.bottomAnchor.constraint(equalTo: coverImageView.bottomAnchor),

            completionTickImageView.trailingAnchor.constraint(equalTo: completionOverlayView.trailingAnchor, constant: -4),
            completionTickImageView.widthAnchor.constraint(equalToConstant: 20),
            completionTickImageView.heightAnchor.constraint(equalToConstant: 20),

            progressView.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: coverImageView.trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: coverImageView.bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4),

            adultContentBadge.topAnchor.constraint(equalTo: coverImageView.topAnchor, constant: 6),
            adultContentBadge.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor, constant: 6),
            adultContentBadge.widthAnchor.constraint(equalToConstant: 36),
            adultContentBadge.heightAnchor.constraint(equalToConstant: 20),
            completionTickImageView.centerYAnchor.constraint(equalTo: adultContentBadge.centerYAnchor)
        ])

        [coverImageView, completionOverlayView].forEach {
            $0.layer.cornerRadius = UIConstants.shared.bookCoverCornerRadius
            $0.layer.masksToBounds = true
        }
    }

    func configure(with story: CDBookInternal) {
        contentMetadata = story

        if let dateString = story.availableForAllDateString,
           !story.isAvailableToUser,
           let unlockDate = DateFormatters.earlyAccessDateFormatter.date(from: dateString) {
            releaseLabel.text = "Releases"
            releaseDateLabel.text = unlockDate.localizedMediumDateString
        } else {
            if let genreString = story.genreString,
               let genre = BookInternalGenre(rawValue: genreString) {
                releaseLabel.text = genre.displayString
            } else {
                releaseLabel.text = ""
            }
            let authorName = story.abbreviatedAuthorName
            if let authorName, !authorName.isEmpty {
                releaseDateLabel.text = authorName
            } else {
                releaseDateLabel.text = "\(story.listeningTimeMinutesRounded) min"
            }
        }

        if
            let coverImageURLThumbnail = story.coverImageURLThumbnail,
            let imageURL = URL(string: coverImageURLThumbnail) {
            coverImageView.kf.indicatorType = .activity
            coverImageView.kf.setImage(with: imageURL, placeholder: nil, options: [.transition(.fade(0.2))])
        } else {
            coverImageView.image = UIImage(systemName: "book.fill")?.withRenderingMode(.alwaysTemplate)
            coverImageView.tintColor = Colours.textPrimary.withAlphaComponent(0.3)
        }

        updateCompletionStatus()
        updateProgressBar()
        updateAdultContentBadge(story: story)
    }

    private func updateAdultContentBadge(story: CDBookInternal) {
        adultContentBadge.isHidden = !story.shouldShowAdultContentBadgeOnCovers
    }

    private func updateCompletionStatus() {
        guard let contentMetadata else { return }
        let isCompleted = AccountManager.shared.userHasCompletedBookInternalWithUUID(contentMetadata.contentUUID)
        completionOverlayView.isHidden = !isCompleted
    }

    private func updateProgressBar() {
        guard let contentMetadata else { return }
        let isCompleted = AccountManager.shared.userHasCompletedBookInternalWithUUID(contentMetadata.contentUUID)
        if isCompleted {
            progressView.isHidden = true
            return
        }
        if let progressPercentage = ReadingUserDefaults.progressForBookWithUUID(contentMetadata.contentUUID), progressPercentage > 0 {
            progressView.progress = Float(progressPercentage) / 100.0
            progressView.isHidden = false
        } else {
            progressView.isHidden = true
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentMetadata = nil
        releaseLabel.text = nil
        releaseDateLabel.text = nil
        coverImageView.image = nil
        coverImageView.kf.cancelDownloadTask()
        completionOverlayView.isHidden = true
        progressView.isHidden = true
        progressView.progress = 0
        adultContentBadge.isHidden = true
    }
}
