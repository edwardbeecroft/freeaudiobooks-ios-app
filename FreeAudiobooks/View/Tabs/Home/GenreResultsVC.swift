//
//  GenreResultsVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 13/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import SuperwallKit

protocol GenreResultsVCDelegate: AnyObject {
    func genreResultsVC(_ vc: GenreResultsVC, didSelectBook book: CDBookInternal, sourceItems: [CDBookInternal])
}

enum GenreResultsSource {
    case genre(genre: BookInternalGenre, excludedBookUUID: String?)
    case recentlyViewed
    case tag(title: String, tag: String, genre: BookInternalGenre?)
}

class GenreResultsVC: UIViewController {

    // MARK: - Properties

    private let source: GenreResultsSource
    private var stories: [CDBookInternal] = []
    private var earlyAccessBooks: [CDBookInternal] = []
    weak var delegate: GenreResultsVCDelegate?
    var onBookSelected: ((CDBookInternal) -> Void)?
    var onBookSelectedWithSourceItems: ((CDBookInternal, [CDBookInternal]) -> Void)?

    private var shouldShowEarlyAccessUpsell: Bool {
        RCValues.shared.bool(forKey: .showDiscoverEASearchUpsellWidget) &&
        !AccountManager.shared.userIsSubscribed &&
        earlyAccessBooks.count >= 5
    }

    private var titleText: String {
        switch source {
        case .genre(let genre, _):
            return genre.displayString
        case .recentlyViewed:
            return "Recently viewed"
        case .tag(let title, _, _):
            return title
        }
    }

    private var shouldShowCloseButton: Bool {
        presentingViewController != nil && navigationController?.viewControllers.first === self
    }

    // MARK: - UI Elements

    private let tableView = UITableView()

    // MARK: - Initialization

    init(source: GenreResultsSource) {
        self.source = source
        super.init(nibName: nil, bundle: nil)
    }

    convenience init(genre: BookInternalGenre, excludedBookUUID: String? = nil) {
        self.init(source: .genre(genre: genre, excludedBookUUID: excludedBookUUID))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        setupTableView()
        loadStories()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshForSubscriberStatus),
                                               name: .didUpdateSubscriberStatus,
                                               object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        tableView.reloadData()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard NavigationBarStyler.reapplyIfNeeded(on: self,
                                                  previousTraitCollection: previousTraitCollection) else { return }
        setupNavigationBar()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        view.backgroundColor = Colours.surfacePrimary
        title = titleText

        guard let navigationBar = navigationController?.navigationBar else { return }
        NavigationBarStyler.apply(to: navigationBar,
                                  fallbackTraitCollection: view.window?.traitCollection ?? traitCollection)

        if shouldShowCloseButton {
            let closeButton = UIBarButtonItem(
                image: UIImage(systemName: "xmark"),
                style: .plain,
                target: self,
                action: #selector(closeTapped)
            )
            closeButton.tintColor = Colours.textPrimary
            navigationItem.leftBarButtonItem = closeButton
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = Colours.surfacePrimary
        tableView.separatorStyle = .none
        tableView.register(SearchResultsTVC.self, forCellReuseIdentifier: "SearchResultCell")
        tableView.register(EarlyAccessSearchUpsellTVC.self, forCellReuseIdentifier: "EarlyAccessSearchUpsellCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120

        view.addSubviewForConstraints(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadStories() {
        let storyManager = CoreDataBookInternalManager.shared

        switch source {
        case .genre(let genre, let excludedBookUUID):
            let genreStories = storyManager.getAll(in: [genre])
                .filter { $0.contentUUID != excludedBookUUID }

            if AccountManager.shared.userIsSubscribed {
                stories = genreStories
            } else {
                stories = genreStories.filter(\.isAvailableToUser)
            }

            earlyAccessBooks = genreStories.filter { !$0.isAvailableToUser }.shuffled()

        case .recentlyViewed:
            let viewedStories = ReadingUserDefaults.getRecentlyViewedBookInternals()
            stories = viewedStories
            earlyAccessBooks = viewedStories.filter { !$0.isAvailableToUser }.shuffled()
        case .tag(_, let tag, let genre):
            let candidateStories = genre.map { storyManager.getAll(in: [$0]) } ?? storyManager.getAll()
            let taggedStories = candidateStories.filter { story in
                story.tags.contains(tag) && (genre == nil || story.genre == genre)
            }

            if AccountManager.shared.userIsSubscribed {
                stories = taggedStories.sorted { $0.readerCount > $1.readerCount }
            } else {
                stories = taggedStories
                    .filter(\.isAvailableToUser)
                    .sorted { $0.readerCount > $1.readerCount }
            }

            earlyAccessBooks = taggedStories.filter { !$0.isAvailableToUser }.shuffled()
        }

        tableView.reloadData()
    }

    // MARK: - Actions

    private func showBookDetails(_ book: CDBookInternal) {
        let sourceItems = stories
        if let delegate {
            delegate.genreResultsVC(self, didSelectBook: book, sourceItems: sourceItems)
            return
        }

        if let onBookSelectedWithSourceItems {
            onBookSelectedWithSourceItems(book, sourceItems)
            return
        }

        if let onBookSelected {
            onBookSelected(book)
            return
        }

        let bookDetailVC = BookDetailVC(contentMetadata: book)
        navigationController?.pushViewController(bookDetailVC, animated: true)
    }

    private func displayPaywall(placement: PaywallPlacement) {
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
                case .purchased(_):
                    self.refreshForSubscriberStatus()
                case .restored:
                    self.refreshForSubscriberStatus()
                }
            }
        }
        Superwall.shared.register(placement: placement.rawValue, params: nil, handler: handler)
    }

    @objc private func refreshForSubscriberStatus() {
        loadStories()
    }

    // MARK: - Save Handler

    private func handleSaveStory<T: SaveableMetadataView>(story: CDBookInternal, view: T) {
        let storyUUID = story.contentUUID
        let isSavedAtStart = AccountManager.shared.user?.savedBookInternalUUIDs.contains(storyUUID) ?? false

        if isSavedAtStart {
            AccountManager.shared.user?.savedBookInternalUUIDs.removeAll(where: { $0 == storyUUID })
        } else {
            AccountManager.shared.user?.savedBookInternalUUIDs.append(storyUUID)
        }

        view.updateSaveElements()

        AccountManager.shared.handleSaveBookInternal(story, save: !isSavedAtStart, saveVenue: .story) { [weak self] in
            guard let self = self else { return }
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

    // MARK: - Download Handlers

    private func tappedDownload<T: DownloadableMetadataView>(view: T) {
        guard let bookMetadata = view.contentMetadata else { return }

        if bookMetadata.hasDownloadedAudio {
            showDeletePopup(bookMetadata: bookMetadata, view: view)
        } else if APIBookInternalAudioManager.shared.isDownloading(bookUUID: bookMetadata.contentUUID) {
            view.updateDownloadElements()
        } else {
            performDownload(bookMetadata: bookMetadata, view: view)
        }
    }

    private func performDownload<T: DownloadableMetadataView>(bookMetadata: ReadableContentMetadata, view: T) {
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

                switch result {
                case .downloaded, .alreadyDownloaded:
                    break
                case .quotaExceeded:
                    self.presentListeningQuotaDepletedSheet(for: bookMetadata) { [weak self, weak view] in
                        guard let self, let view else { return }
                        self.performDownload(bookMetadata: bookMetadata, view: view)
                    }
                case .noAudio:
                    self.showNoAudioAlert()
                case .failed:
                    self.showDownloadError(bookMetadata: bookMetadata, view: view)
                }
            }
        }
    }

    private func showDeletePopup<T: DownloadableMetadataView>(bookMetadata: ReadableContentMetadata, view: T) {
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.handleDelete(bookMetadata: bookMetadata, view: view)
            }
        }
        let alertController = UIAlertController(
            title: "Delete Audiobook",
            message: "Delete the downloaded audiobook from this device?",
            preferredStyle: .alert
        )
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        present(alertController, animated: true, completion: nil)
    }

    private func handleDelete<T: DownloadableMetadataView>(bookMetadata: ReadableContentMetadata, view: T) {
        guard let cdBookInternal = bookMetadata as? CDBookInternal else { return }

        if cdBookInternal.hasDownloadedAudio {
            CoreDataBookInternalAudioManager.shared.deleteBookInternalAudio(bookUUID: cdBookInternal.contentUUID) { success in
                DispatchQueue.main.async {
                    if !success {
                        print("Failed to delete audio for \(cdBookInternal.contentUUID)")
                        view.updateDownloadElements()
                        return
                    }
                    DownloadTimestampManager.shared.removeAudioTimestamp(uuid: cdBookInternal.contentUUID)
                    APIBookInternalAudioManager.shared.clearDownloadState(for: cdBookInternal.contentUUID)
                }
            }
        } else {
            APIBookInternalAudioManager.shared.clearDownloadState(for: cdBookInternal.contentUUID)
            view.updateDownloadElements()
        }
    }

    private func showNoAudioAlert() {
        let alertController = UIAlertController(title: "No Audio Available", message: "This book doesn't have an audiobook version available.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }

    private func showDownloadError<T: DownloadableMetadataView>(bookMetadata: ReadableContentMetadata, view: T) {
        let retryAction = UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.performDownload(bookMetadata: bookMetadata, view: view)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let alertController = UIAlertController(
            title: "Download Failed",
            message: "There was an error downloading this book. Please check your internet connection and try again.",
            preferredStyle: .alert
        )
        alertController.addAction(cancelAction)
        alertController.addAction(retryAction)
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource

extension GenreResultsVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let baseCount = stories.count
        return shouldShowEarlyAccessUpsell ? baseCount + 1 : baseCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if shouldShowEarlyAccessUpsell && indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EarlyAccessSearchUpsellCell", for: indexPath) as! EarlyAccessSearchUpsellTVC
            cell.configure(with: earlyAccessBooks, totalCount: earlyAccessBooks.count)

            cell.tappedUnlockHandler = { [weak self] in
                guard let self else { return }
                DispatchQueue.main.async {
                    AnalyticsManager.shared.trackEarlyAccessSearchUpsellTapped()
                    self.displayPaywall(placement: .earlyAccessSearchResultsUpsell)
                }
            }

            cell.tappedChevronHandler = { [weak self] in
                guard let self else { return }
                DispatchQueue.main.async {
                    let earlyAccessVC = EarlyAccessVC()
                    earlyAccessVC.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(earlyAccessVC, animated: true)
                }
            }

            return cell
        }

        let resultIndex = shouldShowEarlyAccessUpsell ? indexPath.row - 1 : indexPath.row

        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! SearchResultsTVC
        let story = stories[resultIndex]

        cell.set(contentMetadata: story, displayContext: .normal)

        cell.tappedHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                if let onBookSelectedWithSourceItems = self.onBookSelectedWithSourceItems {
                    onBookSelectedWithSourceItems(story, self.stories)
                    return
                }
                if let onBookSelected = self.onBookSelected {
                    onBookSelected(story)
                    return
                }
                if !story.isAvailableToUser {
                    self.displayPaywall(placement: .earlyAccess)
                } else {
                    self.showBookDetails(story)
                }
            }
        }

        cell.tappedSaveHandler = { [weak self] view in
            guard let self else { return }
            DispatchQueue.main.async {
                self.handleSaveStory(story: story, view: view)
            }
        }

        cell.tappedDownloadHandler = { [weak self] view in
            guard let self else { return }
            DispatchQueue.main.async {
                self.tappedDownload(view: view)
            }
        }

        cell.selectionStyle = .none
        return cell
    }
}

// MARK: - UITableViewDelegate

extension GenreResultsVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}
