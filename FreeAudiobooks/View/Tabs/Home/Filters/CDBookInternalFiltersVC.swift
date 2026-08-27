//
//  CDBookInternalFiltersVC.swift
//  FreeAudiobooks
//
//  Created by Claude on 09/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

protocol BookInternalFiltersVCDelegate: AnyObject {
    func didApplyFilters(_ filters: CDBookInternalSearchObject)
    func didClearFilters()
    func didChangeSortOption(_ sort: CDBookInternalSearchSortOption)
}

extension BookInternalFiltersVCDelegate {
    func didChangeSortOption(_ sort: CDBookInternalSearchSortOption) {}
}

private final class SearchFilterPillButton: UIButton {
    override var isSelected: Bool {
        didSet { updateAppearance() }
    }

    override var isEnabled: Bool {
        didSet { updateAppearance() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        titleLabel?.font = Fonts.medium14
        layer.cornerRadius = 16
        layer.borderWidth = 1
        contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        updateAppearance()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateAppearance()
    }

    private func updateAppearance() {
        if !isEnabled {
            backgroundColor = Colours.surfaceSecondary.withAlphaComponent(0.7)
            layer.borderColor = Colours.inputBorder.cgColor
            setTitleColor(Colours.textTertiary, for: .normal)
            return
        }

        if isSelected {
            backgroundColor = Colours.themeAccentDark
            layer.borderColor = Colours.themeAccentDark.cgColor
            setTitleColor(.white, for: .normal)
        } else {
            backgroundColor = Colours.surfaceCard
            layer.borderColor = Colours.inputBorder.cgColor
            setTitleColor(Colours.textPrimary, for: .normal)
        }
    }
}

private final class SearchFilterSectionHeaderView: UIView {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    init(title: String, subtitle: String? = nil) {
        super.init(frame: .zero)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateSubtitle(_ subtitle: String?) {
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle == nil
    }

    private func setupUI() {
        titleLabel.font = Fonts.semiBold16
        titleLabel.textColor = Colours.textPrimary

        subtitleLabel.font = Fonts.medium13
        subtitleLabel.textColor = Colours.textTertiary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.isHidden = subtitleLabel.text == nil

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 2
        addSubviewForConstraints(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

private extension CDBookInternalSearchSortOption {
    var compactSheetTitle: String {
        switch self {
        case .relevance: return "Relevance"
        case .popularity: return "Popular"
        case .newest: return "Newest"
        case .highestRated: return "Top rated"
        }
    }
}

private extension CDBookInternalMinimumRating {
    var compactSheetTitle: String {
        switch self {
        case .any: return "Any"
        case .threePlus: return "3+"
        case .fourPlus: return "4+"
        case .fourPointFivePlus: return "4.5+"
        }
    }
}

class CDBookInternalFiltersVC: BottomSheetController {

    // MARK: - Properties

    weak var delegate: BookInternalFiltersVCDelegate?

    private let committedSearchObject: CDBookInternalSearchObject
    private var draftSearchObject: CDBookInternalSearchObject

    private var sortButtons: [CDBookInternalSearchSortOption: SearchFilterPillButton] = [:]
    private var genreButtons: [BookInternalGenre: SearchFilterPillButton] = [:]
    private var formatButtons: [CDBookInternalFormatFilter: SearchFilterPillButton] = [:]
    private var lengthButtons: [CDBookInternalLengthBucket: SearchFilterPillButton] = [:]
    private var ratingButtons: [CDBookInternalMinimumRating: SearchFilterPillButton] = [:]

    // MARK: - UI

    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()

    private let sortHeaderView = SearchFilterSectionHeaderView(
        title: "Sort",
        subtitle: "Relevance uses popularity when no search query is entered."
    )
    private let sortGridStackView = UIStackView()

    private let genreHeaderView = SearchFilterSectionHeaderView(title: "Genre")
    private let genreGridStackView = UIStackView()

    private let formatHeaderView = SearchFilterSectionHeaderView(title: "Format")
    private let formatPillsStackView = UIStackView()

    private let lengthHeaderView = SearchFilterSectionHeaderView(title: "Length")
    private let lengthPillsStackView = UIStackView()

    private let ratingHeaderView = SearchFilterSectionHeaderView(title: "Minimum Rating")
    private let ratingPillsStackView = UIStackView()

    private let adultHeaderView = SearchFilterSectionHeaderView(
        title: "Adult Content",
        subtitle: "Available for Romance only."
    )
    private let adultRowView = UIView()
    private let adultToggleLabel = UILabel()
    private let adultToggleSwitch = UISwitch()

    private let bottomBarView = UIView()
    private let clearAllButton = UIButton(type: .system)
    private let applyButton = Buttons.primaryCTA(buttonTitle: "Apply")
    private let activeFiltersLabel = UILabel()

    // MARK: - Init

    init(currentFilters: CDBookInternalSearchObject) {
        self.committedSearchObject = currentFilters.copy()
        self.draftSearchObject = currentFilters.copy()
        super.init(nibName: nil, bundle: nil)
        preferredSheetSizing = .large
        preferredSheetCornerRadius = 24
        //preferredSheetBackdropColor = UIColor.black.withAlphaComponent(0.25)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        rebuildPills()
        refreshUI()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        adultRowView.layer.borderColor = Colours.inputBorder.cgColor
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = Colours.surfaceCard
        view.layer.masksToBounds = true

        setupHeader()
        setupScrollView()
        setupBottomBar()
        setupConstraints()
    }

    private func setupHeader() {
        headerView.backgroundColor = Colours.surfaceCard
        view.addSubviewForConstraints(headerView)

        titleLabel.text = "Sort & Filter"
        titleLabel.font = Fonts.semiBold18
        titleLabel.textColor = Colours.textPrimary

        let closeImage = UIImage(systemName: "xmark")
        closeButton.setImage(closeImage, for: .normal)
        closeButton.tintColor = Colours.textPrimary
        closeButton.backgroundColor = Colours.backgroundGrey
        closeButton.layer.cornerRadius = 16
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        headerView.addSubviewForConstraints(titleLabel)
        headerView.addSubviewForConstraints(closeButton)

        let divider = UIView()
        divider.backgroundColor = Colours.separator
        headerView.addSubviewForConstraints(divider)

        NSLayoutConstraint.activate([
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

    private func setupScrollView() {
        scrollView.showsVerticalScrollIndicator = true
        scrollView.keyboardDismissMode = .onDrag
        view.addSubviewForConstraints(scrollView)

        contentStackView.axis = .vertical
        contentStackView.spacing = 16
        scrollView.addSubviewForConstraints(contentStackView)

        configurePillStack(formatPillsStackView)
        configurePillStack(lengthPillsStackView)
        configurePillStack(ratingPillsStackView)

        sortGridStackView.axis = .vertical
        sortGridStackView.spacing = 8

        genreGridStackView.axis = .vertical
        genreGridStackView.spacing = 8

        setupAdultRow()

        addSection(sortHeaderView, body: sortGridStackView)
        addSection(genreHeaderView, body: genreGridStackView)
        addSection(formatHeaderView, body: formatPillsStackView)
        addSection(lengthHeaderView, body: lengthPillsStackView)
        addSection(ratingHeaderView, body: ratingPillsStackView)
        addSection(adultHeaderView, body: adultRowView)
    }

    private func setupAdultRow() {
        adultToggleLabel.font = Fonts.medium15
        adultToggleLabel.textColor = Colours.textPrimary
        adultToggleLabel.text = "Include 18+"

        adultToggleSwitch.onTintColor = Colours.orangePrimary
        adultToggleSwitch.addTarget(self, action: #selector(adultToggleChanged), for: .valueChanged)

        adultRowView.addSubviewForConstraints(adultToggleLabel)
        adultRowView.addSubviewForConstraints(adultToggleSwitch)

        NSLayoutConstraint.activate([
            adultToggleLabel.leadingAnchor.constraint(equalTo: adultRowView.leadingAnchor, constant: 12),
            adultToggleLabel.topAnchor.constraint(equalTo: adultRowView.topAnchor, constant: 10),
            adultToggleLabel.bottomAnchor.constraint(equalTo: adultRowView.bottomAnchor, constant: -10),

            adultToggleSwitch.trailingAnchor.constraint(equalTo: adultRowView.trailingAnchor, constant: -12),
            adultToggleSwitch.centerYAnchor.constraint(equalTo: adultToggleLabel.centerYAnchor),
            adultToggleLabel.trailingAnchor.constraint(lessThanOrEqualTo: adultToggleSwitch.leadingAnchor, constant: -12)
        ])

        adultRowView.backgroundColor = Colours.backgroundGrey
        adultRowView.layer.cornerRadius = UIConstants.shared.cardCornerRadius
        adultRowView.layer.borderWidth = 1
        adultRowView.layer.borderColor = Colours.inputBorder.cgColor
    }

    private func setupBottomBar() {
        bottomBarView.backgroundColor = Colours.surfaceCard
        view.addSubviewForConstraints(bottomBarView)

        let divider = UIView()
        divider.backgroundColor = Colours.separator
        bottomBarView.addSubviewForConstraints(divider)

        let clearAllButtonColor = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
        clearAllButton.setTitle("Clear all", for: .normal)
        clearAllButton.setTitleColor(clearAllButtonColor, for: .normal)
        clearAllButton.tintColor = clearAllButtonColor
        clearAllButton.titleLabel?.font = Fonts.medium15
        clearAllButton.addTarget(self, action: #selector(clearAllTapped), for: .touchUpInside)

        activeFiltersLabel.font = Fonts.medium13
        activeFiltersLabel.textColor = Colours.textSecondary
        activeFiltersLabel.textAlignment = .center

        applyButton.setTitle("Apply", for: .normal)
        applyButton.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)
        let applyButtonHeight: CGFloat = 44
        applyButton.layer.cornerRadius = applyButtonHeight / 2
        
        bottomBarView.addSubviewForConstraints(clearAllButton)
        bottomBarView.addSubviewForConstraints(activeFiltersLabel)
        bottomBarView.addSubviewForConstraints(applyButton)

        NSLayoutConstraint.activate([
            divider.topAnchor.constraint(equalTo: bottomBarView.topAnchor),
            divider.leadingAnchor.constraint(equalTo: bottomBarView.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: bottomBarView.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),

            clearAllButton.leadingAnchor.constraint(equalTo: bottomBarView.leadingAnchor, constant: 16),
            clearAllButton.centerYAnchor.constraint(equalTo: applyButton.centerYAnchor),

            applyButton.trailingAnchor.constraint(equalTo: bottomBarView.trailingAnchor, constant: -16),
            applyButton.topAnchor.constraint(equalTo: bottomBarView.topAnchor, constant: 12),
            applyButton.widthAnchor.constraint(equalToConstant: 120),
            applyButton.heightAnchor.constraint(equalToConstant: applyButtonHeight),

            activeFiltersLabel.centerYAnchor.constraint(equalTo: applyButton.centerYAnchor),
            activeFiltersLabel.leadingAnchor.constraint(greaterThanOrEqualTo: clearAllButton.trailingAnchor, constant: 8),
            activeFiltersLabel.trailingAnchor.constraint(lessThanOrEqualTo: applyButton.leadingAnchor, constant: -8),
            activeFiltersLabel.centerXAnchor.constraint(equalTo: bottomBarView.centerXAnchor),
            activeFiltersLabel.bottomAnchor.constraint(equalTo: bottomBarView.safeBottomAnchor, constant: -12)
        ])
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 53),

            bottomBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBarView.topAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }

    private func configurePillStack(_ stackView: UIStackView) {
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .fill
        stackView.distribution = .fillProportionally
    }

    private func addSection(_ header: UIView, body: UIView) {
        let sectionStack = UIStackView(arrangedSubviews: [header, body])
        sectionStack.axis = .vertical
        sectionStack.spacing = 8
        contentStackView.addArrangedSubview(sectionStack)
    }

    // MARK: - Build UI

    private func rebuildPills() {
        buildSortPills()
        buildGenreGrid()
        buildFormatPills()
        buildLengthPills()
        buildRatingPills()
    }

    private func buildSortPills() {
        sortGridStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        sortButtons.removeAll()

        let options = CDBookInternalSearchSortOption.allCases
        stride(from: 0, to: options.count, by: 2).forEach { index in
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 8
            row.distribution = .fillEqually

            let leftOption = options[index]
            let leftButton = makePillButton(title: leftOption.compactSheetTitle)
            leftButton.addTarget(self, action: #selector(sortPillTapped(_:)), for: .touchUpInside)
            leftButton.tag = index
            sortButtons[leftOption] = leftButton
            row.addArrangedSubview(leftButton)

            if index + 1 < options.count {
                let rightOption = options[index + 1]
                let rightButton = makePillButton(title: rightOption.compactSheetTitle)
                rightButton.addTarget(self, action: #selector(sortPillTapped(_:)), for: .touchUpInside)
                rightButton.tag = index + 1
                sortButtons[rightOption] = rightButton
                row.addArrangedSubview(rightButton)
            } else {
                row.addArrangedSubview(UIView())
            }

            sortGridStackView.addArrangedSubview(row)
        }
    }

    private func buildGenreGrid() {
        genreGridStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        genreButtons.removeAll()

        let genres = BookInternalGenre.allCases
        stride(from: 0, to: genres.count, by: 2).forEach { index in
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 8
            row.distribution = .fillEqually

            let leftGenre = genres[index]
            let leftButton = makePillButton(title: leftGenre.displayString)
            leftButton.addTarget(self, action: #selector(genrePillTapped(_:)), for: .touchUpInside)
            leftButton.tag = index
            genreButtons[leftGenre] = leftButton
            row.addArrangedSubview(leftButton)

            if index + 1 < genres.count {
                let rightGenre = genres[index + 1]
                let rightButton = makePillButton(title: rightGenre.displayString)
                rightButton.addTarget(self, action: #selector(genrePillTapped(_:)), for: .touchUpInside)
                rightButton.tag = index + 1
                genreButtons[rightGenre] = rightButton
                row.addArrangedSubview(rightButton)
            } else {
                let spacer = UIView()
                row.addArrangedSubview(spacer)
            }

            genreGridStackView.addArrangedSubview(row)
        }
    }

    private func buildFormatPills() {
        formatPillsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        CDBookInternalFormatFilter.filterDisplayOrder.enumerated().forEach { index, option in
            let button = makePillButton(title: option.displayTitle)
            button.addTarget(self, action: #selector(formatPillTapped(_:)), for: .touchUpInside)
            button.tag = index
            formatButtons[option] = button
            formatPillsStackView.addArrangedSubview(button)
        }
    }

    private func buildLengthPills() {
        lengthPillsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        CDBookInternalLengthBucket.allCases.forEach { option in
            let button = makePillButton(title: option.displayTitle)
            button.addTarget(self, action: #selector(lengthPillTapped(_:)), for: .touchUpInside)
            button.tag = CDBookInternalLengthBucket.allCases.firstIndex(of: option) ?? 0
            lengthButtons[option] = button
            lengthPillsStackView.addArrangedSubview(button)
        }
    }

    private func buildRatingPills() {
        ratingPillsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        CDBookInternalMinimumRating.allCases.forEach { option in
            let button = makePillButton(title: option.compactSheetTitle)
            button.addTarget(self, action: #selector(ratingPillTapped(_:)), for: .touchUpInside)
            button.tag = CDBookInternalMinimumRating.allCases.firstIndex(of: option) ?? 0
            ratingButtons[option] = button
            ratingPillsStackView.addArrangedSubview(button)
        }
    }

    private func makePillButton(title: String) -> SearchFilterPillButton {
        let button = SearchFilterPillButton(frame: .zero)
        button.setTitle(title, for: .normal)
        return button
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func clearAllTapped() {
        HapticFeedbackHelper.shared.triggerLightImpactFeedback()
        draftSearchObject.clearAll()
        delegate?.didClearFilters()
        dismiss(animated: true)
    }

    @objc private func applyTapped() {
        HapticFeedbackHelper.shared.triggerLightImpactFeedback()

        if draftSearchObject.genre != .romance {
            draftSearchObject.includeAdultContentForRomance = false
        }

        delegate?.didApplyFilters(draftSearchObject.copy())
        dismiss(animated: true)
    }

    @objc private func adultToggleChanged() {
        HapticFeedbackHelper.shared.triggerSelectionChangeHaptic()
        draftSearchObject.includeAdultContentForRomance = adultToggleSwitch.isOn
        refreshUI()
    }

    @objc private func sortPillTapped(_ sender: UIButton) {
        let options = CDBookInternalSearchSortOption.allCases
        guard sender.tag >= 0, sender.tag < options.count else { return }
        HapticFeedbackHelper.shared.triggerSelectionChangeHaptic()
        let selectedOption = options[sender.tag]
        draftSearchObject.sortOption = selectedOption
        delegate?.didChangeSortOption(selectedOption)
        refreshUI()
    }

    @objc private func genrePillTapped(_ sender: UIButton) {
        let options = BookInternalGenre.allCases
        guard sender.tag >= 0, sender.tag < options.count else { return }
        HapticFeedbackHelper.shared.triggerSelectionChangeHaptic()

        let previousGenre = draftSearchObject.genre
        let selectedGenre = options[sender.tag]
        if draftSearchObject.genre == selectedGenre {
            draftSearchObject.genre = nil
        } else {
            draftSearchObject.genre = selectedGenre
        }

        if draftSearchObject.genre == .romance, previousGenre != .romance {
            draftSearchObject.includeAdultContentForRomance = true
        } else if draftSearchObject.genre != .romance {
            draftSearchObject.includeAdultContentForRomance = false
        }

        refreshUI()
    }

    @objc private func formatPillTapped(_ sender: UIButton) {
        let options = CDBookInternalFormatFilter.filterDisplayOrder
        guard sender.tag >= 0, sender.tag < options.count else { return }
        HapticFeedbackHelper.shared.triggerSelectionChangeHaptic()
        draftSearchObject.format = options[sender.tag]
        refreshUI()
    }

    @objc private func lengthPillTapped(_ sender: UIButton) {
        let options = CDBookInternalLengthBucket.allCases
        guard sender.tag >= 0, sender.tag < options.count else { return }
        HapticFeedbackHelper.shared.triggerSelectionChangeHaptic()
        let bucket = options[sender.tag]
        let nextValue: CDBookInternalLengthBucket? = draftSearchObject.selectedLengthBucket == bucket ? nil : bucket
        draftSearchObject.setLengthBucket(nextValue)
        refreshUI()
    }

    @objc private func ratingPillTapped(_ sender: UIButton) {
        let options = CDBookInternalMinimumRating.allCases
        guard sender.tag >= 0, sender.tag < options.count else { return }
        HapticFeedbackHelper.shared.triggerSelectionChangeHaptic()
        draftSearchObject.minimumRating = options[sender.tag]
        refreshUI()
    }

    // MARK: - UI Refresh

    private func refreshUI() {
        let selectedLength = draftSearchObject.selectedLengthBucket
        let romanceSelected = draftSearchObject.genre == .romance

        for (option, button) in sortButtons {
            button.isSelected = draftSearchObject.sortOption == option
        }
        for (genre, button) in genreButtons {
            button.isSelected = draftSearchObject.genre == genre
        }
        for (option, button) in formatButtons {
            button.isSelected = draftSearchObject.format == option
        }
        for (option, button) in lengthButtons {
            button.isSelected = selectedLength == option
        }
        for (option, button) in ratingButtons {
            button.isSelected = draftSearchObject.minimumRating == option
        }

        adultToggleSwitch.isEnabled = romanceSelected
        adultToggleLabel.textColor = romanceSelected ? Colours.textPrimary : Colours.textTertiary
        adultToggleSwitch.setOn(romanceSelected && draftSearchObject.includeAdultContentForRomance, animated: false)
        adultRowView.alpha = romanceSelected ? 1.0 : 0.7

        let activeConfigurationCount = draftSearchObject.activeFilterCount + (draftSearchObject.sortOption == .relevance ? 0 : 1)
        activeFiltersLabel.text = activeConfigurationCount > 0 ? "\(activeConfigurationCount) active" : "No active filters"
    }
}
