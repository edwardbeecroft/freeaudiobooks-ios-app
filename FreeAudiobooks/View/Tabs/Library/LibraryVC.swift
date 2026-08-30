//
//  ConversationsVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 02/09/2020.
//  Copyright © 2020 Radically Better Ltd. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseStorage
import NVActivityIndicatorView
import Lottie
import PopupDialog
import BetterSegmentedControl
import SuperwallKit

private enum LibrarySegment: Int {
    case inProgress = 0
    case saved = 1
    case completed = 2
}

private struct LibraryJourneyData {
    let continueReadingContent: [ReadableContentMetadata]
    let completedContent: [ReadableContentMetadata]
    let savedWantToReadContent: [ReadableContentMetadata]

    static let empty = LibraryJourneyData(continueReadingContent: [],
                                          completedContent: [],
                                          savedWantToReadContent: [])
}

class LibraryVC: UIViewController {

    private let headerView = HeaderView(
        titleText: "Library",
        alwaysHideUpsell: true,
        showBottomBorder: true,
        showsListeningQuotaPill: true
    )
    private let controlsContainerView = UIView()
    private let offlineBanner = OfflineBannerView()
    private var hasFailedRequests = false
    private var isBannerCurrentlyVisible = false
    private var isFetchInProgress = false
    private var savedDownloadedTopConstraint: NSLayoutConstraint!

    private var savedDownloadedSegmentedControl: BetterSegmentedControl!
    private let filterChipsStack = UIStackView()
    private var downloadedFilterButton: UIButton!
    private var downloadTypeFilterButton: UIButton!
    private var isDownloadedFilterActive = false
    private let introSectionBottomBorderView = UIView()
    private let emptyStateLayoutGuide = UILayoutGuide()
    private var noConversationsCenterYConstraint: NSLayoutConstraint!
    
    private let tableView = UITableView()
    private lazy var noSavedResponsesAnimationView: LottieAnimationView = {
        let animationView = LottieAnimationView()
        animationView.loopMode = .loop
        animationView.backgroundColor = nil
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.contentMode = .scaleAspectFit

        Task {
            do {
                let dotLottie = try await DotLottieFile.named("books-1e")
                await MainActor.run {
                    animationView.loadAnimation(from: dotLottie)
                    if !animationView.isHidden {
                        animationView.play()
                    }
                }
            } catch {
                print("Failed to load library empty-state animation: \(error)")
            }
        }

        return animationView
    }()
    private let noConversationsLabel = UILabel()
    private let browseLibraryButton = Buttons.primaryCTA(buttonTitle: "Browse Library")
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(getStoriesWithRefreshControl), for: .valueChanged)
        refreshControl.tintColor = Colours.textPrimary
        return refreshControl
    }()
    
    // Cached book collections for performance
    private var cachedSavedContent: [ReadableContentMetadata]?
    private var libraryJourneyData = LibraryJourneyData.empty

    private var loadingIndicatorView: NVActivityIndicatorView?

    private var selectedSegment: LibrarySegment {
        LibrarySegment(rawValue: Int(savedDownloadedSegmentedControl.index)) ?? .saved
    }

    private var currentSegmentItems: [ReadableContentMetadata] {
        var items: [ReadableContentMetadata]
        switch selectedSegment {
        case .inProgress: items = libraryJourneyData.continueReadingContent
        case .saved:      items = libraryJourneyData.savedWantToReadContent
        case .completed:  items = libraryJourneyData.completedContent
        }

        if isDownloadedFilterActive {
            items = items.filter { $0.hasDownloadedAudio }
        }
        return items
    }

    @objc private func getStoriesWithRefreshControl() {
        fetchSavedBooks(isRefreshControl: true)
    }

    private func savedLibraryContent() -> [ReadableContentMetadata] {
        if let cached = cachedSavedContent {
            return cached
        }

        guard let user = AccountManager.shared.user else { return [] }
        let sortedContent = user.sortedSavedContent(contentType: nil)
        cachedSavedContent = sortedContent
        return sortedContent
    }

    private func refreshLibraryJourneyData() {
        let continueReadingContent = ReadingUserDefaults.getReadingInProgressContent()
            .filter { !$0.isCompleted() }
            .filter { (ReadingUserDefaults.progressForBookWithUUID($0.contentUUID) ?? 0) < 100 }

        let completedContent = resolvedCompletedContent()
        let inProgressUUIDs = Set(continueReadingContent.map(\.contentUUID))
        let completedUUIDs = Set(completedContent.map(\.contentUUID))
        let savedWantToReadContent = savedLibraryContent().filter {
            !inProgressUUIDs.contains($0.contentUUID) &&
            !completedUUIDs.contains($0.contentUUID)
        }

        libraryJourneyData = LibraryJourneyData(continueReadingContent: continueReadingContent,
                                                completedContent: completedContent,
                                                savedWantToReadContent: savedWantToReadContent)
    }

    private func resolvedCompletedContent() -> [ReadableContentMetadata] {
        guard let user = AccountManager.shared.user else { return [] }

        let orderedUUIDs = Array(user.completedBookInternalUUIDs.reversed())
        var resolved: [ReadableContentMetadata] = []
        var seenUUIDs = Set<String>()

        for uuid in orderedUUIDs {
            guard !seenUUIDs.contains(uuid) else { continue }

            let metadata: ReadableContentMetadata? = CoreDataBookInternalManager.shared.getWithUUID(uuid: uuid)

            guard let metadata else { continue }
            seenUUIDs.insert(uuid)
            resolved.append(metadata)
        }

        return resolved
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colours.surfacePrimary

        setupNoStoriesUI()

        setupLibraryHeaderView()
        setupOfflineBanner()
        setupSavedDownloadedSegmentedControl()
        setupFilterChips()
        setupTableView()
        refreshLibraryJourneyData()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(connectivityDidChange),
                                               name: NetworkMonitor.connectivityChangedNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshForSubscriberStatus),
                                               name: .didUpdateSubscriberStatus,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        headerView.update()
        updateElementVisibility()
        // Show banner if currently offline (even without failed requests)
        if !NetworkMonitor.shared.isConnected {
            showOfflineBanner(true)
        }

        fetchSavedBooks(isRefreshControl: false)

        AnalyticsManager.shared.trackSavedStoriesViewed()
    }
}

extension LibraryVC {
    private func setupLibraryHeaderView() {
        headerView.imageViewTappedHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                if let user = AccountManager.shared.user, user.profileImageURLString != nil {
                    self.goToAccountVC()
                }
            }
        }

        headerView.listeningQuotaTappedHandler = { [weak self] in
            self?.presentListeningQuotaSheet()
        }

        // White background behind status bar to match header
        let statusBarBackground = UIView()
        statusBarBackground.backgroundColor = Colours.chromeBackground
        view.addSubviewForConstraints(statusBarBackground)

        view.addSubviewForConstraints(headerView)

        NSLayoutConstraint.activate([
            statusBarBackground.topAnchor.constraint(equalTo: view.topAnchor),
            statusBarBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBarBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBarBackground.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    func setupOfflineBanner() {
        view.addSubviewForConstraints(offlineBanner)
        offlineBanner.isHidden = true

        NSLayoutConstraint.activate([
            offlineBanner.topAnchor.constraint(equalTo: view.safeTopAnchor),
            offlineBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            offlineBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        offlineBanner.retryTappedHandler = { [weak self] in
            guard let self = self else { return }
            self.fetchSavedBooks(isRefreshControl: false)
        }
    }

    func showOfflineBanner(_ show: Bool) {
        DispatchQueue.main.async {
            self.isBannerCurrentlyVisible = show
            self.offlineBanner.isHidden = !show
            self.offlineBanner.updateStatus(isOffline: show)
            self.updateSavedDownloadedConstraints()
        }
    }

    @objc func connectivityDidChange(_ notification: Notification) {
        guard let isConnected = notification.userInfo?["isConnected"] as? Bool else { return }

        DispatchQueue.main.async {
            if isConnected {
                // Back online
                if self.hasFailedRequests {
                    // Had failed requests - show "Back online!" and retry
                    if !self.isBannerCurrentlyVisible {
                        self.showOfflineBanner(true)
                    }
                    self.fetchSavedBooks(isRefreshControl: false)
                } else {
                    // No failed requests - hide banner only if it's currently showing
                    if self.isBannerCurrentlyVisible {
                        self.showOfflineBanner(false)
                    }
                }
            } else {
                // Connection dropped - show banner only if not already showing
                if !self.isBannerCurrentlyVisible {
                    self.showOfflineBanner(true)
                }
            }
        }
    }

    private func updateSavedDownloadedConstraints() {
        savedDownloadedTopConstraint.isActive = false
        if offlineBanner.isHidden {
            savedDownloadedTopConstraint = controlsContainerView.topAnchor.constraint(
                equalTo: headerView.bottomAnchor
            )
        } else {
            savedDownloadedTopConstraint = controlsContainerView.topAnchor.constraint(
                equalTo: offlineBanner.bottomAnchor
            )
        }
        savedDownloadedTopConstraint.isActive = true
        view.layoutIfNeeded()
    }
}

extension LibraryVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func showImagePicker() {
        DispatchQueue.main.async {
            let imagePicker = UIImagePickerController()
            imagePicker.allowsEditing = true
            imagePicker.delegate = self
            imagePicker.modalPresentationStyle = .fullScreen
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var selectedImage: UIImage?
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            selectedImage = editedImage
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            selectedImage = originalImage
        }
        
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
        
        guard let image = selectedImage else {return}
        handleUploadImage(image)
    }
    
    private func handleUploadImage(_ image: UIImage) {
        AccountManager.shared.uploadProfileImage(image: image) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .progress: break
            case .error:
                DispatchQueue.main.async {
                    self.showUploadRetryError(image: image)
                }
            case .explicit:
                DispatchQueue.main.async {
                    self.showPossibleInappropriateContentAlert()
                }
            case .downloadURL:
                DispatchQueue.main.async {
                    AppNotifiers.shared.shouldReloadAccountVC = true
                }
            }
        }
    }
    
    private func showPossibleInappropriateContentAlert() {
        AnalyticsManager.shared.trackExplicitImageDetected()
        let alertController = AlertControllers.inappropriateContentAlert(multipleImageUpload: false)
        present(alertController, animated: true, completion: nil)
    }
    
    func showUploadRetryError(image: UIImage) {
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let retryAction = UIAlertAction(title: "Retry", style: .default) { [weak self] retryTapped in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.handleUploadImage(image)
            }
        }
        let alertController = UIAlertController(title: "Network Error", message: "Please ensure you have an active internet connection and try again.", preferredStyle: .alert)
        alertController.addAction(cancelAction)
        alertController.addAction(retryAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension LibraryVC {
    func setupSavedDownloadedSegmentedControl() {
        let unselectedSegmentTextColor = UIColor.dynamic(
            light: .white,
            dark: UIColor.white.withAlphaComponent(0.65)
        )
        let selectedSegmentTextColor = Colours.themeAccentDark
        let selectedSegmentBackgroundColor = UIColor.dynamic(
            light: .white,
            dark: UIColor(hexString: "#EDEDED")
        )

        savedDownloadedSegmentedControl = BetterSegmentedControl(
            frame: .zero,
            segments: LabelSegment.segments(withTitles: [
                "In Progress",
                "Saved",
                "Completed"],
                                            normalFont: Fonts.semiBold14,
                                            normalTextColor: unselectedSegmentTextColor,
                                            selectedFont:Fonts.semiBold14,
                                            selectedTextColor: selectedSegmentTextColor),
            index: 0,
            options: [.backgroundColor(Colours.themeAccentDark),
                      .indicatorViewBackgroundColor(selectedSegmentBackgroundColor),
                      .indicatorViewInset(2),
                      .cornerRadius(UIConstants.shared.cornerRadius),
                      .animationSpringDamping(1.0)])

        savedDownloadedSegmentedControl.addTarget(self, action: #selector(segmentValueChanged), for: .valueChanged)

        // Container with grey background for segmented control + filter chips
        controlsContainerView.backgroundColor = Colours.backgroundGrey
        view.addSubviewForConstraints(controlsContainerView)

        controlsContainerView.addSubviewForConstraints(savedDownloadedSegmentedControl)

        savedDownloadedTopConstraint = controlsContainerView.topAnchor.constraint(equalTo: headerView.bottomAnchor)
        NSLayoutConstraint.activate([
            savedDownloadedTopConstraint,
            controlsContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            savedDownloadedSegmentedControl.topAnchor.constraint(equalTo: controlsContainerView.topAnchor, constant: 12),
            savedDownloadedSegmentedControl.leadingAnchor.constraint(equalTo: controlsContainerView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            savedDownloadedSegmentedControl.trailingAnchor.constraint(equalTo: controlsContainerView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            savedDownloadedSegmentedControl.heightAnchor.constraint(equalToConstant: 36),
        ])

        savedDownloadedSegmentedControl.setIndex(0)
    }

    func setupFilterChips() {
        filterChipsStack.axis = .horizontal
        filterChipsStack.spacing = 8
        filterChipsStack.alignment = .center

        downloadedFilterButton = makeFilterChip(title: "Downloaded", action: #selector(downloadedFilterTapped))
        downloadTypeFilterButton = makeDownloadTypeChip()
        downloadTypeFilterButton.isHidden = true

        filterChipsStack.addArrangedSubview(downloadedFilterButton)
        filterChipsStack.addArrangedSubview(downloadTypeFilterButton)

        controlsContainerView.addSubviewForConstraints(filterChipsStack)

        NSLayoutConstraint.activate([
            filterChipsStack.topAnchor.constraint(equalTo: savedDownloadedSegmentedControl.bottomAnchor, constant: 12),
            filterChipsStack.leadingAnchor.constraint(equalTo: controlsContainerView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            filterChipsStack.bottomAnchor.constraint(equalTo: controlsContainerView.bottomAnchor, constant: -12),
        ])

        // Bottom border on controls container
        introSectionBottomBorderView.backgroundColor = Colours.separator
        controlsContainerView.addSubviewForConstraints(introSectionBottomBorderView)
        NSLayoutConstraint.activate([
            introSectionBottomBorderView.leadingAnchor.constraint(equalTo: controlsContainerView.leadingAnchor),
            introSectionBottomBorderView.trailingAnchor.constraint(equalTo: controlsContainerView.trailingAnchor),
            introSectionBottomBorderView.bottomAnchor.constraint(equalTo: controlsContainerView.bottomAnchor),
            introSectionBottomBorderView.heightAnchor.constraint(equalToConstant: 1)
        ])

        view.addLayoutGuide(emptyStateLayoutGuide)
        NSLayoutConstraint.activate([
            emptyStateLayoutGuide.topAnchor.constraint(equalTo: controlsContainerView.bottomAnchor),
            emptyStateLayoutGuide.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            emptyStateLayoutGuide.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            emptyStateLayoutGuide.bottomAnchor.constraint(equalTo: view.safeBottomAnchor)
        ])

        noConversationsCenterYConstraint?.isActive = false
        noConversationsCenterYConstraint = noConversationsLabel.centerYAnchor.constraint(equalTo: emptyStateLayoutGuide.centerYAnchor, constant: 24)
        noConversationsCenterYConstraint.isActive = true
    }

    private func makeFilterChip(title: String, action: Selector?) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = Fonts.semiBold14
        let accent = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
        button.setTitleColor(accent, for: .normal)
        button.backgroundColor = accent.withAlphaComponent(0.1)
        button.layer.cornerRadius = 14
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        if let action {
            button.addTarget(self, action: action, for: .touchUpInside)
        }
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 28)
        ])
        return button
    }

    private func makeDownloadTypeChip() -> UIButton {
        makeFilterChip(title: "Downloaded", action: nil)
    }

    private func updateFilterChipAppearance(_ button: UIButton, isActive: Bool) {
        let accent = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
        if isActive {
            button.backgroundColor = Colours.themeAccentDark
            button.setTitleColor(.white, for: .normal)
        } else {
            button.backgroundColor = accent.withAlphaComponent(0.1)
            button.setTitleColor(accent, for: .normal)
        }
    }

    @objc func downloadedFilterTapped() {
        isDownloadedFilterActive.toggle()
        updateFilterChipAppearance(downloadedFilterButton, isActive: isDownloadedFilterActive)

        UIView.animate(withDuration: 0.25) {
            self.downloadTypeFilterButton.isHidden = true
            self.downloadTypeFilterButton.alpha = 0
            self.view.layoutIfNeeded()
        }

        tableView.reloadData()
        updateElementVisibility()
    }

    @objc func segmentValueChanged() {
        refreshLibraryJourneyData()
        tableView.reloadData()
        updateElementVisibility()
    }
}

extension LibraryVC: UITableViewDelegate, UITableViewDataSource {
    private func setupTableView() {
        let bottomOverscrollInset: CGFloat = 40

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        
        view.addSubviewForConstraints(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: controlsContainerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    
        tableView.register(SearchResultsTVC.self, forCellReuseIdentifier: "cell")
        tableView.isHidden = true
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.contentInset.bottom = bottomOverscrollInset
        tableView.scrollIndicatorInsets.bottom = bottomOverscrollInset
        tableView.addSubview(refreshControl)
        tableView.separatorStyle = .none
        
        tableView.delaysContentTouches = false
        for case let scrollView as UIScrollView in tableView.subviews {
            scrollView.delaysContentTouches = false
        }
        
        if #available(iOS 15, *) {
            tableView.sectionHeaderTopPadding = 0
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        currentSegmentItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let items = currentSegmentItems
        let contentMetadata = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SearchResultsTVC

        let displayContext: SmallMetadataDisplayContext
        switch selectedSegment {
        case .inProgress: displayContext = .normal
        case .saved:      displayContext = .librarySaved
        case .completed:  displayContext = .libraryCompleted
        }

        cell.set(contentMetadata: contentMetadata, displayContext: displayContext)
        cell.tappedSaveHandler = { [weak self] metadataView in
            self?.tappedSave(contentMetadata: contentMetadata, view: metadataView)
        }
        cell.tappedDownloadHandler = { [weak self] view in
            self?.tappedDownload(view: view)
        }
        cell.tappedHandler = { [weak self] in
            guard let self else { return }
            if self.selectedSegment == .inProgress {
                self.resumeReadingIfPossible(for: contentMetadata)
            } else {
                self.showBookWithMetadata(contentMetadata, sourceItems: items)
            }
        }
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        false
    }
}


extension LibraryVC {
    func showBookWithMetadata(_ bookMetadata: ReadableContentMetadata,
                              sourceItems: [ReadableContentMetadata]? = nil) {
        let bookDetailVC = BookDetailVC(contentMetadata: bookMetadata)
        bookDetailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(bookDetailVC, animated: true)
    }
}

private extension LibraryVC {
    func refreshVisibleContentAfterBookDetailDismiss() {
        refreshContentCache()
        tableView.reloadData()
        updateElementVisibility()
    }

    func resumeReadingIfPossible(for metadata: ReadableContentMetadata) {
        if ReadingUserDefaults.getLastReadMode(for: metadata.contentUUID) == .audio {
            if let bookInternal = metadata as? CDBookInternal,
               resumeCachedAudiobookIfAllowed(
                   bookInternal: bookInternal,
                   navigationController: navigationController
               ) {
                return
            } else if let bookInternal = metadata as? CDBookInternal, !bookInternal.isAvailableToUser {
                displayPaywall(placement: .earlyAccess, bookInternal: bookInternal)
            } else {
                showBookWithMetadata(metadata, sourceItems: libraryJourneyData.continueReadingContent)
            }
            return
        }

        let localContent: ReadableContent? = APIBookInternalContentManager.getBookInternalContent(bookUUID: metadata.contentUUID)

        if let localContent {
            presentReadingModePaywall(bookInternal: metadata as? CDBookInternal) { [weak self] in
                guard let self, let navigationController else { return }
                let bookDetailVC = BookDetailVC(contentMetadata: metadata)
                bookDetailVC.hidesBottomBarWhenPushed = true
                let readingVC = ReadingVC(metadata: metadata, content: localContent)

                var viewControllers = navigationController.viewControllers
                viewControllers.append(bookDetailVC)
                viewControllers.append(readingVC)
                navigationController.setViewControllers(viewControllers, animated: true)
            }
            return
        }

        if let bookInternal = metadata as? CDBookInternal, !bookInternal.isAvailableToUser {
            displayPaywall(placement: .earlyAccess, bookInternal: bookInternal)
        } else {
            showBookWithMetadata(metadata, sourceItems: libraryJourneyData.continueReadingContent)
        }
    }

}

extension LibraryVC {
    private func tappedSave<T: SaveableMetadataView>(contentMetadata: ReadableContentMetadata, view: T) {
        handleSave(contentMetadata: contentMetadata, view: view)
    }
}

private extension LibraryVC {
    func handleSave<T: SaveableMetadataView>(contentMetadata: ReadableContentMetadata, view: T) {
        let contentUUID = contentMetadata.contentUUID
        guard let cdBookInternal = contentMetadata as? CDBookInternal else { return }
        let isSavedAtStart = AccountManager.shared.user?.savedBookInternalUUIDs.contains(contentUUID) ?? false

        if isSavedAtStart {
            AccountManager.shared.user?.savedBookInternalUUIDs.removeAll(where: { $0 == contentUUID })
        } else {
            AccountManager.shared.user?.savedBookInternalUUIDs.append(contentUUID)

            let newSavedCount = AccountManager.shared.user?.totalSavedBooksCount ?? 0
            let requiredLaunchCount = RCValues.shared.int(forKey: .requiredLaunchCountForSKReview) ?? 2
            if newSavedCount >= 3 && SKReviewManager.launchCount >= requiredLaunchCount {
                SKReviewManager.requestReview(venue: .savedBook)
            }
        }

        AccountManager.shared.handleSaveBookInternal(cdBookInternal,
                                                     save: !isSavedAtStart,
                                                     saveVenue: .story,
                                                     completion: { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if !isSavedAtStart {
                    EmailOptInPromptManager.shared.handleTrigger(.bookSaved, genre: cdBookInternal.genre, from: self)
                }
            }
        })

        // Invalidate saved content cache since save status changed
        invalidateSavedContentCache()
        
        tableView.reloadData()
        updateElementVisibility()
    }
}

extension LibraryVC {
    func displayPaywall(placement: PaywallPlacement, bookInternal: CDBookInternal?) {
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
                case .purchased(let product):
                    print("Purchased \(product.productIdentifier)")                    
                    AnalyticsManager.shared.trackPaywallUserSubscribed(placement: placement, cdBookInternal: bookInternal)
                    self.showSubscribeSuccessPopup()
                    self.refreshForSubscriberStatus()
                case .restored:
                    print("Restored purchases.")
                    AnalyticsManager.shared.trackPaywallRestorePurchasesSuccess()
                    self.refreshForSubscriberStatus()
                }
            }
        }
        Superwall.shared.register(placement: placement.rawValue, params: nil, handler: handler)
    }
    
    @objc func refreshForSubscriberStatus() {
        // Refresh cache in case subscription status affects available books
        self.refreshContentCache()
        self.tableView.reloadData()
        self.updateElementVisibility()
    }
}

private extension LibraryVC {
    func setupNoStoriesUI() {
        setupNoOrdersLabel()
        setupBrowseItemsButton()
        setupNoSavedItemsAnimationView()
    }
    func setupNoOrdersLabel() {
        view.addSubviewForConstraints(noConversationsLabel)
        noConversationsLabel.textColor = Colours.subtext
        noConversationsLabel.font = Fonts.medium16
        noConversationsLabel.numberOfLines = 0
        noConversationsLabel.lineBreakMode = .byWordWrapping
        noConversationsLabel.textAlignment = .center
        
        noConversationsCenterYConstraint = noConversationsLabel.centerYAnchor.constraint(equalTo: view.safeCenterYAnchor, constant: 80)
        NSLayoutConstraint.activate([
            noConversationsLabel.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 40),
            noConversationsLabel.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -40),
            noConversationsCenterYConstraint
        ])
        noConversationsLabel.isHidden = true
    }
    func setupBrowseItemsButton() {
        view.addSubviewForConstraints(browseLibraryButton)
        NSLayoutConstraint.activate([
            browseLibraryButton.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 60),
            browseLibraryButton.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -60),
            browseLibraryButton.topAnchor.constraint(equalTo: noConversationsLabel.bottomAnchor, constant: UIConstants.shared.standardMargin),
            browseLibraryButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        browseLibraryButton.addTarget(self, action: #selector(browseItemsTapped), for: .touchUpInside)
        browseLibraryButton.isHidden = true
    }
    func setupNoSavedItemsAnimationView() {
        view.addSubviewForConstraints(noSavedResponsesAnimationView)
        NSLayoutConstraint.activate([
            noSavedResponsesAnimationView.widthAnchor.constraint(equalToConstant: 180),
            noSavedResponsesAnimationView.heightAnchor.constraint(equalToConstant: 180),
            noSavedResponsesAnimationView.bottomAnchor.constraint(equalTo: noConversationsLabel.topAnchor, constant: -0),
            noSavedResponsesAnimationView.centerXAnchor.constraint(equalTo: view.safeCenterXAnchor)
        ])
        noSavedResponsesAnimationView.isHidden = true
    }
    @objc func browseItemsTapped() {
        if isDownloadedFilterActive {
            isDownloadedFilterActive = false
            updateFilterChipAppearance(downloadedFilterButton, isActive: false)
            downloadTypeFilterButton.isHidden = true
            tableView.reloadData()
            updateElementVisibility()
        } else {
            if let tabBar = tabBarController as? AppTabBarController {
                tabBar.selectTab(tab: .discover)
            }
        }
    }
}

private extension LibraryVC {
    func fetchSavedBooks(isRefreshControl: Bool) {
        // Prevent concurrent fetches
        guard !isFetchInProgress else {
            print("Fetch already in progress, skipping")
            return
        }

        isFetchInProgress = true

        let dispatchGroup = DispatchGroup()
        var anyRequestFailed = false

        let savedBookInternalUUIDs = AccountManager.shared.user?.savedBookInternalUUIDs ?? []
        let completedBookInternalUUIDs = AccountManager.shared.user?.completedBookInternalUUIDs ?? []
        var firestoreIDsToFetch = Array(Set(savedBookInternalUUIDs + completedBookInternalUUIDs))
        let alreadyFetchedFirestoreIDs = CoreDataBookInternalManager.shared.getWithUUIDs(uuids: firestoreIDsToFetch).compactMap({ $0.uuid })
        firestoreIDsToFetch.removeAll(where: { alreadyFetchedFirestoreIDs.contains($0) })

        if firestoreIDsToFetch.isEmpty {
            self.isFetchInProgress = false
            self.handleFetchComplete()
        } else {
            if !isRefreshControl {
                showLoadingIndicator(show: true)
            }
            if !firestoreIDsToFetch.isEmpty {
                dispatchGroup.enter()
                APIBookInternalManager.shared.fetchStoriesWithIDs(uuids: firestoreIDsToFetch) { firestoreSuccess in
                    if !firestoreSuccess {
                        // If Firebase fails, it couldn't get data from cache or network
                        anyRequestFailed = true
                    }
                    dispatchGroup.leave()
                }
            }

            dispatchGroup.notify(queue: .main) {
                self.isFetchInProgress = false
                if anyRequestFailed {
                    // Show offline banner instead of retry UI
                    self.hasFailedRequests = true
                    self.showOfflineBanner(true)
                } else {
                    // Requests succeeded
                    self.hasFailedRequests = false
                    // Only hide banner if we're actually online
                    if NetworkMonitor.shared.isConnected {
                        self.showOfflineBanner(false)
                    }
                }
                self.handleFetchComplete()
            }
        }
    }

    func handleFetchComplete() {
        // Refresh cache since new data was fetched
        refreshContentCache()

        self.tableView.reloadData()
        self.showLoadingIndicator(show: false)
        self.refreshControl.endRefreshing()
    }
}

private extension LibraryVC {
    func showLoadingIndicator(show: Bool) {
        if show {
            guard loadingIndicatorView == nil else { return }
            
            [noConversationsLabel,
             browseLibraryButton,
             noSavedResponsesAnimationView,
             tableView].forEach { $0?.isHidden = true }
            
            noSavedResponsesAnimationView.stop()
            
            loadingIndicatorView = NVActivityIndicatorView(frame: CGRect.zero, type: NVActivityIndicatorType.circleStrokeSpin, color: Colours.textPrimary, padding: 0)
            guard let indicatorView = loadingIndicatorView else { return }
            
            indicatorView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(indicatorView)
            NSLayoutConstraint.activate([
                indicatorView.centerYAnchor.constraint(equalTo: view.safeCenterYAnchor, constant: 40),
                indicatorView.widthAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight),
                indicatorView.heightAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight),
                indicatorView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
            ])
            indicatorView.startAnimating()
        } else {
            loadingIndicatorView?.stopAnimating()
            loadingIndicatorView?.removeFromSuperview()
            loadingIndicatorView = nil
            
            updateElementVisibility()
        }
    }
    func updateElementVisibility() {
        let items = currentSegmentItems
        let hasFiltersActive = isDownloadedFilterActive

        if items.isEmpty {
            tableView.isHidden = true
            noConversationsLabel.isHidden = false
            noSavedResponsesAnimationView.isHidden = false
            noSavedResponsesAnimationView.play()

            if hasFiltersActive {
                let segmentName: String
                switch selectedSegment {
                case .inProgress: segmentName = "in-progress"
                case .saved:      segmentName = "saved"
                case .completed:  segmentName = "completed"
                }

                noConversationsLabel.text = "No \(segmentName) downloaded audiobooks found."

                browseLibraryButton.setTitle("Clear Filters", for: [])
                browseLibraryButton.isHidden = false
            } else {
                switch selectedSegment {
                case .inProgress:
                    noConversationsLabel.text = "Audiobooks you start listening to will appear here."
                case .saved:
                    noConversationsLabel.text = "Audiobooks you save will appear here."
                case .completed:
                    noConversationsLabel.text = "Audiobooks you finish will appear here."
                }
                browseLibraryButton.setTitle("Browse Library", for: [])
                browseLibraryButton.isHidden = false
            }
        } else {
            noSavedResponsesAnimationView.isHidden = true
            noSavedResponsesAnimationView.stop()
            tableView.isHidden = false
            noConversationsLabel.isHidden = true
            browseLibraryButton.isHidden = true
        }
    }
}


// MARK: - Cache Management
private extension LibraryVC {
    
    func refreshContentCache() {
        cachedSavedContent = nil
        refreshLibraryJourneyData()
    }

    func invalidateSavedContentCache() {
        cachedSavedContent = nil
        refreshLibraryJourneyData()
    }
}

private extension LibraryVC {
    func tappedDownload<T: DownloadableMetadataView>(view: T) {
        guard let bookMetadata = view.contentMetadata else { return }

        if bookMetadata.hasDownloadedAudio {
            showDeletePopup(bookMetadata: bookMetadata, view: view)
        } else if APIBookInternalAudioManager.shared.isDownloading(bookUUID: bookMetadata.contentUUID) {
            view.updateDownloadElements()
        } else if let bookInternal = bookMetadata as? CDBookInternal, !bookInternal.isAvailableToUser {
            displayPaywall(placement: .earlyAccess, bookInternal: bookInternal)
        } else {
            handleDownload(bookMetadata: bookMetadata, view: view)
        }
    }
    func handleDownload<T: DownloadableMetadataView>(bookMetadata: ReadableContentMetadata, view: T) {
        HapticFeedbackHelper.shared.triggerLightImpactFeedback()
        view.startDownloadAnimation()

        APIBookInternalAudioManager.shared.downloadAudiobook(for: bookMetadata, progressHandler: { progress in
            DispatchQueue.main.async {
                view.updateDownloadProgress(progress)
            }
        }) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                view.stopDownloadAnimation()
                view.updateDownloadElements()
                self.refreshContentCache()

                switch result {
                case .downloaded, .alreadyDownloaded:
                    break
                case .quotaExceeded:
                    self.presentListeningQuotaDepletedSheet(for: bookMetadata) { [weak self, weak view] in
                        guard let self, let view else { return }
                        self.handleDownload(bookMetadata: bookMetadata, view: view)
                    }
                case .noAudio:
                    self.showNoAudioAlert()
                case .failed:
                    self.showDownloadError(bookMetadata: bookMetadata, view: view)
                }
            }
        }
    }

    func showDownloadError<T: DownloadableMetadataView>(bookMetadata: ReadableContentMetadata, view: T) {
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let retryAction = UIAlertAction(title: "Retry", style: .default) { [weak self] retryTapped in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.handleDownload(bookMetadata: bookMetadata, view: view)
            }
        }
        let alertController = UIAlertController(title: "Network Error", message: "Please ensure you have an active internet connection and try again.", preferredStyle: .alert)
        alertController.addAction(cancelAction)
        alertController.addAction(retryAction)
        present(alertController, animated: true, completion: nil)
    }
    func showDeletePopup<T: DownloadableMetadataView>(bookMetadata: ReadableContentMetadata, view: T) {
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let retryAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] retryTapped in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.handleDelete(bookMetadata: bookMetadata, view: view)
            }
        }
        let alertTitle = "Delete Content"
        let alertController = UIAlertController(title: alertTitle, message: "Delete the downloaded audiobook from this device?", preferredStyle: .alert)
        alertController.addAction(cancelAction)
        alertController.addAction(retryAction)
        present(alertController, animated: true, completion: nil)
    }
    func handleDelete<T: DownloadableMetadataView>(bookMetadata: ReadableContentMetadata, view: T) {
        guard let cdBookInternal = bookMetadata as? CDBookInternal else { return }
        handleDeleteBookInternalAudio(cdBookInternal, metadataView: view)
    }

    func handleDeleteBookInternalAudio<T: DownloadableMetadataView>(_ cdBookInternal: CDBookInternal, metadataView: T) {
        if cdBookInternal.hasDownloadedAudio {
            CoreDataBookInternalAudioManager.shared.deleteBookInternalAudio(bookUUID: cdBookInternal.contentUUID) { [weak self] success in
                DispatchQueue.main.async {
                    if !success {
                        print("⚠️ Failed to delete audio content for book: \(cdBookInternal.contentUUID)")
                        metadataView.updateDownloadElements()
                        return
                    }

                    DownloadTimestampManager.shared.removeAudioTimestamp(uuid: cdBookInternal.contentUUID)
                    APIBookInternalAudioManager.shared.clearDownloadState(for: cdBookInternal.contentUUID)

                    // Invalidate cache when content is deleted
                    self?.refreshContentCache()

                    self?.tableView.reloadData()
                    self?.updateElementVisibility()
                }
            }
        } else {
            APIBookInternalAudioManager.shared.clearDownloadState(for: cdBookInternal.contentUUID)
            metadataView.updateDownloadElements()
        }
    }

    func showNoAudioAlert() {
        let alertController = UIAlertController(title: "No Audio Available", message: "This book doesn't have an audiobook version available.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
}
