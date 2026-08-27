//
//  PersonalizedHomeVC.swift
//  FreeAudiobooks
//
//  Created by OpenAI Codex on 27/03/2026.
//

import UIKit
import SkeletonView
import SuperwallKit

final class PersonalizedHomeVC: UIViewController {

    // MARK: - Properties

    private var allStories: [CDBookInternal] = []
    private var homeEligibleTags: [BookInternalTag] = []
    private var genreCardPresentations: [GenreCardPresentation] = []
    private var displayedPresentations: [PersonalizedHomeSectionPresentation] = []
    private var displayedSections: [DiscoverSection] = []
    private var scrollToSectionUUIDAfterFetch: String?
    private var hasFailedRequests = false
    private var isBannerCurrentlyVisible = false
    private var isFetchInProgress = false
    private var hasCompletedInitialSectionSetup = false
    private var hasPresentedMissingFavoriteGenresSelector = false

    private var carouselTVCOffsets = [String: CGPoint]()
    private var heroCarouselTVCOffsets = [String: CGPoint]()
    private var tagPreviewOffsets = [String: CGPoint]()
    private var genreTilesOffsets = [String: CGPoint]()

    // MARK: - UI

    private let offlineBanner = OfflineBannerView()
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

        if !NetworkMonitor.shared.isConnected {
            showOfflineBanner(true)
        }

        if AppNotifiers.shared.shouldReloadHomeVC {
            AppNotifiers.shared.shouldReloadHomeVC = false
            if !ensureFavoriteGenresSelectionIfNeeded() {
                rebuildFeed()
                tableView.reloadData()
            }
        } else if hasCompletedInitialSectionSetup {
            if !ensureFavoriteGenresSelectionIfNeeded() {
                reloadContinueReadingSection()
            }
        }

        AnalyticsManager.shared.trackDiscoverViewed(homeVariant: .personalized)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - HomeTabControlling

extension PersonalizedHomeVC: HomeTabControlling {
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
}

// MARK: - Setup

private extension PersonalizedHomeVC {
    func setupUI() {
        setupTableView()
        setupTopGradient()
        setupHeaderView()
        setupOfflineBanner()
        setupConstraints()
    }

    func setupTableView() {
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
        tableView.register(HeroCarouselTVC.self, forCellReuseIdentifier: "HeroCarouselCell")
        tableView.register(ShortStoryCarouselSubtitleTVC.self, forCellReuseIdentifier: "BookInternalCarouselSubtitleTVC")
        tableView.register(HomeTagPreviewTVC.self, forCellReuseIdentifier: HomeTagPreviewTVC.reuseIdentifier)
        tableView.register(GenreTilesCarouselTVC.self, forCellReuseIdentifier: "GenreTilesCarouselCell")
        tableView.register(FavoriteGenresCTATVC.self, forCellReuseIdentifier: FavoriteGenresCTATVC.reuseIdentifier)
        tableView.register(ShortStorySearchPromptTVC.self, forCellReuseIdentifier: "SearchPromptCell")
        view.addSubviewForConstraints(tableView)
    }

    func setupTopGradient() {
        topFadeGradientView.isUserInteractionEnabled = false
        updateTopGradientColors()
        topFadeGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        topFadeGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        topFadeGradientView.layer.addSublayer(topFadeGradientLayer)
        view.addSubviewForConstraints(topFadeGradientView)
    }

    func updateTopGradientColors() {
        topFadeGradientLayer.colors = [
            Colours.chromeBackground.cgColor,
            Colours.chromeBackground.cgColor
        ]
    }

    func setupHeaderView() {
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

    func setupOfflineBanner() {
        view.addSubviewForConstraints(offlineBanner)
        offlineBanner.isHidden = true
        offlineBanner.retryTappedHandler = { [weak self] in
            self?.loadInitialData(isPullToRefresh: false)
        }
    }

    func setupConstraints() {
        tableViewTopConstraint = tableView.topAnchor.constraint(equalTo: view.topAnchor)
        headerTopConstraint = headerContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)

        NSLayoutConstraint.activate([
            offlineBanner.topAnchor.constraint(equalTo: view.safeTopAnchor),
            offlineBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            offlineBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            offlineBanner.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            tableViewTopConstraint!,
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            headerTopConstraint!,
            headerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: headerContainerView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),

            searchBarView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            searchBarView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            searchBarView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),
            searchBarView.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor),

            topFadeGradientView.topAnchor.constraint(equalTo: view.topAnchor),
            topFadeGradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topFadeGradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topFadeGradientView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])

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

    func updateHeaderContentInset() {
        headerContainerView.layoutIfNeeded()
        let headerHeight = headerContainerView.frame.height
        guard headerHeight > 0 else { return }

        if tableView.contentInset.top != headerHeight {
            tableView.contentInset.top = headerHeight
            tableView.verticalScrollIndicatorInsets.top = headerHeight
        }
    }
}

// MARK: - Data Loading

private extension PersonalizedHomeVC {
    func loadInitialData(isPullToRefresh: Bool) {
        guard !isFetchInProgress else { return }
        isFetchInProgress = true

        if !isPullToRefresh {
            showLoadingIndicator(show: true)
        }

        let dispatchGroup = DispatchGroup()
        var storiesFailed = false
        var configsFailed = false
        var fetchedStories: [CDBookInternal] = []
        var fetchedHomeEligibleTags: [BookInternalTag] = []

        dispatchGroup.enter()
        APIBookInternalManager.shared.fetchAllShortStories { success, stories in
            if !success {
                storiesFailed = true
            } else {
                fetchedStories = stories
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        BookInternalTagManager.shared.ensureHomeEligibleTags(for: currentFavoriteGenres()) { success, tags in
            if !success {
                configsFailed = true
            }
            fetchedHomeEligibleTags = tags
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        BookInternalTagManager.shared.fetchGenreCharts { success, _ in
            if !success {
                configsFailed = true
            }
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            self.isFetchInProgress = false
            if storiesFailed {
                self.allStories = CoreDataBookInternalManager.shared.getAll()
            } else {
                self.allStories = fetchedStories
            }
            self.homeEligibleTags = fetchedHomeEligibleTags
            self.genreCardPresentations = GenreCardPresentation.buildAll(from: self.allStories)

            let hadFailures = storiesFailed || configsFailed
            if hadFailures {
                self.hasFailedRequests = true
                self.showOfflineBanner(true)
            } else {
                self.hasFailedRequests = false
                if NetworkMonitor.shared.isConnected {
                    self.showOfflineBanner(false)
                }
            }

            if self.allStories.isEmpty && storiesFailed {
                self.showFetchError(isPullToRefresh: isPullToRefresh)
                self.showLoadingIndicator(show: false)
                self.refreshControl.endRefreshing()
                return
            }
            if self.ensureFavoriteGenresSelectionIfNeeded() {
                self.displayedPresentations = []
                self.displayedSections = []
            } else {
                self.rebuildFeed()
            }
            self.headerView.update()

            self.hasCompletedInitialSectionSetup = true
            self.tableView.reloadData()

            if let scrollTarget = self.scrollToSectionUUIDAfterFetch {
                self.scrollToSectionWithUUID(sectionUUID: scrollTarget)
                self.scrollToSectionUUIDAfterFetch = nil
            }

            self.showLoadingIndicator(show: false)
            self.refreshControl.endRefreshing()
        }
    }

    func rebuildFeed() {
        let favoriteGenres = currentFavoriteGenres()
        let completedBookUUIDs = AccountManager.shared.user?.completedBookInternalUUIDs ?? []
        let userID = AccountManager.shared.user?.uuid ?? guestSeedIdentifier(for: favoriteGenres)

        var builder = PersonalizedFeedBuilder(
            favoriteGenres: favoriteGenres,
            allStories: allStories,
            userIsSubscribed: AccountManager.shared.userIsSubscribed,
            userID: userID,
            tags: homeEligibleTags,
            genreCharts: BookInternalTagManager.shared.genreCharts,
            completedBookUUIDs: completedBookUUIDs
        )

        displayedPresentations = builder.buildSections()

        if AppConstants.shared.developmentMode == .screenshots {
            displayedPresentations.removeAll { $0.kind == .earlyAccess || $0.kind == .hero }
        }

        displayedSections = displayedPresentations.enumerated().map { index, presentation in
            presentation.asDiscoverSection(position: index)
        }
    }

    func reloadContinueReadingSection() {
        rebuildFeed()
        tableView.reloadData()
    }

    @discardableResult
    func ensureFavoriteGenresSelectionIfNeeded() -> Bool {
        guard currentFavoriteGenres().isEmpty else {
            hasPresentedMissingFavoriteGenresSelector = false
            return false
        }

        guard !hasPresentedMissingFavoriteGenresSelector else { return true }
        guard presentedViewController as? FavoriteGenreSelectionVC == nil else { return true }

        hasPresentedMissingFavoriteGenresSelector = true
        DispatchQueue.main.async { [weak self] in
            self?.presentFavoriteGenreSelection()
        }
        return true
    }

    func currentFavoriteGenres() -> [BookInternalGenre] {
        if let user = AccountManager.shared.user, !user.favoriteGenres.isEmpty {
            return user.favoriteGenres
        }
        if let guestGenres = getGuestSelectedGenres(), !guestGenres.isEmpty {
            return guestGenres
        }
        return []
    }

    func getGuestSelectedGenres() -> [BookInternalGenre]? {
        if let newGenres = NewOnboardingUserDefaults.getSelectedGenres(), !newGenres.isEmpty {
            return newGenres
        }
        return OnboardingGenreUserDefaults.getSelectedGenres()
    }

    func guestSeedIdentifier(for genres: [BookInternalGenre]) -> String {
        let joinedGenres = genres.map(\.rawValue).joined(separator: "|")
        return joinedGenres.isEmpty ? "guest" : "guest-\(joinedGenres)"
    }
}

// MARK: - Actions

private extension PersonalizedHomeVC {
    @objc func pullToRefresh() {
        loadInitialData(isPullToRefresh: true)
    }

    @objc func showFetchError(isPullToRefresh: Bool) {
        showLoadingIndicator(show: false)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let retryAction = UIAlertAction(title: "Retry", style: .default) { _ in
            self.loadInitialData(isPullToRefresh: isPullToRefresh)
        }

        let alertController = UIAlertController(title: "Network Error",
                                                message: "Please check your connection and try again.",
                                                preferredStyle: .alert)
        alertController.addAction(cancelAction)
        alertController.addAction(retryAction)
        present(alertController, animated: true)
    }

    @objc func handleReadingVCExitNotification() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.handleReadingVCExitNotification()
            }
            return
        }

        guard hasCompletedInitialSectionSetup else { return }
        reloadContinueReadingSection()
        headerView.update()
    }

    func handlePendingAction() {
        if let action = AppNotifiers.shared.launchActionNeedsHandling {
            handleLaunchAction(action)
        }
    }

    func handleLaunchAction(_ action: LaunchAction) {
        switch action {
        case .bookInternal(let bookUUID):
            if let bookMetadata = CoreDataBookInternalManager.shared.getWithUUID(uuid: bookUUID) {
                showBookDetails(bookMetadata)
            } else {
                APIBookInternalManager.shared.fetchStoriesWithIDs(uuids: [bookUUID]) { success in
                    guard success,
                          let bookMetadata = CoreDataBookInternalManager.shared.getWithUUID(uuid: bookUUID) else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.showBookDetails(bookMetadata)
                    }
                }
            }
        case .savedBooks:
            (tabBarController as? AppTabBarController)?.selectTab(tab: .bookshelf)
        case .roadmap:
            let vc = RoadmapVC(wasPresented: false)
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case .section(let sectionUUID):
            scrollToSectionWithUUID(sectionUUID: sectionUUID)
        }

        AppNotifiers.shared.launchActionNeedsHandling = nil
    }
}

// MARK: - Search Bar

private extension PersonalizedHomeVC {
    func setupSearchBarHandlers() {
        searchBarView.searchBarTappedHandler = { [weak self] in
            self?.switchToSearchTab()
        }
        searchBarView.genreFilterTappedHandler = { [weak self] in
            self?.presentGenreFilterSelection()
        }
        searchBarView.readingTimeFilterTappedHandler = { [weak self] in
            self?.presentReadingTimeSelection()
        }
        searchBarView.moreFilterTappedHandler = { [weak self] in
            self?.presentMoreFilters()
        }
    }

    func switchToSearchTab(initialFilters: CDBookInternalSearchObject? = nil) {
        if let tabBarController = tabBarController as? AppTabBarController {
            tabBarController.showSearch(initialFilters: initialFilters)
            return
        }

        let searchVC = SearchVC(initialFilters: initialFilters ?? CDBookInternalSearchObject())
        searchVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(searchVC, animated: true)
    }

    func presentGenreFilterSelection() {
        let genreVC = BookInternalGenreSelectionVC(selectedGenre: nil)
        genreVC.delegate = self
        present(genreVC, animated: true)
    }

    func presentReadingTimeSelection() {
        let readingTimeVC = ReadingTimeSelectionVC()
        readingTimeVC.delegate = self
        present(readingTimeVC, animated: true)
    }

    func presentMoreFilters() {
        let filtersVC = CDBookInternalFiltersVC(currentFilters: CDBookInternalSearchObject())
        filtersVC.delegate = self
        present(filtersVC, animated: true)
    }

    func presentFavoriteGenreSelection() {
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
}

// MARK: - Loading / Offline

private extension PersonalizedHomeVC {
    func resolvedSkeletonInterfaceStyle() -> UIUserInterfaceStyle {
        AppearanceManager.shared.effectiveInterfaceStyle(
            fallbackTraitCollection: view.window?.traitCollection ?? traitCollection
        )
    }

    func showLoadingIndicator(show: Bool) {
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
            return
        }

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

        tableView.alpha = 1
        headerContainerView.alpha = 1
        headerContainerView.isHidden = false
        topFadeGradientView.alpha = 1
        topFadeGradientView.isHidden = false
    }

    func showOfflineBanner(_ show: Bool) {
        DispatchQueue.main.async {
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
                if self.hasFailedRequests {
                    if !self.isBannerCurrentlyVisible {
                        self.showOfflineBanner(true)
                    }
                    self.loadInitialData(isPullToRefresh: false)
                } else if self.isBannerCurrentlyVisible {
                    self.showOfflineBanner(false)
                }
            } else if !self.isBannerCurrentlyVisible {
                self.showOfflineBanner(true)
            }
        }
    }

    func updateTableTopConstraint() {
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
}

// MARK: - UITableViewDataSource

extension PersonalizedHomeVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayedSections.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = displayedSections[indexPath.row]
        let stories = section.stories
        let presentation = displayedPresentations[indexPath.row]

        if presentation.kind == .tagBrowser {
            let cell = tableView.dequeueReusableCell(withIdentifier: HomeTagPreviewTVC.reuseIdentifier, for: indexPath) as! HomeTagPreviewTVC
            cell.configure(title: presentation.title, tags: presentation.previewTags)
            cell.tappedTagHandler = { [weak self] tag in
                let viewController = TagResultsVC(tag: tag)
                viewController.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(viewController, animated: true)
            }
            cell.tappedViewAllHandler = { [weak self] in
                self?.handleSeeAllTapped(for: presentation)
            }
            cell.selectionStyle = .none
            return cell
        }

        switch section.type {
        case .genreShortcuts:
            let cell = tableView.dequeueReusableCell(withIdentifier: "GenreTilesCarouselCell", for: indexPath) as! GenreTilesCarouselTVC
            cell.configure(with: section, presentations: genreCardPresentations)
            cell.tappedGenreHandler = { [weak self] genre in
                let filters = CDBookInternalSearchObject()
                filters.genre = genre
                self?.switchToSearchTab(initialFilters: filters)
            }
            cell.selectionStyle = .none
            return cell

        case .favoriteGenresCTA:
            let cell = tableView.dequeueReusableCell(withIdentifier: FavoriteGenresCTATVC.reuseIdentifier, for: indexPath) as! FavoriteGenresCTATVC
            cell.configure(title: presentation.title, subtitle: presentation.subtitle)
            cell.tappedHandler = { [weak self] in
                self?.presentFavoriteGenreSelection()
            }
            cell.selectionStyle = .none
            return cell

        case .searchPromptCTA:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchPromptCell", for: indexPath) as! ShortStorySearchPromptTVC
            cell.ctaTappedHandler = { [weak self] in
                self?.switchToSearchTab()
            }
            cell.selectionStyle = .none
            return cell

        case .continueReading:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContinueReadingCarouselCell", for: indexPath) as! ContinueReadingCarouselTVC
            cell.configure(with: section, stories: stories)
            cell.tappedContinueHandler = { [weak self] story in
                self?.handleContinueTapped(story)
            }
            cell.tappedBrowseStoriesHandler = { [weak self] in
                self?.switchToSearchTab()
            }
            cell.selectionStyle = .none
            return cell

        case .earlyAccess:
            let cell = tableView.dequeueReusableCell(withIdentifier: "EarlyAccessCarouselTVC", for: indexPath) as! ShortStoryEarlyAccessCarouselTVC
            let mode: ShortStoryEarlyAccessCarouselTVC.Mode = AccountManager.shared.userIsSubscribed ? .subscriberExclusive : .upsell
            cell.configure(title: section.title, stories: stories, mode: mode)
            cell.tappedBookInternalHandler = { [weak self] story in
                guard let self else { return }
                if !story.isAvailableToUser {
                    self.displayPaywall(placement: .earlyAccess, bookInternal: story)
                } else {
                    self.showBookDetails(story,
                                                                                  sourceItems: stories.map { $0 as ReadableContentMetadata })
                }
            }
            cell.tappedUnlockPlusHandler = { [weak self] in
                guard let self else { return }
                AnalyticsManager.shared.trackTappedDiscoverEarlyAccessCTA()
                self.displayPaywall(placement: .earlyAccess, bookInternal: nil)
            }
            cell.tappedViewAllHandler = { [weak self] in
                self?.handleSeeAllTapped(for: presentation)
            }
            cell.selectionStyle = .none
            return cell

        case .heroCarousel:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeroCarouselCell", for: indexPath) as! HeroCarouselTVC
            cell.configure(with: stories)
            cell.tappedBookInternalHandler = { [weak self] story in
                guard let self else { return }
                if !story.isAvailableToUser {
                    self.displayPaywall(placement: .earlyAccess, bookInternal: story)
                } else {
                    self.showBookDetails(story,
                                                                                  sourceItems: stories.map { $0 as ReadableContentMetadata })
                }
            }
            cell.selectionStyle = .none
            return cell

        case .thisWeeksTopTen, .mostPopular, .latestReleases, .genre, .becauseYouRead:
            let tappedBookInternalHandler: (CDBookInternal) -> Void = { [weak self] story in
                guard let self else { return }
                if !story.isAvailableToUser {
                    self.displayPaywall(placement: .earlyAccess, bookInternal: story)
                } else {
                    self.showBookDetails(story,
                                                                                  sourceItems: stories.map { $0 as ReadableContentMetadata })
                }
            }

            let tappedShowMoreChevronHandler: () -> Void = { [weak self] in
                self?.handleSeeAllTapped(for: presentation)
            }

            if shouldUseSubtitleCarousel(for: section) {
                let cell = tableView.dequeueReusableCell(withIdentifier: "BookInternalCarouselSubtitleTVC", for: indexPath) as! ShortStoryCarouselSubtitleTVC
                cell.configure(with: section, stories: stories)
                cell.tappedBookInternalHandler = tappedBookInternalHandler
                cell.tappedShowMoreChevronHandler = tappedShowMoreChevronHandler
                cell.selectionStyle = .none
                return cell
            }

            let cell = tableView.dequeueReusableCell(withIdentifier: "BookInternalCarouselTVC", for: indexPath) as! ShortStoryCarouselTVC
            cell.configure(with: section, stories: stories)
            cell.tappedBookInternalHandler = tappedBookInternalHandler
            cell.tappedShowMoreChevronHandler = tappedShowMoreChevronHandler
            cell.selectionStyle = .none
            return cell

        default:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            return cell
        }
    }

    func shouldUseSubtitleCarousel(for section: DiscoverSection) -> Bool {
        let subtitle = (section.subtitle ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return !subtitle.isEmpty && section.type.supportsSubtitle
    }

    func handleSeeAllTapped(for presentation: PersonalizedHomeSectionPresentation) {
        if presentation.kind == .tagBrowser {
            let viewController = TagSelectionVC(genres: presentation.browseGenres,
                                                titleText: tagBrowserTitle(for: presentation))
            viewController.didSelectTag = { [weak self] tag in
                let resultsVC = TagResultsVC(tag: tag)
                resultsVC.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(resultsVC, animated: true)
            }
            present(viewController, animated: true)
            return
        }

        if presentation.kind == .earlyAccess {
            if let genre = presentation.genre {
                let filters = CDBookInternalSearchObject()
                filters.genre = genre
                switchToSearchTab(initialFilters: filters)
            } else {
                showEarlyAccessVC()
            }
            return
        }

        if let tag = presentation.tag {
            let viewController: UIViewController
            if let bookInternalTag = bookInternalTag(for: tag, genre: presentation.genre) {
                viewController = TagResultsVC(tag: bookInternalTag)
            } else {
                viewController = GenreResultsVC(source: .tag(title: presentation.title,
                                                             tag: tag,
                                                             genre: presentation.genre))
            }
            viewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(viewController, animated: true)
            return
        }

        guard let genre = presentation.genre else { return }
        let filters = CDBookInternalSearchObject()
        filters.genre = genre
        switchToSearchTab(initialFilters: filters)
    }

    func bookInternalTag(for tag: String, genre: BookInternalGenre?) -> BookInternalTag? {
        homeEligibleTags.first {
            $0.isHomeEligible && $0.tag == tag && (genre == nil || $0.genre == genre)
        }
    }

    func tagBrowserTitle(for presentation: PersonalizedHomeSectionPresentation) -> String {
        if presentation.browseGenres.count == 1, let genre = presentation.browseGenres.first {
            return "\(genre.displayString) tags"
        }
        return "Your genre tags"
    }
}

// MARK: - UITableViewDelegate

extension PersonalizedHomeVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = displayedSections[indexPath.row]
        let presentation = displayedPresentations[indexPath.row]

        if presentation.kind == .tagBrowser {
            let containerWidth = max(tableView.bounds.width, view.bounds.width, UIScreen.main.bounds.width)
            return HomeTagPreviewTVC.Layout.totalHeight(for: presentation.previewTags,
                                                        containerWidth: containerWidth)
        } else if section.type == .genreShortcuts {
            return GenreTilesCarouselTVC.Layout.totalHeight
        } else if section.type.isCTASection {
            return UITableView.automaticDimension
        } else if section.type == .continueReading {
            return ContinueReadingCarouselTVC.Layout.totalHeight
        } else if section.type == .earlyAccess {
            return ShortStoryEarlyAccessCarouselTVC.Layout.totalHeight
        } else if section.type == .heroCarousel {
            return HeroCarouselTVC.Layout.totalHeight
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
        } else if let tagPreviewCell = cell as? HomeTagPreviewTVC {
            tagPreviewOffsets[section.uuid] = tagPreviewCell.getContentOffset()
        } else if let genreTilesCell = cell as? GenreTilesCarouselTVC {
            genreTilesOffsets[section.uuid] = genreTilesCell.getContentOffset()
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row < displayedSections.count else { return }
        let section = displayedSections[indexPath.row]

        if let carouselCell = cell as? ShortStoryCarouselTVC, let offset = carouselTVCOffsets[section.uuid] {
            DispatchQueue.main.async {
                carouselCell.setContentOffset(offset)
            }
        } else if let subtitleCarouselCell = cell as? ShortStoryCarouselSubtitleTVC, let offset = carouselTVCOffsets[section.uuid] {
            DispatchQueue.main.async {
                subtitleCarouselCell.setContentOffset(offset)
            }
        } else if let heroCarouselCell = cell as? HeroCarouselTVC, let offset = heroCarouselTVCOffsets[section.uuid] {
            DispatchQueue.main.async {
                heroCarouselCell.setContentOffset(offset)
            }
        } else if let tagPreviewCell = cell as? HomeTagPreviewTVC, let offset = tagPreviewOffsets[section.uuid] {
            DispatchQueue.main.async {
                tagPreviewCell.setContentOffset(offset)
            }
        } else if let genreTilesCell = cell as? GenreTilesCarouselTVC, let offset = genreTilesOffsets[section.uuid] {
            DispatchQueue.main.async {
                genreTilesCell.setContentOffset(offset)
            }
        }
    }
}

// MARK: - Reading / Navigation

private extension PersonalizedHomeVC {
    func pauseVisibleHeroCarouselAutoScroll() {
        tableView.visibleCells.forEach { ($0 as? HeroCarouselTVC)?.pauseAutoScroll() }
    }

    func resumeVisibleHeroCarouselAutoScroll() {
        tableView.visibleCells.forEach { ($0 as? HeroCarouselTVC)?.resumeAutoScrollIfNeeded() }
    }

    func handleContinueTapped(_ story: CDBookInternal) {
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

    func showBookDetails(_ bookMetadata: ReadableContentMetadata,
                         sourceItems: [ReadableContentMetadata]? = nil) {
        pauseVisibleHeroCarouselAutoScroll()
        let bookDetailVC = BookDetailVC(contentMetadata: bookMetadata)
        bookDetailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(bookDetailVC, animated: true)
    }

    func showEarlyAccessVC() {
        let earlyAccessVC = EarlyAccessVC()
        earlyAccessVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(earlyAccessVC, animated: true)
    }

}

// MARK: - Paywall / Subscriber Refresh

extension PersonalizedHomeVC {
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
                    break
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
        rebuildFeed()
        tableView.reloadData()
    }
}

// MARK: - Header Actions

extension PersonalizedHomeVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func showImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = .fullScreen
        present(imagePicker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let selectedImage = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)

        dismiss(animated: true)

        guard let image = selectedImage else { return }
        handleUploadImage(image)
    }

    private func handleUploadImage(_ image: UIImage) {
        headerView.showImageLoadingIndicator(show: true)
        AccountManager.shared.uploadProfileImage(image: image) { [weak self] result in
            guard let self else { return }
            switch result {
            case .progress:
                break
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
        present(alertController, animated: true)
    }

    private func showUploadRetryError(image: UIImage) {
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let retryAction = UIAlertAction(title: "Retry", style: .default) { _ in
            self.handleUploadImage(image)
        }
        let alertController = UIAlertController(title: "Network Error",
                                                message: "Please ensure you have an active internet connection and try again.",
                                                preferredStyle: .alert)
        alertController.addAction(cancelAction)
        alertController.addAction(retryAction)
        present(alertController, animated: true)
    }
}

// MARK: - Delegates

extension PersonalizedHomeVC: FavoriteGenreSelectionDelegate {
    func didUpdateFavoriteGenres(_ genres: [BookInternalGenre]) {
        hasPresentedMissingFavoriteGenresSelector = false
        BookInternalTagManager.shared.ensureHomeEligibleTags(for: genres) { [weak self] success, tags in
            guard let self else { return }
            if success {
                homeEligibleTags = tags
            }
            rebuildFeed()
            tableView.reloadData()
        }
    }
}

extension PersonalizedHomeVC: BookInternalGenreSelectionDelegate {
    func didSelectGenre(_ genre: BookInternalGenre) {
        let filters = CDBookInternalSearchObject()
        filters.genre = genre
        switchToSearchTab(initialFilters: filters)
    }

    func didClearGenre() {}
}

extension PersonalizedHomeVC: ReadingTimeSelectionDelegate {
    func didSelectReadingTime(_ bucket: CDBookInternalLengthBucket) {
        let filters = CDBookInternalSearchObject()
        filters.setLengthBucket(bucket)
        switchToSearchTab(initialFilters: filters)
    }
}

extension PersonalizedHomeVC: BookInternalFiltersVCDelegate {
    func didApplyFilters(_ filters: CDBookInternalSearchObject) {
        switchToSearchTab(initialFilters: filters)
    }

    func didClearFilters() {}
}

extension PersonalizedHomeVC {
    func showStatsVC() {
        let statsVC = StatsVC()
        let navController = UINavigationController(rootViewController: statsVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
    }
}

private final class HomeTagPreviewTVC: UITableViewCell {
    static let reuseIdentifier = "HomeTagPreviewTVC"

    struct Layout {
        static let topMargin: CGFloat = 22
        static let estimatedTitleHeight: CGFloat = 24
        static let titleToCollectionSpacing: CGFloat = 10
        static let chipHeight: CGFloat = 32
        static let minimumCollectionHeight: CGFloat = chipHeight
        static let chipSpacing: CGFloat = 10
        static let bottomMargin: CGFloat = 16
        static let horizontalInsets = UIEdgeInsets(top: 0,
                                                   left: UIConstants.shared.standardMargin,
                                                   bottom: 0,
                                                   right: UIConstants.shared.standardMargin)

        static func collectionHeight(for tags: [BookInternalTag], containerWidth: CGFloat) -> CGFloat {
            guard !tags.isEmpty else { return minimumCollectionHeight }

            let availableWidth = max(120, containerWidth - horizontalInsets.left - horizontalInsets.right)
            var rowCount = 1
            var currentRowWidth: CGFloat = 0

            for tag in tags {
                let chipWidth = HomeTagPreviewChipCVC.width(for: tag.title, maxWidth: availableWidth)
                let proposedWidth = currentRowWidth == 0 ? chipWidth : currentRowWidth + chipSpacing + chipWidth
                if proposedWidth > availableWidth, currentRowWidth > 0 {
                    rowCount += 1
                    currentRowWidth = chipWidth
                } else {
                    currentRowWidth = proposedWidth
                }
            }

            return CGFloat(rowCount) * chipHeight + CGFloat(max(0, rowCount - 1)) * chipSpacing
        }

        static func totalHeight(for tags: [BookInternalTag], containerWidth: CGFloat) -> CGFloat {
            topMargin + estimatedTitleHeight + titleToCollectionSpacing + collectionHeight(for: tags,
                                                                                           containerWidth: containerWidth) + bottomMargin
        }
    }

    private var tags: [BookInternalTag] = []
    private let titleLabel = UILabel()
    private let viewAllButton = UIButton(type: .system)
    private let collectionView: UICollectionView
    private var collectionHeightConstraint: NSLayoutConstraint?

    var tappedTagHandler: ((BookInternalTag) -> Void)?
    var tappedViewAllHandler: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let layout = UICollectionViewLeftAlignedLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = Layout.chipSpacing
        layout.minimumInteritemSpacing = Layout.chipSpacing
        layout.sectionInset = Layout.horizontalInsets
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = Colours.surfacePrimary
        selectionStyle = .none

        titleLabel.font = UIConstants.shared.carouselTitleFont
        titleLabel.textColor = UIConstants.shared.carouselTitleTextColour
        contentView.addSubviewForConstraints(titleLabel)

        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 8, weight: .bold)
        let chevronImage = UIImage(systemName: "chevron.right", withConfiguration: chevronConfig)
        let accentColor = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
        viewAllButton.setTitle("View all", for: .normal)
        viewAllButton.setTitleColor(accentColor, for: .normal)
        viewAllButton.titleLabel?.font = Fonts.medium15
        viewAllButton.setImage(chevronImage, for: .normal)
        viewAllButton.tintColor = accentColor
        viewAllButton.semanticContentAttribute = .forceRightToLeft
        viewAllButton.contentHorizontalAlignment = .right
        viewAllButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 2)
        viewAllButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
        viewAllButton.addTarget(self, action: #selector(viewAllTapped), for: .touchUpInside)
        contentView.addSubviewForConstraints(viewAllButton)

        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isScrollEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(HomeTagPreviewChipCVC.self, forCellWithReuseIdentifier: HomeTagPreviewChipCVC.reuseIdentifier)
        contentView.addSubviewForConstraints(collectionView)

        collectionHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: Layout.minimumCollectionHeight)
        collectionHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Layout.topMargin),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: viewAllButton.leadingAnchor, constant: -12),

            viewAllButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor, constant: 1),
            viewAllButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            viewAllButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 84),
            viewAllButton.heightAnchor.constraint(equalToConstant: 30),

            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Layout.titleToCollectionSpacing),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Layout.bottomMargin)
        ])
    }

    func configure(title: String, tags: [BookInternalTag]) {
        titleLabel.text = title
        self.tags = tags
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let containerWidth = max(contentView.bounds.width, UIScreen.main.bounds.width)
        let targetHeight = Layout.collectionHeight(for: tags, containerWidth: containerWidth)
        if collectionHeightConstraint?.constant != targetHeight {
            collectionHeightConstraint?.constant = targetHeight
        }
        collectionView.collectionViewLayout.invalidateLayout()
    }

    @objc private func viewAllTapped() {
        tappedViewAllHandler?()
    }

    func setContentOffset(_ offset: CGPoint) {
        collectionView.setContentOffset(offset, animated: false)
    }

    func getContentOffset() -> CGPoint {
        collectionView.contentOffset
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        tags.removeAll()
        titleLabel.text = nil
        tappedTagHandler = nil
        tappedViewAllHandler = nil
        setContentOffset(.zero)
    }
}

extension HomeTagPreviewTVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        tags.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeTagPreviewChipCVC.reuseIdentifier, for: indexPath) as! HomeTagPreviewChipCVC
        cell.configure(title: tags[indexPath.item].title)
        return cell
    }
}

extension HomeTagPreviewTVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        tappedTagHandler?(tags[indexPath.item])
    }
}

extension HomeTagPreviewTVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let title = tags[indexPath.item].title
        let availableWidth = max(120,
                                 max(collectionView.bounds.width, UIScreen.main.bounds.width) - Layout.horizontalInsets.left - Layout.horizontalInsets.right)
        return CGSize(width: HomeTagPreviewChipCVC.width(for: title, maxWidth: availableWidth),
                      height: Layout.chipHeight)
    }
}

private final class HomeTagPreviewChipCVC: UICollectionViewCell {
    static let reuseIdentifier = "HomeTagPreviewChipCVC"

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.layer.cornerRadius = HomeTagPreviewTVC.Layout.chipHeight / 2
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = Colours.inputBorder.cgColor
        contentView.backgroundColor = Colours.surfaceCard

        titleLabel.font = Fonts.medium13
        titleLabel.textColor = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byClipping
        contentView.addSubviewForConstraints(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String) {
        titleLabel.text = title
    }

    static func width(for title: String, maxWidth: CGFloat) -> CGFloat {
        let font = Fonts.medium13
        let textWidth = (title as NSString).size(withAttributes: [.font: font]).width
        return min(max(textWidth + 24, 64), maxWidth)
    }
}
