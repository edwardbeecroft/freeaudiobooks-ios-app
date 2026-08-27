//
//  TagResultsVC.swift
//  FreeAudiobooks
//
//  Created by OpenAI Codex on 27/03/2026.
//

import UIKit

final class TagResultsVC: GenreResultsVC {
    init(tag: BookInternalTag) {
        super.init(source: .tag(title: tag.title, tag: tag.tag, genre: tag.genre))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct TagBrowserChipItem {
    let title: String
    let genre: BookInternalGenre?
}

final class TagSelectionVC: BottomSheetController {

    private let genres: [BookInternalGenre]
    private let titleText: String
    private let selectedTag: BookInternalTag?
    private var allTags: [BookInternalTag] = []
    private var displayedTags: [BookInternalTag] = []
    private var activeGenre: BookInternalGenre?
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let clearButton = UIButton(type: .system)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let chipScrollView = UIScrollView()
    private let chipStackView = UIStackView()
    private var chipButtons: [UIButton] = []
    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No tags available yet."
        label.textColor = Colours.textSecondary
        label.font = Fonts.regular16
        label.textAlignment = .center
        return label
    }()
    var didSelectTag: ((BookInternalTag) -> Void)?
    var didClearTag: (() -> Void)?

    init(genres: [BookInternalGenre], titleText: String, selectedTag: BookInternalTag? = nil) {
        self.genres = genres
        self.titleText = titleText
        self.selectedTag = selectedTag
        super.init(nibName: nil, bundle: nil)
        preferredSheetSizing = .large
        preferredSheetCornerRadius = 24
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colours.surfaceCard
        view.layer.masksToBounds = true
        setupHeader()
        setupTableView()
        reloadSections()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bottomInset = view.safeAreaInsets.bottom + 8
        if tableView.contentInset.bottom != bottomInset {
            tableView.contentInset.bottom = bottomInset
            tableView.verticalScrollIndicatorInsets.bottom = bottomInset
        }
    }

    private func setupTableView() {
        chipScrollView.showsHorizontalScrollIndicator = false
        chipScrollView.alwaysBounceHorizontal = true
        chipScrollView.isHidden = genres.count <= 1
        view.addSubviewForConstraints(chipScrollView)

        chipStackView.axis = .horizontal
        chipStackView.spacing = 8
        chipStackView.alignment = .center
        chipScrollView.addSubviewForConstraints(chipStackView)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = Colours.surfaceCard
        tableView.separatorStyle = .none
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.sectionHeaderTopPadding = 0
        let footerView = UIView()
        footerView.backgroundColor = Colours.surfaceCard
        tableView.tableFooterView = footerView
        tableView.register(SelectionTableViewCell.self, forCellReuseIdentifier: "TagBrowserCell")
        view.addSubviewForConstraints(tableView)
        NSLayoutConstraint.activate([
            chipScrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: genres.count > 1 ? 8 : 0),
            chipScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chipScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chipScrollView.heightAnchor.constraint(equalToConstant: genres.count > 1 ? 42 : 0),

            chipStackView.leadingAnchor.constraint(equalTo: chipScrollView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            chipStackView.trailingAnchor.constraint(equalTo: chipScrollView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            chipStackView.topAnchor.constraint(equalTo: chipScrollView.topAnchor),
            chipStackView.bottomAnchor.constraint(equalTo: chipScrollView.bottomAnchor),
            chipStackView.heightAnchor.constraint(equalTo: chipScrollView.heightAnchor),

            tableView.topAnchor.constraint(equalTo: chipScrollView.bottomAnchor, constant: genres.count > 1 ? 8 : 0),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        rebuildGenreChips()
    }

    private func setupHeader() {
        headerView.backgroundColor = Colours.surfaceCard
        view.addSubviewForConstraints(headerView)

        titleLabel.text = titleText
        titleLabel.font = Fonts.bold19
        titleLabel.textColor = Colours.textPrimary

        let closeImage = UIImage(systemName: "xmark")
        closeButton.setImage(closeImage, for: .normal)
        closeButton.tintColor = Colours.textPrimary
        closeButton.backgroundColor = Colours.backgroundGrey
        closeButton.layer.cornerRadius = 16
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        headerView.addSubviewForConstraints(titleLabel)
        headerView.addSubviewForConstraints(closeButton)

        if selectedTag != nil {
            clearButton.setTitle("Clear", for: .normal)
            clearButton.setTitleColor(Colours.lightUI, for: .normal)
            clearButton.titleLabel?.font = Fonts.medium15
            clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
            headerView.addSubviewForConstraints(clearButton)

            NSLayoutConstraint.activate([
                clearButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
                clearButton.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -12)
            ])
        }

        let divider = UIView()
        divider.backgroundColor = Colours.separator
        headerView.addSubviewForConstraints(divider)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 52),

            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),

            closeButton.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            divider.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func clearTapped() {
        dismiss(animated: true) { [didClearTag] in
            didClearTag?()
        }
    }

    private func reloadSections() {
        BookInternalTagManager.shared.ensureHomeEligibleTags(for: genres) { [weak self] _, tags in
            guard let self else { return }
            let genreStories = CoreDataBookInternalManager.shared.getAll(in: genres)
            allTags = PersonalizedHomeTagBrowserRanking.rankedTags(
                from: tags,
                stories: genreStories,
                userIsSubscribed: AccountManager.shared.userIsSubscribed
            )

            rebuildGenreChips()
            refreshDisplayedTags()
        }
    }

    private func refreshDisplayedTags() {
        if let activeGenre {
            displayedTags = allTags.filter { $0.genre == activeGenre }
        } else {
            displayedTags = allTags
        }
        tableView.backgroundView = displayedTags.isEmpty ? emptyLabel : nil
        tableView.reloadData()
    }

    private func rebuildGenreChips() {
        chipButtons.forEach {
            chipStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        chipButtons.removeAll()

        guard genres.count > 1 else { return }

        let items = [TagBrowserChipItem(title: "All", genre: nil)] + genres.map {
            TagBrowserChipItem(title: $0.displayString, genre: $0)
        }

        for item in items {
            let button = UIButton(type: .system)
            button.setTitle(item.title, for: .normal)
            button.titleLabel?.font = Fonts.medium14
            button.layer.cornerRadius = 14
            button.layer.masksToBounds = true
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
            button.tag = chipButtons.count
            button.addTarget(self, action: #selector(genreChipTapped(_:)), for: .touchUpInside)
            button.accessibilityIdentifier = item.genre?.rawValue ?? "all"
            chipButtons.append(button)
            chipStackView.addArrangedSubview(button)
        }

        updateGenreChipAppearance()
    }

    private func updateGenreChipAppearance() {
        let accent = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
        for button in chipButtons {
            let identifier = button.accessibilityIdentifier
            let isSelected: Bool
            if identifier == "all" {
                isSelected = activeGenre == nil
            } else {
                isSelected = identifier == activeGenre?.rawValue
            }

            button.backgroundColor = isSelected ? Colours.themeAccentDark : accent.withAlphaComponent(0.1)
            button.setTitleColor(isSelected ? .white : accent, for: .normal)
        }
    }

    @objc private func genreChipTapped(_ sender: UIButton) {
        let identifier = sender.accessibilityIdentifier
        if identifier == "all" {
            activeGenre = nil
        } else if let identifier, let genre = BookInternalGenre(rawValue: identifier) {
            activeGenre = genre
        }

        updateGenreChipAppearance()
        refreshDisplayedTags()
    }
}

extension TagSelectionVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayedTags.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tag = displayedTags[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TagBrowserCell", for: indexPath) as! SelectionTableViewCell
        cell.configure(with: tag.title, isSelected: tag.id == selectedTag?.id)
        return cell
    }
}

extension TagSelectionVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        50
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let tag = displayedTags[indexPath.row]
        dismiss(animated: true) { [didSelectTag] in
            didSelectTag?(tag)
        }
    }
}
