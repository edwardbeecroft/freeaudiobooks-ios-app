//
//  RoadmapVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 06/03/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseFirestore
import NVActivityIndicatorView
import PopupDialog
import BetterSegmentedControl

class RoadmapVC: UIViewController {

    private let retryButton = UIButton(type: .system)
    private let tableView = UITableView()

    private var loadingIndicatorView: NVActivityIndicatorView?

    // Animation tracking
    private var hasAnimatedInitialLoad = false
    private var animatedIndexPaths = Set<IndexPath>()

    // Header card (contains search + segmented control)
    private let headerCardView = UIView()

    // Search
    private var searchText = ""
    private let searchTextField = UITextField()
    private let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
    
    private let ctaContainerView = UIView()
    private let addRoadmapItemButton = Buttons.primaryCTA(buttonTitle: RCValues.shared.string(forKey: .addRoadmapItemButtonTitle))
    private let headerDividerView = UIView()
    private let ctaTopBorderView = UIView()
    
    var segmentedControl: BetterSegmentedControl!
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(getPostsWithRefreshControl), for: .valueChanged)
        refreshControl.tintColor = Colours.textPrimary
        return refreshControl
    }()
    
    @objc private func getPostsWithRefreshControl() {
        fetchPosts(isRefreshControl: true)
    }
    
    let wasPresented: Bool
    init(wasPresented: Bool) {
        self.wasPresented = wasPresented
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addIphoneXBottomView(colour: Colours.chromeBackground)
        view.backgroundColor = Colours.surfaceSecondary
        
        setupRetryFetchUI()

        setupNavBar()
        setupSearchBar()
        setupSegmentedControl()
        setupBottomCTASection()
        setupTableView()
        
        hideKeyboardWhenTappedAround()
        updateAppearanceColors()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        
        AnalyticsManager.shared.trackRoadmapViewed()
        
        fetchPosts()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateAppearanceColors()
        setupNavBar()
    }
}

private extension RoadmapVC {
    func fetchPosts(isRefreshControl: Bool = false) {
        if !isRefreshControl {
            showLoadingIndicator(show: true)
        }

        RoadmapManager.shared.fetchAllRoadmapItems { [weak self] success in
            guard let self = self else { return }
            
            guard success else {
                DispatchQueue.main.async {
                    self.showRetryFetchUI()
                }
                return
            }
            
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()

                if isRefreshControl {
                    // Pull-to-refresh: reload immediately with animation
                    self.animatedIndexPaths.removeAll()
                    self.tableView.reloadData()
                } else {
                    // Initial load: wait for loading indicator, then animate
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        self.showLoadingIndicator(show: false)
                        self.animatedIndexPaths.removeAll()
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
}

private extension RoadmapVC {
    func setupNavBar() {
        guard let navigationBar = self.navigationController?.navigationBar else {return}
        navigationBar.tintColor = Colours.textPrimary
        navigationBar.barTintColor = Colours.surfaceSecondary

        navigationController?.view.backgroundColor = Colours.surfaceSecondary
        
        let btnLeftMenu: UIButton = UIButton(type: .system)
        let imageName = wasPresented ? "dismissIcon" : "backButtonNavIcon"
        let backImage = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        btnLeftMenu.setImage(backImage, for: .normal)
        btnLeftMenu.tintColor = Colours.textPrimary
        
        btnLeftMenu.addTarget(self, action: #selector(popVC), for: .touchUpInside)
        btnLeftMenu.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        let barButton = UIBarButtonItem(customView: btnLeftMenu)
        self.navigationItem.leftBarButtonItem = barButton
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Colours.surfaceSecondary
        appearance.titleTextAttributes = Fonts.navBarTitleTextAttributes
        appearance.shadowColor = Colours.separator
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
        
        let titleLabel = UILabel()
        titleLabel.text = "Feature Requests"
        titleLabel.font = Fonts.navBarTitleTextAttributes[.font] as? UIFont
        titleLabel.textColor = Fonts.navBarTitleTextAttributes[.foregroundColor] as? UIColor ?? Colours.textPrimary

        let betaCapsule = PaddedLabel()
        betaCapsule.text = "Beta"
        betaCapsule.font = Fonts.semiBold12
        betaCapsule.textColor = Colours.orangePrimary
        betaCapsule.backgroundColor = Colours.orangePrimary.withAlphaComponent(0.1)
        betaCapsule.layer.cornerRadius = 8
        betaCapsule.layer.masksToBounds = true
        betaCapsule.layer.borderWidth = 1
        betaCapsule.layer.borderColor = Colours.orangePrimary.cgColor
        betaCapsule.topInset = 2
        betaCapsule.bottomInset = 2
        betaCapsule.leftInset = 8
        betaCapsule.rightInset = 8
        betaCapsule.isHidden = !RCValues.shared.bool(forKey: .showRoadmapBetaTag)

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, betaCapsule])
        titleStack.axis = .horizontal
        titleStack.spacing = 8
        titleStack.alignment = .center

        self.navigationItem.titleView = titleStack

    }

    @objc func popVC() {
        if wasPresented {
            self.dismiss(animated: true)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
}

private extension RoadmapVC {
    func setupSearchBar() {
        // Header card with shadow (contains search + segmented control)
        headerCardView.backgroundColor = Colours.surfaceCard
        headerCardView.layer.cornerRadius = 16
        headerCardView.layer.shadowColor = Colours.shadowBase.withAlphaComponent(0.08).cgColor
        headerCardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        headerCardView.layer.shadowOpacity = 1
        headerCardView.layer.shadowRadius = 8

        view.addSubviewForConstraints(headerCardView)

        // Search icon
        searchIcon.tintColor = Colours.grey140
        searchIcon.contentMode = .scaleAspectFit
        headerCardView.addSubviewForConstraints(searchIcon)

        // Search text field (no separate background, just inside header card)
        searchTextField.placeholder = "Search requests..."
        searchTextField.font = Fonts.medium16
        searchTextField.textColor = Colours.textPrimary
        searchTextField.returnKeyType = .search
        searchTextField.clearButtonMode = .whileEditing
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)

        headerCardView.addSubviewForConstraints(searchTextField)

        // Divider between search and segmented control
        headerDividerView.backgroundColor = Colours.separator
        headerCardView.addSubviewForConstraints(headerDividerView)

        NSLayoutConstraint.activate([
            headerCardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: UIConstants.shared.standardMargin),
            headerCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.shared.standardMargin),
            headerCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.shared.standardMargin),

            searchIcon.leadingAnchor.constraint(equalTo: headerCardView.leadingAnchor, constant: 16),
            searchIcon.topAnchor.constraint(equalTo: headerCardView.topAnchor, constant: 14),
            searchIcon.widthAnchor.constraint(equalToConstant: 20),
            searchIcon.heightAnchor.constraint(equalToConstant: 20),

            searchTextField.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 10),
            searchTextField.trailingAnchor.constraint(equalTo: headerCardView.trailingAnchor, constant: -16),
            searchTextField.centerYAnchor.constraint(equalTo: searchIcon.centerYAnchor),

            headerDividerView.topAnchor.constraint(equalTo: searchIcon.bottomAnchor, constant: 14),
            headerDividerView.leadingAnchor.constraint(equalTo: headerCardView.leadingAnchor, constant: 16),
            headerDividerView.trailingAnchor.constraint(equalTo: headerCardView.trailingAnchor, constant: -16),
            headerDividerView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    @objc func searchTextChanged() {
        searchText = searchTextField.text ?? ""
        animatedIndexPaths.removeAll()
        tableView.reloadData()
    }
}

private extension RoadmapVC {
    func setupSegmentedControl() {
        segmentedControl = BetterSegmentedControl(
            frame: .zero,
            segments: LabelSegment.segments(withTitles: [
                                            "Requested",
                                            "Released"],
                                            normalFont: Fonts.semiBold15,
                                            normalTextColor: .white,
                                            selectedFont:Fonts.semiBold15,
                                            selectedTextColor: Colours.themeAccentDark),
            index: 0,
            options: [.backgroundColor(Colours.themeAccentDark),
                      .indicatorViewBackgroundColor(Colours.surfacePrimary),
                      .cornerRadius(20),
                      .animationSpringDamping(1.0)])
        segmentedControl.addTarget(self, action: #selector(segmentValueChanged), for: .valueChanged)

        // Add to header card (below the divider)
        headerCardView.addSubviewForConstraints(segmentedControl)
        NSLayoutConstraint.activate([
            segmentedControl.leadingAnchor.constraint(equalTo: headerCardView.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: headerCardView.trailingAnchor, constant: -16),
            segmentedControl.topAnchor.constraint(equalTo: searchIcon.bottomAnchor, constant: 28),
            segmentedControl.heightAnchor.constraint(equalToConstant: 40),
            segmentedControl.bottomAnchor.constraint(equalTo: headerCardView.bottomAnchor, constant: -16)
        ])
    }
    
    @objc func segmentValueChanged() {
        animatedIndexPaths.removeAll()
        tableView.reloadData()
    }
}

extension RoadmapVC {
    func setupBottomCTASection() {
        ctaContainerView.backgroundColor = Colours.chromeBackground
        view.addSubviewForConstraints(ctaContainerView)
        NSLayoutConstraint.activate([
            ctaContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ctaContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ctaContainerView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor)
        ])
        
        ctaContainerView.addSubviewForConstraints(addRoadmapItemButton)
        NSLayoutConstraint.activate([
            addRoadmapItemButton.leadingAnchor.constraint(equalTo: ctaContainerView.leadingAnchor, constant: 20),
            addRoadmapItemButton.trailingAnchor.constraint(equalTo: ctaContainerView.trailingAnchor, constant: -20),
            addRoadmapItemButton.bottomAnchor.constraint(equalTo: ctaContainerView.bottomAnchor, constant: -UIConstants.shared.standardMargin),
            addRoadmapItemButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        addRoadmapItemButton.addTarget(self, action: #selector(tappedAddPost), for: .touchUpInside)
        
        ctaTopBorderView.backgroundColor = Colours.separator
        ctaContainerView.addSubviewForConstraints(ctaTopBorderView)
        NSLayoutConstraint.activate([
            ctaTopBorderView.topAnchor.constraint(equalTo: ctaContainerView.topAnchor),
            ctaTopBorderView.bottomAnchor.constraint(equalTo: addRoadmapItemButton.topAnchor, constant: -UIConstants.shared.standardMargin),
            ctaTopBorderView.leftAnchor.constraint(equalTo: ctaContainerView.leftAnchor),
            ctaTopBorderView.rightAnchor.constraint(equalTo: ctaContainerView.rightAnchor),
            ctaTopBorderView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
}

extension RoadmapVC: UITableViewDelegate, UITableViewDataSource {
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        
        view.addSubviewForConstraints(tableView)
        NSLayoutConstraint.activate([
            tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            tableView.topAnchor.constraint(equalTo: headerCardView.bottomAnchor, constant: 16),
            tableView.bottomAnchor.constraint(equalTo: ctaContainerView.topAnchor)
        ])
        tableView.register(RoadmapTVC.self, forCellReuseIdentifier: "general-cell")
        tableView.isHidden = true
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        tableView.addSubview(refreshControl)
        
        if #available(iOS 15, *) {
            tableView.sectionHeaderTopPadding = 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "general-cell", for: indexPath) as! RoadmapTVC
        
        let roadmapItem = itemsForCurrentSegment()[indexPath.row]
        cell.roadmapItem = roadmapItem
        
        cell.tappedUpvoteHandler = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.handleVote(roadmapItem: roadmapItem, cell)
            }
        }
        
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !animatedIndexPaths.contains(indexPath) else { return }
        animatedIndexPaths.insert(indexPath)

        // Set initial state
        cell.alpha = 0
        cell.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)

        // Staggered delay based on row
        let delay = Double(indexPath.row) * 0.08

        UIView.animate(
            withDuration: 0.4,
            delay: delay,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.3,
            options: [.curveEaseOut],
            animations: {
                cell.alpha = 1
                cell.transform = .identity
            }
        )
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = itemsForCurrentSegment()[indexPath.row]
        let detailVC = RoadmapItemDetailVC(roadmapItem: item)

        detailVC.dismissHandler = { [weak self] in
            self?.dismiss(animated: true)
        }

        detailVC.upvoteHandler = { [weak self] in
            guard let self = self else { return }
            self.handleVote(roadmapItem: item, tableView.cellForRow(at: indexPath)!)
        }

        self.present(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsForCurrentSegment().count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}

extension RoadmapVC {
    func itemsForCurrentSegment() -> [RoadmapItem] {
        // Requested tab: underReview, planned, inProgress
        let requestedItems = RoadmapManager.shared.roadmapItems.filter { $0.status != .released }
        // Released tab: released only
        let releasedItems = RoadmapManager.shared.roadmapItems.filter { $0.status == .released }
        let filteredBySegment = segmentedControl.index == 0 ? requestedItems : releasedItems

        if searchText.isEmpty {
            return filteredBySegment
        }

        let lowercasedSearch = searchText.lowercased()
        return filteredBySegment.filter {
            $0.title.lowercased().contains(lowercasedSearch) ||
            $0.description.lowercased().contains(lowercasedSearch)
        }
    }
}

extension RoadmapVC {
    func handleVote(roadmapItem: RoadmapItem, _ cell: UITableViewCell) {

        RoadmapVotingUserDefaults.handleVoteForRoadmapItem(roadmapItem)

        let wasUpvote = RoadmapVotingUserDefaults.roadmapUpvotedUUIDs.contains(roadmapItem.uuid)
        RoadmapManager.shared.adjustUpvoteCountForRoadmapItemWithUUID(roadmapItem.uuid, wasUpvote: wasUpvote)

        if wasUpvote {
            AnalyticsManager.shared.trackRoadmapItemUpvoted()
        }

        tableView.reloadData()

        HapticFeedbackHelper.shared.prepareLightFeedbackGenerator()
        HapticFeedbackHelper.shared.triggerLightImpactFeedback()
    }
}

extension RoadmapVC {
    func showLoadingIndicator(show: Bool) {
        if show {
            tableView.isHidden = true
            guard loadingIndicatorView == nil else { return }
            loadingIndicatorView = NVActivityIndicatorView(frame: CGRect.zero, type: NVActivityIndicatorType.circleStrokeSpin, color: Colours.textPrimary, padding: 0)
            guard let indicatorView = loadingIndicatorView else {return}
            
            indicatorView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(indicatorView)
            NSLayoutConstraint.activate([
                indicatorView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
                indicatorView.widthAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight),
                indicatorView.heightAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight),
                indicatorView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
            ])
            indicatorView.startAnimating()
        } else {
            self.tableView.isHidden = false
            
            loadingIndicatorView?.stopAnimating()
            loadingIndicatorView?.removeFromSuperview()
            loadingIndicatorView = nil
        }
    }
}

extension RoadmapVC {
    func setupRetryFetchUI() {
        retryButton.setTitle("Retry", for: .normal)
        retryButton.setTitleColor(Colours.textPrimary, for: .normal)
        retryButton.titleLabel?.font = Fonts.medium15
        retryButton.layer.borderColor = Colours.inputBorder.cgColor
        retryButton.layer.borderWidth = 1
        retryButton.layer.cornerRadius = 4
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(retryButton)
        let height: CGFloat = 30
        NSLayoutConstraint.activate([
            retryButton.widthAnchor.constraint(equalToConstant: 100),
            retryButton.heightAnchor.constraint(equalToConstant: height),
            retryButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            retryButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        retryButton.alpha = 0
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
    }
    
    func showRetryFetchUI() {
        retryButton.alpha = 1
        showLoadingIndicator(show: false)
        tableView.isHidden = true
    }
    
    @objc func retryTapped() {
        retryButton.alpha = 0
        fetchPosts()
    }

    private func updateAppearanceColors() {
        view.backgroundColor = Colours.surfaceSecondary
        headerCardView.backgroundColor = Colours.surfaceCard
        headerCardView.layer.shadowColor = Colours.shadowBase.withAlphaComponent(0.08).cgColor
        headerDividerView.backgroundColor = Colours.separator
        ctaContainerView.backgroundColor = Colours.chromeBackground
        ctaTopBorderView.backgroundColor = Colours.separator
        retryButton.setTitleColor(Colours.textPrimary, for: .normal)
        retryButton.layer.borderColor = Colours.inputBorder.cgColor
    }
}

extension RoadmapVC {
    @objc func tappedAddPost() {
        AnalyticsManager.shared.trackRoadmapAddItemTapped()
        showAddPostVC()
    }
}

extension RoadmapVC: SubmitRoadmapItemVCDelegate {
    func showAddPostVC() {
        let submitVC = SubmitRoadmapItemVC()
        submitVC.delegate = self
        self.present(submitVC, animated: true)
    }
    func didSubmitNewRoadmapItem() {
        self.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Thanks for the suggestion!",
                                              message: "Your submission is in review. If approved, it will be added to the “Requested” list so the community can vote.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
}

// MARK: - UITextFieldDelegate
extension RoadmapVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
