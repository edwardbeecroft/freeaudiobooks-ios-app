//
//  ShortStoryCVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 08/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import Kingfisher

extension ShortStoryCVC {
    struct Layout {
        static let containerTopBottomPadding: CGFloat = 8
        static let coverImageHeight: CGFloat = UIConstants.shared.discoverCardCoverHeight
        static let coverImageCornerRadius: CGFloat = UIConstants.shared.bookCoverCornerRadius
        static let metaTopSpacing: CGFloat = 6
        static let titleLabelHeight: CGFloat = 34  // Fixed height for up to 2 lines
        static let metaLabelHeight: CGFloat = 16
        static let metaLabelSpacing: CGFloat = 2

        // Calculate cover image width based on height and aspect ratio from UIConstants
        static var coverImageWidth: CGFloat {
            return coverImageHeight * UIConstants.shared.bookInternalCoverImageWidthToHeightRatio
        }

        // Calculate total card height based on all internal components
        static var cardHeight: CGFloat {
            return containerTopBottomPadding +           // Top padding
                   coverImageHeight +                    // Cover image
                   metaTopSpacing +                      // Spacing to metadata
                   titleLabelHeight +                    // Title (2 lines max)
                   metaLabelSpacing +                    // Spacing
                   metaLabelHeight +                     // Genre
                   containerTopBottomPadding             // Bottom padding
        }
    }
}

class ShortStoryCVC: UICollectionViewCell {

    // MARK: - Properties

    var contentMetadata: ReadableContentMetadata?
    
    // MARK: - UI Elements
    
    private let containerView = UIView()
    private let coverImageView = UIImageView()
    private let completionOverlayView = UIView()
    private let completionTickImageView = UIImageView()
    private let adultContentBadge = AdultContentBadge()
    private let titleLabel = UILabel()
    private let genreLabel = UILabel()

    private let progressView = UIProgressView(progressViewStyle: .bar)

    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        
        setupContainerView()
        setupCoverImageView()
        setupCompletionOverlay()
        setupAdultContentBadge()
        setupProgressView()
        setupMetaLabels()
        setupConstraints()

        [coverImageView, completionOverlayView].forEach {
            $0.layer.cornerRadius = Layout.coverImageCornerRadius
            $0.layer.masksToBounds = true
        }
    }
    
    private func setupContainerView() {
        contentView.addSubviewForConstraints(containerView)
    }
    
    private func setupCoverImageView() {
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.backgroundColor = UIColor.systemGray6
        
        containerView.addSubviewForConstraints(coverImageView)
    }
    
    private func setupCompletionOverlay() {
        completionOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        completionOverlayView.isHidden = true

        completionTickImageView.image = UIImage(systemName: "checkmark.circle.fill")
        completionTickImageView.tintColor = UIColor.white
        completionTickImageView.contentMode = .scaleAspectFit

        coverImageView.addSubviewForConstraints(completionOverlayView)
        completionOverlayView.addSubviewForConstraints(completionTickImageView)
    }

    private func setupAdultContentBadge() {
        adultContentBadge.isHidden = true
        coverImageView.addSubviewForConstraints(adultContentBadge)
    }

    private func setupProgressView() {
        progressView.progressTintColor = Colours.orangePrimary
        progressView.trackTintColor = UIColor.systemGray5
        progressView.isHidden = true

        coverImageView.addSubviewForConstraints(progressView)
    }

    private func setupMetaLabels() {
        titleLabel.font = Fonts.medium14
        titleLabel.textColor = Colours.textPrimary
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail

        genreLabel.font = Fonts.regular14
        genreLabel.textColor = Colours.lightUI
        genreLabel.numberOfLines = 1

        containerView.addSubviewForConstraints(titleLabel)
        containerView.addSubviewForConstraints(genreLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Cover image view
            coverImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Layout.containerTopBottomPadding),
            coverImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            coverImageView.heightAnchor.constraint(equalToConstant: Layout.coverImageHeight),
            coverImageView.widthAnchor.constraint(equalToConstant: Layout.coverImageWidth),

            // Title label (below cover)
            titleLabel.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: Layout.metaTopSpacing),
            titleLabel.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: coverImageView.trailingAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: Layout.titleLabelHeight),

            // Genre label
            genreLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Layout.metaLabelSpacing),
            genreLabel.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor),
            genreLabel.trailingAnchor.constraint(equalTo: coverImageView.trailingAnchor),
            genreLabel.heightAnchor.constraint(equalToConstant: Layout.metaLabelHeight),
            genreLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Layout.containerTopBottomPadding),

            // Completion overlay (over cover image only)
            completionOverlayView.topAnchor.constraint(equalTo: coverImageView.topAnchor),
            completionOverlayView.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor),
            completionOverlayView.trailingAnchor.constraint(equalTo: coverImageView.trailingAnchor),
            completionOverlayView.bottomAnchor.constraint(equalTo: coverImageView.bottomAnchor),

            // Completion tick (top-right corner)
            completionTickImageView.trailingAnchor.constraint(equalTo: completionOverlayView.trailingAnchor, constant: -4),
            completionTickImageView.widthAnchor.constraint(equalToConstant: 20),
            completionTickImageView.heightAnchor.constraint(equalToConstant: 20),

            // Progress view (overlaid at bottom of cover image)
            progressView.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: coverImageView.trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: coverImageView.bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4),

            // Adult content badge (top-left corner)
            adultContentBadge.topAnchor.constraint(equalTo: coverImageView.topAnchor, constant: 6),
            adultContentBadge.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor, constant: 6),
            adultContentBadge.widthAnchor.constraint(equalToConstant: 36),
            adultContentBadge.heightAnchor.constraint(equalToConstant: 20),

            completionTickImageView.centerYAnchor.constraint(equalTo: adultContentBadge.centerYAnchor),
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with story: CDBookInternal, section: DiscoverSection? = nil) {
        self.contentMetadata = story

        // Load cover image
        if
            let coverImageURLThumbnail = story.coverImageURLThumbnail,
            let imageURL = URL(string: coverImageURLThumbnail) {
            coverImageView.kf.indicatorType = .activity
            coverImageView.kf.setImage(
                with: imageURL,
                placeholder: nil,
                options: [.transition(.fade(0.2))]
            )
        } else {
            // Set placeholder image
            coverImageView.image = UIImage(systemName: "book.fill")?
                .withRenderingMode(.alwaysTemplate)
            coverImageView.tintColor = Colours.textPrimary.withAlphaComponent(0.3)
        }

        // Metadata labels
        titleLabel.text = story.title
        if let genreString = story.genreString,
           let genre = BookInternalGenre(rawValue: genreString) {
            genreLabel.text = genre.displayString
        } else {
            genreLabel.text = nil
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
        guard let contentMetadata = contentMetadata else { return }

        // Don't show progress bar if book is completed
        let isCompleted = AccountManager.shared.userHasCompletedBookInternalWithUUID(contentMetadata.contentUUID)
        if isCompleted {
            progressView.isHidden = true
            return
        }

        // Get numeric progress percentage (0-100)
        if let progressPercentage = ReadingUserDefaults.progressForBookWithUUID(contentMetadata.contentUUID),
           progressPercentage > 0 {
            // Convert to 0.0-1.0 range
            let progressValue = Float(progressPercentage) / 100.0
            progressView.progress = progressValue
            progressView.isHidden = false
        } else {
            progressView.isHidden = true
        }
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        contentMetadata = nil
        coverImageView.image = nil
        coverImageView.kf.cancelDownloadTask()
        completionOverlayView.isHidden = true
        progressView.isHidden = true
        progressView.progress = 0
        adultContentBadge.isHidden = true
        titleLabel.text = nil
        genreLabel.text = nil
    }
}
