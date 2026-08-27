//
//  EarlyAccessVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 03/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import SuperwallKit

extension EarlyAccessVC {
    struct SizeInfo {
        static let numberOfColumns: CGFloat = 3
        static let horizontalPadding: CGFloat = UIConstants.shared.standardMargin
        static let minimumInteritemSpacing: CGFloat = UIConstants.shared.discoverGridMinimumInteritemSpacing
        static let minimumLineSpacing: CGFloat = 16

        static func getItemWidth(boundWidth: CGFloat) -> CGFloat {
            // Total width = collection view width - (left + right padding) - (spaces between columns)
            let totalWidth = boundWidth - (horizontalPadding * 2) - ((numberOfColumns - 1) * minimumInteritemSpacing)
            let itemWidth = totalWidth / numberOfColumns
            // Floor to avoid floating-point precision issues that can cause layout to show fewer columns
            return floor(itemWidth)
        }
    }
}

class EarlyAccessVC: UIViewController {

    // MARK: - Properties

    private var stories: [CDBookInternal]

    // MARK: - UI Elements

    private var collectionView: UICollectionView!
    private let bottomContainerView = UIView()
    private var collectionViewBottomConstraint: NSLayoutConstraint!
    private lazy var ctaButton: UIButton = {
        return Buttons.gradientButton(buttonTitle: "Start 7-Day Free Access", cornerRadius: UIConstants.shared.fullButtonCornerRadius)
    }()

    // MARK: - Initialization

    init() {
        self.stories = []
        super.init(nibName: nil, bundle: nil)
        refreshStories()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        setupCollectionView()
        setupBottomContainer()
        setupConstraints()
        
        if !AccountManager.shared.userIsSubscribed {
            view.addIphoneXBottomView(colour: Colours.backgroundGrey)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        refreshStories()

        // Always reload collection view when returning to this screen
        // (e.g., after downloading/deleting content, saving/unsaving, completing a book)
        collectionView.reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Force layout invalidation to ensure correct sizing after view is laid out
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        NavigationBarStyler.reapplyIfNeeded(
            on: self,
            previousTraitCollection: previousTraitCollection,
            refreshNavigationItems: { [weak self] in
                self?.setupNavigationBar()
            }
        )
    }

    // MARK: - Setup

    private func refreshStories() {
        stories = CoreDataBookInternalManager.shared.getAll()
            .filter { $0.isEarlyAccess }
            .sorted { book1, book2 in
                let date1 = book1.availableForAllDateString
                    .flatMap { DateFormatters.earlyAccessDateFormatter.date(from: $0) } ?? Date.distantFuture
                let date2 = book2.availableForAllDateString
                    .flatMap { DateFormatters.earlyAccessDateFormatter.date(from: $0) } ?? Date.distantFuture

                return date1 < date2
            }
    }

    private func setupNavigationBar() {
        view.backgroundColor = Colours.surfacePrimary

        guard let navigationBar = self.navigationController?.navigationBar else { return }
        NavigationBarStyler.apply(to: navigationBar)

        let btnLeftMenu: UIButton = UIButton(type: .system)
        let backImage = UIImage(named: "backButtonNavIcon")?.withRenderingMode(.alwaysTemplate)
        btnLeftMenu.setImage(backImage, for: .normal)
        btnLeftMenu.tintColor = Colours.textPrimary

        btnLeftMenu.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        btnLeftMenu.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        let barButton = UIBarButtonItem(customView: btnLeftMenu)
        self.navigationItem.leftBarButtonItem = barButton

        // Create attributed title with "Audiobooks+" in gradient color
        let titleText = "Audiobooks+ Early Access"
        let attributedString = NSMutableAttributedString(string: titleText)

        let effectiveStyle = AppearanceManager.shared.effectiveInterfaceStyle(
            fallbackTraitCollection: view.window?.traitCollection ?? traitCollection
        )
        let titleColor = Colours.textPrimary.resolvedColor(
            with: UITraitCollection(userInterfaceStyle: effectiveStyle)
        )

        // Set default color for entire string
        attributedString.addAttribute(.foregroundColor,
                                     value: titleColor,
                                     range: NSRange(location: 0, length: titleText.count))

        // Apply font from nav bar title attributes
        if let font = Fonts.navBarTitleTextAttributes[.font] as? UIFont {
            attributedString.addAttribute(.font,
                                        value: font,
                                        range: NSRange(location: 0, length: titleText.count))
        }

        // Find range of "FreeBooks+" and apply gradient color
        if let range = titleText.range(of: "Audiobooks+") {
            let nsRange = NSRange(range, in: titleText)
            attributedString.addAttribute(.foregroundColor,
                                        value: Colours.orangePrimary,
                                        range: nsRange)
        }

        // Create custom title label
        let titleLabel = UILabel()
        titleLabel.attributedText = attributedString
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = SizeInfo.minimumLineSpacing
        layout.minimumInteritemSpacing = SizeInfo.minimumInteritemSpacing
        layout.sectionInset = UIEdgeInsets(
            top: 16,
            left: SizeInfo.horizontalPadding,
            bottom: 16,
            right: SizeInfo.horizontalPadding
        )

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = Colours.surfacePrimary
        collectionView.register(EarlyAccessShortStoryCVC.self, forCellWithReuseIdentifier: "EarlyAccessShortStoryCVC")
        collectionView.alwaysBounceVertical = true

        view.addSubviewForConstraints(collectionView)
    }

    private func setupBottomContainer() {
        bottomContainerView.backgroundColor = Colours.backgroundGrey
        view.addSubviewForConstraints(bottomContainerView)

        // Add top border
        let borderView = UIView()
        borderView.backgroundColor = Colours.separator
        bottomContainerView.addSubviewForConstraints(borderView)

        // Create title label
        let titleLabel = UILabel()
        titleLabel.text = "Get new titles 90 days early, plus:"
        titleLabel.font = Fonts.semiBold15
        titleLabel.textColor = Colours.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        bottomContainerView.addSubviewForConstraints(titleLabel)

        // Create benefits stack view
        let benefitsStack = UIStackView()
        benefitsStack.axis = .vertical
        benefitsStack.spacing = 6
        benefitsStack.alignment = .leading
        bottomContainerView.addSubviewForConstraints(benefitsStack)

        // Add benefits
        let benefits = [
          "Download audiobooks to your library",
          "Listen to 500+ premium audiobooks",
          "Enjoy 100% ad-free listening"
        ]

        for benefit in benefits {
            let benefitView = createBenefitView(text: benefit)
            benefitsStack.addArrangedSubview(benefitView)
        }

        // Calculate width of longest benefit text for centering
        let fontAttributes = [NSAttributedString.Key.font: Fonts.medium15]
        var largestWidth: CGFloat = 0
        for benefit in benefits {
            let width = (benefit as NSString).size(withAttributes: fontAttributes).width
            if width > largestWidth {
                largestWidth = width
            }
        }

        // Add checkmark width (20) + spacing (12) to total width
        let totalWidth = largestWidth + 20 + 12 + 2

        // Add CTA button
        ctaButton.addTarget(self, action: #selector(ctaButtonTapped), for: .touchUpInside)
        bottomContainerView.addSubviewForConstraints(ctaButton)

        NSLayoutConstraint.activate([
            // Border
            borderView.topAnchor.constraint(equalTo: bottomContainerView.topAnchor),
            borderView.leadingAnchor.constraint(equalTo: bottomContainerView.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: bottomContainerView.trailingAnchor),
            borderView.heightAnchor.constraint(equalToConstant: 1),

            // Title label
            titleLabel.topAnchor.constraint(equalTo: borderView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: bottomContainerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: bottomContainerView.trailingAnchor, constant: -16),

            // Benefits stack - centered with calculated width
            benefitsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            benefitsStack.centerXAnchor.constraint(equalTo: bottomContainerView.centerXAnchor),
            benefitsStack.widthAnchor.constraint(equalToConstant: totalWidth),

            // CTA Button
            ctaButton.topAnchor.constraint(equalTo: benefitsStack.bottomAnchor, constant: 16),
            ctaButton.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 60),
            ctaButton.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -60),
            ctaButton.bottomAnchor.constraint(equalTo: bottomContainerView.safeBottomAnchor, constant: -16),
            ctaButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight)
        ])
    }

    private func createBenefitView(text: String) -> UIView {
        let container = UIView()

        // Checkmark icon using paywall tick
        let checkmark = UIImageView()
        checkmark.image = UIImage(named: "paywall-tick-green")
        checkmark.contentMode = .scaleAspectFit
        container.addSubviewForConstraints(checkmark)

        // Benefit text
        let label = UILabel()
        label.text = text
        label.font = Fonts.medium15
        label.textColor = Colours.subtext
        label.numberOfLines = 0
        container.addSubviewForConstraints(label)

        NSLayoutConstraint.activate([
            checkmark.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            checkmark.centerYAnchor.constraint(equalTo: label.centerYAnchor, constant: 1),
            checkmark.widthAnchor.constraint(equalToConstant: 16),
            checkmark.heightAnchor.constraint(equalToConstant: 16),

            label.leadingAnchor.constraint(equalTo: checkmark.trailingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Bottom container
            bottomContainerView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            bottomContainerView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            bottomContainerView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),

            // Collection view
            collectionView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        // Set initial state
        updateBottomContainerVisibility()
    }

    private func updateBottomContainerVisibility() {
        let isSubscribed = AccountManager.shared.userIsSubscribed

        // Deactivate existing constraint if it exists
        collectionViewBottomConstraint?.isActive = false

        if isSubscribed {
            // For subscribers: anchor collection view to bottom, hide container
            bottomContainerView.isHidden = true
            collectionViewBottomConstraint = collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        } else {
            // For non-subscribers: anchor collection view to bottom container top
            bottomContainerView.isHidden = false
            collectionViewBottomConstraint = collectionView.bottomAnchor.constraint(equalTo: bottomContainerView.topAnchor)
        }

        collectionViewBottomConstraint.isActive = true
    }

    // MARK: - Actions

    @objc private func ctaButtonTapped() {
        displayPaywall(bookInternal: nil)
    }

    private func displayPaywall(bookInternal: CDBookInternal?) {
        displayPaywall(placement: .earlyAccess, bookInternal: bookInternal)
    }

    private func displayPaywall(placement: PaywallPlacement, bookInternal: CDBookInternal?) {
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
                    print("No purchase occurred.")
                case .purchased(let product):
                    print("Purchased \(product.productIdentifier)")
                    AnalyticsManager.shared.trackPaywallUserSubscribed(placement: placement, cdBookInternal: bookInternal)

                    // Show success popup
                    self.showSubscribeSuccessPopup()

                    // Update UI to hide bottom container
                    self.updateBottomContainerVisibility()

                    self.refreshStories()

                    // Reload collection view to update cell states (books are now unlocked)
                    self.collectionView.reloadData()
                case .restored:
                    AnalyticsManager.shared.trackPaywallRestorePurchasesSuccess()

                    // Update UI to hide bottom container
                    self.updateBottomContainerVisibility()

                    self.refreshStories()

                    // Reload collection view to update cell states (books are now unlocked)
                    self.collectionView.reloadData()
                }
            }
        }
        Superwall.shared.register(placement: placement.rawValue, params: nil, handler: handler)
    }

    // MARK: - Download Handlers

    private func handleDownloadForStory<T: DownloadableMetadataView>(view: T) {
        guard let bookMetadata = view.contentMetadata else { return }

        if bookMetadata.hasDownloadedAudio {
            showDeletePopupForStory(bookMetadata: bookMetadata, view: view)
        } else if APIBookInternalAudioManager.shared.isDownloading(bookUUID: bookMetadata.contentUUID) {
            view.updateDownloadElements()
        } else {
            performDownloadForStory(bookMetadata: bookMetadata, view: view)
        }
    }

    private func performDownloadForStory<T: DownloadableMetadataView>(bookMetadata: ReadableContentMetadata, view: T) {
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
                        self.performDownloadForStory(bookMetadata: bookMetadata, view: view)
                    }
                case .noAudio:
                    self.showNoAudioAlert()
                case .failed:
                    self.showDownloadErrorForStory(bookMetadata: bookMetadata, view: view)
                }
            }
        }
    }

    private func showDeletePopupForStory<T: DownloadableMetadataView>(bookMetadata: ReadableContentMetadata, view: T) {
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.handleDeleteForStory(bookMetadata: bookMetadata, view: view)
            }
        }
        let alertController = UIAlertController(title: "Delete Audiobook", message: "Delete the downloaded audiobook from this device?", preferredStyle: .alert)
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        present(alertController, animated: true, completion: nil)
    }

    private func handleDeleteForStory<T: DownloadableMetadataView>(bookMetadata: ReadableContentMetadata, view: T) {
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

    private func showDownloadErrorForStory<T: DownloadableMetadataView>(bookMetadata: ReadableContentMetadata, view: T) {
        let retryAction = UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.performDownloadForStory(bookMetadata: bookMetadata, view: view)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let alertController = UIAlertController(title: "Download Failed", message: "There was an error downloading this book. Please check your internet connection and try again.", preferredStyle: .alert)
        alertController.addAction(cancelAction)
        alertController.addAction(retryAction)
        present(alertController, animated: true, completion: nil)
    }

    private func showNoAudioAlert() {
        let alertController = UIAlertController(title: "No Audio Available", message: "This book doesn't have an audiobook version available.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }

    // MARK: - Helper Methods

    private func handleCellTapped(for story: CDBookInternal) {
        if !story.isAvailableToUser {
            displayPaywall(bookInternal: story)
        } else {
            showBookDetails(story)
        }
    }

    private func showBookDetails(_ bookMetadata: ReadableContentMetadata) {
        let bookDetailVC = BookDetailVC(contentMetadata: bookMetadata)
        bookDetailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(bookDetailVC, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension EarlyAccessVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EarlyAccessShortStoryCVC", for: indexPath) as! EarlyAccessShortStoryCVC
        let story = stories[indexPath.item]

        cell.configure(with: story)

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension EarlyAccessVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemWidth = SizeInfo.getItemWidth(boundWidth: collectionView.bounds.width)
        let itemHeight = EarlyAccessShortStoryCVC.Layout.cardHeight(forCoverWidth: itemWidth)

        return CGSize(width: itemWidth, height: itemHeight)
    }
}

// MARK: - UICollectionViewDelegate

extension EarlyAccessVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let story = stories[indexPath.item]
        handleCellTapped(for: story)
    }
}
