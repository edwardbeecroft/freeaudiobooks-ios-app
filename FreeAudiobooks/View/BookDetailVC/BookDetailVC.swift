//
//  BookDetailVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 06/08/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import FirebaseFirestore
import FirebaseCore
import FirebaseAuth
import Kingfisher
import PopupDialog
import StoreKit
import BetterSegmentedControl
import SuperwallKit
import Cosmos

// Metadata under the title adapts to the information available for each book.
//
// Rating chip (beside the genre pill, hidden below minimumRatingsToDisplay):
    // ★ 4.46 · 23
//
// Metadata line:
    // 1 hr 45 min · 12 chapters

class BookDetailVC: UIViewController {

    /// A book needs this many ratings before a score is shown at all.
    static let minimumRatingsToDisplay = 5

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let storyTitleLabel = UILabel()
    private let authorMetadataStackView = UIStackView()
    private let authorNameLabel = UILabel()
    private let genrePillView = GenrePillView()
    private let adultContentBadge = AdultContentBadge()
    private let coverImageView = CoverImageView(widthMultiplier: 0.50, parentVenue: .book)
    
    private let actionsContainerView = UIStackView()
    private let saveButton = CircularIconButton()
    private let downloadButton = CircularIconButton()
    private let saveLikeShareSplitter = SplitterView()
    
    private let pillRowStackView = UIStackView()
    private let ratingChipView = BookDetailRatingChipView()
    private let metadataLineLabel = UILabel()
    private lazy var genrePillTapGestureRecognizer = UITapGestureRecognizer(
        target: self,
        action: #selector(genrePillTapped)
    )

    private let storySynopsisIntroLabel = UILabel()
    private let storySynopsisLabel = UILabel()
    private let synopsisReadMoreButton = UIButton(type: .system)
    private var synopsisReadMoreButtonHeightConstraint: NSLayoutConstraint?
    private var storySynopsisLabelMinHeightConstraint: NSLayoutConstraint?
    private var isSynopsisExpanded = false
    private var synopsisLoadingIndicatorView: NVActivityIndicatorView?
    private let generateAIStorySynopsisButton = Buttons.transparentButtonWithBorder(borderColor: Colours.inputBorder.cgColor,
                                                                                    buttonTitle: "Generate Synopsis with AI ✨",
                                                                                    titleColor: Colours.textPrimary)
    private let storySynopsisSplitter = SplitterView()
    private let tagsSectionContainerView = UIView()
    private let tagsSectionStackView = UIStackView()
    private let tagsIntroLabel = UILabel()
    private let tagPillsContainerView = OldTagPillWrapView()
    private let tagsSplitter = SplitterView()
    private var tagsSectionTopConstraint: NSLayoutConstraint?
    private var tagsSectionCollapsedHeightConstraint: NSLayoutConstraint?
    private var tagsSectionExpandedConstraints: [NSLayoutConstraint] = []

    private let reviewsSectionContainerView = UIView()
    private let reviewsSectionStackView = UIStackView()
    private let reviewsIntroLabel = UILabel()
    private let reviewsSummaryContainerView = UIView()
    private let reviewsScoreLabel = UILabel()
    private let reviewsSummaryStackView = UIStackView()
    private let reviewsStarsView = CosmosView()
    private let reviewsCountLabel = UILabel()
    private let writtenReviewsSubheadingLabel = UILabel()
    private lazy var writtenReviewsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = .zero
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = .fast
        collectionView.clipsToBounds = false
        return collectionView
    }()
    private let reviewsSplitter = SplitterView()
    private var writtenReviewsCollectionHeightConstraint: NSLayoutConstraint?
    private var writtenReviews: [APIBookReview] = []

    private var shouldShowWrittenReviewsSection: Bool {
        RCValues.shared.bool(forKey: .shouldShowWrittenReviews)
    }

    private var shouldShowReviewsSection: Bool {
        guard
            shouldShowWrittenReviewsSection,
            let bookInternal = contentMetadata as? CDBookInternal else {
            return false
        }
        return BookDetailVC.hasDisplayableRating(numberOfRatings: Int(bookInternal.numberOfRatings))
    }
    
    private let storyBookshelvesIntroLabel = UILabel()
    private let storyBookshelvesLabel = UILabel()
    private let storyBookshelvesSplitter = SplitterView()
    
    private let criticsReviewsIntroLabel = UILabel()
    private let criticsReviewsLabel = UILabel()
    private let criticsReviewsSplitter = SplitterView()
    private var criticsReviewsLoadingIndicatorView: NVActivityIndicatorView?
    private let getCriticsReviewsButton = Buttons.transparentButtonWithBorder(borderColor: Colours.inputBorder.cgColor,
                                                                              buttonTitle: "Get Critics Reviews",
                                                                              titleColor: Colours.textPrimary)

    private let moreInGenreIntroLabel = UILabel()
    private lazy var moreInGenreCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: UIConstants.shared.standardMargin, bottom: 0, right: UIConstants.shared.standardMargin)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    private var relatedStories: [CDBookInternal] = []
    private let moreInGenreSectionContainerView = UIView()
    private var moreInGenreSectionTopConstraint: NSLayoutConstraint?
    private var moreInGenreSectionCollapsedHeightConstraint: NSLayoutConstraint?
    private var moreInGenreSectionExpandedConstraints: [NSLayoutConstraint] = []
    private var visibleBookInternalStories: [CDBookInternal]?
    private var eligibleTagsForCurrentBookGenre: [BookInternalTag] = []
    private var hasStartedBookDetailSectionsLoad = false

    private let bottomContainerView = UIView()
    private let downloadingLabel = UILabel()
    private let downloadProgressView = UIProgressView()
    
    enum StartReadingCTAVariant: String {
        case startReading
        case readNow
        
        var startTitle: String {
            switch self {
            case .startReading: "Start Reading"
            case .readNow: "Read Now"
            }
        }
        var continueTitle: String {
            switch self {
            case .startReading: "Continue Reading"
            case .readNow: "Continue"
            }
        }
    }
    private var startReadingCTAVariant: StartReadingCTAVariant {
        let variantString = RCValues.shared.string(forKey: .startReadingCTAVariant)
        let variant = StartReadingCTAVariant(rawValue: variantString) ?? .startReading
        return variant
    }
    private lazy var readNowButton: UIButton = {
        return Buttons.primaryCTA(buttonTitle: primaryCTATitle)
    }()
    private let readButton = CircularNonGradientButton()
    private var isAudioDownloadInProgress = false
    private var displayedAudioDownloadPercentage: Int?
    private var pendingAudiobookOfflineStartAfterSubscription = false
    
    let contentMetadata: ReadableContentMetadata
    init(contentMetadata: ReadableContentMetadata) {
        self.contentMetadata = contentMetadata
        super.init(nibName:nil, bundle:nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colours.surfacePrimary
        view.addIphoneXBottomView(colour: Colours.backgroundGrey)
        
        print("Showing content with ID: \(contentMetadata.contentUUID)")
        
        setupNavBar()
        setupBottomContainerView()
        setupScrollView()
        
        setupBookImageView()
        setupAdultContentBadge()
        setupStoryTitleLabel()
        setupAuthorNameLabel()
        
        setupActionButtonUI()
        setupUIForContentType(contentMetadata.contentType)
        observeAudioDownloadState()
        
        updateSaveElements()
        updateDownloadElements()
        syncAudioDownloadStateFromManager(showCompletionIfVisible: false)
        updateAdditionalInfoView()
        
        if let bookInternal = contentMetadata as? CDBookInternal {
            ReadingUserDefaults.markBookInternalViewed(bookInternal: bookInternal)
            AnalyticsManager.shared.trackBookInternalMetadataViewed(genre: bookInternal.genre)

            // Track for email opt-in 5th detail view trigger (with 30-min deduplication)
            EmailOptInUserDefaults.recordBookDetailView(bookUUID: bookInternal.contentUUID)
        }

        if SKReviewManager.launchCount == 1 {
            AnalyticsManager.shared.trackFirstLaunchBookMetadataViewed()
        }
        
        SKReviewManager.incrementStoryViews()
        
        populateData()
        loadBookDetailSectionsIfNeeded()
        
        // So we update the recently viewed section
        AppNotifiers.shared.shouldReloadDiscoverVC = true
        
        syncReviews()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard NavigationBarStyler.reapplyIfNeeded(on: self,
                                                  previousTraitCollection: previousTraitCollection) else { return }
        setupNavBar()
        generateAIStorySynopsisButton.layer.borderColor = Colours.inputBorder.cgColor
        getCriticsReviewsButton.layer.borderColor = Colours.inputBorder.cgColor
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        
        updatePrimaryCTAButtonTitle()

        updateAdditionalInfoView()
        updateReadingProgressView()
        updateCompletionStatus()
        updateCoverImageProgress()
        updateDownloadElements()
        syncAudioDownloadStateFromManager(showCompletionIfVisible: false)
        syncReviews()
    }

    private var primaryCTATitle: String {
        if contentMetadata.hasAnyAudiobook {
            if AccountManager.shared.userHasCompletedBookInternalWithUUID(contentMetadata.contentUUID) {
                return "Listen Now"
            }
            return hasStartedAudiobook ? "Continue Listening" : "Listen Now"
        }

        let startReadingText = startReadingCTAVariant.startTitle
        let continueText = startReadingCTAVariant.continueTitle
        if AccountManager.shared.userHasCompletedBookInternalWithUUID(contentMetadata.contentUUID) {
            return startReadingText
        }

        if
            let offset = ReadingUserDefaults.getOffsetForBookWithUUID(contentMetadata.contentUUID),
            offset.hasStartedReading {
            return continueText
        }

        return startReadingText
    }

    private var hasStartedAudiobook: Bool {
        guard contentMetadata.hasAnyAudiobook else { return false }
        // Positions survive audio-file deletion so the book can be re-downloaded
        // and resumed - started is about progress, not whether the file is on disk.
        return AudioPositionManager.shared.hasPosition(for: contentMetadata.contentUUID)
    }

    private func updatePrimaryCTAButtonTitle() {
        setPrimaryCTAButtonTitle(primaryCTATitle)
    }

    private func setPrimaryCTAButtonTitle(_ title: String) {
        UIView.performWithoutAnimation {
            readNowButton.setTitle(title, for: .normal)
            readNowButton.layoutIfNeeded()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if AppNotifiers.shared.shouldHandleBookCompletion {
            AppNotifiers.shared.shouldHandleBookCompletion = false

            // Request SKReview on book completion
            SKReviewManager.requestReview(venue: .completedBook)

            // Defer email opt-in to DiscoverVC (guardrail checked there)
            if
                EmailOptInPromptManager.shared.isEverEligible,
                let completedBookGenre = (contentMetadata as? CDBookInternal)?.genre {
                EmailOptInUserDefaults.hasPendingBookCompletedTrigger = true
                EmailOptInUserDefaults.pendingBookCompletedGenre = completedBookGenre
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        refreshWrittenReviewsLayoutIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        showDownloadLoadingIndicator(show: false)

        // Check for 5th book detail view trigger (email opt-in)
        // Only fire when popping back (not pushing forward) and threshold reached
        if isMovingFromParent,
           let bookInternal = contentMetadata as? CDBookInternal,
           EmailOptInUserDefaults.hasReachedBookDetailViewThreshold {

            // Present from parent VC after pop animation completes
            if let parentVC = navigationController?.viewControllers.last {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    EmailOptInPromptManager.shared.handleTrigger(
                        .fifthBookDetailView,
                        genre: bookInternal.genre,
                        from: parentVC
                    ) { didShow in
                        // Only mark as fired if prompt was actually shown
                        // This allows retry after 30-day cooldown
                        if didShow {
                            EmailOptInUserDefaults.markDetailViewTriggerFired()
                        }
                    }
                }
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension BookDetailVC {
    func syncReviews() {
        if let bookInternal = contentMetadata as? CDBookInternal {
            let rating = bookInternal.rating > 0 ? bookInternal.rating : nil
            let numberOfRatings = bookInternal.numberOfRatings > 0 ? Int(bookInternal.numberOfRatings) : nil
            updateRatingsView(rating: rating, numberOfRatings: numberOfRatings)
            if shouldShowReviewsSection {
                updateReviewsSummary(rating: rating, numberOfRatings: numberOfRatings)
            }
        } else {
            updateRatingsView(rating: nil, numberOfRatings: nil)
            if shouldShowReviewsSection {
                updateReviewsSummary(rating: nil, numberOfRatings: nil)
            }
        }

        if shouldShowReviewsSection {
            fetchWrittenReviews()
        }
    }
}

extension BookDetailVC {
    func updateAdditionalInfoView() {
        var segments: [String] = []

        if let cdBookInternal = contentMetadata as? CDBookInternal {
            if let listeningTime = BookDetailVC.listeningTimeText(minutes: cdBookInternal.listeningTimeMinutesRounded) {
                segments.append(listeningTime)
            }
            let chapters = cdBookInternal.chapterCountInt
            if chapters > 0 {
                segments.append("\(chapters) chapter\(chapters == 1 ? "" : "s")")
            }
        }

        metadataLineLabel.text = segments.joined(separator: " · ")
        metadataLineLabel.isHidden = segments.isEmpty
    }

    static func listeningTimeText(minutes: Int) -> String? {
        guard minutes > 0 else { return nil }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        switch (hours, remainingMinutes) {
        case (0, let mins):
            return "\(mins) min"
        case (let hrs, 0):
            return "\(hrs) hr"
        case (let hrs, let mins):
            return "\(hrs) hr \(mins) min"
        }
    }

    static func hasDisplayableRating(numberOfRatings: Int?) -> Bool {
        guard let numberOfRatings else { return false }
        return numberOfRatings >= minimumRatingsToDisplay
    }
    
    func updateReadingProgressView() {
        authorNameLabel.text = "by \(contentMetadata.authorsString)"
        if let genre = contentMetadata.genreDisplayString {
            genrePillView.configure(with: genre)
            genrePillView.isHidden = false
        } else {
            genrePillView.isHidden = true
        }
        updatePillRowVisibility()
    }

    func updateRatingsView(rating: Double?, numberOfRatings: Int?) {
        guard
            let rating = rating,
            let numberOfRatings = numberOfRatings,
            BookDetailVC.hasDisplayableRating(numberOfRatings: numberOfRatings) else {
            ratingChipView.isHidden = true
            updatePillRowVisibility()
            return
        }

        ratingChipView.isHidden = false
        ratingChipView.configure(rating: rating, numberOfRatings: numberOfRatings)
        updatePillRowVisibility()
    }

    func updatePillRowVisibility() {
        pillRowStackView.isHidden = genrePillView.isHidden && ratingChipView.isHidden
    }

    func setupNavBar() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        NavigationBarStyler.apply(to: navigationBar,
                                  fallbackTraitCollection: view.window?.traitCollection ?? traitCollection)
        navigationBar.isTranslucent = false

        let btnLeftMenu: UIButton = UIButton(type: .system)
        let backImage = UIImage(named: "backButtonNavIcon")?.withRenderingMode(.alwaysTemplate)
        btnLeftMenu.setImage(backImage, for: .normal)
        btnLeftMenu.tintColor = navigationBar.tintColor

        btnLeftMenu.addTarget(self, action: #selector(popVC), for: .touchUpInside)
        btnLeftMenu.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        let barButton = UIBarButtonItem(customView: btnLeftMenu)
        self.navigationItem.leftBarButtonItem = barButton

        // Add share button if sharingDeeplinkURL is available
        if contentMetadata.sharingDeeplinkURL != nil {
            let shareButton = UIButton(type: .system)
            let shareImage = UIImage(systemName: "square.and.arrow.up")?.withRenderingMode(.alwaysTemplate)
            shareButton.setImage(shareImage, for: .normal)
            shareButton.tintColor = navigationBar.tintColor
            shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
            shareButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            let shareBarButton = UIBarButtonItem(customView: shareButton)
            self.navigationItem.rightBarButtonItem = shareBarButton
        }

        self.title = "Audiobook Overview"
    }
    
    @objc func popVC() {
        self.navigationController?.popViewController(animated: true)
    }

    @objc private func shareButtonTapped() {
        guard let sharingURL = contentMetadata.sharingDeeplinkURL else { return }

        // Create preset share message
        var shareText = "Check out this audiobook"
        if let title = contentMetadata.title {
            shareText += ": \"\(title)\""
        }
        shareText += " on FreeAudiobooks!\n\n\(sharingURL)"

        showShareSheetWithText(shareText)
    }
}

extension BookDetailVC {
    func populateData() {
        storyTitleLabel.text = contentMetadata.title
        authorNameLabel.text = "by \(contentMetadata.authorsString)"
        if let genre = contentMetadata.genreDisplayString {
            genrePillView.configure(with: genre)
            genrePillView.isHidden = false
        } else {
            genrePillView.isHidden = true
        }
        updatePillRowVisibility()

        storyBookshelvesLabel.text = contentMetadata.collectionsText ?? "N/A"
        
        updateCompletionStatus()
    }
    
    private func updateCompletionStatus() {
        let isCompleted = AccountManager.shared.userHasCompletedBookInternalWithUUID(contentMetadata.contentUUID)
        coverImageView.showCompletionStatus(isCompleted)
    }

    private func updateCoverImageProgress() {
        let progressPercentage = ReadingUserDefaults.progressForBookWithUUID(contentMetadata.contentUUID)
        coverImageView.setProgress(progressPercentage)
    }
}

extension BookDetailVC {
    func showNotificationsPopup() {
        let style = PopupDialogDefaultView.customStyle.defaultCustomStyle
        PopupHelper.setAppearanceForStyle(style: style)
        
        let title = "Be the first to know"
        let message = "Join thousands of listeners getting notified when new stories go live"
        
        let popup = PopupDialog(title: title, message: message, image: nil, buttonAlignment: .vertical, transitionStyle: .fadeIn, preferredWidth: 500, panGestureDismissal: false, hideStatusBar: false, completion: nil)
        
        let buttonTwo = DefaultButton(title: "Notify Me", action: {
            DispatchQueue.main.async {
                let current = UNUserNotificationCenter.current()
                let options: UNAuthorizationOptions = [.sound, .badge, .alert]
                
                current.requestAuthorization(options: options) { granted, error in
                    //
                }
            }
        })
        
        let buttonOne = DefaultButton(title: "Cancel", action: {
            //
        })
        
        buttonOne.titleColor = Colours.grey100
        buttonOne.buttonColor = nil
        
        popup.addButtons([buttonTwo, buttonOne])
        self.present(popup, animated: true, completion: nil)
    }
}

extension BookDetailVC {
    func setupBottomContainerView() {
        bottomContainerView.backgroundColor = Colours.backgroundGrey
        view.addSubviewForConstraints(bottomContainerView)
        NSLayoutConstraint.activate([
            bottomContainerView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            bottomContainerView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            bottomContainerView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor)
        ])

        // Conditionally set up buttons based on audio support
        if contentMetadata.hasAnyAudiobook {
            setupReadButton()
            setupListenNowButtonWithReadOption()
        } else {
            setupReadNowButtonOnly()
        }

        let borderView = UIView()
        borderView.backgroundColor = Colours.separator
        bottomContainerView.addSubviewForConstraints(borderView)
        NSLayoutConstraint.activate([
            borderView.topAnchor.constraint(equalTo: bottomContainerView.topAnchor),
            borderView.bottomAnchor.constraint(equalTo: readNowButton.topAnchor, constant: -16),
            borderView.leftAnchor.constraint(equalTo: bottomContainerView.leftAnchor),
            borderView.rightAnchor.constraint(equalTo: bottomContainerView.rightAnchor),
            borderView.heightAnchor.constraint(equalToConstant: 1)
        ])

        setupDownloadingUI()
    }
    func setupReadButton() {
        let bookSymbolConfiguration = UIImage.SymbolConfiguration(weight: .medium)
        let bookImage = UIImage(systemName: "book", withConfiguration: bookSymbolConfiguration)?.withRenderingMode(.alwaysTemplate)
        readButton.setImage(bookImage, for: .normal)
        readButton.tintColor = .white

        bottomContainerView.addSubviewForConstraints(readButton)
        NSLayoutConstraint.activate([
            readButton.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -60),
            readButton.widthAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight),
            readButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight)
        ])
        readButton.addTarget(self, action: #selector(readNowTapped), for: .touchUpInside)
    }

    func setupListenNowButtonWithReadOption() {
        configurePlayIconOnPrimaryCTA()
        bottomContainerView.addSubviewForConstraints(readNowButton)
        NSLayoutConstraint.activate([
            readNowButton.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 60),
            readNowButton.trailingAnchor.constraint(equalTo: readButton.leadingAnchor, constant: -10),
            readNowButton.bottomAnchor.constraint(equalTo: bottomContainerView.bottomAnchor, constant: -16),
            readNowButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight),

            readButton.centerYAnchor.constraint(equalTo: readNowButton.centerYAnchor),
        ])
        readNowButton.addTarget(self, action: #selector(listenNowTapped), for: .touchUpInside)
        readNowButton.layer.cornerRadius = UIConstants.shared.fullButtonHeight / 2
    }

    /// Adds a play SF Symbol to the left of the primary CTA's title for the
    /// audiobook states (Listen Now / Continue Listening).
    private func configurePlayIconOnPrimaryCTA() {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let playImage = UIImage(systemName: "play.fill", withConfiguration: symbolConfig)?
            .withRenderingMode(.alwaysTemplate)
        readNowButton.setImage(playImage, for: .normal)
        readNowButton.tintColor = Colours.pinkCTATitle

        let spacing: CGFloat = 8
        readNowButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -spacing / 2, bottom: 0, right: spacing / 2)
        readNowButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing / 2, bottom: 0, right: -spacing / 2)
        readNowButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing / 2, bottom: 0, right: spacing / 2)
    }

    func setupReadNowButtonOnly() {
        bottomContainerView.addSubviewForConstraints(readNowButton)
        NSLayoutConstraint.activate([
            readNowButton.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 60),
            readNowButton.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -60),
            readNowButton.bottomAnchor.constraint(equalTo: bottomContainerView.bottomAnchor, constant: -16),
            readNowButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight)
        ])
        readNowButton.addTarget(self, action: #selector(readNowTapped), for: .touchUpInside)
        readNowButton.layer.cornerRadius = UIConstants.shared.fullButtonHeight / 2
    }
    func setupDownloadingUI() {
        downloadingLabel.font = Fonts.medium16
        downloadingLabel.textColor = Colours.textPrimary
        bottomContainerView.addSubviewForConstraints(downloadingLabel)
        NSLayoutConstraint.activate([
            downloadingLabel.centerYAnchor.constraint(equalTo: readNowButton.centerYAnchor),
            downloadingLabel.centerXAnchor.constraint(equalTo: readNowButton.centerXAnchor),
        ])
        downloadingLabel.text = "Downloading..."

        bottomContainerView.addSubviewForConstraints(downloadProgressView)
        NSLayoutConstraint.activate([
            downloadProgressView.topAnchor.constraint(equalTo: downloadingLabel.bottomAnchor, constant: 8),
            downloadProgressView.leadingAnchor.constraint(equalTo: readNowButton.leadingAnchor),
            downloadProgressView.trailingAnchor.constraint(equalTo: readNowButton.trailingAnchor)
        ])
        [downloadingLabel, downloadProgressView].forEach { $0.isHidden = true }
    }
}

extension BookDetailVC: UIScrollViewDelegate {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView === writtenReviewsCollectionView else { return }
        guard !writtenReviews.isEmpty else { return }

        let itemSpacing: CGFloat = 12
        let itemWidth = writtenReviewCardWidth()
        let itemStride = itemWidth + itemSpacing
        guard itemStride > 0 else { return }

        let proposedOffsetX = max(-scrollView.adjustedContentInset.left, targetContentOffset.pointee.x)
        let rawIndex = proposedOffsetX / itemStride

        let snappedIndex: CGFloat
        if velocity.x > 0.2 {
            snappedIndex = ceil(rawIndex)
        } else if velocity.x < -0.2 {
            snappedIndex = floor(rawIndex)
        } else {
            snappedIndex = round(rawIndex)
        }

        let maxOffsetX = max(
            -scrollView.adjustedContentInset.left,
            scrollView.contentSize.width - scrollView.bounds.width + scrollView.adjustedContentInset.right
        )
        let snappedOffsetX = min(
            max(snappedIndex * itemStride, -scrollView.adjustedContentInset.left),
            maxOffsetX
        )

        targetContentOffset.pointee.x = snappedOffsetX
    }

    func setupScrollView() {
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            scrollView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomContainerView.topAnchor)
        ])
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        
//         scrollView.contentInsetAdjustmentBehavior = .never
//         scrollView.contentInset = UIEdgeInsets(top: 88, left: 0, bottom: 34, right: 0)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
            contentView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
}

private extension BookDetailVC {
    func setupStoryTitleLabel() {
        storyTitleLabel.font = Fonts.semiBold19
        storyTitleLabel.textColor = Colours.textPrimary
        storyTitleLabel.numberOfLines = 0
        storyTitleLabel.lineBreakMode = .byWordWrapping
        storyTitleLabel.textAlignment = .center

        contentView.addSubviewForConstraints(storyTitleLabel)

        // Title below cover image (matching Android HeaderSection layout)
        NSLayoutConstraint.activate([
            storyTitleLabel.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 24),
            storyTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            storyTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin)
        ])
    }
    func setupAuthorNameLabel() {
        authorMetadataStackView.axis = .vertical
        authorMetadataStackView.alignment = .center
        authorMetadataStackView.spacing = 6

        authorNameLabel.numberOfLines = 1
        authorNameLabel.font = Fonts.medium15
        authorNameLabel.textColor = Colours.textSecondary

        pillRowStackView.axis = .horizontal
        pillRowStackView.alignment = .center
        pillRowStackView.spacing = 8
        pillRowStackView.addArrangedSubview(genrePillView)
        pillRowStackView.addArrangedSubview(ratingChipView)
        ratingChipView.isHidden = true

        metadataLineLabel.numberOfLines = 1
        metadataLineLabel.font = Fonts.medium13
        metadataLineLabel.textColor = Colours.textSecondary
        metadataLineLabel.textAlignment = .center

        authorMetadataStackView.addArrangedSubview(authorNameLabel)
        authorMetadataStackView.addArrangedSubview(pillRowStackView)
        authorMetadataStackView.setCustomSpacing(10, after: pillRowStackView)
        authorMetadataStackView.addArrangedSubview(metadataLineLabel)

        // Keep the genre target independent from the rating chip's review action.
        genrePillTapGestureRecognizer.delegate = self
        pillRowStackView.addGestureRecognizer(genrePillTapGestureRecognizer)
        pillRowStackView.isUserInteractionEnabled = true

        ratingChipView.tappedHandler = { [weak self] in
            self?.scrollToReviewsSection()
        }
        ratingChipView.setTapEnabled(shouldShowReviewsSection)

        contentView.addSubviewForConstraints(authorMetadataStackView)
        NSLayoutConstraint.activate([
            authorMetadataStackView.topAnchor.constraint(equalTo: storyTitleLabel.bottomAnchor, constant: 10), // was 4
            authorMetadataStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // optional but recommended for long author names / localization:
            authorMetadataStackView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            authorMetadataStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
        ])
    }

    func setupAdultContentBadge() {
        // Check if book contains adult content
        let showBadge: Bool
        if let bookInternal = contentMetadata as? CDBookInternal {
            showBadge = bookInternal.containsAdultContent
        } else {
            showBadge = false
        }

        // Add badge as subview of coverImageView for overlay effect (like ShortStoryCVC and Android)
        coverImageView.addSubviewForConstraints(adultContentBadge)

        // Match the progress badge's inset so both cover badges share a baseline.
        NSLayoutConstraint.activate([
            adultContentBadge.topAnchor.constraint(
                equalTo: coverImageView.topAnchor,
                constant: UIConstants.shared.coverImageBadgeInset
            ),
            adultContentBadge.leadingAnchor.constraint(
                equalTo: coverImageView.leadingAnchor,
                constant: UIConstants.shared.coverImageBadgeInset
            ),
            adultContentBadge.widthAnchor.constraint(equalToConstant: 36),
            adultContentBadge.heightAnchor.constraint(equalToConstant: 20)
        ])

        adultContentBadge.isHidden = !showBadge
    }
}

extension BookDetailVC {
    func setupBookImageView() {
        contentView.addSubviewForConstraints(coverImageView)

        // Cover image at top of content, centered, 55% width (matching Android)
        NSLayoutConstraint.activate([
            coverImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UIConstants.shared.standardMargin),
            coverImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            coverImageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: coverImageView.getWidthMultiplier() ?? 0.55)
        ])

        coverImageView.coverCornerRadiusOverride = 12

        // Set content mode based on type
        if contentMetadata.contentType == .bookInternal {
            coverImageView.setContentMode(.scaleAspectFill)
        } else {
            coverImageView.setContentMode(.scaleAspectFit)
        }

        let progressPercentage = ReadingUserDefaults.progressForBookWithUUID(contentMetadata.contentUUID)
        coverImageView.setImage(urlString: contentMetadata.coverImageXLURLString ?? contentMetadata.coverImageURLString,
                                isBookCompleted: contentMetadata.isCompleted(),
                                progressPercentage: progressPercentage)
    }
}

private extension BookDetailVC {
    func setupActionButtonUI() {
        setupActionsContainerView()
        setupSaveLikeShareSplitter()
    }
    
    func setupActionsContainerView() {
        actionsContainerView.axis = .horizontal
        actionsContainerView.spacing = 32
        actionsContainerView.alignment = .center
        actionsContainerView.distribution = .equalSpacing

        contentView.addSubviewForConstraints(actionsContainerView)
        NSLayoutConstraint.activate([
            actionsContainerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            actionsContainerView.topAnchor.constraint(equalTo: authorMetadataStackView.bottomAnchor, constant: 22)
        ])

        let iconConfig = UIImage.SymbolConfiguration(weight: .semibold)

        // Setup save button
        saveButton.setTitle("Save")
        saveButton.setIcon(UIImage(systemName: "bookmark", withConfiguration: iconConfig))
        saveButton.tappedHandler = { [weak self] in
            self?.tappedSave()
        }
        actionsContainerView.addArrangedSubview(saveButton)

        // Setup download button
        downloadButton.setTitle("Download")
        downloadButton.setIcon(UIImage(systemName: "arrow.down", withConfiguration: iconConfig))
        downloadButton.tappedHandler = { [weak self] in
            self?.tappedDownload()
        }
        actionsContainerView.addArrangedSubview(downloadButton)
    }
    
    func setupSaveLikeShareSplitter() {
        contentView.addSubviewForConstraints(saveLikeShareSplitter)
        NSLayoutConstraint.activate([
            saveLikeShareSplitter.topAnchor.constraint(equalTo: actionsContainerView.bottomAnchor, constant: UIConstants.shared.standardMargin),
            saveLikeShareSplitter.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            saveLikeShareSplitter.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            saveLikeShareSplitter.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
}

private extension BookDetailVC {
    func updateSaveElements() {
        var isSaved = false
        if let user = AccountManager.shared.user {
            isSaved = user.savedBookInternalUUIDs.contains(contentMetadata.contentUUID)
        }
        let iconConfig = UIImage.SymbolConfiguration(weight: .semibold)
        saveButton.setVisualState(isSelected: isSaved,
                                  selectedIcon: UIImage(systemName: "bookmark.fill", withConfiguration: iconConfig),
                                  normalIcon: UIImage(systemName: "bookmark", withConfiguration: iconConfig))
    }

    func updateDownloadElements() {
        guard !isAudioDownloadInProgress else { return }

        if contentMetadata.hasDownloadedAudio {
            setDownloadedImage()
            downloadButton.setTitle("Downloaded")
        } else {
            let iconConfig = UIImage.SymbolConfiguration(weight: .semibold)
            downloadButton.setVisualState(isSelected: false,
                                          selectedIcon: UIImage(systemName: "arrow.down", withConfiguration: iconConfig),
                                          normalIcon: UIImage(systemName: "arrow.down", withConfiguration: iconConfig))
            downloadButton.borderWidth = 0
            downloadButton.borderColor = nil
            downloadButton.setTitle("Download")
        }
    }

    private func setDownloadedImage() {
        let iconConfig = UIImage.SymbolConfiguration(weight: .semibold)
        downloadButton.setIcon(UIImage(systemName: "checkmark", withConfiguration: iconConfig))
        downloadButton.iconTintColor = Colours.downloadedGreen
        downloadButton.backgroundColour = Colours.actionIconBackground
        downloadButton.borderWidth = 0
        downloadButton.borderColor = nil
    }

    func observeAudioDownloadState() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioDownloadStateDidChange(_:)),
            name: .audiobookDownloadStateDidChange,
            object: APIBookInternalAudioManager.shared
        )
    }

    @objc func audioDownloadStateDidChange(_ notification: Notification) {
        guard notification.userInfo?["bookUUID"] as? String == contentMetadata.contentUUID else { return }
        syncAudioDownloadStateFromManager(showCompletionIfVisible: true)
    }

    func syncAudioDownloadStateFromManager(showCompletionIfVisible: Bool) {
        let wasDownloading = isAudioDownloadInProgress
        let state = APIBookInternalAudioManager.shared.downloadState(for: contentMetadata.contentUUID)

        switch state {
        case .idle:
            if isAudioDownloadInProgress {
                endAudioDownloadUI()
            }
        case let .downloading(progress):
            if !isAudioDownloadInProgress {
                beginAudioDownloadUI()
            }
            updateAudioDownloadUI(progress: progress)
        case .downloaded:
            if isAudioDownloadInProgress {
                endAudioDownloadUI()
            } else {
                updateDownloadElements()
                updatePrimaryCTAButtonTitle()
            }

            if showCompletionIfVisible,
               wasDownloading,
               isCurrentVisibleBookDetail {
                showAudioDownloadSuccess()
            }
        case let .failed(error):
            if isAudioDownloadInProgress {
                endAudioDownloadUI()
            }

            if showCompletionIfVisible,
               wasDownloading,
               isCurrentVisibleBookDetail {
                showAudioDownloadError(error, language: .english)
            }
        }
    }

    var isCurrentVisibleBookDetail: Bool {
        isViewLoaded && view.window != nil && navigationController?.topViewController === self
    }
}

private extension BookDetailVC {
    func scrollToReviewsSection() {
        guard
            reviewsSectionContainerView.superview != nil else { return }

        view.layoutIfNeeded()
        let rawTargetY = max(0, reviewsSectionContainerView.frame.minY - 12)
        let minOffsetY = -scrollView.adjustedContentInset.top
        let maxOffsetY = max(
            minOffsetY,
            scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom
        )
        let clampedTargetY = min(max(rawTargetY, minOffsetY), maxOffsetY)
        scrollView.setContentOffset(CGPoint(x: 0, y: clampedTargetY), animated: true)
    }
}

private extension BookDetailVC {
    func setupUIForContentType(_ contentType: ContentType) {
        setupSectionsForBookInternal()
    }

    func setupSectionsForBookInternal() {
        var topElement: UIView = saveLikeShareSplitter
        topElement = setupSynopsisSection(topElement: topElement)
        topElement = setupTagsSection(topElement: topElement)
        if shouldShowReviewsSection {
            topElement = setupReviewsSection(topElement: topElement)
        }

        // More in Genre section (conditional on having related stories)
        topElement = setupMoreInGenreSection(topElement: topElement)

        // Anchor final element to bottom
        setupBottomConstraint(for: topElement)
    }
}

private extension BookDetailVC {
    func setupReviewsSection(topElement: UIView) -> UIView {
        reviewsSectionStackView.axis = .vertical
        reviewsSectionStackView.spacing = 16
        reviewsSectionStackView.alignment = .fill

        reviewsIntroLabel.text = "Reviews"
        reviewsIntroLabel.textColor = Colours.textPrimary
        reviewsIntroLabel.font = Fonts.semiBold19
        reviewsIntroLabel.numberOfLines = 0
        reviewsIntroLabel.lineBreakMode = .byWordWrapping

        setupReviewsSummaryView()
        setupWrittenReviewsSubheading()
        setupWrittenReviewsCollectionView()

        reviewsSectionContainerView.addSubviewForConstraints(reviewsSectionStackView)
        reviewsSectionContainerView.addSubviewForConstraints(reviewsSplitter)
        NSLayoutConstraint.activate([
            reviewsSectionStackView.topAnchor.constraint(equalTo: reviewsSectionContainerView.topAnchor),
            reviewsSectionStackView.leadingAnchor.constraint(equalTo: reviewsSectionContainerView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            reviewsSectionStackView.trailingAnchor.constraint(equalTo: reviewsSectionContainerView.trailingAnchor, constant: -UIConstants.shared.standardMargin),

            reviewsSplitter.topAnchor.constraint(equalTo: reviewsSectionStackView.bottomAnchor, constant: UIConstants.shared.standardMargin),
            reviewsSplitter.leadingAnchor.constraint(equalTo: reviewsSectionContainerView.leadingAnchor),
            reviewsSplitter.trailingAnchor.constraint(equalTo: reviewsSectionContainerView.trailingAnchor),
            reviewsSplitter.heightAnchor.constraint(equalToConstant: 1),
            reviewsSplitter.bottomAnchor.constraint(equalTo: reviewsSectionContainerView.bottomAnchor)
        ])

        [reviewsIntroLabel, reviewsSummaryContainerView, writtenReviewsSubheadingLabel, writtenReviewsCollectionView].forEach {
            reviewsSectionStackView.addArrangedSubview($0)
        }

        contentView.addSubviewForConstraints(reviewsSectionContainerView)
        NSLayoutConstraint.activate([
            reviewsSectionContainerView.topAnchor.constraint(equalTo: topElement.bottomAnchor, constant: UIConstants.shared.standardMargin),
            reviewsSectionContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            reviewsSectionContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        applyInitialReviewsSummary()
        updateWrittenReviewsVisibility(animated: false)

        return reviewsSectionContainerView
    }

    func setupReviewsSummaryView() {
        reviewsScoreLabel.font = Fonts.boldWithSize(42)
        reviewsScoreLabel.textColor = Colours.textPrimary
        reviewsScoreLabel.setContentHuggingPriority(.required, for: .horizontal)
        reviewsScoreLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        reviewsSummaryStackView.axis = .vertical
        reviewsSummaryStackView.spacing = 6
        reviewsSummaryStackView.alignment = .trailing

        reviewsStarsView.settings.updateOnTouch = false
        reviewsStarsView.settings.fillMode = .precise
        reviewsStarsView.settings.starSize = 16
        reviewsStarsView.settings.starMargin = 2
        reviewsStarsView.settings.emptyBorderWidth = 1
        reviewsStarsView.setContentHuggingPriority(.required, for: .horizontal)
        reviewsStarsView.setContentCompressionResistancePriority(.required, for: .horizontal)

        reviewsCountLabel.font = Fonts.medium14
        reviewsCountLabel.textColor = Colours.textSecondary
        reviewsCountLabel.numberOfLines = 1
        reviewsCountLabel.textAlignment = .right

        reviewsSummaryStackView.addArrangedSubview(reviewsStarsView)
        reviewsSummaryStackView.addArrangedSubview(reviewsCountLabel)

        reviewsSummaryContainerView.addSubviewForConstraints(reviewsScoreLabel)
        reviewsSummaryContainerView.addSubviewForConstraints(reviewsSummaryStackView)
        NSLayoutConstraint.activate([
            reviewsScoreLabel.leadingAnchor.constraint(equalTo: reviewsSummaryContainerView.leadingAnchor),
            reviewsScoreLabel.topAnchor.constraint(equalTo: reviewsSummaryContainerView.topAnchor),
            reviewsScoreLabel.bottomAnchor.constraint(equalTo: reviewsSummaryContainerView.bottomAnchor),

            reviewsSummaryStackView.leadingAnchor.constraint(equalTo: reviewsScoreLabel.trailingAnchor, constant: 20),
            reviewsSummaryStackView.topAnchor.constraint(equalTo: reviewsSummaryContainerView.topAnchor, constant: 6),
            reviewsSummaryStackView.trailingAnchor.constraint(equalTo: reviewsSummaryContainerView.trailingAnchor),
            reviewsSummaryStackView.bottomAnchor.constraint(lessThanOrEqualTo: reviewsSummaryContainerView.bottomAnchor)
        ])
    }

    func setupWrittenReviewsCollectionView() {
        writtenReviewsCollectionView.register(OldBookDetailReviewCardCell.self, forCellWithReuseIdentifier: OldBookDetailReviewCardCell.reuseIdentifier)
        writtenReviewsCollectionView.delegate = self
        writtenReviewsCollectionView.dataSource = self

        writtenReviewsCollectionHeightConstraint = writtenReviewsCollectionView.heightAnchor.constraint(equalToConstant: OldBookDetailReviewCardCell.maximumHeight)
        writtenReviewsCollectionHeightConstraint?.isActive = true
    }

    func setupWrittenReviewsSubheading() {
        writtenReviewsSubheadingLabel.font = Fonts.semiBold15
        writtenReviewsSubheadingLabel.textColor = Colours.textPrimary
        writtenReviewsSubheadingLabel.text = "Most Helpful Reviews"
        writtenReviewsSubheadingLabel.numberOfLines = 1
        writtenReviewsSubheadingLabel.isHidden = true
    }

    func applyInitialReviewsSummary() {
        guard let bookInternal = contentMetadata as? CDBookInternal else {
            updateReviewsSummary(rating: nil, numberOfRatings: nil)
            return
        }

        let rating = bookInternal.rating > 0 ? bookInternal.rating : nil
        let numberOfRatings = bookInternal.numberOfRatings > 0 ? Int(bookInternal.numberOfRatings) : nil
        updateReviewsSummary(rating: rating, numberOfRatings: numberOfRatings)
    }

    func updateReviewsSummary(rating: Double?, numberOfRatings: Int?) {
        guard
            let rating,
            let numberOfRatings,
            BookDetailVC.hasDisplayableRating(numberOfRatings: numberOfRatings) else {
            reviewsScoreLabel.font = Fonts.semiBold19
            reviewsScoreLabel.text = "Pending"
            reviewsCountLabel.text = "No ratings yet"
            configureReviewsStars(rating: 0, isPending: true)
            return
        }

        reviewsScoreLabel.font = Fonts.boldWithSize(42)
        reviewsScoreLabel.text = String(format: "%.2f", rating)
        reviewsCountLabel.text = "\(numberOfRatings) Rating\(numberOfRatings == 1 ? "" : "s")"
        configureReviewsStars(rating: rating, isPending: false)
    }

    func configureReviewsStars(rating: Double, isPending: Bool) {
        let tintColor = isPending ? Colours.textTertiary : Colours.textPrimary
        reviewsStarsView.settings.filledColor = tintColor
        reviewsStarsView.settings.filledBorderColor = tintColor
        reviewsStarsView.settings.emptyBorderColor = Colours.veryLightUI
        reviewsStarsView.rating = rating
    }

    func fetchWrittenReviews() {
        APIBookReviewsManager.shared.fetchReviewsForMetadata(contentMetadata: contentMetadata) { [weak self] reviews, success in
            guard let self = self else { return }

            DispatchQueue.main.async {
                guard success else {
                    self.writtenReviews = []
                    self.updateWrittenReviewsVisibility(animated: true)
                    return
                }

                let resolvedReviews = reviews ?? []
                self.writtenReviews = Array(
                    resolvedReviews.filter { review in
                        !(review.comment?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
                    }.prefix(10)
                )
                self.writtenReviewsCollectionView.reloadData()
                self.updateWrittenReviewsVisibility(animated: true)
            }
        }
    }

    func reviewDisplayName(for review: APIBookReview) -> String {
        let displayName = review.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return displayName.isEmpty ? "FreeAudiobooks Listener" : displayName
    }

    func reviewDateText(for date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "d MMM"
        } else {
            formatter.dateFormat = "d MMM yyyy"
        }
        return formatter.string(from: date)
    }

    func updateWrittenReviewsVisibility(animated: Bool) {
        let hasWrittenReviews = !writtenReviews.isEmpty
        writtenReviewsSubheadingLabel.isHidden = !hasWrittenReviews
        writtenReviewsCollectionView.isHidden = !hasWrittenReviews
        writtenReviewsCollectionHeightConstraint?.constant = hasWrittenReviews ? preferredWrittenReviewsCollectionHeight() : 0
        writtenReviewsCollectionView.collectionViewLayout.invalidateLayout()

        guard animated else { return }
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

    func preferredWrittenReviewsCollectionHeight() -> CGFloat {
        guard !writtenReviews.isEmpty else { return 0 }
        let cardWidth = writtenReviewCardWidth()
        return writtenReviews.reduce(0) { currentTallest, review in
            max(currentTallest, OldBookDetailReviewCardCell.preferredHeight(for: review, width: cardWidth))
        }
    }

    func writtenReviewCardWidth() -> CGFloat {
        let availableWidth = writtenReviewsCollectionView.bounds.width > 0
            ? writtenReviewsCollectionView.bounds.width
            : UIScreen.main.bounds.width
        return max(240, availableWidth - 28)
    }

    func refreshWrittenReviewsLayoutIfNeeded() {
        guard !writtenReviews.isEmpty else { return }
        let targetHeight = preferredWrittenReviewsCollectionHeight()
        guard abs((writtenReviewsCollectionHeightConstraint?.constant ?? 0) - targetHeight) > 0.5 else { return }
        writtenReviewsCollectionHeightConstraint?.constant = targetHeight
        writtenReviewsCollectionView.collectionViewLayout.invalidateLayout()
    }

    func setupTagsSection(topElement: UIView) -> UIView {
        tagsSectionStackView.axis = .vertical
        tagsSectionStackView.spacing = 12
        tagsSectionStackView.alignment = .fill
        tagsSectionStackView.isHidden = true

        tagsIntroLabel.text = "Tags"
        tagsIntroLabel.textColor = Colours.textPrimary
        tagsIntroLabel.font = Fonts.semiBold19
        tagsIntroLabel.numberOfLines = 0
        tagsIntroLabel.lineBreakMode = .byWordWrapping
        tagsIntroLabel.textAlignment = .left
        tagPillsContainerView.setContentHuggingPriority(.required, for: .vertical)
        tagPillsContainerView.setContentCompressionResistancePriority(.required, for: .vertical)

        tagsSectionContainerView.addSubviewForConstraints(tagsSectionStackView)
        tagsSectionContainerView.addSubviewForConstraints(tagsSplitter)
        tagsSectionExpandedConstraints = [
            tagsSectionStackView.topAnchor.constraint(equalTo: tagsSectionContainerView.topAnchor),
            tagsSectionStackView.leadingAnchor.constraint(equalTo: tagsSectionContainerView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            tagsSectionStackView.trailingAnchor.constraint(equalTo: tagsSectionContainerView.trailingAnchor, constant: -UIConstants.shared.standardMargin),

            tagsSplitter.topAnchor.constraint(equalTo: tagsSectionStackView.bottomAnchor, constant: UIConstants.shared.standardMargin),
            tagsSplitter.leadingAnchor.constraint(equalTo: tagsSectionContainerView.leadingAnchor),
            tagsSplitter.trailingAnchor.constraint(equalTo: tagsSectionContainerView.trailingAnchor),
            tagsSplitter.heightAnchor.constraint(equalToConstant: 1),
            tagsSplitter.bottomAnchor.constraint(equalTo: tagsSectionContainerView.bottomAnchor)
        ]
        NSLayoutConstraint.activate(tagsSectionExpandedConstraints)

        [tagsIntroLabel, tagPillsContainerView].forEach {
            tagsSectionStackView.addArrangedSubview($0)
        }

        contentView.addSubviewForConstraints(tagsSectionContainerView)
        let topConstraint = tagsSectionContainerView.topAnchor.constraint(equalTo: topElement.bottomAnchor, constant: UIConstants.shared.standardMargin)
        tagsSectionTopConstraint = topConstraint
        tagsSectionCollapsedHeightConstraint = tagsSectionContainerView.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            topConstraint,
            tagsSectionContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tagsSectionContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        refreshTagsSectionIfNeeded()
        return tagsSectionContainerView
    }

    func refreshTagsSectionIfNeeded() {
        guard let book = contentMetadata as? CDBookInternal else {
            updateTagsSectionVisibility(hasItems: false)
            return
        }

        updateTagsSectionVisibility(hasItems: false)
        BookInternalTagManager.shared.ensureHomeEligibleTags(for: book.genre) { [weak self] success, tags in
            guard let self else { return }
            if success {
                eligibleTagsForCurrentBookGenre = tags
            }
            renderTagsSection()
        }
    }

    func renderTagsSection() {
        guard let visibleBookInternalStories else {
            updateTagsSectionVisibility(hasItems: false)
            return
        }

        let items = resolvedEligibleTagItems(from: visibleBookInternalStories)
        tagPillsContainerView.configure(items: items, target: self, action: #selector(tagPillTapped(_:)))
        updateTagsSectionVisibility(hasItems: !items.isEmpty)

        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

    func updateTagsSectionVisibility(hasItems: Bool) {
        tagsSectionContainerView.isHidden = !hasItems
        tagsSectionStackView.isHidden = !hasItems
        tagsSplitter.isHidden = !hasItems
        tagsSectionTopConstraint?.constant = hasItems ? UIConstants.shared.standardMargin : 0

        if hasItems {
            tagsSectionCollapsedHeightConstraint?.isActive = false
            NSLayoutConstraint.activate(tagsSectionExpandedConstraints)
        } else {
            NSLayoutConstraint.deactivate(tagsSectionExpandedConstraints)
            tagsSectionCollapsedHeightConstraint?.isActive = true
        }
    }

    func resolvedEligibleTagItems(from visibleBooks: [CDBookInternal]) -> [OldBookDetailTagPillItem] {
        guard let book = contentMetadata as? CDBookInternal else { return [] }
        let uniqueTags = Array(NSOrderedSet(array: book.tags)) as? [String] ?? []

        return uniqueTags.compactMap { tag in
            guard let bookInternalTag = bookInternalTagForDisplayTag(tag, genre: book.genre) else { return nil }
            guard hasOtherVisibleBook(for: bookInternalTag, excluding: book.contentUUID, in: visibleBooks) else { return nil }
            return OldBookDetailTagPillItem(title: bookInternalTag.title, tag: bookInternalTag.tag)
        }
    }

    func hasOtherVisibleBook(for tag: BookInternalTag,
                             excluding currentBookUUID: String,
                             in visibleBooks: [CDBookInternal]) -> Bool {
        visibleBooks.contains {
            $0.contentUUID != currentBookUUID &&
            $0.genre == tag.genre &&
            $0.tags.contains(tag.tag) &&
            (AccountManager.shared.userIsSubscribed || $0.isAvailableToUser)
        }
    }

    func bookInternalTagForDisplayTag(_ tag: String, genre: BookInternalGenre) -> BookInternalTag? {
        eligibleTagsForCurrentBookGenre.first {
            $0.genre == genre && $0.tag == tag
        }
    }

    @objc private func tagPillTapped(_ sender: OldTagPillButton) {
        presentTagResults(for: sender.tagValue)
    }

    func presentTagResults(for tag: String) {
        guard let book = contentMetadata as? CDBookInternal else { return }
        guard let bookInternalTag = bookInternalTagForDisplayTag(tag, genre: book.genre) else { return }
        let tagResultsVC = TagResultsVC(tag: bookInternalTag)
        tagResultsVC.delegate = self
        let navController = UINavigationController(rootViewController: tagResultsVC)
        present(navController, animated: true)
    }

    func setupSynopsisSection(topElement: UIView) -> UIView {
        setupSynopsisIntroLabel(topElement: topElement)
        setupSynopsisLabel()
        setupSynopsisReadMoreButton()

        // Only show AI synopsis button for content that needs it
        if contentMetadata.needsAISynopsis {
            setupGenerateSynopsisButton()
        } else if let synopsis = contentMetadata.synopsis {
            // For short stories, display the synopsis immediately
            setSynopsisPreviewText(synopsis)
            generateAIStorySynopsisButton.isHidden = true
        }

        // Always add splitter for chaining to next section
        setupSynopsisSplitter()

        return storySynopsisSplitter
    }

    func setupSynopsisIntroLabel(topElement: UIView) {
        storySynopsisIntroLabel.text = "Synopsis"
        storySynopsisIntroLabel.textColor = Colours.textPrimary
        storySynopsisIntroLabel.font = Fonts.semiBold19
        storySynopsisIntroLabel.numberOfLines = 0
        storySynopsisIntroLabel.lineBreakMode = .byWordWrapping

        contentView.addSubviewForConstraints(storySynopsisIntroLabel)
        NSLayoutConstraint.activate([
            storySynopsisIntroLabel.topAnchor.constraint(equalTo: topElement.bottomAnchor, constant: UIConstants.shared.standardMargin),
            storySynopsisIntroLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            storySynopsisIntroLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin)
        ])
    }
    func setupSynopsisLabel() {
        storySynopsisLabel.textColor = Colours.textSecondary
        storySynopsisLabel.font = Fonts.medium15
        storySynopsisLabel.numberOfLines = 3
        storySynopsisLabel.lineBreakMode = .byWordWrapping

        storySynopsisLabel.clipsToBounds = true

        contentView.addSubviewForConstraints(storySynopsisLabel)
        storySynopsisLabelMinHeightConstraint = storySynopsisLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        storySynopsisLabelMinHeightConstraint?.isActive = true
        NSLayoutConstraint.activate([
            storySynopsisLabel.topAnchor.constraint(equalTo: storySynopsisIntroLabel.bottomAnchor, constant: 12),
            storySynopsisLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            storySynopsisLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin)
        ])

        storySynopsisLabel.contentMode = .topLeft
        storySynopsisLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(synopsisReadMoreTapped))
        storySynopsisLabel.addGestureRecognizer(tap)
    }
    
    func setupSynopsisReadMoreButton() {
        let synopsisActionColor = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
        synopsisReadMoreButton.setTitle("Show More", for: .normal)
        synopsisReadMoreButton.setTitleColor(synopsisActionColor, for: .normal)
        synopsisReadMoreButton.titleLabel?.font = Fonts.medium14
        synopsisReadMoreButton.tintColor = synopsisActionColor
        synopsisReadMoreButton.semanticContentAttribute = .forceRightToLeft
        synopsisReadMoreButton.contentHorizontalAlignment = .left
        synopsisReadMoreButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4)
        synopsisReadMoreButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
        synopsisReadMoreButton.isHidden = true
        synopsisReadMoreButton.addTarget(self, action: #selector(synopsisReadMoreTapped), for: .touchUpInside)
        updateSynopsisReadMoreButtonTextAndChevron()

        contentView.addSubviewForConstraints(synopsisReadMoreButton)
        synopsisReadMoreButtonHeightConstraint = synopsisReadMoreButton.heightAnchor.constraint(equalToConstant: 0)
        synopsisReadMoreButtonHeightConstraint?.isActive = true
        NSLayoutConstraint.activate([
            synopsisReadMoreButton.topAnchor.constraint(equalTo: storySynopsisLabel.bottomAnchor, constant: 8),
            synopsisReadMoreButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            synopsisReadMoreButton.widthAnchor.constraint(equalToConstant: 100)
        ])
    }

    @objc func synopsisReadMoreTapped() {
        guard !(storySynopsisLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) else { return }
        isSynopsisExpanded.toggle()
        applySynopsisExpansionState(animated: true)
    }

    func applySynopsisExpansionState(animated: Bool) {
        if isSynopsisExpanded {
            storySynopsisLabel.numberOfLines = 0
        } else {
            storySynopsisLabel.numberOfLines = 3
        }
        updateSynopsisReadMoreButtonTextAndChevron()

        let hasSynopsisText = !(storySynopsisLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        storySynopsisLabelMinHeightConstraint?.constant = hasSynopsisText ? 0 : 60
        setSynopsisReadMoreControlVisible(hasSynopsisText)

        if animated {
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
    }

    func setSynopsisReadMoreControlVisible(_ isVisible: Bool) {
        synopsisReadMoreButton.isHidden = !isVisible
        synopsisReadMoreButtonHeightConstraint?.constant = isVisible ? 22 : 0
    }

    func updateSynopsisReadMoreButtonTextAndChevron() {
        let title = isSynopsisExpanded ? "Show Less" : "Show More"
        let symbolName = isSynopsisExpanded ? "chevron.up" : "chevron.down"
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        let image = UIImage(systemName: symbolName, withConfiguration: chevronConfig)

        for state: UIControl.State in [.normal, .highlighted] {
            synopsisReadMoreButton.setTitle(title, for: state)
            synopsisReadMoreButton.setImage(image, for: state)
        }

        synopsisReadMoreButton.setNeedsLayout()
        synopsisReadMoreButton.layoutIfNeeded()
    }

    func setSynopsisPreviewText(_ text: String) {
        storySynopsisLabel.text = text
        storySynopsisLabelMinHeightConstraint?.constant = 0
        isSynopsisExpanded = false
        applySynopsisExpansionState(animated: false)
    }

    func setupGenerateSynopsisButton() {
        contentView.addSubviewForConstraints(generateAIStorySynopsisButton)
        NSLayoutConstraint.activate([
            generateAIStorySynopsisButton.centerYAnchor.constraint(equalTo: storySynopsisLabel.centerYAnchor),
            generateAIStorySynopsisButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            generateAIStorySynopsisButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            generateAIStorySynopsisButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.midButtonHeight)
        ])
        generateAIStorySynopsisButton.addTarget(self, action: #selector(generateAIStorySynopsisButtonTapped), for: .touchUpInside)
        
        generateAIStorySynopsisButton.layer.cornerRadius = UIConstants.shared.midButtonCornerRadius
    }
    
    @objc func generateAIStorySynopsisButtonTapped() {
        setSynopsisPreviewText(contentMetadata.synopsis ?? "")
    }
    
    func showSynopsisLoadingIndicator(show: Bool) {
        if show {
            [generateAIStorySynopsisButton].forEach { $0.isHidden = true }
            setSynopsisReadMoreControlVisible(false)
            guard synopsisLoadingIndicatorView == nil else { return }
            synopsisLoadingIndicatorView = NVActivityIndicatorView(frame: CGRect.zero, type: NVActivityIndicatorType.circleStrokeSpin, color: Colours.textPrimary, padding: 0)
            guard let indicatorView = synopsisLoadingIndicatorView else {return}
            
            indicatorView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(indicatorView)
            NSLayoutConstraint.activate([
                indicatorView.centerYAnchor.constraint(equalTo: generateAIStorySynopsisButton.centerYAnchor),
                indicatorView.widthAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight),
                indicatorView.heightAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight),
                indicatorView.centerXAnchor.constraint(equalTo: generateAIStorySynopsisButton.centerXAnchor)
            ])
            indicatorView.startAnimating()
        } else {
            synopsisLoadingIndicatorView?.stopAnimating()
            synopsisLoadingIndicatorView?.removeFromSuperview()
            synopsisLoadingIndicatorView = nil
        }
    }
    
    func showGenerateSynopsisAlert() {
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] cancelTapped in
            guard let self = self else { return }
            DispatchQueue.main.async {
                [self.generateAIStorySynopsisButton].forEach { $0.isHidden = false }
            }
        }
        let retryAction = UIAlertAction(title: "Retry", style: .default) { [weak self] retryTapped in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.generateAIStorySynopsisButtonTapped()
            }
        }
        let alertController = UIAlertController(title: "Network Error", message: "Please ensure you have an active internet connection and try again.", preferredStyle: .alert)
        alertController.addAction(cancelAction)
        alertController.addAction(retryAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func setupSynopsisSplitter() {
        contentView.addSubviewForConstraints(storySynopsisSplitter)
        NSLayoutConstraint.activate([
            storySynopsisSplitter.topAnchor.constraint(equalTo: synopsisReadMoreButton.bottomAnchor, constant: UIConstants.shared.standardMargin),
            storySynopsisSplitter.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            storySynopsisSplitter.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            storySynopsisSplitter.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
}

private extension BookDetailVC {
    func setupMoreInGenreSection(topElement: UIView) -> UIView {
        guard contentMetadata.contentType == .bookInternal else {
            return topElement
        }

        setupMoreInGenreContainer(topElement: topElement)
        updateMoreInGenreSectionVisibility(hasItems: false, animated: false)

        return moreInGenreSectionContainerView
    }

    func setupMoreInGenreContainer(topElement: UIView) {
        guard moreInGenreSectionContainerView.superview == nil else { return }

        setupMoreInGenreIntroLabel()
        setupMoreInGenreCollectionView()

        contentView.addSubviewForConstraints(moreInGenreSectionContainerView)

        let topConstraint = moreInGenreSectionContainerView.topAnchor.constraint(equalTo: topElement.bottomAnchor, constant: 0)
        moreInGenreSectionTopConstraint = topConstraint
        moreInGenreSectionCollapsedHeightConstraint = moreInGenreSectionContainerView.heightAnchor.constraint(equalToConstant: 0)
        moreInGenreSectionExpandedConstraints = [
            moreInGenreIntroLabel.topAnchor.constraint(equalTo: moreInGenreSectionContainerView.topAnchor),
            moreInGenreIntroLabel.leadingAnchor.constraint(equalTo: moreInGenreSectionContainerView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            moreInGenreIntroLabel.trailingAnchor.constraint(equalTo: moreInGenreSectionContainerView.trailingAnchor, constant: -UIConstants.shared.standardMargin),

            moreInGenreCollectionView.topAnchor.constraint(equalTo: moreInGenreIntroLabel.bottomAnchor, constant: 12),
            moreInGenreCollectionView.leadingAnchor.constraint(equalTo: moreInGenreSectionContainerView.leadingAnchor),
            moreInGenreCollectionView.trailingAnchor.constraint(equalTo: moreInGenreSectionContainerView.trailingAnchor),
            moreInGenreCollectionView.heightAnchor.constraint(equalToConstant: ShortStoryCVC.Layout.cardHeight),
            moreInGenreCollectionView.bottomAnchor.constraint(equalTo: moreInGenreSectionContainerView.bottomAnchor)
        ]

        NSLayoutConstraint.activate([
            topConstraint,
            moreInGenreSectionContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            moreInGenreSectionContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    func setupMoreInGenreIntroLabel() {
        guard let bookInternal = contentMetadata as? CDBookInternal else { return }
        let genreName = bookInternal.genre.displayString

        moreInGenreIntroLabel.text = "More in \(genreName)"
        moreInGenreIntroLabel.textColor = Colours.textPrimary
        moreInGenreIntroLabel.font = Fonts.semiBold19
        moreInGenreIntroLabel.numberOfLines = 0
        moreInGenreIntroLabel.lineBreakMode = .byWordWrapping

        moreInGenreSectionContainerView.addSubviewForConstraints(moreInGenreIntroLabel)
    }

    func setupMoreInGenreCollectionView() {
        moreInGenreCollectionView.register(ShortStoryCVC.self, forCellWithReuseIdentifier: "ShortStoryCVC")
        moreInGenreCollectionView.delegate = self
        moreInGenreCollectionView.dataSource = self

        moreInGenreSectionContainerView.addSubviewForConstraints(moreInGenreCollectionView)
    }

    func loadBookDetailSectionsIfNeeded() {
        guard
            !hasStartedBookDetailSectionsLoad,
            let bookInternal = contentMetadata as? CDBookInternal else {
            return
        }

        hasStartedBookDetailSectionsLoad = true
        let currentBookUUID = bookInternal.contentUUID
        let currentGenre = bookInternal.genre

        CoreDataBookInternalManager.shared.getAllAsync { [weak self] stories in
            guard let self else { return }

            self.visibleBookInternalStories = stories
            self.refreshTagsSectionIfNeeded()
            self.updateRelatedStories(from: stories, currentBookUUID: currentBookUUID, currentGenre: currentGenre)
        }
    }

    func updateRelatedStories(from visibleBooks: [CDBookInternal],
                              currentBookUUID: String,
                              currentGenre: BookInternalGenre) {
        guard moreInGenreSectionContainerView.superview != nil else { return }

        var excludedUUIDs = ReadingUserDefaults.bookUUIDsWithProgress()
        if let completedUUIDs = AccountManager.shared.user?.completedBookInternalUUIDs {
            excludedUUIDs.formUnion(completedUUIDs)
        }
        excludedUUIDs.insert(currentBookUUID)

        relatedStories = Array(
            visibleBooks
                .filter {
                    $0.contentUUID != currentBookUUID &&
                    $0.genre == currentGenre &&
                    !excludedUUIDs.contains($0.contentUUID) &&
                    $0.isAvailableToUser
                }
                .shuffled()
                .prefix(20)
        )

        moreInGenreCollectionView.reloadData()
        updateMoreInGenreSectionVisibility(hasItems: !relatedStories.isEmpty, animated: true)
    }

    func updateMoreInGenreSectionVisibility(hasItems: Bool, animated: Bool) {
        moreInGenreSectionContainerView.isHidden = !hasItems
        moreInGenreIntroLabel.isHidden = !hasItems
        moreInGenreCollectionView.isHidden = !hasItems
        moreInGenreSectionTopConstraint?.constant = hasItems ? UIConstants.shared.standardMargin : 0

        if hasItems {
            moreInGenreSectionCollapsedHeightConstraint?.isActive = false
            NSLayoutConstraint.activate(moreInGenreSectionExpandedConstraints)
        } else {
            NSLayoutConstraint.deactivate(moreInGenreSectionExpandedConstraints)
            moreInGenreSectionCollapsedHeightConstraint?.isActive = true
        }

        guard animated else { return }
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
}

private extension BookDetailVC {
    func setupBookshelvesSection(topElement: UIView) -> UIView {
        setupBookshelvesIntroLabel(topElement: topElement)
        setupBookshelvesLabel()
        setupBookshelvesSplitter()

        return storyBookshelvesSplitter
    }

    func setupBookshelvesIntroLabel(topElement: UIView) {
        storyBookshelvesIntroLabel.text = "Collections"
        storyBookshelvesIntroLabel.textColor = Colours.textPrimary
        storyBookshelvesIntroLabel.font = Fonts.semiBold19
        storyBookshelvesIntroLabel.numberOfLines = 0
        storyBookshelvesIntroLabel.lineBreakMode = .byWordWrapping

        contentView.addSubviewForConstraints(storyBookshelvesIntroLabel)
        NSLayoutConstraint.activate([
            storyBookshelvesIntroLabel.topAnchor.constraint(equalTo: topElement.bottomAnchor, constant: UIConstants.shared.standardMargin),
            storyBookshelvesIntroLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            storyBookshelvesIntroLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin)
        ])
    }
    func setupBookshelvesLabel() {
        storyBookshelvesLabel.textColor = Colours.textSecondary
        storyBookshelvesLabel.font = Fonts.medium15
        storyBookshelvesLabel.numberOfLines = 0
        storyBookshelvesLabel.lineBreakMode = .byWordWrapping
        
        storyBookshelvesLabel.clipsToBounds = true
        
        contentView.addSubviewForConstraints(storyBookshelvesLabel)
        NSLayoutConstraint.activate([
            storyBookshelvesLabel.topAnchor.constraint(equalTo: storyBookshelvesIntroLabel.bottomAnchor, constant: 12),
            storyBookshelvesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            storyBookshelvesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin)
        ])
        
        storyBookshelvesLabel.contentMode = .topLeft
    }
    
    func setupBookshelvesSplitter() {
        contentView.addSubviewForConstraints(storyBookshelvesSplitter)
        NSLayoutConstraint.activate([
            storyBookshelvesSplitter.topAnchor.constraint(equalTo: storyBookshelvesLabel.bottomAnchor, constant: UIConstants.shared.standardMargin),
            storyBookshelvesSplitter.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            storyBookshelvesSplitter.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            storyBookshelvesSplitter.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
}

private extension BookDetailVC {
    func setupCriticsReviewsSection(topElement: UIView) -> UIView {
        setupCriticsReviewsIntroLabel(topElement: topElement)
        setupCriticsReviewsLabel()
        setupGetCriticsReviewsButton()

        return criticsReviewsLabel
    }
    func setupCriticsReviewsIntroLabel(topElement: UIView) {
        criticsReviewsIntroLabel.text = "Critics Reviews"
        criticsReviewsIntroLabel.textColor = Colours.textPrimary
        criticsReviewsIntroLabel.font = Fonts.semiBold19
        criticsReviewsIntroLabel.numberOfLines = 0
        criticsReviewsIntroLabel.lineBreakMode = .byWordWrapping
        
        contentView.addSubviewForConstraints(criticsReviewsIntroLabel)
        NSLayoutConstraint.activate([
            criticsReviewsIntroLabel.topAnchor.constraint(equalTo: topElement.bottomAnchor, constant: UIConstants.shared.standardMargin),
            criticsReviewsIntroLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            criticsReviewsIntroLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin)
        ])
    }
    func setupCriticsReviewsLabel() {
        criticsReviewsLabel.textColor = Colours.textSecondary
        criticsReviewsLabel.font = Fonts.medium15
        criticsReviewsLabel.numberOfLines = 0
        criticsReviewsLabel.lineBreakMode = .byWordWrapping
        
        criticsReviewsLabel.clipsToBounds = true
        
        contentView.addSubviewForConstraints(criticsReviewsLabel)
        NSLayoutConstraint.activate([
            criticsReviewsLabel.topAnchor.constraint(equalTo: criticsReviewsIntroLabel.bottomAnchor, constant: 12),
            criticsReviewsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            criticsReviewsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            criticsReviewsLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            criticsReviewsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UIConstants.shared.standardMargin)
        ])
        
        criticsReviewsLabel.contentMode = .topLeft
    }
    
    func setupGetCriticsReviewsButton() {
        contentView.addSubviewForConstraints(getCriticsReviewsButton)
        NSLayoutConstraint.activate([
            getCriticsReviewsButton.centerYAnchor.constraint(equalTo: criticsReviewsLabel.centerYAnchor),
            getCriticsReviewsButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            getCriticsReviewsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            getCriticsReviewsButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.midButtonHeight)
        ])
        getCriticsReviewsButton.addTarget(self, action: #selector(getCriticsReviewsButtonTapped), for: .touchUpInside)
        
        getCriticsReviewsButton.layer.cornerRadius = UIConstants.shared.midButtonCornerRadius
    }
    
    @objc func getCriticsReviewsButtonTapped() {
        criticsReviewsLabel.text = ""
    }
    
    func showCriticsReviewsLoadingIndicator(show: Bool) {
        if show {
            [getCriticsReviewsButton].forEach { $0.isHidden = true }
            guard criticsReviewsLoadingIndicatorView == nil else { return }
            criticsReviewsLoadingIndicatorView = NVActivityIndicatorView(frame: CGRect.zero, type: NVActivityIndicatorType.circleStrokeSpin, color: Colours.textPrimary, padding: 0)
            guard let indicatorView = criticsReviewsLoadingIndicatorView else {return}
            
            indicatorView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(indicatorView)
            NSLayoutConstraint.activate([
                indicatorView.centerYAnchor.constraint(equalTo: getCriticsReviewsButton.centerYAnchor),
                indicatorView.widthAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight),
                indicatorView.heightAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight),
                indicatorView.centerXAnchor.constraint(equalTo: getCriticsReviewsButton.centerXAnchor)
            ])
            indicatorView.startAnimating()
        } else {
            criticsReviewsLoadingIndicatorView?.stopAnimating()
            criticsReviewsLoadingIndicatorView?.removeFromSuperview()
            criticsReviewsLoadingIndicatorView = nil
        }
    }
    
    func showGenerateCriticsReviewsAlert() {
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] cancelTapped in
            guard let self = self else { return }
            DispatchQueue.main.async {
                [self.getCriticsReviewsButton].forEach { $0.isHidden = false }
            }
        }
        let retryAction = UIAlertAction(title: "Retry", style: .default) { [weak self] retryTapped in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.getCriticsReviewsButtonTapped()
            }
        }
        let alertController = UIAlertController(title: "Network Error", message: "Please ensure you have an active internet connection and try again.", preferredStyle: .alert)
        alertController.addAction(cancelAction)
        alertController.addAction(retryAction)
        present(alertController, animated: true, completion: nil)
    }
    
    /// Sets up bottom constraint for the last element when critics reviews section is not shown
    private func setupBottomConstraint(for element: UIView) {
        NSLayoutConstraint.activate([
            element.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UIConstants.shared.standardMargin)
        ])
    }
}

private extension BookDetailVC {
    @objc func readNowTapped() {
        
        AnalyticsManager.shared.trackStartReadingTapped()
        
        guard let bookInternal = contentMetadata as? CDBookInternal else { return }
        presentReadingModePaywall(bookInternal: bookInternal) { [weak self] in
            self?.openReadingAfterAccessGranted(bookInternal: bookInternal)
        }
    }

    func openReadingAfterAccessGranted(bookInternal: CDBookInternal) {
        if let bookInternalContent = APIBookInternalContentManager.getBookInternalContent(bookUUID: bookInternal.contentUUID) {
            showReadingVC(content: bookInternalContent)
        } else if Reachability.isConnectedToNetwork() {
            showBookInternal(bookInternal: bookInternal)
        } else {
            showOfflinePopup()
        }
    }
    func showOfflinePopup() {
        let alert = UIAlertController(title: "Network Offline", message: "Please check your connection and try again.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Retry", style: .default , handler: { [weak self] action in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.readNowTapped()
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    func showBookInternal(bookInternal: CDBookInternal) {
        showDownloadLoadingIndicator(show: true)
        downloadingLabel.text = "Loading..."
        
        // Check cache or download
        if let content = APIBookInternalContentManager.getBookInternalContent(bookUUID: bookInternal.contentUUID) {
            if Reachability.isConnectedToNetwork() {
                self.showReadingVC(content: content)
            } else {
                self.showOfflinePopup()
            }
        } else {
            APIBookInternalContentManager.downloadBookInternal(bookUUID: bookInternal.contentUUID, isTemporary: true, progress: { [weak self] progress in
                guard let self = self, let progress = progress else { return }
                DispatchQueue.main.async {
                    self.updateProgress(progress)
                }
            }) { [weak self] bookInternalContent, error in
                guard let self = self else { return }
                
                guard error == nil, let bookInternalContent = bookInternalContent else {
                    DispatchQueue.main.async {
                        self.showBookInternalContentFetchAlert()
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    
                    self.showReadingVC(content: bookInternalContent)
                }
            }
        }
    }
    
    func showBookInternalContentFetchAlert() {
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.showDownloadLoadingIndicator(show: false)
            }
        }
        let retryAction = UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.readNowTapped()
            }
        }
        let alertController = UIAlertController(title: "Network Error", message: "Please ensure you have an active internet connection and try again.", preferredStyle: .alert)
        alertController.addAction(cancelAction)
        alertController.addAction(retryAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension BookDetailVC {
    func displayPaywall(placement: PaywallPlacement) {
        let handler = PaywallPresentationHandler()
        handler.onPresent { _ in
            DispatchQueue.main.async {
                AnalyticsManager.shared.trackPaywallViewedForPlacement(placement)
            }
        }
        handler.onDismiss { [weak self] _, result in
            guard let self else { return }
            DispatchQueue.main.async {
                switch result {
                case .declined:
                    print("No purchased occurred.")
                    if placement == .downloadOfflineAudio {
                        self.pendingAudiobookOfflineStartAfterSubscription = false
                    }
                case .purchased(let product):
                    print("Purchased \(product.productIdentifier)")
                    if placement == .downloadOfflineAudio {
                        AnalyticsManager.shared.trackPaywallUserSubscribedForDLPlacement()
                    }
                    AnalyticsManager.shared.trackPaywallUserSubscribed(placement: placement, cdBookInternal: self.contentMetadata as? CDBookInternal)
                    self.showSubscribeSuccessPopup()
                    self.handleSubscribed(placement: placement)
                case .restored:
                    print("Restored purchases.")
                    AnalyticsManager.shared.trackPaywallRestorePurchasesSuccess()
                    self.handleSubscribed(placement: placement)
                }
            }
        }
        Superwall.shared.register(placement: placement.rawValue, params: nil, handler: handler)
    }
    func handleSubscribed(placement: PaywallPlacement) {
        if placement == .downloadOfflineAudio {
            if pendingAudiobookOfflineStartAfterSubscription {
                pendingAudiobookOfflineStartAfterSubscription = false
                startAudiobookOfflinePlayback(playAfterDownload: true)
            } else if let bookInternal = contentMetadata as? CDBookInternal,
                      bookInternal.cachedAudio?.isTemporaryDownload == true {
                CoreDataBookInternalAudioManager.shared.promoteTemporaryDownload(bookUUID: bookInternal.contentUUID)
            }
        }
        updateDownloadElements()
        updateAdditionalInfoView()
    }
}

extension BookDetailVC {
    func showReadingVC(content: ReadableContent) {
        navigateToReadingVC(content: content)
    }

    func navigateToReadingVC(content: ReadableContent) {
        guard let cdBookInternal = contentMetadata as? CDBookInternal else { return }
        if AccountManager.shared.userHasCompletedBookInternalWithUUID(contentMetadata.contentUUID) {
            AccountManager.shared.handleCompletedBookInternal(cdBookInternal, completed: false, completion: {})
            ReadingUserDefaults.clearOffsetForBookWithUUID(contentMetadata.contentUUID)
            AudioPositionManager.shared.clearPosition(for: contentMetadata.contentUUID)
        }
        let readingModeVC = ReadingVC(metadata: contentMetadata, content: content)
        navigationController?.pushViewController(readingModeVC, animated: true)
    }

    @objc private func genrePillTapped() {
        presentGenreResults()
    }

    private func presentGenreResults() {
        guard let cdBookInternal = contentMetadata as? CDBookInternal else { return }
        let genreResultsVC = GenreResultsVC(genre: cdBookInternal.genre, excludedBookUUID: cdBookInternal.contentUUID)
        genreResultsVC.delegate = self
        let navController = UINavigationController(rootViewController: genreResultsVC)
        present(navController, animated: true)
    }
}

extension BookDetailVC: GenreResultsVCDelegate {
    func genreResultsVC(_ vc: GenreResultsVC, didSelectBook book: CDBookInternal, sourceItems: [CDBookInternal]) {
        dismiss(animated: true) { [weak self] in
            guard let self else { return }
            let contentOverviewVC = BookDetailVC(contentMetadata: book)
            contentOverviewVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(contentOverviewVC, animated: true)
        }
    }
}

extension BookDetailVC: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer === genrePillTapGestureRecognizer else { return true }
        return touch.view?.isDescendant(of: ratingChipView) != true
    }
}

extension BookDetailVC {
    func updateProgress(_ progress: Double) {
        downloadProgressView.progress = Float(progress)
        downloadProgressView.progressTintColor = Colours.orangePrimary
    }
}

private struct OldBookDetailTagPillItem {
    let title: String
    let tag: String
}

private final class OldTagPillButton: UIButton {
    let tagValue: String

    init(title: String, tagValue: String) {
        self.tagValue = tagValue
        super.init(frame: .zero)
        layer.cornerRadius = 11
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = Colours.inputBorder.cgColor
        backgroundColor = Colours.surfaceCard
        setTitle(title, for: .normal)
        setTitleColor(UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary), for: .normal)
        titleLabel?.font = Fonts.medium13
        titleLabel?.adjustsFontSizeToFitWidth = false
        titleLabel?.numberOfLines = 1
        titleLabel?.lineBreakMode = .byClipping
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        heightAnchor.constraint(equalToConstant: 22).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func width(for title: String) -> CGFloat {
        let textWidth = (title as NSString).size(withAttributes: [.font: Fonts.medium13]).width
        return ceil(textWidth) + 20
    }
}

private final class OldTagPillWrapView: UIView {
    private let stackView = UIStackView()
    private var items: [OldBookDetailTagPillItem] = []
    private weak var target: AnyObject?
    private var action: Selector?
    private var lastLaidOutWidth: CGFloat = 0
    private let horizontalPadding = UIConstants.shared.standardMargin

    override init(frame: CGRect) {
        super.init(frame: frame)
        stackView.axis = .vertical
        stackView.spacing = 6
        stackView.alignment = .fill
        addSubviewForConstraints(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard abs(bounds.width - lastLaidOutWidth) > 1 else { return }
        lastLaidOutWidth = bounds.width
        rebuildRows()
    }

    func configure(items: [OldBookDetailTagPillItem], target: AnyObject?, action: Selector) {
        self.items = items
        self.target = target
        self.action = action
        rebuildRows()
    }

    private func rebuildRows() {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        guard !items.isEmpty else { return }

        let resolvedWidth = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width - (horizontalPadding * 2)
        let availableWidth = max(120, resolvedWidth)
        var currentRow = makeRow()
        var currentWidth: CGFloat = 0

        for item in items {
            let button = OldTagPillButton(title: item.title, tagValue: item.tag)
            if let target, let action {
                button.addTarget(target, action: action, for: .touchUpInside)
            }

            let buttonWidth = OldTagPillButton.width(for: item.title)
            let proposedWidth = currentWidth == 0 ? buttonWidth : currentWidth + 6 + buttonWidth

            if proposedWidth > availableWidth && !currentRow.arrangedSubviews.isEmpty {
                addSpacer(to: currentRow)
                stackView.addArrangedSubview(currentRow)
                currentRow = makeRow()
                currentWidth = 0
            }

            currentRow.addArrangedSubview(button)
            currentWidth = currentWidth == 0 ? buttonWidth : currentWidth + 6 + buttonWidth
        }

        addSpacer(to: currentRow)
        stackView.addArrangedSubview(currentRow)
    }

    private func makeRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 6
        row.alignment = .fill
        row.distribution = .fill
        return row
    }

    private func addSpacer(to row: UIStackView) {
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        row.addArrangedSubview(spacer)
    }
}

private final class OldBookDetailReviewCardCell: UICollectionViewCell {
    static let reuseIdentifier = "OldBookDetailReviewCardCell"
    static let maximumHeight: CGFloat = 186

    private enum Layout {
        static let topInset: CGFloat = 18
        static let horizontalInset: CGFloat = 18
        static let starsHeight: CGFloat = 12
        static let starsToMetaSpacing: CGFloat = 10
        static let avatarHeight: CGFloat = 32
        static let metaToCommentSpacing: CGFloat = 12
        static let bottomInset: CGFloat = 14
        static let commentMaxLines: CGFloat = 5
    }

    private let cardShadowView = UIView()
    private let cardView = UIView()
    private let starsView = CosmosView()
    private let avatarImageView = UIImageView()
    private let metaLabel = UILabel()
    private let commentLabel = UILabel()
    private var currentReviewerDisplayName: String?
    private var currentProfileImageURLString: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = false
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        cardShadowView.layer.shadowPath = UIBezierPath(
            roundedRect: cardShadowView.bounds,
            cornerRadius: cardView.layer.cornerRadius
        ).cgPath
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        commentLabel.text = nil
        metaLabel.text = nil
        starsView.rating = 0
        currentReviewerDisplayName = nil
        currentProfileImageURLString = nil
        avatarImageView.image = ReviewerAvatarPlaceholder.image(
            for: nil,
            diameter: Layout.avatarHeight,
            traitCollection: traitCollection
        )
        avatarImageView.kf.cancelDownloadTask()
    }

    func configure(review: APIBookReview, reviewerName: String, reviewDateText: String) {
        currentReviewerDisplayName = review.displayName
        currentProfileImageURLString = review.profileImageURLString
        metaLabel.text = "\(reviewerName) · \(reviewDateText)"
        commentLabel.text = review.comment?.trimmingCharacters(in: .whitespacesAndNewlines)
        starsView.rating = review.rating
        let placeholderImage = ReviewerAvatarPlaceholder.image(
            for: review.displayName,
            diameter: Layout.avatarHeight,
            traitCollection: traitCollection
        )
        if let urlString = review.profileImageURLString, let imageURL = URL(string: urlString) {
            avatarImageView.kf.indicatorType = .activity
            avatarImageView.kf.setImage(
                with: imageURL,
                placeholder: placeholderImage,
                options: [.transition(.fade(0.2))]
            )
        } else {
            avatarImageView.image = placeholderImage
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard
            traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection),
            currentProfileImageURLString == nil
        else { return }

        avatarImageView.image = ReviewerAvatarPlaceholder.image(
            for: currentReviewerDisplayName,
            diameter: Layout.avatarHeight,
            traitCollection: traitCollection
        )
    }

    static func preferredHeight(for review: APIBookReview, width: CGFloat) -> CGFloat {
        let trimmedComment = review.comment?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let fixedHeight = Layout.topInset
            + Layout.starsHeight
            + Layout.starsToMetaSpacing
            + Layout.avatarHeight
            + Layout.metaToCommentSpacing
            + Layout.bottomInset

        guard !trimmedComment.isEmpty else {
            return min(maximumHeight, ceil(fixedHeight))
        }

        let commentWidth = max(0, width - (Layout.horizontalInset * 2))
        let maxCommentHeight = max(0, maximumHeight - fixedHeight)
        let maxVisibleCommentHeight = ceil(Fonts.medium15.lineHeight * Layout.commentMaxLines)
        let measuredCommentHeight = NSString(string: trimmedComment).boundingRect(
            with: CGSize(width: commentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: Fonts.medium15],
            context: nil
        ).height

        let commentHeight = min(maxCommentHeight, maxVisibleCommentHeight, ceil(measuredCommentHeight))
        return min(maximumHeight, ceil(fixedHeight + commentHeight))
    }

    private func setupViews() {
        cardShadowView.backgroundColor = .clear
        cardShadowView.layer.shadowColor = Colours.shadowBase.cgColor
        cardShadowView.layer.shadowOpacity = 0.08
        cardShadowView.layer.shadowRadius = 14
        cardShadowView.layer.shadowOffset = CGSize(width: 0, height: 6)
        cardShadowView.layer.masksToBounds = false
        contentView.addSubviewForConstraints(cardShadowView)

        cardView.backgroundColor = Colours.surfaceCard
        cardView.layer.cornerRadius = 20
        cardView.layer.cornerCurve = .continuous
        cardView.layer.masksToBounds = true
        cardShadowView.addSubviewForConstraints(cardView)

        starsView.settings.updateOnTouch = false
        starsView.settings.fillMode = .precise
        starsView.settings.starSize = 12
        starsView.settings.starMargin = 2
        starsView.settings.emptyBorderWidth = 1
        starsView.settings.filledColor = Colours.textPrimary
        starsView.settings.filledBorderColor = Colours.textPrimary
        starsView.settings.emptyBorderColor = Colours.veryLightUI

        metaLabel.font = Fonts.medium14
        metaLabel.textColor = Colours.textSecondary
        metaLabel.numberOfLines = 1

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 16
        avatarImageView.layer.masksToBounds = true
        avatarImageView.image = ReviewerAvatarPlaceholder.image(
            for: nil,
            diameter: Layout.avatarHeight,
            traitCollection: traitCollection
        )

        commentLabel.font = Fonts.medium14
        commentLabel.textColor = Colours.textSecondary
        commentLabel.numberOfLines = 5
        commentLabel.lineBreakMode = .byTruncatingTail

        [starsView, avatarImageView, metaLabel, commentLabel].forEach {
            cardView.addSubviewForConstraints($0)
        }

        NSLayoutConstraint.activate([
            cardShadowView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardShadowView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardShadowView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardShadowView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            cardView.topAnchor.constraint(equalTo: cardShadowView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: cardShadowView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: cardShadowView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: cardShadowView.bottomAnchor),

            starsView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 18),
            starsView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),

            avatarImageView.topAnchor.constraint(equalTo: starsView.bottomAnchor, constant: 10),
            avatarImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            avatarImageView.widthAnchor.constraint(equalToConstant: 32),
            avatarImageView.heightAnchor.constraint(equalToConstant: 32),

            metaLabel.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            metaLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 10),
            metaLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),

            commentLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 12),
            commentLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            commentLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),
            commentLabel.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -14)
        ])
    }
}

extension BookDetailVC {
    func showDownloadLoadingIndicator(show: Bool) {
        if show {
            readNowButton.isHidden = true
            [downloadingLabel, downloadProgressView].forEach { $0.isHidden = false }
        } else {
            [downloadingLabel, downloadProgressView].forEach { $0.isHidden = true }
            readNowButton.isHidden = false
        }
    }
}

private extension BookDetailVC {
    func showShareSheetWithText(_ text: String) {
        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popoverController.sourceView = self.view
            popoverController.permittedArrowDirections = UIPopoverArrowDirection.any
        }

        activityViewController.completionWithItemsHandler = { ( activityType, completed: Bool, returnedItems:[Any]?, error: Error?) in
            if completed && activityType != nil {
                // User shared
                SKReviewManager.requestReview(venue: .sharedBook)
            }
        }
        self.present(activityViewController, animated: true, completion: nil)
    }
}

extension BookDetailVC {
    @objc private func tappedSave() {
        handleSave()
    }
    
    @objc private func tappedDownload() {
        guard !isAudioDownloadInProgress else {
            showAudioDownloadInProgressAlert()
            return
        }

        if contentMetadata.hasDownloadedAudio {
            showDeletePopup()
        } else if AccountManager.shared.userIsSubscribed {
            handleDownload()
        } else {
            // Permanent offline downloads are a subscriber feature
            displayPaywall(placement: .downloadOfflineAudio)
        }
    }
}

private extension BookDetailVC {
    func handleSave() {
        handleSaveBookInternal()
    }
}

extension BookDetailVC {
    func handleSaveBook() {
        let storyUUID = contentMetadata.contentUUID
        let isSavedAtStart = AccountManager.shared.user?.savedStoryUUIDs.contains(storyUUID) ?? false
        
        if isSavedAtStart {
            AccountManager.shared.user?.savedStoryUUIDs.removeAll(where: { $0 == storyUUID })
        } else {
            AccountManager.shared.user?.savedStoryUUIDs.append(storyUUID)
            
            let newSavedCount = AccountManager.shared.user?.totalSavedBooksCount ?? 0
            let requiredLaunchCount = RCValues.shared.int(forKey: .requiredLaunchCountForSKReview) ?? 2
            if newSavedCount >= 3 && SKReviewManager.launchCount >= requiredLaunchCount {
                SKReviewManager.requestReview(venue: .savedBook)
            }
        }
        
        updateSaveElements()
        
        AccountManager.shared.handleSaveStoryWithUUID(storyUUID,
                                                      save: !isSavedAtStart,
                                                      saveVenue: .story) { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.updateSaveElements()
            }
        }
    }
    func handleSaveBookInternal() {
        guard let cdBookInternal = contentMetadata as? CDBookInternal else { return }
        let storyUUID = contentMetadata.contentUUID
        let isSavedAtStart = AccountManager.shared.user?.savedBookInternalUUIDs.contains(storyUUID) ?? false
        
        if isSavedAtStart {
            AccountManager.shared.user?.savedBookInternalUUIDs.removeAll(where: { $0 == storyUUID })
        } else {
            AccountManager.shared.user?.savedBookInternalUUIDs.append(storyUUID)
            
            let newSavedCount = AccountManager.shared.user?.totalSavedBooksCount ?? 0
            let requiredLaunchCount = RCValues.shared.int(forKey: .requiredLaunchCountForSKReview) ?? 2
            if newSavedCount >= 3 && SKReviewManager.launchCount >= requiredLaunchCount {
                SKReviewManager.requestReview(venue: .savedBook)
            }
        }
        
        updateSaveElements()
        
        AccountManager.shared.handleSaveBookInternal(cdBookInternal,
                                                     save: !isSavedAtStart,
                                                     saveVenue: .story) { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.updateSaveElements()

                // Trigger email opt-in prompt on successful save (not unsave)
                if !isSavedAtStart {
                    EmailOptInPromptManager.shared.handleTrigger(
                        .bookSaved,
                        genre: cdBookInternal.genre,
                        from: self
                    )
                }
            }
        }
    }
}

// MARK: - Download Functionality
private extension BookDetailVC {
    func beginAudioDownloadUI() {
        guard !isAudioDownloadInProgress else { return }
        isAudioDownloadInProgress = true
        displayedAudioDownloadPercentage = nil
        downloadButton.startProgressIndicator()
        downloadButton.setTitle("0%")
        setPrimaryCTAButtonTitle("Downloading...")
    }

    func updateAudioDownloadUI(progress: Float) {
        if !isAudioDownloadInProgress {
            beginAudioDownloadUI()
        }

        let percentage = max(1, min(99, Int(progress * 100)))
        guard displayedAudioDownloadPercentage != percentage else { return }

        displayedAudioDownloadPercentage = percentage
        downloadButton.updateProgress(progress)
        downloadButton.setTitle("\(percentage)%")
        setPrimaryCTAButtonTitle("Downloading \(percentage)%")
    }

    func endAudioDownloadUI() {
        guard isAudioDownloadInProgress else { return }
        isAudioDownloadInProgress = false
        displayedAudioDownloadPercentage = nil
        downloadButton.stopProgressIndicator()
        updateDownloadElements()
        updatePrimaryCTAButtonTitle()
    }

    func handleDownload() {
        HapticFeedbackHelper.shared.triggerLightImpactFeedback()
        beginAudioDownloadUI()
        
        APIBookInternalAudioManager.shared.downloadAudiobook(for: contentMetadata, progressHandler: { [weak self] progress in
            DispatchQueue.main.async {
                self?.updateAudioDownloadUI(progress: progress)
            }
        }) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.endAudioDownloadUI()

                switch result {
                case .downloaded, .alreadyDownloaded, .failed:
                    break
                case .quotaExceeded:
                    self.presentListeningQuotaDepletedSheet(for: self.contentMetadata) { [weak self] in
                        self?.handleDownload()
                    }
                case .noAudio:
                    self.showNoAudioAlert()
                }
            }
        }
    }
    
    func showDownloadError() {
        showAudioDownloadError(.storageError, language: .english)
    }
    
    func showDeletePopup() {
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] deleteTapped in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.handleDelete()
            }
        }
        let alertController = UIAlertController(title: "Delete Audiobook", message: "Delete the downloaded audiobook from this device?", preferredStyle: .alert)
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func handleDelete() {
        guard let cdBookInternal = contentMetadata as? CDBookInternal else { return }

        if cdBookInternal.hasDownloadedAudio {
            CoreDataBookInternalAudioManager.shared.deleteBookInternalAudio(bookUUID: cdBookInternal.contentUUID) { [weak self] success in
                DispatchQueue.main.async {
                    if !success {
                        print("⚠️ Failed to delete audio content for book: \(cdBookInternal.contentUUID)")
                    }

                    // Update UI after audio deletion completes
                    APIBookInternalAudioManager.shared.clearDownloadState(for: cdBookInternal.contentUUID)
                    self?.updateDownloadElements()

                    DownloadTimestampManager.shared.removeAudioTimestamp(uuid: cdBookInternal.contentUUID)
                }
            }
        } else {
            APIBookInternalAudioManager.shared.clearDownloadState(for: cdBookInternal.contentUUID)
            updateDownloadElements()
        }
    }
    
    func showAudioDownloadInProgressAlert() {
        let alert = UIAlertController(
            title: "Download In Progress",
            message: "Your audiobook is currently downloading. Please wait for it to complete.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Date Extension
private extension Date {
    var year: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: self)
    }
}

extension BookDetailVC {
    @objc private func listenNowTapped() {
        guard contentMetadata.hasAnyAudiobook else {
            return
        }

        // Check if a download is already in progress
        if isAudioDownloadInProgress {
            showAudioDownloadInProgressAlert()
            return
        }

        handleDownloadAudio()
    }
    
    private func handleDownloadAudio() {
        guard let bookInternal = contentMetadata as? CDBookInternal else {
            showNoAudioAlert()
            return
        }

        // On-device audio (permanent or temporary) always plays - the free quota
        // limits starting new audiobooks, not resuming books already started.
        if bookInternal.cachedAudio != nil {
            playCachedAudio()
        } else if contentMetadata.hasAnyAudiobook {
            if AccountManager.shared.userIsSubscribed {
                downloadAudio(language: .english)
            } else if ListeningQuotaManager.shared.canListen(contentUUID: contentMetadata.contentUUID) {
                showAudiobookStoreOfflineSelection()
            } else {
                presentListeningQuotaDepletedSheet(for: contentMetadata) { [weak self] in
                    self?.downloadAudio(language: .english)
                }
            }
        } else {
            // No audio available
            showNoAudioAlert()
        }
    }

    private func showAudiobookStoreOfflineSelection() {
        let viewController = AudiobookStoreOfflineSelectionVC()
        viewController.tapToDismissEnabled = false
        viewController.panToDismissEnabled = false
        viewController.dismissHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.dismiss(animated: true)
            }
        }
        viewController.downloadHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.dismiss(animated: true) {
                    self.handleAudiobookOfflineSelection()
                }
            }
        }
        viewController.onlineOnlyHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.dismiss(animated: true) {
                    self.handleAudiobookOnlineSelection()
                }
            }
        }
        viewController.preferredSheetSizing = .fill
        present(viewController, animated: true)
    }

    private func handleAudiobookOnlineSelection() {
        guard Reachability.isConnectedToNetwork() else {
            showAudiobookOfflineAlert()
            return
        }

        guard let bookInternal = contentMetadata as? CDBookInternal else {
            showNoAudioAlert()
            return
        }

        if bookInternal.cachedAudio != nil {
            // Already on-device - play through the standard quota-checked path
            handleDownloadAudio()
        } else if contentMetadata.hasAnyAudiobook {
            downloadAudio(language: .english, isTemporary: true, playAfterDownload: true)
        } else {
            showNoAudioAlert()
        }
    }

    private func handleAudiobookOfflineSelection() {
        if AccountManager.shared.userIsSubscribed {
            startAudiobookOfflinePlayback(playAfterDownload: true)
        } else {
            pendingAudiobookOfflineStartAfterSubscription = true
            displayPaywall(placement: .downloadOfflineAudio)
        }
    }

    private func startAudiobookOfflinePlayback(playAfterDownload: Bool) {
        guard let bookInternal = contentMetadata as? CDBookInternal else {
            showNoAudioAlert()
            return
        }

        if let audioData = bookInternal.cachedAudio {
            if audioData.isTemporaryDownload {
                CoreDataBookInternalAudioManager.shared.promoteTemporaryDownload(bookUUID: bookInternal.contentUUID)
                updateDownloadElements()
            }
            playAudio(audioData, bookInternal: bookInternal)
        } else if contentMetadata.hasAnyAudiobook {
            downloadAudio(language: .english, playAfterDownload: playAfterDownload)
        } else {
            showNoAudioAlert()
        }
    }

    private func playCachedAudio() {
        guard
            let bookInternal = contentMetadata as? CDBookInternal,
            let audioData = bookInternal.cachedAudio else {
            showNoAudioAlert()
            return
        }

        if AccountManager.shared.userIsSubscribed, audioData.isTemporaryDownload {
            CoreDataBookInternalAudioManager.shared.promoteTemporaryDownload(bookUUID: bookInternal.contentUUID)
            updateDownloadElements()
        }
        playAudio(audioData, bookInternal: bookInternal)
    }

    private func playAudio(_ audioData: CDBookInternalAudio, bookInternal: CDBookInternal) {
        if AccountManager.shared.userHasCompletedBookInternalWithUUID(contentMetadata.contentUUID) {
            AccountManager.shared.handleCompletedBookInternal(bookInternal, completed: false, completion: {})
            AudioPositionManager.shared.clearPosition(for: contentMetadata.contentUUID)
            ReadingUserDefaults.clearOffsetForBookWithUUID(contentMetadata.contentUUID)
        }

        let audiobookPlayerVC = AudiobookPlayerVC(bookInternal: bookInternal, audioData: audioData)
        navigationController?.pushViewController(audiobookPlayerVC, animated: true)
    }

    private func downloadAudio(language: AudiobookLanguage, isTemporary: Bool = false, playAfterDownload: Bool = false) {
        beginAudioDownloadUI()

        APIBookInternalAudioManager.shared.downloadAudiobook(
            for: contentMetadata,
            language: language,
            isTemporary: isTemporary,
            progressHandler: { [weak self] progress in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.updateAudioDownloadUI(progress: progress)
                }
            }
        ) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.endAudioDownloadUI()

                switch result {
                case .downloaded(let audioData):
                    if playAfterDownload, let bookInternal = self.contentMetadata as? CDBookInternal {
                        self.playAudio(audioData, bookInternal: bookInternal)
                    }
                case .alreadyDownloaded:
                    if playAfterDownload {
                        self.playCachedAudio()
                    }
                case .failed:
                    break
                case .quotaExceeded:
                    self.presentListeningQuotaDepletedSheet(for: self.contentMetadata) { [weak self] in
                        // The user has just subscribed, so any retry is a permanent download.
                        self?.downloadAudio(language: language, playAfterDownload: playAfterDownload)
                    }
                case .noAudio:
                    self.showNoAudioAlert()
                }
            }
        }
    }

    private func showAudiobookOfflineAlert() {
        let alertController = UIAlertController(
            title: "Network Offline",
            message: "Please check your connection and try again. To listen offline, please join Audiobooks+.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }

    private func showNoAudioAlert() {
        let alertController = UIAlertController(
            title: "No Audio Available",
            message: "This book doesn't have an audiobook version available.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }

    private func showAudioDownloadSuccess() {
        let alertController = UIAlertController(
            title: "Download Complete",
            message: "Audiobook has been downloaded and is ready to play.",
            preferredStyle: .alert
        )

        // Preferred action - Listen now
        let listenNowAction = UIAlertAction(title: "Listen now", style: .default) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.playCachedAudio()
            }
        }
        alertController.addAction(listenNowAction)
        alertController.preferredAction = listenNowAction

        // Secondary action - Later
        let laterAction = UIAlertAction(title: "Later", style: .cancel)
        alertController.addAction(laterAction)

        present(alertController, animated: true)
    }

    private func showAudioDownloadError(_ error: APIBookInternalAudioManager.AudioDownloadError, language: AudiobookLanguage) {
        let alertController = UIAlertController(
            title: "Download Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.downloadAudio(language: language)
            }
        })

        present(alertController, animated: true)
    }

    private func deleteDownloadedAudio() {
        guard let bookInternal = contentMetadata as? CDBookInternal else { return }

        let alertController = UIAlertController(
            title: "Delete Audiobook",
            message: "Are you sure you want to delete the downloaded audiobook? You can re-download it later.",
            preferredStyle: .alert
        )

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.performAudioDeletion(for: bookInternal)
        })

        present(alertController, animated: true)
    }

    private func performAudioDeletion(for bookInternal: CDBookInternal) {
        CoreDataBookInternalAudioManager.shared.deleteBookInternalAudio(
            bookUUID: bookInternal.contentUUID
        ) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.showAudioDeletionSuccess()
                } else {
                    self?.showAudioDeletionError()
                }
            }
        }
    }

    private func showAudioDeletionSuccess() {
        let alertController = UIAlertController(
            title: "Audiobook Deleted",
            message: "The downloaded audiobook has been removed from your device.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }

    private func showAudioDeletionError() {
        let alertController = UIAlertController(
            title: "Deletion Failed",
            message: "Unable to delete the audiobook. Please try again.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
}

// MARK: - More in Genre Collection View
extension BookDetailVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === moreInGenreCollectionView {
            return relatedStories.count
        } else if collectionView === writtenReviewsCollectionView {
            return writtenReviews.count
        } else {
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView === moreInGenreCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShortStoryCVC", for: indexPath) as? ShortStoryCVC else {
                return UICollectionViewCell()
            }

            let cdBookInternal = relatedStories[indexPath.item]
            cell.configure(with: cdBookInternal)

            return cell
        }

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OldBookDetailReviewCardCell.reuseIdentifier, for: indexPath) as? OldBookDetailReviewCardCell else {
            return UICollectionViewCell()
        }

        let review = writtenReviews[indexPath.item]
        cell.configure(
            review: review,
            reviewerName: reviewDisplayName(for: review),
            reviewDateText: reviewDateText(for: review.createdDate)
        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView === moreInGenreCollectionView else { return }
        let cdBookInternal = relatedStories[indexPath.item]
        let contentOverviewVC = BookDetailVC(contentMetadata: cdBookInternal)
        navigationController?.pushViewController(contentOverviewVC, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView === moreInGenreCollectionView {
            return CGSize(width: ShortStoryCVC.Layout.coverImageWidth, height: ShortStoryCVC.Layout.cardHeight)
        } else {
            let cardWidth = writtenReviewCardWidth()
            return CGSize(width: cardWidth, height: preferredWrittenReviewsCollectionHeight())
        }
    }

    private func handleSaveForStory(_ story: CDBookInternal) {
        let storyUUID = story.contentUUID
        let isSavedAtStart = AccountManager.shared.user?.savedBookInternalUUIDs.contains(storyUUID) ?? false

        if isSavedAtStart {
            AccountManager.shared.user?.savedBookInternalUUIDs.removeAll(where: { $0 == storyUUID })
        } else {
            AccountManager.shared.user?.savedBookInternalUUIDs.append(storyUUID)
        }

        // Reload the cell to update save button state
        if let index = relatedStories.firstIndex(where: { $0.contentUUID == storyUUID }) {
            let indexPath = IndexPath(item: index, section: 0)
            moreInGenreCollectionView.reloadItems(at: [indexPath])
        }

        AccountManager.shared.handleSaveBookInternal(story, save: !isSavedAtStart, saveVenue: .story) { [weak self] in
            guard let self = self else { return }
            // Trigger email opt-in prompt on successful save (not unsave)
            if !isSavedAtStart {
                DispatchQueue.main.async {
                    EmailOptInPromptManager.shared.handleTrigger(
                        .bookSaved,
                        genre: story.genre,
                        from: self
                    )
                }
            }
        }
    }
}

// MARK: - Rating chip

/// Compact rating shown beside the genre pill: ★ 4.46 · 23
/// Hidden below `BookDetailVC.minimumRatingsToDisplay`.
class BookDetailRatingChipView: UIView {

    var tappedHandler: (() -> Void)?

    private let starImageView = UIImageView()
    private let label = UILabel()
    private let stackView = UIStackView()
    private lazy var tapGestureRecognizer = UITapGestureRecognizer(
        target: self,
        action: #selector(handleTap)
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupChip()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupChip()
    }

    private func setupChip() {
        layer.cornerRadius = 11
        layer.masksToBounds = true
        layer.borderWidth = 1

        let starConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        starImageView.image = UIImage(systemName: "star.fill", withConfiguration: starConfig)
        starImageView.contentMode = .center
        starImageView.setContentHuggingPriority(.required, for: .horizontal)

        label.font = Fonts.medium13
        label.textAlignment = .center

        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 4
        stackView.isUserInteractionEnabled = false
        stackView.addArrangedSubview(starImageView)
        stackView.addArrangedSubview(label)

        addSubviewForConstraints(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: 22)
        ])

        updateAppearanceColors()

        addGestureRecognizer(tapGestureRecognizer)
        isUserInteractionEnabled = true
    }

    private func updateAppearanceColors() {
        backgroundColor = Colours.surfaceCard
        layer.borderColor = Colours.inputBorder.cgColor
        starImageView.tintColor = Colours.orangePrimary
        label.textColor = Colours.textPrimary
    }

    func configure(rating: Double, numberOfRatings: Int) {
        let formattedRating = Self.formattedRating(rating)
        label.text = "\(formattedRating) · \(numberOfRatings)"
        accessibilityLabel = "Rated \(formattedRating) out of 5 from \(numberOfRatings) ratings"
        accessibilityTraits = tapGestureRecognizer.isEnabled ? .button : .staticText
        isAccessibilityElement = true
    }

    static func formattedRating(_ rating: Double) -> String {
        String(format: "%.2f", rating)
    }

    func setTapEnabled(_ isEnabled: Bool) {
        tapGestureRecognizer.isEnabled = isEnabled
        accessibilityTraits = isEnabled ? .button : .staticText
    }

    @objc private func handleTap() {
        tappedHandler?()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateAppearanceColors()
    }

    override var forFirstBaselineLayout: UIView {
        return label
    }

    override var forLastBaselineLayout: UIView {
        return label
    }
}
