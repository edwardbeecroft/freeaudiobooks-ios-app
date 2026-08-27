//
//  SmallMetadataView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 14/10/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import Kingfisher

enum SmallMetadataDisplayContext {
    case normal
    case librarySaved
    case libraryCompleted
    case downloadedAudiobooks
}

class SmallMetadataView: UIView, DownloadableMetadataView, SaveableMetadataView {
    private let actionButtonSize: CGFloat = 34
    private let minimumHeight: CGFloat = 80

    private let coverImageView = CoverImageView(height: 64, parentVenue: .smallMetadataView)
    private let storyTitleLabel = UILabel()
    private let storyGenreLabel = UILabel()
    private let storyMetadataLabel = UILabel()
    private let adultContentBadge = AdultContentBadge()

    private let chevronLeftButton = UIButton()
    private let chevronRightButton = UIButton()
    private let bottomBorderView = SplitterView()

    private let saveButton = CompactCircularIconButton()
    private let downloadButton = CompactCircularIconButton()

    var tappedSaveHandler: ((SaveableMetadataView) -> Void)?
    var tappedDownloadHandler: ((DownloadableMetadataView) -> Void)?
    var tappedHandler: (() -> Void)?

    private let topBottomPadding: CGFloat = 12

    var contentMetadata: ReadableContentMetadata?
    private var displayContext: SmallMetadataDisplayContext?
    func set(contentMetadata: ReadableContentMetadata, displayContext: SmallMetadataDisplayContext) {
        self.contentMetadata = contentMetadata
        self.displayContext = displayContext
        populateContent()
    }
    
    init() {
        super.init(frame: .zero)
        setupUI()
        observeAudioDownloadState()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupUI() {
        setupCoverImageView()
        setupDownloadButton()
        setupSaveButton()
        setupStoryTitleLabel()
        setupStoryAuthorLabel()
        setupAdultContentBadge()

        setupBottomUI()
        setupBottomBorderView()
        
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }
    
    @objc func handleTap() {
        tappedHandler?()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func populateContent() {
        
        guard
            let contentMetadata,
            let displayContext else {
            return
        }
        
        storyTitleLabel.text = contentMetadata.title

        storyGenreLabel.text = Self.secondaryText(
            genre: contentMetadata.genreDisplayString,
            authors: contentMetadata.authorsString
        )

        // Show adult content badge for bookInternal with adult content
        if let cdBookInternal = contentMetadata as? CDBookInternal {
            adultContentBadge.isHidden = !cdBookInternal.shouldShowAdultContentBadgeOnCovers
        } else {
            adultContentBadge.isHidden = true
        }

        let isCompleted = contentMetadata.isCompleted()
        let progressPercentage = ReadingUserDefaults.progressForBookWithUUID(contentMetadata.contentUUID)
        let durationText: String?
        let releaseText: String?
        if let bookInternal = contentMetadata as? CDBookInternal {
            durationText = BookDetailVC.listeningTimeText(minutes: bookInternal.listeningTimeMinutesRounded)
            if
                !bookInternal.isAvailableToUser,
                let dateString = bookInternal.availableForAllDateString,
                let unlockDate = DateFormatters.earlyAccessDateFormatter.date(from: dateString) {
                releaseText = "Releases \(unlockDate.localizedMediumDateString)"
            } else {
                releaseText = nil
            }
        } else {
            durationText = nil
            releaseText = nil
        }
        let fileSizeText: String?
        if
            displayContext == .downloadedAudiobooks,
            let bookInternal = contentMetadata as? CDBookInternal {
            fileSizeText = bookInternal.downloadedAudio?.fileSizeString
        } else {
            fileSizeText = nil
        }
        storyMetadataLabel.text = Self.metadataText(
            duration: durationText,
            isCompleted: isCompleted || displayContext == .libraryCompleted,
            progressPercentage: progressPercentage,
            releaseText: releaseText,
            fileSize: fileSizeText
        )
        coverImageView.setImage(urlString: contentMetadata.coverImageThumbnailURLString,
                                isBookCompleted: isCompleted,
                                progressPercentage: progressPercentage)

        updateSaveElements()
        updateDownloadElements()
    }

    static func metadataText(duration: String?,
                             isCompleted: Bool,
                             progressPercentage: Int?,
                             releaseText: String? = nil,
                             fileSize: String? = nil) -> String {
        var segments: [String] = []

        if let releaseText = releaseText?.trimmingCharacters(in: .whitespacesAndNewlines), !releaseText.isEmpty {
            segments.append(releaseText)
        } else if isCompleted {
            segments.append("Completed")
        } else if let progressPercentage {
            segments.append("\(progressPercentage)% completed")
        } else if let duration = duration?.trimmingCharacters(in: .whitespacesAndNewlines), !duration.isEmpty {
            segments.append(duration)
        } else {
            segments.append("Not started")
        }

        if let fileSize = fileSize?.trimmingCharacters(in: .whitespacesAndNewlines), !fileSize.isEmpty {
            segments.append(fileSize)
        }

        return segments.joined(separator: " · ")
    }

    static func secondaryText(genre: String?, authors: String) -> String? {
        let trimmedGenre = genre?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmedGenre, !trimmedGenre.isEmpty {
            return trimmedGenre
        }

        let trimmedAuthors = authors.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedAuthors.isEmpty ? nil : trimmedAuthors
    }
}

extension SmallMetadataView {
    func setupCoverImageView() {
        coverImageView.setContentMode(.scaleAspectFit)
        addSubviewForConstraints(coverImageView)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: minimumHeight),
            coverImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 2),
            coverImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UIConstants.shared.standardMargin)
        ])
    }
}

extension SmallMetadataView {
    func setupDownloadButton() {
        addSubviewForConstraints(downloadButton)
        NSLayoutConstraint.activate([
            downloadButton.heightAnchor.constraint(equalToConstant: actionButtonSize),
            downloadButton.widthAnchor.constraint(equalToConstant: actionButtonSize),
            downloadButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UIConstants.shared.standardMargin),
            downloadButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        downloadButton.tappedHandler = { [weak self] in
            guard let self else { return }
            self.tappedDownloadHandler?(self)
        }
    }

    func setupSaveButton() {
        addSubviewForConstraints(saveButton)
        NSLayoutConstraint.activate([
            saveButton.heightAnchor.constraint(equalToConstant: actionButtonSize),
            saveButton.widthAnchor.constraint(equalToConstant: actionButtonSize),
            saveButton.trailingAnchor.constraint(equalTo: downloadButton.leadingAnchor, constant: -8),
            saveButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        saveButton.tappedHandler = { [weak self] in
            guard let self else { return }
            self.tappedSaveHandler?(self)
        }
        saveButton.isAccessibilityElement = true
        saveButton.accessibilityTraits = [.button]
        saveButton.accessibilityLabel = "Save"
        saveButton.setVisualState(isSelected: false,
                                  selectedIcon: selectedBookmarkIcon(),
                                  normalIcon: normalBookmarkIcon())
    }
    func updateSaveElements() {
        guard let contentMetadata else { return }
        var isSaved = false
        if let user = AccountManager.shared.user {
            isSaved = user.savedBookInternalUUIDs.contains(contentMetadata.contentUUID)
        }
        saveButton.setVisualState(isSelected: isSaved,
                                  selectedIcon: selectedBookmarkIcon(),
                                  normalIcon: normalBookmarkIcon())
        saveButton.accessibilityValue = isSaved ? "Saved" : "Not saved"
        saveButton.accessibilityHint = isSaved ? "Double tap to remove from saved" : "Double tap to save"
    }
    
    func updateDownloadElements() {
        guard let contentMetadata else { return }

        switch APIBookInternalAudioManager.shared.downloadState(for: contentMetadata.contentUUID) {
        case .downloading(let progress):
            setDownloadingProgress(progress)
        case .downloaded:
            setDownloadedImage()
        case .idle, .failed:
            downloadButton.setIcon(downloadActionIcon())
            downloadButton.iconTintColor = Colours.actionIconForeground
            downloadButton.backgroundColour = Colours.actionIconBackground
            downloadButton.borderWidth = 0
            downloadButton.borderColor = nil
            downloadButton.stopProgressIndicator()
        }
    }

    private func setDownloadedImage() {
        let iconConfig = UIImage.SymbolConfiguration(weight: .semibold)
        downloadButton.stopProgressIndicator()
        downloadButton.setIcon(UIImage(systemName: "checkmark", withConfiguration: iconConfig))
        downloadButton.iconTintColor = Colours.downloadedGreen
        downloadButton.backgroundColour = Colours.actionIconBackground
        downloadButton.borderWidth = 0
        downloadButton.borderColor = nil
    }
    
    func startDownloadAnimation() {
        setDownloadingProgress(0)
    }

    func updateDownloadProgress(_ progress: Float) {
        setDownloadingProgress(progress)
    }

    func stopDownloadAnimation() {
        downloadButton.stopProgressIndicator()
    }

    private func setDownloadingProgress(_ progress: Float) {
        downloadButton.iconTintColor = Colours.actionIconForeground
        downloadButton.backgroundColour = Colours.actionIconBackground
        downloadButton.borderWidth = 0
        downloadButton.borderColor = nil
        downloadButton.updateProgress(progress)
    }

    private func observeAudioDownloadState() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioDownloadStateDidChange(_:)),
            name: .audiobookDownloadStateDidChange,
            object: APIBookInternalAudioManager.shared
        )
    }

    @objc private func audioDownloadStateDidChange(_ notification: Notification) {
        guard notification.userInfo?["bookUUID"] as? String == contentMetadata?.contentUUID else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let state = notification.userInfo?["state"] as? AudiobookDownloadState {
                self.applyDownloadState(state)
            } else {
                self.updateDownloadElements()
            }
        }
    }

    private func applyDownloadState(_ state: AudiobookDownloadState) {
        switch state {
        case .downloading(let progress):
            setDownloadingProgress(progress)
        case .downloaded:
            setDownloadedImage()
        case .idle, .failed:
            setDownloadActionImage()
        }
    }

    private func setDownloadActionImage() {
        downloadButton.setIcon(downloadActionIcon())
        downloadButton.iconTintColor = Colours.actionIconForeground
        downloadButton.backgroundColour = Colours.actionIconBackground
        downloadButton.borderWidth = 0
        downloadButton.borderColor = nil
        downloadButton.stopProgressIndicator()
    }
}

private extension SmallMetadataView {
    func downloadActionIcon() -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        return UIImage(systemName: "arrow.down", withConfiguration: config) ?? UIImage(named: "download-icon")
    }

    func normalBookmarkIcon() -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .heavy)
        return UIImage(systemName: "bookmark", withConfiguration: config)
    }

    func selectedBookmarkIcon() -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .heavy)
        return UIImage(systemName: "bookmark.fill", withConfiguration: config)
    }
}

private extension SmallMetadataView {
    func setupStoryTitleLabel() {
        storyTitleLabel.textColor = Colours.textPrimary
        storyTitleLabel.font = Fonts.semiBold15
        storyTitleLabel.numberOfLines = 1
        storyTitleLabel.lineBreakMode = .byTruncatingTail
        
        addSubviewForConstraints(storyTitleLabel)
        NSLayoutConstraint.activate([
            storyTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: topBottomPadding),
            storyTitleLabel.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 16),
            storyTitleLabel.trailingAnchor.constraint(equalTo: saveButton.leadingAnchor, constant: -12)
        ])
    }
}

extension SmallMetadataView {
    func setupStoryAuthorLabel() {
        storyGenreLabel.textColor = Colours.lightUI
        storyGenreLabel.font = Fonts.medium13
        storyGenreLabel.numberOfLines = 1
        storyGenreLabel.lineBreakMode = .byTruncatingTail
        storyGenreLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        storyGenreLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        addSubviewForConstraints(storyGenreLabel)
        NSLayoutConstraint.activate([
            storyGenreLabel.topAnchor.constraint(equalTo: storyTitleLabel.bottomAnchor, constant: 4),
            storyGenreLabel.leadingAnchor.constraint(equalTo: storyTitleLabel.leadingAnchor)
        ])
    }

    func setupAdultContentBadge() {
        adultContentBadge.isHidden = true
        adultContentBadge.style = .inlineMetadata

        addSubviewForConstraints(adultContentBadge)
        NSLayoutConstraint.activate([
            adultContentBadge.leadingAnchor.constraint(equalTo: storyGenreLabel.trailingAnchor, constant: 6),
            adultContentBadge.centerYAnchor.constraint(equalTo: storyGenreLabel.centerYAnchor),
            adultContentBadge.trailingAnchor.constraint(lessThanOrEqualTo: saveButton.leadingAnchor, constant: -8),
            adultContentBadge.widthAnchor.constraint(equalToConstant: 36),
            adultContentBadge.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
}

extension SmallMetadataView {
    func setupBottomUI() {
        setupLeadingElements()
        //setupTrailingElements()
    }
    func setupLeadingElements() {
        storyMetadataLabel.textColor = Colours.lightUI
        storyMetadataLabel.font = Fonts.medium13
        storyMetadataLabel.numberOfLines = 1
        storyMetadataLabel.lineBreakMode = .byTruncatingTail

        addSubviewForConstraints(storyMetadataLabel)
        NSLayoutConstraint.activate([
            storyMetadataLabel.leadingAnchor.constraint(equalTo: storyTitleLabel.leadingAnchor),
            storyMetadataLabel.trailingAnchor.constraint(lessThanOrEqualTo: saveButton.leadingAnchor, constant: -12),
            storyMetadataLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -topBottomPadding)
        ])
        let top = storyMetadataLabel.topAnchor.constraint(equalTo: storyGenreLabel.bottomAnchor, constant: 4)
        top.priority = UILayoutPriority(999)
        top.isActive = true
    }
}

extension SmallMetadataView {
    private func setupBottomBorderView() {
        bottomBorderView.backgroundColor = Colours.separator
        addSubviewForConstraints(bottomBorderView)
        NSLayoutConstraint.activate([
            bottomBorderView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomBorderView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UIConstants.shared.standardMargin),
            bottomBorderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomBorderView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    func hideBottomBorderView() {
        bottomBorderView.isHidden = true
    }
}
