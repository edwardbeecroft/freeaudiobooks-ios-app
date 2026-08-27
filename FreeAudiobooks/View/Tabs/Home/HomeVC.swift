//
//  HomeVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 08/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import SkeletonView
import SuperwallKit

class HomeVC: UIViewController {
    
    // MARK: - Properties

    private var allStories: [CDBookInternal] = []
    private var genreCardPresentations: [GenreCardPresentation] = []
    private var scrollToSectionUUIDAfterFetch: String?
    private var forYouSessionOrderUUIDs: [String] = []
    private var forYouSessionGenresFingerprint: String?
    private var displayedSections: [DiscoverSection] = []

    /// Whether user just completed onboarding this session (used to optimize their first experience)
    private var didCompleteOnboardingThisSession: Bool {
        NewOnboardingUserDefaults.didCompleteThisSession()
    }

    /// Filtered sections to display based on story availability
    private func makeDisplayedSectionsSnapshot() -> [DiscoverSection] {
        var sections = DiscoverSectionManager.shared.allSections
        guard !sections.isEmpty else {
            // We don't need to run all the below code if the sections fetch hasn't completed yet
            return sections
        }

        let hasContinueReadingItems = DiscoverSectionManager.shared.collectionWithType(type: .continueReading)?.stories.isEmpty == false
        if !hasContinueReadingItems {
            sections.removeAll(where: { $0.type == .continueReading })
        }
        
        // Remove early access section if no early access books or remote config disables it
        let hasEarlyAccessBooks = allStories.contains(where: { $0.isEarlyAccess })
        if !hasEarlyAccessBooks || RCValues.shared.bool(forKey: .shouldShowEarlyAccessSection) != true {
            sections.removeAll(where: { $0.type == .earlyAccess })
        }
        if AppConstants.shared.developmentMode == .screenshots {
            sections.removeAll(where: { $0.type == .earlyAccess })
        }

        // Remove becauseYouRead if user is not logged in or has no completed books
        if
            AccountManager.shared.user == nil ||
            AccountManager.shared.user?.completedBookInternalUUIDs.isEmpty == true {
            sections.removeAll(where: { $0.type == .becauseYouRead })
        }

        // Only show sections that have stories OR are CTA sections
        sections = sections.filter { section in
            // Hero sections require at least one story with complete hero metadata.
            if section.type == .heroCarousel {
                return section.stories.contains(where: { $0.isValidHeroCarouselStory })
            }
            // Include if section has stories
            if !section.stories.isEmpty {
                return true
            }
            // Or if it's a CTA section (which doesn't need stories)
            if section.type.isCTASection {
                return true
            }
            // We'll always have something to show for these
            let sectionsWithDynamicContent: [DiscoverSectionType] = [.forYou, .adultContent]
            if sectionsWithDynamicContent.contains(section.type) {
                return true
            }
            return false
        }

        // First launch optimization: Move For You section to index 0 (only if completed this session)
        if didCompleteOnboardingThisSession {
            if let forYouIndex = sections.firstIndex(where: { $0.type == .forYou }) {
                let forYouSection = sections.remove(at: forYouIndex)
                sections.insert(forYouSection, at: 0)
            }
        }

        return sections
    }
    
    private let offlineBanner = OfflineBannerView()
    private var hasFailedRequests = false
    private var isBannerCurrentlyVisible = false
    private var isFetchInProgress = false

    // Carousel offset preservation
    private var carouselTVCOffsets = [String: CGPoint]()
    private var heroCarouselTVCOffsets = [String: CGPoint]()
    
    // MARK: - UI Elements
    
    private let headerView = HeaderView(
        titleText: "Home",
        alwaysHideUpsell: false,
        showBottomBorder: true,
        showsListeningQuotaPill: true
    )
    private let headerContainerView = UIView()
    private let searchBarView = DiscoverSearchBarView()
    private let tableView = UITableView()
    private let topFadeGradientView = UIView()
    private let topFadeGradientLayer = CAGradientLayer()
    private var skeletonView: HomeSkeletonView?
    private var tableViewTopConstraint: NSLayoutConstraint?
    private var headerTopConstraint: NSLayoutConstraint?
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        refreshControl.tintColor = Colours.textPrimary
        return refreshControl
    }()
    
    private var hasCompletedInitialSectionSetup: Bool = false

    // MARK: - Genre Helpers

    /// Gets guest-selected genres, checking new onboarding first, then legacy
    private func getGuestSelectedGenres() -> [BookInternalGenre]? {
        // Check new onboarding UserDefaults first
        if let newGenres = NewOnboardingUserDefaults.getSelectedGenres(), !newGenres.isEmpty {
            return newGenres
        }
        // Fall back to legacy UserDefaults (for users who completed old onboarding)
        return OnboardingGenreUserDefaults.getSelectedGenres()
    }

    private func shouldUseSubtitleCarousel(for section: DiscoverSection) -> Bool {
        let subtitle = (section.subtitle ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return !subtitle.isEmpty && section.type.supportsSubtitle
    }

    private func currentFavoriteGenresForForYou() -> [BookInternalGenre] {
        if let user = AccountManager.shared.user, !user.favoriteGenres.isEmpty {
            return user.favoriteGenres
        }
        if let guestGenres = getGuestSelectedGenres(), !guestGenres.isEmpty {
            return guestGenres
        }
        return []
    }

    private func forYouGenresFingerprint(_ genres: [BookInternalGenre]) -> String {
        genres.map { $0.rawValue }.sorted().joined(separator: "|")
    }

    private func sessionStableForYouStories(_ stories: [CDBookInternal], favoriteGenres: [BookInternalGenre]) -> [CDBookInternal] {
        let fingerprint = forYouGenresFingerprint(favoriteGenres)
        if forYouSessionGenresFingerprint != fingerprint {
            forYouSessionGenresFingerprint = fingerprint
            forYouSessionOrderUUIDs.removeAll()
        }

        guard !stories.isEmpty else {
            forYouSessionOrderUUIDs.removeAll()
            return []
        }

        if forYouSessionOrderUUIDs.isEmpty {
            let shuffledStories = stories.shuffled()
            forYouSessionOrderUUIDs = shuffledStories.map { $0.contentUUID }
            return shuffledStories
        }

        var candidateByUUID: [String: CDBookInternal] = [:]
        for story in stories {
            candidateByUUID[story.contentUUID] = story
        }
        var orderedStories: [CDBookInternal] = []
        orderedStories.reserveCapacity(stories.count)
        var seenUUIDs = Set<String>()

        for uuid in forYouSessionOrderUUIDs {
            guard let story = candidateByUUID[uuid] else { continue }
            orderedStories.append(story)
            seenUUIDs.insert(uuid)
        }

        let newUnseenStories = stories.filter { seenUUIDs.insert($0.contentUUID).inserted }
        orderedStories.append(contentsOf: newUnseenStories)
        forYouSessionOrderUUIDs = orderedStories.map { $0.contentUUID }

        return orderedStories
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colours.surfacePrimary
        setupUI()
        loadInitialData(isPullToRefresh: false)
        
        hideKeyboardWhenTappedAround()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshForSubscriberStatus),
                                               name: .didUpdateSubscriberStatus,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(connectivityDidChange),
                                               name: NetworkMonitor.connectivityChangedNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleReadingVCExitNotification),
                                               name: .didExitReadingVC,
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: animated)
        headerView.update()

        // Show banner if currently offline (even without failed requests)
        if !NetworkMonitor.shared.isConnected {
            showOfflineBanner(true)
        }
        
        if AppNotifiers.shared.shouldReloadHomeVC {
            AppNotifiers.shared.shouldReloadHomeVC = false
            loadDataForAllSections()
            refreshDisplayedSections()
            tableView.reloadData()
        } else if hasCompletedInitialSectionSetup {
            reloadContinueReadingSection()
        }
        
        // Track page view for analytics
        AnalyticsManager.shared.trackDiscoverViewed(homeVariant: .original)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // These are here for TESTING ONLY
        // showSubscribeSuccessPopup()
        // showEnhancedBookCompletion()
        
        resumeVisibleHeroCarouselAutoScroll()
        handlePendingAction()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderContentInset()
        topFadeGradientLayer.frame = topFadeGradientView.bounds
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateTopGradientColors()
        skeletonView?.startAnimating(interfaceStyle: resolvedSkeletonInterfaceStyle())
    }

    /// Shows deferred email opt-in from book completion
    private func handlePendingEmailOptIn() {
        guard EmailOptInUserDefaults.hasPendingBookCompletedTrigger else { return }

        // Capture the completed book's genre before the delay
        guard let completedBookGenre = EmailOptInUserDefaults.pendingBookCompletedGenre else {
            EmailOptInUserDefaults.clearPendingBookCompleted()
            return
        }

        // Small delay to let the screen settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            EmailOptInPromptManager.shared.handleTrigger(.bookCompleted, genre: completedBookGenre, from: self) { didShow in
                // Only clear the pending state if the prompt was actually shown
                // If suppressed (e.g., still within SKReview guardrail), keep for next visit
                if didShow {
                    EmailOptInUserDefaults.clearPendingBookCompleted()
                }
            }
        }
    }
    
    func reloadContinueReadingSection() {
        let inProgressContent = ReadingUserDefaults.getReadingInProgressContent()
        let inProgressBookInternals = inProgressContent.compactMap { $0 as? CDBookInternal }
        let previousSections = displayedSections
        let previousContinueIndex = previousSections.firstIndex(where: { $0.type == .continueReading })

        if let continueReadingSection = DiscoverSectionManager.shared.collectionWithType(type: .continueReading) {
            continueReadingSection.stories = inProgressBookInternals
        }

        refreshDisplayedSections()

        let currentContinueIndex = displayedSections.firstIndex(where: { $0.type == .continueReading })
        let sectionUUIDsChanged = previousSections.map(\.uuid) != displayedSections.map(\.uuid)

        if sectionUUIDsChanged {
            tableView.reloadData()
        } else if let currentContinueIndex {
            tableView.reloadRows(at: [IndexPath(row: currentContinueIndex, section: 0)], with: .none)
        } else if previousContinueIndex != nil {
            tableView.reloadData()
        }
    }

    @objc private func handleReadingVCExitNotification() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.handleReadingVCExitNotification()
            }
            return
        }

        guard hasCompletedInitialSectionSetup else { return }
        reloadContinueReadingSection()
        headerView.update()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Launch Action Handling

    func handlePendingAction() {
        if let action = AppNotifiers.shared.launchActionNeedsHandling {
            handleLaunchAction(action)
        } else {
            handlePendingEmailOptIn()
        }
    }

    func handleLaunchAction(_ action: LaunchAction) {
        switch action {
        case .bookInternal(let bookUUID):
            if let bookMetadata = CoreDataBookInternalManager.shared.getWithUUID(uuid: bookUUID) {
                showBookDetails(bookMetadata)
            } else {
                APIBookInternalManager.shared.fetchStoriesWithIDs(uuids: [bookUUID]) { success in
                    guard
                        success,
                        let bookMetadata = CoreDataBookInternalManager.shared.getWithUUID(uuid: bookUUID) else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.showBookDetails(bookMetadata)
                    }
                }
            }
        case .savedBooks:
            (self.tabBarController as? AppTabBarController)?.selectTab(tab: .bookshelf)
        case .roadmap:
            let vc = RoadmapVC(wasPresented: false)
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        case .section(let sectionUUID):
            scrollToSectionWithUUID(sectionUUID: sectionUUID)
        }
        AppNotifiers.shared.launchActionNeedsHandling = nil
    }

    func scrollToSectionWithUUID(sectionUUID: String) {
        guard hasCompletedInitialSectionSetup else {
            scrollToSectionUUIDAfterFetch = sectionUUID
            return
        }
        navigationController?.popToViewController(self, animated: false)
        if let index = displayedSections.firstIndex(where: { $0.uuid == sectionUUID }) {
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: true)
        }
    }

    // MARK: - Setup

    private func setupUI() {
        setupTableView()
        setupTopGradient()
        setupHeaderView()
        setupOfflineBanner()
        setupConstraints()
    }

    private func setupOfflineBanner() {
        view.addSubviewForConstraints(offlineBanner)
        offlineBanner.isHidden = true
        
        offlineBanner.retryTappedHandler = { [weak self] in
            guard let self = self else { return }
            self.loadInitialData(isPullToRefresh: false)
        }
    }
    
    private func setupTopGradient() {
        topFadeGradientView.isUserInteractionEnabled = false
        updateTopGradientColors()
        topFadeGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        topFadeGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        topFadeGradientView.layer.addSublayer(topFadeGradientLayer)
        view.addSubviewForConstraints(topFadeGradientView)
    }

    private func updateTopGradientColors() {
        topFadeGradientLayer.colors = [
            Colours.chromeBackground.cgColor,
            Colours.chromeBackground.cgColor
        ]
    }

    private func setupHeaderView() {
        headerContainerView.backgroundColor = Colours.backgroundGrey
        headerContainerView.addSubviewForConstraints(headerView)
        headerContainerView.addSubviewForConstraints(searchBarView)
        view.addSubviewForConstraints(headerContainerView)

        setupSearchBarHandlers()

        headerView.imageViewTappedHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                if
                    let user = AccountManager.shared.user,
                    user.profileImageURLString != nil {
                    self.goToAccountVC()
                } else {
                    self.showImagePicker()
                }
            }
        }

        headerView.upgradeTappedHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.displayPaywall(placement: .homeHeroUpsell, bookInternal: nil)
            }
        }

        headerView.listeningQuotaTappedHandler = { [weak self] in
            self?.presentListeningQuotaSheet()
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = Colours.surfacePrimary
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 200
        tableView.rowHeight = UITableView.automaticDimension
        tableView.refreshControl = refreshControl
        tableView.register(ShortStoryCarouselTVC.self, forCellReuseIdentifier: "BookInternalCarouselTVC")
        tableView.register(ShortStoryEarlyAccessCarouselTVC.self, forCellReuseIdentifier: "EarlyAccessCarouselTVC")
        tableView.register(ContinueReadingCarouselTVC.self, forCellReuseIdentifier: "ContinueReadingCarouselCell")
        tableView.register(ShortStorySearchPromptTVC.self, forCellReuseIdentifier: "SearchPromptCell")
        tableView.register(ForYouPromptTVC.self, forCellReuseIdentifier: "ForYouPromptCell")
        tableView.register(GenreTilesCarouselTVC.self, forCellReuseIdentifier: "GenreTilesCarouselCell")
        tableView.register(HeroCarouselTVC.self, forCellReuseIdentifier: "HeroCarouselCell")
        tableView.register(ShortStoryCarouselSubtitleTVC.self, forCellReuseIdentifier: "BookInternalCarouselSubtitleTVC")

        view.addSubviewForConstraints(tableView)
    }
    
    private func setupConstraints() {
        tableViewTopConstraint = tableView.topAnchor.constraint(equalTo: view.topAnchor)
        headerTopConstraint = headerContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)

        NSLayoutConstraint.activate([
            // Offline banner
            offlineBanner.topAnchor.constraint(equalTo: view.safeTopAnchor),
            offlineBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            offlineBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            offlineBanner.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            // Table view (edge to edge, content scrolls under the header)
            tableViewTopConstraint!,
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Floating header overlay
            headerTopConstraint!,
            headerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Header content inside floating container
            headerView.topAnchor.constraint(equalTo: headerContainerView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),

            // Search bar below header title
            searchBarView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            searchBarView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            searchBarView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),
            searchBarView.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor),

            // Top fade gradient (starts at very top of screen, covers through safe area)
            topFadeGradientView.topAnchor.constraint(equalTo: view.topAnchor),
            topFadeGradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topFadeGradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topFadeGradientView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])

        // Bottom border on floating header
        let borderView = UIView()
        borderView.backgroundColor = Colours.separator
        headerContainerView.addSubviewForConstraints(borderView)

        NSLayoutConstraint.activate([
            borderView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
            borderView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    private func updateHeaderContentInset() {
        headerContainerView.layoutIfNeeded()
        let headerHeight = headerContainerView.frame.height
        guard headerHeight > 0 else { return }

        if tableView.contentInset.top != headerHeight {
            tableView.contentInset.top = headerHeight
            tableView.verticalScrollIndicatorInsets.top = headerHeight
        }
    }

    private func refreshDisplayedSections() {
        displayedSections = makeDisplayedSectionsSnapshot()
    }

    // MARK: - Data Loading
    
    private func loadInitialData(isPullToRefresh: Bool) {
        // Prevent concurrent fetches
        guard !isFetchInProgress else {
            print("Fetch already in progress, skipping")
            return
        }

        isFetchInProgress = true

        if !isPullToRefresh {
            showLoadingIndicator(show: true)
        }

        let dispatchGroup = DispatchGroup()
        var storiesFailed = false
        var sectionsFailed = false
        var fetchedStories: [CDBookInternal] = []

        // Fetch all short stories
        dispatchGroup.enter()
        APIBookInternalManager.shared.fetchAllShortStories { success, stories in
            if !success {
                storiesFailed = true
            } else {
                fetchedStories = stories
            }
            dispatchGroup.leave()
        }

        // Fetch discover sections
        dispatchGroup.enter()
        DiscoverSectionManager.shared.fetchAllSections { success in
            if !success {
                sectionsFailed = true
            }
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            self.isFetchInProgress = false

            if storiesFailed || sectionsFailed {
                // Show offline banner with whatever data we have (cached or empty)
                self.hasFailedRequests = true
                self.showOfflineBanner(true)
                self.showFetchError(isPullToRefresh: isPullToRefresh)
                self.showLoadingIndicator(show: false)
                self.refreshControl.endRefreshing()
                return
            }

            // Requests succeeded
            self.hasFailedRequests = false
            // Only hide banner if we're actually online
            if NetworkMonitor.shared.isConnected {
                self.showOfflineBanner(false)
            }

            self.allStories = fetchedStories
            self.genreCardPresentations = GenreCardPresentation.buildAll(from: self.allStories)

            // Load data for each section (synchronous)
            self.loadDataForAllSections()
            self.refreshDisplayedSections()
            self.headerView.update()

            self.hasCompletedInitialSectionSetup = true
            self.tableView.reloadData()

            if let scrollToSectionUUIDAfterFetch = self.scrollToSectionUUIDAfterFetch {
                self.scrollToSectionWithUUID(sectionUUID: scrollToSectionUUIDAfterFetch)
                self.scrollToSectionUUIDAfterFetch = nil
            }

            self.showLoadingIndicator(show: false)
            self.refreshControl.endRefreshing()
        }
    }
    
    @objc func showFetchError(isPullToRefresh: Bool) {
        
        self.showLoadingIndicator(show: false)
        
        let title = "Network Error"
        let message = "Please check your connection and try again."

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let retryAction = UIAlertAction(title: "Retry", style: .default) { _ in
            DispatchQueue.main.async {
                self.loadInitialData(isPullToRefresh: isPullToRefresh)
            }
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(cancelAction)
        alertController.addAction(retryAction)
        self.present(alertController, animated: true, completion: nil)
    }

    private func loadDataForAllSections() {
        let generallyAvailableStories = allStories
            .filter({ !$0.isEarlyAccess })
        
        print("All Stories: \(allStories.count)")
        print("Generally Available Stories: \(generallyAvailableStories.count)")
        
        if AppConstants.shared.developmentMode == .screenshots {
            DiscoverSectionManager.shared.allSections.removeAll(where: { $0.type == .heroCarousel })
        }
        
        // This has to use DiscoverSectionManager.shared.allSections vs the local sectionsToDisplay as this filters on stories.
        for section in DiscoverSectionManager.shared.allSections {
            loadDataForSection(section, generallyAvailableStories: generallyAvailableStories)
            
            if AppConstants.shared.developmentMode == .screenshots {
                let storyUUIDs = section.stories.compactMap({ $0.contentUUID })
                print("Section: \(section.title)\nStory IDs: \(storyUUIDs)\n")
                switch section.type {
                case .heroCarousel:
                    section.bookIDs = ["4E306AD9-0A10-43E3-8D79-E14DABE7BE74", "9C00775B-1759-4E31-B8CF-9C1FE81C4AD8", "B944DF10-D755-4472-9F0E-33E4D1A66F88", "8E15B1D3-2637-48A2-B919-F6B37488CA8D", "2685706C-134A-45EA-AAEC-60497DA12C1C"]
                case .thisWeeksTopTen:
                    section.bookIDs = ["AEEC053F-6F9D-4FFE-834E-0EDCB4E4E200", "43485C67-3709-48B2-A9EE-C3B4DA260449", "187994CF-02F4-46F0-9756-27FCABBCC9B3", "B90D0855-F155-4851-A7B7-2862AE23A82B", "1D2872E6-BA08-42EC-B2FE-A78063D0659D", "AF5C49D3-0F6B-4D5E-99E6-DABB65FE90DA", "8EC7490C-9366-4ED6-AA1C-4F76EE120818", "02E05BA8-B46C-42E4-AAEE-1D57FD521AA0", "4F09F877-12B4-42E2-B525-4A3BFC64869F", "9DC425B0-2F70-4172-BA69-7F47C9D9B512"]
                case .latestReleases:
                    section.bookIDs = ["5820FC6E-A46D-4649-B467-46FF5CA99EFD", "BBEF5BEA-0DD8-4B73-867A-5D25A64427BC", "02634BC7-DED5-4F26-B1C6-F1C58B851F9C", "669746FD-03FC-4464-B74C-0979E955CAEA", "5D650AC3-A2E1-4497-AC12-050DA4DD507B", "B50F1022-EC75-439E-95DF-C4505849C50A", "0B758873-8C71-41FD-BFCF-227C72A50085", "2D91D6D0-03C2-4EFB-BD59-DEFF89A56512", "EF120EAE-4BD7-43E3-9098-8B0BE5B8CBDB", "627BA17F-6C0D-4D0C-9BFE-20CBD04FC4B6", "224978C6-ED81-4CF8-B9CA-3D02492EF555", "D3A5764D-8A32-4536-BE3D-1BEB8DDCCE22", "896C2713-2AB1-4E4D-B3C7-F4CEB5081A9E", "B944DF10-D755-4472-9F0E-33E4D1A66F88", "DDA6D015-8D7C-4B45-85B7-10A00E7CEE92", "E6EA1BD2-C70C-4206-B37C-B0A166FA69C7", "9C00775B-1759-4E31-B8CF-9C1FE81C4AD8", "17F784BD-F699-4601-8A7B-D4D51CED9A98", "AF5C49D3-0F6B-4D5E-99E6-DABB65FE90DA", "1D2872E6-BA08-42EC-B2FE-A78063D0659D", "F759E488-607B-42BE-B4CC-90BBF08DED2C", "EB1F7D5A-E1FB-4E49-916C-98F1A582E386", "AC08159D-D738-4259-B61A-586B3E83333F", "D48B118E-0F7C-40C7-90C7-E115102C0EBE", "BBEF5BEA-0DD8-4B73-867A-5D25A64427BC", "1CC1EEE8-CF03-4F24-B79A-177C592D0514", "9725F542-860C-425F-B93B-B71F4D1B980E", "134F3F1F-3574-4E8D-9ED2-C8142422F451", "B10F3D7F-9671-40D5-A77B-77122D784280", "03CC6930-D162-47F5-9386-CC711DACB3AF"]
                case .forYou:
                    var firstIDs = UIDevice().iPad ?
                    ["07BADFFB-C70A-4A78-8868-99605CE662EF", "A00E2AE5-B754-494F-9957-11C99E06E82D", "4EE8208F-358C-4D83-8214-B169AEF1AD69", "896C2713-2AB1-4E4D-B3C7-F4CEB5081A9E"] :
                    ["E6EA1BD2-C70C-4206-B37C-B0A166FA69C7", "CEDE6C94-836C-4E7B-A7A7-F988F0C1DA88", "AEEC053F-6F9D-4FFE-834E-0EDCB4E4E200", "896C2713-2AB1-4E4D-B3C7-F4CEB5081A9E"]
                    firstIDs.append(contentsOf: ["E44DCA91-1C8E-4CD2-B231-E397108F8A50", "6DFF342E-3BB4-422B-9C0B-432D90AE90FB", "04066723-AD31-4E19-B00F-B068225EEFAF", "32598177-20D8-4409-986F-1C34743C27AC", "EE69FCC6-06B0-44B7-84F5-5562F5856888", "124310A1-0091-41F7-B8C6-99459F766E23", "D37D37DE-BC3F-470F-B1C1-05D9668F27A3", "91DC445C-4C0D-4380-87CF-712168987B57", "625BBDBA-F0E3-4231-85AB-505F90FA2337", "577DE679-2917-44F1-A59F-2E90EA543EFB", "CD2D5523-635C-4220-A6FE-68B95CD64111", "430803A6-DF83-428F-BFF9-9D4C0C1BD5A1", "07BADFFB-C70A-4A78-8868-99605CE662EF", "CDD3CC16-14E5-4EC1-911F-EC3109C484D2", "3FECAB6B-25B4-4F97-BFDC-E5AA851F18B2", "F89EDAF6-E6BC-4957-B07B-0469367E58EA", "98477FC7-A2AF-413E-B622-6CA3ACD0C5BC", "CF4B2D43-1326-4760-B64C-75C689C92667", "0266A78D-7389-47E5-93BB-F2FED15AAC74", "DC7A3A61-A93D-4CFB-906A-E70834394077", "E662F688-109E-44A5-B529-A36BB1842938", "B8305D97-2BF4-4B84-BA5D-A584B4C53C1F", "D8EDC2A4-479A-4953-ACA5-1308116AD445", "2E89A458-06C2-42F6-B04F-6E84DC1CEFF5", "C7EE627C-E209-415E-8C3C-D6D56400B556", "6D72EA74-057D-4DE9-9E6C-DBB066BB13CB", "8C289421-DB46-4FC9-9364-88DF487178D7", "2A7BD9AB-E308-4EC8-A74A-B19678C49254", "6AF8D35E-84E5-42A7-8C8E-31CC3E25E5C8", "F767746C-5128-4B1B-8C56-36CE1F3609E9", "BFE54988-32F0-4824-940A-E9D7E96516C3"])
                    section.bookIDs = firstIDs
                case .mostPopular:
                    section.bookIDs = ["BBEF5BEA-0DD8-4B73-867A-5D25A64427BC", "389CAB25-89F1-45A6-B278-75E65EC8059E", "1D2872E6-BA08-42EC-B2FE-A78063D0659D", "43485C67-3709-48B2-A9EE-C3B4DA260449", "B944DF10-D755-4472-9F0E-33E4D1A66F88", "CDEF5183-3472-41E7-A46E-846A137A3EB1", "02E05BA8-B46C-42E4-AAEE-1D57FD521AA0", "3A43AA7A-5F87-49D1-937D-E39416227BB7", "17F784BD-F699-4601-8A7B-D4D51CED9A98", "D48B118E-0F7C-40C7-90C7-E115102C0EBE", "7EF9E473-FAA3-4B29-8BD4-D520936669F8", "D6D7F7E3-A4AD-48E7-B1EA-0CD723AA23EA", "4116A9E2-A23E-4BC8-BB6B-E633B87339DB", "EB1F7D5A-E1FB-4E49-916C-98F1A582E386", "C4B9E7CB-BE83-4820-AD33-EB45D2A2EAF0", "7D181FEE-7ECF-43FE-B30D-7C6AB622089B", "AEEC053F-6F9D-4FFE-834E-0EDCB4E4E200", "69669395-70CB-4E68-A23F-1F23BE74DC98", "294F19EE-3BCA-46B5-8EE3-A60119D003B7", "9ACDD805-43D4-41B1-8766-89CAB6F681A1", "98E3B1D2-D32F-404A-AE1B-E74B09CBE4FF", "134F3F1F-3574-4E8D-9ED2-C8142422F451", "751C2E2C-84EB-4BFE-BDE7-1D817406D103", "9E7070D0-5734-46C2-93D6-FBB6AF763983", "07BADFFB-C70A-4A78-8868-99605CE662EF", "8E15B1D3-2637-48A2-B919-F6B37488CA8D", "187994CF-02F4-46F0-9756-27FCABBCC9B3", "ADB49353-2313-413B-8947-CCAEF0FCDDF2", "B90D0855-F155-4851-A7B7-2862AE23A82B", "A000DB70-BC64-47A1-B497-7B0B580DB278"]
                default: break
                }
                allStories.first(where: { $0.contentUUID == "7E056AF7-7923-42D5-ADBF-353B0D7C11E9" })?.containsAdultContent = true
            }
            if let ids = section.bookIDs {
                let newStories = ids.compactMap { bookID in
                    allStories.first(where: { $0.contentUUID == bookID })
                }
                section.stories = newStories
            }
        }
    }
    
    private func loadDataForSection(_ section: DiscoverSection, generallyAvailableStories: [CDBookInternal]) {
        guard !allStories.isEmpty else { return }
        
        var filteredStories: [CDBookInternal] = []
        let userIsSubscribed = AccountManager.shared.userIsSubscribed
        
        switch section.type {
        case .continueReading:
            let inProgressContent = ReadingUserDefaults.getReadingInProgressContent()
            filteredStories = inProgressContent.compactMap { $0 as? CDBookInternal }
        case .forYou:
            let favoriteGenres = currentFavoriteGenresForForYou()

            if !favoriteGenres.isEmpty {
                // Filter stories that match any of the user's favorite genres
                let forYouStories = generallyAvailableStories
                    .filter { story in
                        guard let storyGenreString = story.genreString else { return false }
                        guard let storyGenre = BookInternalGenre(rawValue: storyGenreString) else { return false }
                        return favoriteGenres.contains(storyGenre)
                    }
                    .filter { !$0.isCompleted() } // Exclude completed books
                    .filter { userIsSubscribed || $0.isAvailableToUser }
                
                if didCompleteOnboardingThisSession {
                    filteredStories = forYouStories.sorted(by: { $0.readerCount > $1.readerCount })
                } else {
                    filteredStories = sessionStableForYouStories(forYouStories, favoriteGenres: favoriteGenres)
                }
            } else {
                // No favorite genres selected - show empty for now (will show prompt cell)
                forYouSessionOrderUUIDs.removeAll()
                forYouSessionGenresFingerprint = nil
                filteredStories = []
            }
        case .earlyAccess:
            // Only show books that are in early access
            // Sort by soonest unlock date first (parse date strings)
            filteredStories = allStories
                .filter { $0.isEarlyAccess }
                .sorted(by: { book1, book2 in
                    // Parse date strings for comparison
                    let date1 = book1.availableForAllDateString.flatMap { DateFormatters.earlyAccessDateFormatter.date(from: $0) } ?? Date.distantFuture
                    let date2 = book2.availableForAllDateString.flatMap { DateFormatters.earlyAccessDateFormatter.date(from: $0) } ?? Date.distantFuture
                    
                    return date1 < date2
                })
        case .latestReleases:
            filteredStories = generallyAvailableStories
                .filter { userIsSubscribed || $0.isAvailableToUser }
                .sorted(by: { $0.datePublished ?? Date() > $1.datePublished ?? Date() })
        case .zeroToThirtyMinutes:
            filteredStories = generallyAvailableStories
                .filter { $0.listeningTimeMinutesRounded <= 30 }
                .filter { userIsSubscribed || $0.isAvailableToUser }
                .shuffled()
        case .thirtyToNinetyMinutes:
            filteredStories = generallyAvailableStories
                .filter { $0.listeningTimeMinutesRounded > 30 && $0.listeningTimeMinutesRounded <= 90 }
                .filter { userIsSubscribed || $0.isAvailableToUser }
                .shuffled()
        case .ninetyPlusMinutes:
            filteredStories = generallyAvailableStories
                .filter { $0.listeningTimeMinutesRounded > 90 }
                .filter { userIsSubscribed || $0.isAvailableToUser }
                .shuffled()
        case .mostPopular:
            filteredStories = generallyAvailableStories
                .filter { userIsSubscribed || $0.isAvailableToUser }
                .sorted { $0.readerCount > $1.readerCount }
        case .heroCarousel:
            if let bookIDs = section.bookIDs {
                filteredStories = bookIDs.compactMap { bookID in
                    allStories.first(where: { $0.contentUUID == bookID })
                }
            } else {
                filteredStories = []
            }
        case .favoriteGenresCTA, .searchPromptCTA, .genreShortcuts:
            // CTA sections don't need stories - it's a static widget
            filteredStories = []
        case .thisWeeksTopTen:
            // Use bookIDs from the section if available
            if let bookIDs = section.bookIDs {
                filteredStories = bookIDs.compactMap { bookID in
                    allStories.first(where: { $0.contentUUID == bookID })
                }
            } else {
                filteredStories = []
            }
        case .genre:
            // Use genre from the section if available
            if let genre = section.genre {
                filteredStories = generallyAvailableStories
                    .filter { $0.genreString == genre.rawValue }
                    .filter { userIsSubscribed || $0.isAvailableToUser }
                    .shuffled()
            } else {
                filteredStories = []
            }
        case .becauseYouRead:
            // Get user's most recently completed book
            guard
                let user = AccountManager.shared.user,
                !user.completedBookInternalUUIDs.isEmpty,
                let mostRecentCompletedUUID = user.completedBookInternalUUIDs.last,
                let sourceBook = CoreDataBookInternalManager.shared.getWithUUID(uuid: mostRecentCompletedUUID) else {
                filteredStories = []
                break
            }

            let sourceGenre = sourceBook.genre

            // Set dynamic title with the source book's title
            section.dynamicTitle = "Because you listened to \(sourceBook.title ?? "This Story")"

            // Filter stories by same genre, excluding the source book and already read/started stories
            let bookUUIDsWithProgress = ReadingUserDefaults.bookUUIDsWithProgress()
            filteredStories = generallyAvailableStories
                .filter { $0.genreString == sourceGenre.rawValue }
                .filter { $0.contentUUID != mostRecentCompletedUUID }
                .filter { !$0.isCompleted() }
                .filter { !bookUUIDsWithProgress.contains($0.contentUUID) }
                .filter { userIsSubscribed || $0.isAvailableToUser }
                .shuffled()
        case .adultContent:
            filteredStories = generallyAvailableStories
                .filter { $0.containsAdultContent }
                .filter { userIsSubscribed || $0.isAvailableToUser }
                .shuffled()
        }
        
        // Limit to reasonable number for horizontal scrolling
        if filteredStories.count > 30 && section.type != .earlyAccess {
            filteredStories = Array(filteredStories.prefix(30))
        }

        // Logs used for getting data for Screenshots development mode
//        print("Section: \(section.title)")
//        print(filteredStories.compactMap({ $0.uuid }))
        
        section.stories = filteredStories
    }
    
    // MARK: - Actions
    
    @objc private func pullToRefresh() {
        loadInitialData(isPullToRefresh: true)
    }
    
    // MARK: - Loading Indicator

    private func resolvedSkeletonInterfaceStyle() -> UIUserInterfaceStyle {
        AppearanceManager.shared.effectiveInterfaceStyle(
            fallbackTraitCollection: view.window?.traitCollection ?? traitCollection
        )
    }
    
    private func showLoadingIndicator(show: Bool) {
        if show {
            tableView.alpha = 0
            headerContainerView.alpha = 0
            headerContainerView.isHidden = true
            topFadeGradientView.alpha = 0
            topFadeGradientView.isHidden = true

            if skeletonView == nil {
                let skeleton = HomeSkeletonView()
                view.addSubviewForConstraints(skeleton)
                NSLayoutConstraint.activate([
                    skeleton.topAnchor.constraint(equalTo: tableView.topAnchor),
                    skeleton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    skeleton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    skeleton.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ])
                skeletonView = skeleton
            }
            skeletonView?.startAnimating(interfaceStyle: resolvedSkeletonInterfaceStyle())
        } else {
            guard let skeleton = skeletonView else {
                tableView.alpha = 1
                headerContainerView.alpha = 1
                headerContainerView.isHidden = false
                topFadeGradientView.alpha = 1
                topFadeGradientView.isHidden = false
                return
            }

            skeleton.stopAnimating()
            skeleton.removeFromSuperview()
            skeletonView = nil

            self.tableView.alpha = 1
            self.headerContainerView.alpha = 1
            self.headerContainerView.isHidden = false
            self.topFadeGradientView.alpha = 1
            self.topFadeGradientView.isHidden = false
        }
    }
    
    // MARK: - Offline Banner
    
    private func showOfflineBanner(_ show: Bool) {
        DispatchQueue.main.async {
            print("Network Monitoring: Show banner on HomeVC: \(show)")
            self.isBannerCurrentlyVisible = show
            self.offlineBanner.isHidden = !show
            self.offlineBanner.updateStatus(isOffline: show)
            self.updateTableTopConstraint()
        }
    }
    
    @objc func connectivityDidChange(_ notification: Notification) {
        guard let isConnected = notification.userInfo?["isConnected"] as? Bool else { return }
        
        DispatchQueue.main.async {
            if isConnected {
                // Back online
                if self.hasFailedRequests {
                    if !self.isBannerCurrentlyVisible {
                        self.showOfflineBanner(true)
                    }
                    self.loadInitialData(isPullToRefresh: false)
                } else {
                    if self.isBannerCurrentlyVisible {
                        self.showOfflineBanner(false)
                    }
                }
            } else {
                if !self.isBannerCurrentlyVisible {
                    self.showOfflineBanner(true)
                }
            }
        }
    }
    
    private func updateTableTopConstraint() {
        tableViewTopConstraint?.isActive = false
        headerTopConstraint?.isActive = false

        if offlineBanner.isHidden {
            tableViewTopConstraint = tableView.topAnchor.constraint(equalTo: view.topAnchor)
            headerTopConstraint = headerContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        } else {
            tableViewTopConstraint = tableView.topAnchor.constraint(equalTo: offlineBanner.bottomAnchor)
            headerTopConstraint = headerContainerView.topAnchor.constraint(equalTo: offlineBanner.bottomAnchor)
        }

        tableViewTopConstraint?.isActive = true
        headerTopConstraint?.isActive = true
        view.layoutIfNeeded()
    }
    
    // MARK: - Header Actions (for tab experiment)
    
    private func showImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = .fullScreen
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    private func switchToSearchTab(initialFilters: CDBookInternalSearchObject? = nil) {
        if let tabBarController = tabBarController as? AppTabBarController {
            tabBarController.showSearch(initialFilters: initialFilters)
            return
        }

        let searchVC = SearchVC(initialFilters: initialFilters ?? CDBookInternalSearchObject())
        searchVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(searchVC, animated: true)
    }

    private func presentFavoriteGenreSelection() {
        // Get current genres from user or UserDefaults (for guest users)
        var currentGenres: [BookInternalGenre] = []
        if let user = AccountManager.shared.user {
            currentGenres = user.favoriteGenres
        } else if let guestGenres = getGuestSelectedGenres() {
            currentGenres = guestGenres
        }

        let genreSelectionVC = FavoriteGenreSelectionVC(currentGenres: currentGenres)
        genreSelectionVC.preferredSheetSizing = .fill
        genreSelectionVC.delegate = self
        genreSelectionVC.tapToDismissEnabled = false
        genreSelectionVC.panToDismissEnabled = false
        present(genreSelectionVC, animated: true)
    }

    private func presentGenreFilterSelection() {
        let genreVC = BookInternalGenreSelectionVC(selectedGenre: nil)
        genreVC.delegate = self
        present(genreVC, animated: true)
    }

    private func presentReadingTimeSelection() {
        let readingTimeVC = ReadingTimeSelectionVC()
        readingTimeVC.delegate = self
        present(readingTimeVC, animated: true)
    }

    private func presentMoreFilters() {
        let filtersVC = CDBookInternalFiltersVC(currentFilters: CDBookInternalSearchObject())
        filtersVC.delegate = self
        present(filtersVC, animated: true)
    }

    private func setupSearchBarHandlers() {
        searchBarView.searchBarTappedHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async { self.switchToSearchTab() }
        }
        searchBarView.genreFilterTappedHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async { self.presentGenreFilterSelection() }
        }
        searchBarView.readingTimeFilterTappedHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async { self.presentReadingTimeSelection() }
        }
        searchBarView.moreFilterTappedHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async { self.presentMoreFilters() }
        }
    }
}

// MARK: - UITableViewDataSource

extension HomeVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedSections.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = displayedSections[indexPath.row]
        let stories = section.stories

        switch section.type {
        case .forYou:
            // Show prompt cell if user has no favorite genres (check both Firebase and UserDefaults)
            let userHasFavoriteGenres = AccountManager.shared.user?.favoriteGenres.isEmpty == false
            let guestHasFavoriteGenres = getGuestSelectedGenres()?.isEmpty == false
            let hasAnyFavoriteGenres = userHasFavoriteGenres || guestHasFavoriteGenres

            if !hasAnyFavoriteGenres {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ForYouPromptCell", for: indexPath) as! ForYouPromptTVC
                cell.selectGenresTappedHandler = { [weak self] in
                    guard let self else { return }
                    DispatchQueue.main.async {
                        self.presentFavoriteGenreSelection()
                    }
                }
                cell.selectionStyle = .none
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "BookInternalCarouselTVC", for: indexPath) as! ShortStoryCarouselTVC
                cell.configure(with: section, stories: stories)

                cell.tappedBookInternalHandler = { [weak self] cdBookInternal in
                    guard let self else { return }
                    DispatchQueue.main.async {
                        if !cdBookInternal.isAvailableToUser {
                            self.displayPaywall(placement: .earlyAccess, bookInternal: cdBookInternal)
                        } else {
                            self.showBookDetails(
                                cdBookInternal,
                                                                sourceItems: stories.map { $0 as ReadableContentMetadata }
                            )
                        }
                    }
                }

                cell.tappedEditHandler = { [weak self] in
                    guard let self else { return }
                    DispatchQueue.main.async {
                        self.presentFavoriteGenreSelection()
                    }
                }

                cell.selectionStyle = .none
                return cell
            }

        case .searchPromptCTA:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchPromptCell", for: indexPath) as! ShortStorySearchPromptTVC
            cell.ctaTappedHandler = { [weak self] in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.switchToSearchTab()
                }
            }
            cell.selectionStyle = .none
            return cell

        case .favoriteGenresCTA:
            assertionFailure("favoriteGenresCTA should only be used by PersonalizedHomeVC")
            return UITableViewCell()

        case .genreShortcuts:
            let cell = tableView.dequeueReusableCell(withIdentifier: "GenreTilesCarouselCell", for: indexPath) as! GenreTilesCarouselTVC
            cell.configure(with: section, presentations: genreCardPresentations)
            cell.tappedGenreHandler = { [weak self] genre in
                guard let self else { return }
                DispatchQueue.main.async {
                    let filters = CDBookInternalSearchObject()
                    filters.genre = genre
                    self.switchToSearchTab(initialFilters: filters)
                }
            }
            return cell

        case .continueReading:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContinueReadingCarouselCell", for: indexPath) as! ContinueReadingCarouselTVC
            cell.configure(with: section, stories: stories)

            cell.tappedContinueHandler = { [weak self] cdBookInternal in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.handleContinueTapped(cdBookInternal)
                }
            }

            cell.tappedBrowseStoriesHandler = { [weak self] in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.switchToSearchTab()
                }
            }
            cell.selectionStyle = .none
            return cell

        case .earlyAccess:
            let cell = tableView.dequeueReusableCell(withIdentifier: "EarlyAccessCarouselTVC", for: indexPath) as! ShortStoryEarlyAccessCarouselTVC
            cell.configure(with: section, stories: stories)

            cell.tappedBookInternalHandler = { [weak self] cdBookInternal in
                guard let self else { return }
                DispatchQueue.main.async {
                    if !cdBookInternal.isAvailableToUser {
                        self.displayPaywall(placement: .earlyAccess, bookInternal: cdBookInternal)
                    } else {
                        self.showBookDetails(
                            cdBookInternal,
                                                        sourceItems: stories.map { $0 as ReadableContentMetadata }
                        )
                    }
                }
            }

            cell.tappedUnlockPlusHandler = { [weak self] in
                guard let self else { return }
                DispatchQueue.main.async {
                    AnalyticsManager.shared.trackTappedDiscoverEarlyAccessCTA()
                    self.displayPaywall(placement: .earlyAccess, bookInternal: nil)
                }
            }

            cell.tappedViewAllHandler = { [weak self] in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.showEarlyAccessVC()
                }
            }

            cell.selectionStyle = .none
            return cell

        case .heroCarousel:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeroCarouselCell", for: indexPath) as! HeroCarouselTVC
            cell.configure(with: stories)

            cell.tappedBookInternalHandler = { [weak self] story in
                guard let self else { return }
                DispatchQueue.main.async {
                    if !story.isAvailableToUser {
                        self.displayPaywall(placement: .earlyAccess, bookInternal: story)
                    } else {
                        self.showBookDetails(
                            story,
                                                        sourceItems: stories.map { $0 as ReadableContentMetadata }
                        )
                    }
                }
            }

            cell.selectionStyle = .none
            return cell

        case .thisWeeksTopTen, .zeroToThirtyMinutes, .thirtyToNinetyMinutes, .ninetyPlusMinutes, .mostPopular, .latestReleases, .genre, .becauseYouRead, .adultContent:
            let tappedBookInternalHandler: (CDBookInternal) -> Void = { [weak self] cdBookInternal in
                guard let self else { return }
                DispatchQueue.main.async {
                    if !cdBookInternal.isAvailableToUser {
                        self.displayPaywall(placement: .earlyAccess, bookInternal: cdBookInternal)
                    } else {
                        self.showBookDetails(
                            cdBookInternal,
                                                        sourceItems: stories.map { $0 as ReadableContentMetadata }
                        )
                    }
                }
            }

            let tappedShowMoreChevronHandler: () -> Void = { [weak self] in
                guard let self else { return }
                DispatchQueue.main.async {
                    let filters = CDBookInternalSearchObject()
                    switch section.type {
                    case .zeroToThirtyMinutes:
                        filters.maxReadingTime = 30
                    case .thirtyToNinetyMinutes:
                        filters.minReadingTime = 30
                        filters.maxReadingTime = 90
                    case .ninetyPlusMinutes:
                        filters.minReadingTime = 90
                    case .genre:
                        guard let genre = section.genre else { return }
                        filters.genre = genre
                    default:
                        return
                    }
                    self.switchToSearchTab(initialFilters: filters)
                }
            }

            if shouldUseSubtitleCarousel(for: section) {
                let cell = tableView.dequeueReusableCell(withIdentifier: "BookInternalCarouselSubtitleTVC", for: indexPath) as! ShortStoryCarouselSubtitleTVC
                cell.configure(with: section, stories: stories)
                cell.tappedBookInternalHandler = tappedBookInternalHandler
                cell.tappedShowMoreChevronHandler = tappedShowMoreChevronHandler
                cell.selectionStyle = .none
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "BookInternalCarouselTVC", for: indexPath) as! ShortStoryCarouselTVC
                cell.configure(with: section, stories: stories)
                cell.tappedBookInternalHandler = tappedBookInternalHandler
                cell.tappedShowMoreChevronHandler = tappedShowMoreChevronHandler
                cell.selectionStyle = .none
                return cell
            }
        }
    }
}

// MARK: - UITableViewDelegate

extension HomeVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = displayedSections[indexPath.row]

        if section.type == .genreShortcuts {
            return GenreTilesCarouselTVC.Layout.totalHeight
        } else if section.type.isCTASection {
            return UITableView.automaticDimension
        } else if section.type == .continueReading {
            return ContinueReadingCarouselTVC.Layout.totalHeight
        } else if section.type == .earlyAccess {
            return ShortStoryEarlyAccessCarouselTVC.Layout.totalHeight
        } else if section.type == .heroCarousel {
            return HeroCarouselTVC.Layout.totalHeight
        } else if section.type == .forYou {
            let userHasFavoriteGenres = AccountManager.shared.user?.favoriteGenres.isEmpty == false
            let guestHasFavoriteGenres = getGuestSelectedGenres()?.isEmpty == false
            let hasAnyFavoriteGenres = userHasFavoriteGenres || guestHasFavoriteGenres
            if !hasAnyFavoriteGenres {
                return UITableView.automaticDimension
            } else {
                return ShortStoryCarouselTVC.Layout.totalHeight
            }
        } else if shouldUseSubtitleCarousel(for: section) {
            return ShortStoryCarouselSubtitleTVC.Layout.totalHeight
        } else {
            return ShortStoryCarouselTVC.Layout.totalHeight
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row < displayedSections.count else { return }

        let section = displayedSections[indexPath.row]

        if let carouselCell = cell as? ShortStoryCarouselTVC {
            carouselTVCOffsets[section.uuid] = carouselCell.getContentOffset()
        } else if let subtitleCarouselCell = cell as? ShortStoryCarouselSubtitleTVC {
            carouselTVCOffsets[section.uuid] = subtitleCarouselCell.getContentOffset()
        } else if let heroCarouselCell = cell as? HeroCarouselTVC {
            heroCarouselTVCOffsets[section.uuid] = heroCarouselCell.getContentOffset()
        } else if let genreTilesCell = cell as? GenreTilesCarouselTVC {
            carouselTVCOffsets[section.uuid] = genreTilesCell.getContentOffset()
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row < displayedSections.count else { return }

        let section = displayedSections[indexPath.row]

        if let carouselCell = cell as? ShortStoryCarouselTVC {
            if let offset = carouselTVCOffsets[section.uuid] {
                DispatchQueue.main.async {
                    carouselCell.setContentOffset(offset)
                }
            }
        } else if let subtitleCarouselCell = cell as? ShortStoryCarouselSubtitleTVC {
            if let offset = carouselTVCOffsets[section.uuid] {
                DispatchQueue.main.async {
                    subtitleCarouselCell.setContentOffset(offset)
                }
            }
        } else if let heroCarouselCell = cell as? HeroCarouselTVC {
            if let offset = heroCarouselTVCOffsets[section.uuid] {
                DispatchQueue.main.async {
                    heroCarouselCell.setContentOffset(offset)
                }
            }
        } else if let genreTilesCell = cell as? GenreTilesCarouselTVC {
            if let offset = carouselTVCOffsets[section.uuid] {
                DispatchQueue.main.async {
                    genreTilesCell.setContentOffset(offset)
                }
            }
        }
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }

}

extension HomeVC {
    private func pauseVisibleHeroCarouselAutoScroll() {
        tableView.visibleCells.forEach { cell in
            (cell as? HeroCarouselTVC)?.pauseAutoScroll()
        }
    }

    private func resumeVisibleHeroCarouselAutoScroll() {
        tableView.visibleCells.forEach { cell in
            (cell as? HeroCarouselTVC)?.resumeAutoScrollIfNeeded()
        }
    }

    private func handleContinueTapped(_ story: CDBookInternal) {
        let metadata = CoreDataBookInternalManager.shared.getWithUUID(uuid: story.contentUUID) ?? story
        let lastReadMode = ReadingUserDefaults.getLastReadMode(for: metadata.contentUUID) ?? .text

        if lastReadMode == .audio {
            if resumeCachedAudiobookIfAllowed(
                bookInternal: metadata,
                navigationController: navigationController,
                onBeforePush: { [weak self] in self?.pauseVisibleHeroCarouselAutoScroll() }
            ) {
                return
            } else if !story.isAvailableToUser {
                displayPaywall(placement: .earlyAccess, bookInternal: story)
            } else {
                showBookDetails(metadata)
            }
            return
        }

        if let content = APIBookInternalContentManager.getBookInternalContent(bookUUID: metadata.contentUUID) {
            presentReadingModePaywall(bookInternal: metadata) { [weak self] in
                guard let self else { return }
                let bookDetailVC = BookDetailVC(contentMetadata: metadata)
                bookDetailVC.hidesBottomBarWhenPushed = true

                let readingVC = ReadingVC(metadata: metadata, content: content)
                if let navigationController {
                    var viewControllers = navigationController.viewControllers
                    viewControllers.append(bookDetailVC)
                    viewControllers.append(readingVC)
                    pauseVisibleHeroCarouselAutoScroll()
                    navigationController.setViewControllers(viewControllers, animated: true)
                }
            }
            return
        }

        if !story.isAvailableToUser {
            displayPaywall(placement: .earlyAccess, bookInternal: story)
        } else {
            showBookDetails(metadata)
        }
    }

    private func showBookDetails(_ bookMetadata: ReadableContentMetadata,
                                 sourceItems: [ReadableContentMetadata]? = nil) {
        pauseVisibleHeroCarouselAutoScroll()
        let bookDetailVC = BookDetailVC(contentMetadata: bookMetadata)
        bookDetailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(bookDetailVC, animated: true)
    }

    private func showEarlyAccessVC() {
        let earlyAccessVC = EarlyAccessVC()
        earlyAccessVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(earlyAccessVC, animated: true)
    }
}

extension HomeVC {
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
                    AnalyticsManager.shared.trackPaywallRestorePurchasesSuccess()
                    self.refreshForSubscriberStatus()
                }
            }
        }
        Superwall.shared.register(placement: placement.rawValue, params: nil, handler: handler)
    }
    
    @objc func refreshForSubscriberStatus() {
        headerView.update()
        loadDataForAllSections()
        refreshDisplayedSections()
        tableView.reloadData()
    }
}

// MARK: - UIImagePickerControllerDelegate

extension HomeVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
        headerView.showImageLoadingIndicator(show: true)
        AccountManager.shared.uploadProfileImage(image: image) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .progress: break
            case .error:
                DispatchQueue.main.async {
                    self.headerView.showImageLoadingIndicator(show: false)
                    self.headerView.update()
                    self.showUploadRetryError(image: image)
                }
            case .explicit:
                DispatchQueue.main.async {
                    self.headerView.showImageLoadingIndicator(show: false)
                    self.headerView.update()
                    self.showPossibleInappropriateContentAlert()
                }
            case .downloadURL:
                DispatchQueue.main.async {
                    AppNotifiers.shared.shouldReloadAccountVC = true

                    self.headerView.showImageLoadingIndicator(show: false)
                    self.headerView.update()
                }
            }
        }
    }

    private func showPossibleInappropriateContentAlert() {
        AnalyticsManager.shared.trackExplicitImageDetected()
        headerView.showImageLoadingIndicator(show: false)
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

// MARK: - FavoriteGenreSelectionDelegate

extension HomeVC: FavoriteGenreSelectionDelegate {
    func didUpdateFavoriteGenres(_ genres: [BookInternalGenre]) {
        forYouSessionOrderUUIDs.removeAll()
        forYouSessionGenresFingerprint = nil
        // Reload the forYou section to show updated content
        loadDataForAllSections()
        refreshDisplayedSections()
        tableView.reloadData()
    }
}

extension HomeVC: HomeTabControlling {}

// MARK: - BookInternalGenreSelectionDelegate

extension HomeVC: BookInternalGenreSelectionDelegate {
    func didSelectGenre(_ genre: BookInternalGenre) {
        let filters = CDBookInternalSearchObject()
        filters.genre = genre
        switchToSearchTab(initialFilters: filters)
    }

    func didClearGenre() {}
}

// MARK: - ReadingTimeSelectionDelegate

extension HomeVC: ReadingTimeSelectionDelegate {
    func didSelectReadingTime(_ bucket: CDBookInternalLengthBucket) {
        let filters = CDBookInternalSearchObject()
        filters.setLengthBucket(bucket)
        switchToSearchTab(initialFilters: filters)
    }
}

// MARK: - BookInternalFiltersVCDelegate

extension HomeVC: BookInternalFiltersVCDelegate {
    func didApplyFilters(_ filters: CDBookInternalSearchObject) {
        switchToSearchTab(initialFilters: filters)
    }

    func didClearFilters() {
        // No-op — stay on Discover
    }
}

private extension HomeVC {
    func showStatsVC() {
        let statsVC = StatsVC()
        let navController = UINavigationController(rootViewController: statsVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
    }
}

// Testing only
extension HomeVC {
    func showEnhancedBookCompletion() {
        let metadata = CoreDataBookInternalManager.shared.getWithUUID(uuid: "07813139-6625-4AD1-98AF-0D85DF6D6CBC")!
        
        let reviewedContentType: ReviewedContentType = .bookInternal
        
        let dismissAction: () -> Void = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.dismiss(animated: true) {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }

        let popupVC = EnhancedBookCompletionPopupVC(metadata: metadata, reviewedContentType: reviewedContentType)
        popupVC.dismissHandler = dismissAction
        popupVC.preferredSheetSizing = .fit
        popupVC.panToDismissEnabled = false
        popupVC.tapToDismissEnabled = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.present(popupVC, animated: true)
        }
    }
}
