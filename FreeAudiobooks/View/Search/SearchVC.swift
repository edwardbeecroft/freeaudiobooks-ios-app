//
//  SearchVC.swift
//  FreeAudiobooks
//
//  Created by Codex on 20/02/2026.
//

import UIKit
import SuperwallKit
import Kingfisher

private enum SearchViewState: String {
    case discovery
    case refined
}


enum SearchRefinementControl: CaseIterable {
    case genre
    case tag
    case format
    case length
    case rating
    case adult
    case sort
}

private final class SearchRefinementChipView: UIControl {
    private let label = UILabel()
    private let clearButton = UIButton(type: .system)
    private var control: SearchRefinementControl?
    private var labelTrailingToEdgeConstraint: NSLayoutConstraint?
    private var labelTrailingToClearConstraint: NSLayoutConstraint?
    private var clearButtonWidthConstraint: NSLayoutConstraint?
    private var cachedConfiguration: (
        control: SearchRefinementControl,
        title: String,
        isActive: Bool,
        canClear: Bool,
        isEnabled: Bool
    )?

    var onTap: ((SearchRefinementControl) -> Void)?
    var onClear: ((SearchRefinementControl) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        layer.cornerRadius = 14
        clipsToBounds = true

        label.font = UIConstants.shared.filterChipFont
        label.numberOfLines = 1
        addSubviewForConstraints(label)

        clearButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        clearButton.tintColor = UIColor.white.withAlphaComponent(0.95)
        clearButton.isHidden = true
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        addSubviewForConstraints(clearButton)

        addTarget(self, action: #selector(chipTapped), for: .touchUpInside)

        labelTrailingToEdgeConstraint = label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        labelTrailingToClearConstraint = label.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -6)
        clearButtonWidthConstraint = clearButton.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            labelTrailingToEdgeConstraint!,

            clearButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            clearButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            clearButtonWidthConstraint!,
            clearButton.heightAnchor.constraint(equalToConstant: 16),

            heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        if let config = cachedConfiguration {
            configure(
                control: config.control,
                title: config.title,
                isActive: config.isActive,
                canClear: config.canClear,
                isEnabled: config.isEnabled
            )
        }
    }

    func configure(
        control: SearchRefinementControl,
        title: String,
        isActive: Bool,
        canClear: Bool,
        isEnabled: Bool
    ) {
        cachedConfiguration = (control, title, isActive, canClear, isEnabled)
        self.control = control
        label.text = title
        self.isEnabled = isEnabled
        let showsClearButton = isActive && canClear
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits = isActive ? [.button, .selected] : .button
        accessibilityCustomActions = showsClearButton
            ? [UIAccessibilityCustomAction(
                name: "Clear \(title)",
                target: self,
                selector: #selector(accessibilityClearFilter)
            )]
            : nil
        clearButton.isHidden = !showsClearButton
        clearButtonWidthConstraint?.constant = showsClearButton ? 16 : 0
        if showsClearButton {
            labelTrailingToEdgeConstraint?.isActive = false
            labelTrailingToClearConstraint?.isActive = true
        } else {
            labelTrailingToClearConstraint?.isActive = false
            labelTrailingToEdgeConstraint?.isActive = true
        }

        if !isEnabled {
            backgroundColor = Colours.surfaceSecondary.withAlphaComponent(0.75)
            label.textColor = Colours.textTertiary
            return
        }

        let accent = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
        if isActive {
            backgroundColor = Colours.themeAccentDark
            label.textColor = .white
        } else {
            backgroundColor = accent.withAlphaComponent(0.1)
            label.textColor = accent
        }
    }

    @objc private func chipTapped() {
        guard let control, isEnabled else { return }
        onTap?(control)
    }

    @objc private func clearTapped() {
        guard let control, isEnabled else { return }
        onClear?(control)
    }

    @objc private func accessibilityClearFilter() -> Bool {
        guard let control, isEnabled else { return false }
        onClear?(control)
        return true
    }
}

final class SearchRefinementChipsScrollView: UIScrollView {
    private let stackView = UIStackView()
    private var chipViews: [SearchRefinementControl: SearchRefinementChipView] = [:]

    var onTapControl: ((SearchRefinementControl) -> Void)?
    var onClearControl: ((SearchRefinementControl) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        buildChips()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false

        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: heightAnchor)
        ])
    }

    private func buildChips() {
        SearchRefinementControl.allCases.forEach { control in
            let chipView = SearchRefinementChipView()
            chipView.onTap = { [weak self] control in self?.onTapControl?(control) }
            chipView.onClear = { [weak self] control in self?.onClearControl?(control) }
            chipViews[control] = chipView
            stackView.addArrangedSubview(chipView)
        }
    }

    private func applyChipOrder(_ order: [SearchRefinementControl]) {
        stackView.arrangedSubviews.forEach { stackView.removeArrangedSubview($0) }
        order.forEach { control in
            if let chip = chipViews[control] {
                stackView.addArrangedSubview(chip)
            }
        }
    }

    func configure(with searchObject: CDBookInternalSearchObject) {
        let lengthTitle = searchObject.selectedLengthBucket?.displayTitle
        let isRomance = searchObject.genre == .romance
        let showAdultActive = isRomance && searchObject.includeAdultContentForRomance
        let hasGenre = searchObject.genre != nil

        chipViews[.tag]?.isHidden = !hasGenre
        chipViews[.adult]?.isHidden = !isRomance
        if isRomance {
            applyChipOrder([.genre, .adult, .tag, .length, .rating, .format, .sort])
        } else {
            applyChipOrder([.genre, .tag, .length, .rating, .format, .sort, .adult])
        }

        chipViews[.genre]?.configure(
            control: .genre,
            title: searchObject.genre?.displayString ?? "+ Genre",
            isActive: searchObject.genre != nil,
            canClear: searchObject.genre != nil,
            isEnabled: true
        )
        chipViews[.tag]?.configure(
            control: .tag,
            title: searchObject.tag?.title ?? "+ Tag",
            isActive: searchObject.tag != nil,
            canClear: searchObject.tag != nil,
            isEnabled: hasGenre
        )
        chipViews[.format]?.configure(
            control: .format,
            title: searchObject.format == .any ? "+ Format" : searchObject.format.displayTitle,
            isActive: searchObject.format != .any,
            canClear: searchObject.format != .any,
            isEnabled: true
        )
        chipViews[.length]?.configure(
            control: .length,
            title: lengthTitle ?? "+ Listening Time",
            isActive: lengthTitle != nil,
            canClear: lengthTitle != nil,
            isEnabled: true
        )
        chipViews[.rating]?.configure(
            control: .rating,
            title: searchObject.minimumRating == .any ? "+ Rating" : searchObject.minimumRating.displayTitle,
            isActive: searchObject.minimumRating != .any,
            canClear: searchObject.minimumRating != .any,
            isEnabled: true
        )
        chipViews[.adult]?.configure(
            control: .adult,
            title: showAdultActive ? "18+" : "+ 18+",
            isActive: showAdultActive,
            canClear: showAdultActive,
            isEnabled: isRomance
        )
        chipViews[.sort]?.configure(
            control: .sort,
            title: searchObject.sortOption == .relevance ? "+ Sort" : searchObject.sortOption.displayTitle,
            isActive: searchObject.sortOption != .relevance,
            canClear: searchObject.sortOption != .relevance,
            isEnabled: true
        )
    }
}

private struct SearchSingleRefinementOption {
    let title: String
    let isSelected: Bool
}

/// A deliberately small, single-purpose sheet used by the Search refinement capsules.
private final class SearchSingleRefinementPickerVC: BottomSheetController {
    private let titleText: String
    private let options: [SearchSingleRefinementOption]
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let tableView = UITableView()

    var didSelectOption: ((Int) -> Void)?

    init(title: String, options: [SearchSingleRefinementOption]) {
        titleText = title
        self.options = options
        super.init(nibName: nil, bundle: nil)
        preferredSheetSizing = .fit
        preferredSheetCornerRadius = 24
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = Colours.surfaceCard
        view.layer.masksToBounds = true

        headerView.backgroundColor = Colours.surfaceCard
        view.addSubviewForConstraints(headerView)

        titleLabel.text = titleText
        titleLabel.font = Fonts.bold19
        titleLabel.textColor = Colours.textPrimary
        headerView.addSubviewForConstraints(titleLabel)

        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = Colours.textPrimary
        closeButton.backgroundColor = Colours.backgroundGrey
        closeButton.layer.cornerRadius = 16
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        headerView.addSubviewForConstraints(closeButton)

        let divider = UIView()
        divider.backgroundColor = Colours.separator
        headerView.addSubviewForConstraints(divider)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = Colours.surfaceCard
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.register(SelectionTableViewCell.self, forCellReuseIdentifier: "SearchRefinementOptionCell")
        view.addSubviewForConstraints(tableView)

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
            divider.heightAnchor.constraint(equalToConstant: 1),

            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.heightAnchor.constraint(equalToConstant: CGFloat(options.count) * 52)
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

extension SearchSingleRefinementPickerVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let option = options[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchRefinementOptionCell", for: indexPath)
            as! SelectionTableViewCell
        cell.configure(with: option.title, isSelected: option.isSelected)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        52
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        HapticFeedbackHelper.shared.triggerSelectionChangeHaptic()
        dismiss(animated: true) { [didSelectOption] in
            didSelectOption?(indexPath.row)
        }
    }
}

private final class SearchEmptyStateView: UIView {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    var actionHandler: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 10
        addSubviewForConstraints(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        titleLabel.font = Fonts.semiBold20
        titleLabel.textColor = Colours.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        subtitleLabel.font = Fonts.medium15
        subtitleLabel.textColor = Colours.subtext
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        actionButton.titleLabel?.font = Fonts.semiBold16
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.backgroundColor = Colours.ctaBackground
        actionButton.layer.masksToBounds = true
        actionButton.layer.cornerRadius = UIConstants.shared.midButtonHeight / 2
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(actionButton)

        NSLayoutConstraint.activate([
            actionButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.midButtonHeight)
        ])
    }

    @objc private func actionTapped() {
        actionHandler?()
    }

    func configure(isRefined: Bool) {
        if isRefined {
            titleLabel.text = "No books found"
            subtitleLabel.text = "Try adjusting your query or removing filters."
            actionButton.setTitle("Clear refinements", for: .normal)
            actionButton.isHidden = false
        } else {
            titleLabel.text = "No books available right now"
            subtitleLabel.text = "Please check back soon for fresh stories."
            actionButton.isHidden = true
        }
    }
}

private final class SearchDiscoveryEndOfFeedPromptTVC: UITableViewCell {
    enum Action {
        case genre
        case length
        case search
    }

    var actionHandler: ((Action) -> Void)?

    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let buttonsStackView = UIStackView()
    private let genreButton = UIButton(type: .system)
    private let filtersButton = UIButton(type: .system)
    private let searchButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = Colours.surfacePrimary
        selectionStyle = .none
        contentView.backgroundColor = Colours.surfacePrimary

        cardView.backgroundColor = Colours.surfaceSecondary
        cardView.layer.cornerRadius = 14
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = Colours.inputBorder.cgColor
        contentView.addSubviewForConstraints(cardView)

        titleLabel.font = Fonts.semiBold18
        titleLabel.textColor = Colours.textPrimary
        titleLabel.text = "Refine your search"

        subtitleLabel.font = Fonts.medium14
        subtitleLabel.textColor = Colours.subtext
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = "Pick one refinement or search by title."

        buttonsStackView.axis = .horizontal
        buttonsStackView.spacing = 8
        buttonsStackView.distribution = .fillEqually

        configureActionButton(genreButton, title: "Pick a genre", action: #selector(genreTapped))
        configureActionButton(filtersButton, title: "Choose length", action: #selector(lengthTapped))
        configureActionButton(searchButton, title: "Search by title", action: #selector(searchTapped))

        buttonsStackView.addArrangedSubview(genreButton)
        buttonsStackView.addArrangedSubview(filtersButton)
        buttonsStackView.addArrangedSubview(searchButton)

        cardView.addSubviewForConstraints(titleLabel)
        cardView.addSubviewForConstraints(subtitleLabel)
        cardView.addSubviewForConstraints(buttonsStackView)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            buttonsStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12),
            buttonsStackView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            buttonsStackView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            buttonsStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),
            buttonsStackView.heightAnchor.constraint(equalToConstant: 34)
        ])
    }

    private func configureActionButton(_ button: UIButton, title: String, action: Selector) {
        let accent = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = Fonts.medium14
        button.setTitleColor(accent, for: .normal)
        button.backgroundColor = accent.withAlphaComponent(0.1)
        button.layer.cornerRadius = 17
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        cardView.layer.borderColor = Colours.inputBorder.cgColor
        let accent = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
        [genreButton, filtersButton, searchButton].forEach {
            $0.backgroundColor = accent.withAlphaComponent(0.1)
        }
    }

    @objc private func genreTapped() {
        actionHandler?(.genre)
    }

    @objc private func lengthTapped() {
        actionHandler?(.length)
    }

    @objc private func searchTapped() {
        actionHandler?(.search)
    }
}

private final class SearchRecentlyViewedCVC: UICollectionViewCell {
    struct Layout {
        static let containerTopBottomPadding: CGFloat = 8
        static let coverImageHeight: CGFloat = floor(UIConstants.shared.discoverCardCoverHeight * 0.76)
        static let coverImageCornerRadius: CGFloat = UIConstants.shared.bookCoverCornerRadius

        static var coverImageWidth: CGFloat {
            coverImageHeight * UIConstants.shared.bookInternalCoverImageWidthToHeightRatio
        }

        static var cardHeight: CGFloat {
            containerTopBottomPadding + coverImageHeight + containerTopBottomPadding
        }
    }

    static let reuseIdentifier = "SearchRecentlyViewedCVC"

    private var contentMetadata: ReadableContentMetadata?

    private let containerView = UIView()
    private let coverImageView = UIImageView()
    private let completionOverlayView = UIView()
    private let completionTickImageView = UIImageView()
    private let adultContentBadge = AdultContentBadge()
    private let progressView = UIProgressView(progressViewStyle: .bar)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        setupContainerView()
        setupCoverImageView()
        setupCompletionOverlay()
        setupAdultContentBadge()
        setupProgressView()
        setupConstraints()

        [coverImageView, completionOverlayView].forEach {
            $0.layer.cornerRadius = Layout.coverImageCornerRadius
            $0.layer.masksToBounds = true
        }
    }

    private func setupContainerView() {
        contentView.addSubviewForConstraints(containerView)
    }

    private func setupCoverImageView() {
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.backgroundColor = UIColor.systemGray6
        containerView.addSubviewForConstraints(coverImageView)
    }

    private func setupCompletionOverlay() {
        completionOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        completionOverlayView.isHidden = true

        completionTickImageView.image = UIImage(systemName: "checkmark.circle.fill")
        completionTickImageView.tintColor = UIColor.white
        completionTickImageView.contentMode = .scaleAspectFit

        coverImageView.addSubviewForConstraints(completionOverlayView)
        completionOverlayView.addSubviewForConstraints(completionTickImageView)
    }

    private func setupAdultContentBadge() {
        adultContentBadge.isHidden = true
        adultContentBadge.style = .overlay
        coverImageView.addSubviewForConstraints(adultContentBadge)
    }

    private func setupProgressView() {
        progressView.progressTintColor = Colours.orangePrimary
        progressView.trackTintColor = UIColor.systemGray5
        progressView.isHidden = true
        coverImageView.addSubviewForConstraints(progressView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            coverImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Layout.containerTopBottomPadding),
            coverImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            coverImageView.heightAnchor.constraint(equalToConstant: Layout.coverImageHeight),
            coverImageView.widthAnchor.constraint(equalToConstant: Layout.coverImageWidth),
            coverImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Layout.containerTopBottomPadding),

            completionOverlayView.topAnchor.constraint(equalTo: coverImageView.topAnchor),
            completionOverlayView.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor),
            completionOverlayView.trailingAnchor.constraint(equalTo: coverImageView.trailingAnchor),
            completionOverlayView.bottomAnchor.constraint(equalTo: coverImageView.bottomAnchor),

            completionTickImageView.trailingAnchor.constraint(equalTo: completionOverlayView.trailingAnchor, constant: -4),
            completionTickImageView.widthAnchor.constraint(equalToConstant: 20),
            completionTickImageView.heightAnchor.constraint(equalToConstant: 20),

            progressView.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: coverImageView.trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: coverImageView.bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4),

            adultContentBadge.topAnchor.constraint(equalTo: coverImageView.topAnchor, constant: 6),
            adultContentBadge.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor, constant: 6),
            adultContentBadge.widthAnchor.constraint(equalToConstant: 36),
            adultContentBadge.heightAnchor.constraint(equalToConstant: 20),

            completionTickImageView.centerYAnchor.constraint(equalTo: adultContentBadge.centerYAnchor)
        ])
    }

    func configure(with story: CDBookInternal) {
        contentMetadata = story

        if let coverImageURLThumbnail = story.coverImageURLThumbnail,
           let imageURL = URL(string: coverImageURLThumbnail) {
            coverImageView.kf.indicatorType = .activity
            coverImageView.kf.setImage(with: imageURL, placeholder: nil, options: [.transition(.fade(0.2))])
        } else {
            coverImageView.image = UIImage(systemName: "book.fill")?.withRenderingMode(.alwaysTemplate)
            coverImageView.tintColor = Colours.textPrimary.withAlphaComponent(0.3)
        }

        updateCompletionStatus()
        updateProgressBar()
        adultContentBadge.isHidden = !story.shouldShowAdultContentBadgeOnCovers
    }

    private func updateCompletionStatus() {
        guard let contentMetadata else { return }
        let isCompleted = AccountManager.shared.userHasCompletedBookInternalWithUUID(contentMetadata.contentUUID)
        completionOverlayView.isHidden = !isCompleted
    }

    private func updateProgressBar() {
        guard let contentMetadata else { return }
        let isCompleted = AccountManager.shared.userHasCompletedBookInternalWithUUID(contentMetadata.contentUUID)
        if isCompleted {
            progressView.isHidden = true
            return
        }

        if let progressPercentage = ReadingUserDefaults.progressForBookWithUUID(contentMetadata.contentUUID),
           progressPercentage > 0 {
            progressView.progress = Float(progressPercentage) / 100.0
            progressView.isHidden = false
        } else {
            progressView.isHidden = true
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentMetadata = nil
        coverImageView.image = nil
        coverImageView.kf.cancelDownloadTask()
        completionOverlayView.isHidden = true
        progressView.isHidden = true
        progressView.progress = 0
        adultContentBadge.isHidden = true
    }
}

private final class SearchRecentlyViewedCarouselView: UIView {
    struct Layout {
        static let topMargin: CGFloat = 22
        static let estimatedTitleHeight: CGFloat = 24
        static let titleToCollectionSpacing: CGFloat = 0
        static let bottomMargin: CGFloat = 4

        static var collectionHeight: CGFloat {
            SearchRecentlyViewedCVC.Layout.cardHeight
        }

        static var totalHeight: CGFloat {
            topMargin + estimatedTitleHeight + titleToCollectionSpacing + collectionHeight + bottomMargin
        }
    }

    private var stories: [CDBookInternal] = []

    private let titleLabel = UILabel()
    private let seeAllButton = UIButton(type: .system)
    private let collectionView: UICollectionView

    var tappedBookInternalHandler: ((CDBookInternal) -> Void)?
    var tappedShowMoreChevronHandler: (() -> Void)?

    override init(frame: CGRect = .zero) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = UIConstants.shared.discoverCarouselMinimumLineSpacing
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(
            top: 0,
            left: UIConstants.shared.standardMargin,
            bottom: 0,
            right: UIConstants.shared.standardMargin
        )
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = Colours.surfacePrimary
        setupTitleLabel()
        setupSeeAllButton()
        setupCollectionView()
        setupConstraints()
    }

    private func setupTitleLabel() {
        titleLabel.font = UIConstants.shared.carouselTitleFont
        titleLabel.textColor = UIConstants.shared.carouselTitleTextColour
        titleLabel.numberOfLines = 1
        titleLabel.backgroundColor = .clear
        addSubviewForConstraints(titleLabel)
    }

    private func setupSeeAllButton() {
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 8, weight: .bold)
        let chevronImage = UIImage(systemName: "chevron.right", withConfiguration: chevronConfig)
        seeAllButton.setTitle("See all", for: .normal)
        let seeAllColor = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
        seeAllButton.setTitleColor(seeAllColor, for: .normal)
        seeAllButton.titleLabel?.font = Fonts.medium15
        seeAllButton.setImage(chevronImage, for: .normal)
        seeAllButton.tintColor = seeAllColor
        seeAllButton.semanticContentAttribute = .forceRightToLeft
        seeAllButton.contentHorizontalAlignment = .right
        seeAllButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 2)
        seeAllButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
        seeAllButton.setContentHuggingPriority(.required, for: .horizontal)
        seeAllButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        seeAllButton.isHidden = true
        seeAllButton.addTarget(self, action: #selector(seeAllTapped), for: .touchUpInside)
        addSubviewForConstraints(seeAllButton)
    }

    @objc private func seeAllTapped() {
        tappedShowMoreChevronHandler?()
    }

    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(SearchRecentlyViewedCVC.self, forCellWithReuseIdentifier: SearchRecentlyViewedCVC.reuseIdentifier)
        addSubviewForConstraints(collectionView)
    }

    private func setupConstraints() {
        let titleTopConstraint = titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: Layout.topMargin)
        let collectionTopConstraint = collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Layout.titleToCollectionSpacing)
        let collectionBottomConstraint = collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.bottomMargin)
        let collectionHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: Layout.collectionHeight)
        let titleLeadingConstraint = titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UIConstants.shared.standardMargin)
        let titleTrailingToButtonConstraint = titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: seeAllButton.leadingAnchor, constant: -12)
        let buttonLeadingToTitleConstraint = seeAllButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12)
        let buttonTrailingConstraint = seeAllButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UIConstants.shared.standardMargin)
        let buttonMaxWidthConstraint = seeAllButton.widthAnchor.constraint(lessThanOrEqualToConstant: 110)
        let buttonMinWidthConstraint = seeAllButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 84)
        let collapseCompatiblePriority = UILayoutPriority(999)

        titleTopConstraint.priority = collapseCompatiblePriority
        collectionTopConstraint.priority = collapseCompatiblePriority
        collectionBottomConstraint.priority = collapseCompatiblePriority
        collectionHeightConstraint.priority = collapseCompatiblePriority
        titleLeadingConstraint.priority = collapseCompatiblePriority
        titleTrailingToButtonConstraint.priority = collapseCompatiblePriority
        buttonLeadingToTitleConstraint.priority = collapseCompatiblePriority
        buttonTrailingConstraint.priority = collapseCompatiblePriority
        buttonMaxWidthConstraint.priority = collapseCompatiblePriority
        buttonMinWidthConstraint.priority = collapseCompatiblePriority

        NSLayoutConstraint.activate([
            titleTopConstraint,
            titleLeadingConstraint,
            titleTrailingToButtonConstraint,

            seeAllButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor, constant: 1),
            buttonLeadingToTitleConstraint,
            buttonTrailingConstraint,
            buttonMaxWidthConstraint,
            buttonMinWidthConstraint,
            seeAllButton.heightAnchor.constraint(equalToConstant: 30),

            collectionTopConstraint,
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionBottomConstraint,
            collectionHeightConstraint
        ])
    }

    func configure(title: String, stories: [CDBookInternal], showsChevron: Bool) {
        self.stories = stories
        titleLabel.text = title
        seeAllButton.isHidden = !showsChevron
        collectionView.reloadData()
    }
}

extension SearchRecentlyViewedCarouselView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        stories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SearchRecentlyViewedCVC.reuseIdentifier,
            for: indexPath
        ) as! SearchRecentlyViewedCVC
        cell.configure(with: stories[indexPath.item])
        return cell
    }
}

extension SearchRecentlyViewedCarouselView: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(
            width: SearchRecentlyViewedCVC.Layout.coverImageWidth,
            height: SearchRecentlyViewedCVC.Layout.cardHeight
        )
    }
}

extension SearchRecentlyViewedCarouselView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        tappedBookInternalHandler?(stories[indexPath.item])
    }
}

private final class SearchGenreTagPreviewHeaderView: UIView {
    struct Layout {
        static let height: CGFloat = 52
        static let horizontalMargin: CGFloat = 16
        static let chipHeight: CGFloat = 28
        static let chipSpacing: CGFloat = 8
        static let loadingChipWidths: [CGFloat] = [88, 116, 96]
    }

    private var tags: [BookInternalTag] = []
    private var isLoading = false
    private let titleLabel = UILabel()
    private let collectionView: UICollectionView

    var tappedTagHandler: ((BookInternalTag) -> Void)?
    var tappedMoreHandler: (() -> Void)?

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = Layout.chipSpacing
        layout.minimumInteritemSpacing = Layout.chipSpacing
        layout.sectionInset = UIEdgeInsets(top: 0,
                                           left: 0,
                                           bottom: 0,
                                           right: Layout.horizontalMargin)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = Colours.surfacePrimary

        titleLabel.font = Fonts.medium13
        titleLabel.textColor = Colours.textSecondary
        titleLabel.text = "Popular:"
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        addSubviewForConstraints(titleLabel)

        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(SearchGenreTagChipCVC.self,
                                forCellWithReuseIdentifier: SearchGenreTagChipCVC.reuseIdentifier)
        addSubviewForConstraints(collectionView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalMargin),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            collectionView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: Layout.chipSpacing),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.centerYAnchor.constraint(equalTo: centerYAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: Layout.chipHeight)
        ])
    }

    func configureLoading() {
        guard !isLoading || !tags.isEmpty else { return }
        isLoading = true
        tags = []
        reloadCollectionView(animated: window != nil)
    }

    func configure(tags: [BookInternalTag]) {
        let shouldAnimate = isLoading && window != nil
        isLoading = false
        self.tags = tags
        reloadCollectionView(animated: shouldAnimate)
    }

    private func reloadCollectionView(animated: Bool) {
        let updates = {
            self.collectionView.reloadData()
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.setContentOffset(.zero, animated: false)
        }

        guard animated else {
            updates()
            return
        }

        UIView.transition(
            with: collectionView,
            duration: 0.2,
            options: [.transitionCrossDissolve, .allowAnimatedContent, .beginFromCurrentState],
            animations: updates
        )
    }
}

extension SearchGenreTagPreviewHeaderView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        isLoading ? Layout.loadingChipWidths.count : (tags.isEmpty ? 0 : tags.count + 1)
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SearchGenreTagChipCVC.reuseIdentifier,
            for: indexPath
        ) as! SearchGenreTagChipCVC
        if isLoading {
            cell.configureLoading()
        } else if indexPath.item < tags.count {
            cell.configure(title: tags[indexPath.item].title)
        } else {
            cell.configure(title: "More ›", isMore: true)
        }
        return cell
    }
}

extension SearchGenreTagPreviewHeaderView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isLoading else { return }
        if indexPath.item < tags.count {
            tappedTagHandler?(tags[indexPath.item])
        } else {
            tappedMoreHandler?()
        }
    }
}

extension SearchGenreTagPreviewHeaderView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if isLoading {
            return CGSize(width: Layout.loadingChipWidths[indexPath.item], height: Layout.chipHeight)
        }
        let title = indexPath.item < tags.count ? tags[indexPath.item].title : "More ›"
        return CGSize(width: SearchGenreTagChipCVC.width(for: title,
                                                         maxWidth: max(120, collectionView.bounds.width - 32)),
                      height: Layout.chipHeight)
    }
}

private final class SearchGenreTagChipCVC: UICollectionViewCell {
    static let reuseIdentifier = "SearchGenreTagChipCVC"

    private let titleLabel = UILabel()
    private var isMore = false
    private var isLoading = false

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.layer.cornerRadius = SearchGenreTagPreviewHeaderView.Layout.chipHeight / 2
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 1
        contentView.backgroundColor = Colours.surfaceCard
        updateAppearance()

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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateAppearance()
    }

    func configure(title: String, isMore: Bool = false) {
        isLoading = false
        self.isMore = isMore
        titleLabel.text = title
        titleLabel.isHidden = false
        isAccessibilityElement = true
        accessibilityLabel = isMore ? "View all tags" : title
        accessibilityTraits = .button
        updateAppearance()
    }

    func configureLoading() {
        isLoading = true
        isMore = false
        titleLabel.text = nil
        titleLabel.isHidden = true
        isAccessibilityElement = false
        accessibilityLabel = nil
        accessibilityTraits = []
        updateAppearance()
    }

    private func updateAppearance() {
        let accent = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
        if isLoading {
            contentView.layer.borderColor = UIColor.clear.cgColor
            contentView.backgroundColor = Colours.textSecondary.withAlphaComponent(0.14)
        } else {
            contentView.layer.borderColor = (isMore ? UIColor.clear : Colours.inputBorder).cgColor
            contentView.backgroundColor = isMore ? accent.withAlphaComponent(0.1) : Colours.surfaceCard
        }
    }

    static func width(for title: String, maxWidth: CGFloat) -> CGFloat {
        let textWidth = (title as NSString).size(withAttributes: [.font: Fonts.medium13]).width
        return min(max(textWidth + 24, 64), maxWidth)
    }
}

class SearchVC: UIViewController {

    // MARK: - Properties

    private var allStories: [CDBookInternal] = []
    private var searchResults: [CDBookInternal] = []
    private var searchObject: CDBookInternalSearchObject
    private var earlyAccessBooksInSearch: [CDBookInternal] = []
    private var recentlyViewedStories: [CDBookInternal] = []
    private var hasMoreDiscoveryResults = false
    private var genreCardPresentations: [GenreCardPresentation] = []
    private var genreTagPreviewTags: [BookInternalTag] = []
    private var genreTagPreviewGenre: BookInternalGenre?
    private var isGenreTagPreviewLoading = false
    private var trackedGenreImpressions = Set<BookInternalGenre>()
    private let maxRecentlyViewedStories = 12
    private let discoveryLatestReleasesLimit = 60
    private let genreTagPreviewLimit = 8
    private let minimumGenreTagPreviewResultCount = 3
    private let earlyAccessUpsellInsertionResultIndex = 3

    private var searchViewState: SearchViewState {
        searchObject.hasFilters ? .refined : .discovery
    }

    private var searchResultSource: String {
        searchViewState == .discovery ? "discovery_results" : "refined_results"
    }

    private var shouldShowEarlyAccessSearchUpsell: Bool {
        let hasGenreFilter = searchObject.genre != nil
        let hasReadingTimeFilter = searchObject.minReadingTime != nil || searchObject.maxReadingTime != nil

        return RCValues.shared.bool(forKey: .showDiscoverEASearchUpsellWidget) &&
               !AccountManager.shared.userIsSubscribed &&
               (hasGenreFilter || hasReadingTimeFilter) &&
               earlyAccessBooksInSearch.count >= 5
    }

    private var shouldShowDiscoveryEndOfFeedPrompt: Bool {
        searchViewState == .discovery && hasMoreDiscoveryResults && !searchResults.isEmpty
    }

    private var earlyAccessUpsellTableRow: Int? {
        guard shouldShowEarlyAccessSearchUpsell else { return nil }
        return min(earlyAccessUpsellInsertionResultIndex, searchResults.count)
    }

    // MARK: - UI

    private let headerView = HeaderView(
        titleText: "Search",
        alwaysHideUpsell: true,
        showBottomBorder: true,
        showsListeningQuotaPill: true
    )
    private let topContainerView = UIView()
    private let searchContainerView = UIView()
    private let searchTextField = UITextField()
    private let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
    private let filterChipsScrollView = SearchRefinementChipsScrollView()
    private let discoveryHeaderView = UIView()
    private let genreTagPreviewHeaderView = SearchGenreTagPreviewHeaderView()
    private let recentlyViewedModuleContainerView = UIView()
    private let recentlyViewedCarouselView = SearchRecentlyViewedCarouselView()
    private let genreModuleHeaderView = UIView()
    private let genreModuleTitleLabel = UILabel()
    private let genreModuleSubtitleLabel = UILabel()
    private let emptyStateView = SearchEmptyStateView()
    private let discoveryGenreModuleHeight: CGFloat = 184
    private let discoveryRecentlyViewedModuleHeight: CGFloat = SearchRecentlyViewedCarouselView.Layout.totalHeight
    private let discoveryGenreTopSpacingWithoutRecentlyViewed: CGFloat = 10
    private var recentlyViewedModuleHeightConstraint: NSLayoutConstraint?
    private var genreModuleTopConstraint: NSLayoutConstraint?
    private var hasDeferredDiscoveryLayoutUpdate = false
    private var deferredScrollToTop = false

    private lazy var genreCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(GenreTileCVC.self, forCellWithReuseIdentifier: GenreTileCVC.reuseIdentifier)
        return collectionView
    }()

    private let tableView = UITableView()

    // MARK: - Init

    init(initialFilters: CDBookInternalSearchObject = CDBookInternalSearchObject()) {
        self.searchObject = initialFilters.copy()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Colours.surfacePrimary
        setupUI()
        loadStories()
        applyInitialFilters()
        hideKeyboardWhenTappedAround()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshForSubscriberStatus),
                                               name: .didUpdateSubscriberStatus,
                                               object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: animated)
        headerView.update()
        AnalyticsManager.shared.trackSearchViewed()
        AnalyticsManager.shared.trackSearchViewedWithState(state: searchViewState.rawValue)

        trackedGenreImpressions.removeAll()
        loadStories()
        refreshSearchExperience()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if hasDeferredDiscoveryLayoutUpdate {
            applySearchUIStateIfNeeded(scrollToTop: false)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        searchContainerView.layer.shadowPath = UIBezierPath(
            roundedRect: searchContainerView.bounds,
            cornerRadius: UIConstants.shared.cornerRadius
        ).cgPath
        updateSearchContainerAppearance()
        updateDiscoveryHeaderLayoutIfNeeded()
        updateGenreTagPreviewHeaderLayoutIfNeeded()

        // Apply deferred table updates as soon as the view is attached, before/without waiting for full appearance.
        if hasDeferredDiscoveryLayoutUpdate, view.window != nil {
            applySearchUIStateIfNeeded(scrollToTop: false)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateSearchContainerAppearance()
        applySearchFieldPlaceholderAppearance()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - External Navigation

    /// Applies a new entry state when Search is opened from another tab.
    /// Passing `nil` resets Search back to the default browse view.
    func applyEntryFilters(_ filters: CDBookInternalSearchObject?) {
        searchObject = filters?.copy() ?? CDBookInternalSearchObject()
        if searchObject.genre == .romance {
            searchObject.includeAdultContentForRomance = true
        }
        let normalizedQuery = searchObject.query?.trimmingCharacters(in: .whitespacesAndNewlines)
        searchObject.query = (normalizedQuery?.isEmpty == false) ? normalizedQuery : nil
        loadViewIfNeeded()
        loadStories()

        searchTextField.text = searchObject.query ?? ""
        refreshSearchExperience(scrollToTop: true)
    }

    // MARK: - Setup

    private func setupUI() {
        setupHeaderView()
        setupTopContainerView()
        setupSearchContainer()
        setupGenreModule()
        setupDiscoveryHeader()
        setupTableView()
        setupEmptyState()
        setupConstraints()
    }

    private func setupHeaderView() {
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
        topContainerView.addSubviewForConstraints(statusBarBackground)
        NSLayoutConstraint.activate([
            statusBarBackground.topAnchor.constraint(equalTo: topContainerView.topAnchor),
            statusBarBackground.leadingAnchor.constraint(equalTo: topContainerView.leadingAnchor),
            statusBarBackground.trailingAnchor.constraint(equalTo: topContainerView.trailingAnchor),
            statusBarBackground.bottomAnchor.constraint(equalTo: topContainerView.safeAreaLayoutGuide.topAnchor)
        ])

        topContainerView.addSubviewForConstraints(headerView)
    }

    private func setupDiscoveryHeader() {
        discoveryHeaderView.backgroundColor = Colours.surfacePrimary
        recentlyViewedModuleContainerView.backgroundColor = Colours.surfacePrimary

        recentlyViewedCarouselView.tappedBookInternalHandler = { [weak self] cdBookInternal in
            guard let self else { return }
            DispatchQueue.main.async {
                AnalyticsManager.shared.trackSearchBookOpened(
                    source: "discovery_recently_viewed_rail",
                    state: self.searchViewState.rawValue,
                    genre: cdBookInternal.genre
                )
                if !cdBookInternal.isAvailableToUser {
                    self.displayPaywall(placement: .earlyAccess, bookInternal: cdBookInternal)
                } else {
                    self.showBookDetails(
                        cdBookInternal,
                                                sourceItems: self.recentlyViewedStories.map { $0 as ReadableContentMetadata }
                    )
                }
            }
        }
        recentlyViewedCarouselView.tappedShowMoreChevronHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.showRecentlyViewedSeeAll()
            }
        }

        discoveryHeaderView.addSubviewForConstraints(recentlyViewedModuleContainerView)
        discoveryHeaderView.addSubviewForConstraints(genreModuleHeaderView)
        recentlyViewedModuleContainerView.addSubviewForConstraints(recentlyViewedCarouselView)

        recentlyViewedModuleHeightConstraint = recentlyViewedModuleContainerView.heightAnchor.constraint(equalToConstant: 0)
        recentlyViewedModuleHeightConstraint?.isActive = true
        genreModuleTopConstraint = genreModuleHeaderView.topAnchor.constraint(equalTo: recentlyViewedModuleContainerView.bottomAnchor)
        genreModuleTopConstraint?.isActive = true

        NSLayoutConstraint.activate([
            recentlyViewedModuleContainerView.topAnchor.constraint(equalTo: discoveryHeaderView.topAnchor),
            recentlyViewedModuleContainerView.leadingAnchor.constraint(equalTo: discoveryHeaderView.leadingAnchor),
            recentlyViewedModuleContainerView.trailingAnchor.constraint(equalTo: discoveryHeaderView.trailingAnchor),

            recentlyViewedCarouselView.topAnchor.constraint(equalTo: recentlyViewedModuleContainerView.topAnchor),
            recentlyViewedCarouselView.leadingAnchor.constraint(equalTo: recentlyViewedModuleContainerView.leadingAnchor),
            recentlyViewedCarouselView.trailingAnchor.constraint(equalTo: recentlyViewedModuleContainerView.trailingAnchor),
            recentlyViewedCarouselView.bottomAnchor.constraint(equalTo: recentlyViewedModuleContainerView.bottomAnchor),

            genreModuleHeaderView.leadingAnchor.constraint(equalTo: discoveryHeaderView.leadingAnchor),
            genreModuleHeaderView.trailingAnchor.constraint(equalTo: discoveryHeaderView.trailingAnchor),
            genreModuleHeaderView.heightAnchor.constraint(equalToConstant: discoveryGenreModuleHeight),
            genreModuleHeaderView.bottomAnchor.constraint(equalTo: discoveryHeaderView.bottomAnchor)
        ])
    }

    private func setupTopContainerView() {
        topContainerView.backgroundColor = Colours.backgroundGrey
        view.addSubviewForConstraints(topContainerView)
    }

    private func setupSearchContainer() {
        searchContainerView.backgroundColor = Colours.surfaceCard
        searchContainerView.layer.cornerRadius = UIConstants.shared.cornerRadius
        searchContainerView.layer.borderWidth = 1
        updateSearchContainerAppearance()

        topContainerView.addSubviewForConstraints(searchContainerView)

        searchIcon.tintColor = Colours.textSecondary
        searchIcon.contentMode = .scaleAspectFit
        searchContainerView.addSubviewForConstraints(searchIcon)

        searchTextField.placeholder = "Search stories..."
        searchTextField.font = Fonts.medium16
        searchTextField.textColor = Colours.textPrimary
        searchTextField.returnKeyType = .search
        searchTextField.autocorrectionType = .no
        searchTextField.clearButtonMode = .whileEditing
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        searchContainerView.addSubviewForConstraints(searchTextField)
        applySearchFieldPlaceholderAppearance()

        filterChipsScrollView.onTapControl = { [weak self] control in
            guard let self else { return }
            DispatchQueue.main.async {
                HapticFeedbackHelper.shared.triggerLightImpactFeedback()
                switch control {
                case .genre:
                    self.presentGenreSelection()
                case .tag:
                    self.presentTagSelection()
                case .format:
                    self.presentFormatSelection()
                case .length:
                    self.presentLengthSelection()
                case .rating:
                    self.presentRatingSelection()
                case .adult:
                    self.presentAdultSelection()
                case .sort:
                    self.presentSortSelection()
                }
            }
        }

        filterChipsScrollView.onClearControl = { [weak self] control in
            guard let self else { return }
            DispatchQueue.main.async {
                HapticFeedbackHelper.shared.triggerLightImpactFeedback()
                self.clearRefinementChip(control)
            }
        }

        topContainerView.addSubviewForConstraints(filterChipsScrollView)
    }

    private func updateSearchContainerAppearance() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        searchContainerView.backgroundColor = Colours.surfaceCard
        searchContainerView.layer.borderColor = Colours.inputBorder.withAlphaComponent(isDark ? 0.6 : 0.5).cgColor
        searchContainerView.layer.shadowColor = Colours.shadowBase.withAlphaComponent(isDark ? 0.14 : 0.06).cgColor
        searchContainerView.layer.shadowOffset = CGSize(width: 0, height: isDark ? 1 : 2)
        searchContainerView.layer.shadowOpacity = 1
        searchContainerView.layer.shadowRadius = isDark ? 6 : 8
    }

    private func applySearchFieldPlaceholderAppearance() {
        searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Search stories...",
            attributes: [
                .font: Fonts.medium16 as Any,
                .foregroundColor: Colours.textSecondary.withAlphaComponent(0.5) // was 0.75
            ]
        )
    }

    private func setupGenreModule() {
        genreModuleHeaderView.backgroundColor = Colours.surfacePrimary

        genreModuleTitleLabel.font = UIConstants.shared.carouselTitleFont
        genreModuleTitleLabel.textColor = UIConstants.shared.carouselTitleTextColour
        genreModuleTitleLabel.text = "Browse genres"

        genreModuleSubtitleLabel.font = Fonts.medium14
        genreModuleSubtitleLabel.textColor = Colours.subtext
        genreModuleSubtitleLabel.text = "Pick a vibe and jump into fresh stories."

        genreModuleHeaderView.addSubviewForConstraints(genreModuleTitleLabel)
        genreModuleHeaderView.addSubviewForConstraints(genreModuleSubtitleLabel)
        genreModuleHeaderView.addSubviewForConstraints(genreCollectionView)

        let genreTitleLeadingConstraint = genreModuleTitleLabel.leadingAnchor.constraint(equalTo: genreModuleHeaderView.leadingAnchor, constant: 16)
        let genreTitleTrailingConstraint = genreModuleTitleLabel.trailingAnchor.constraint(equalTo: genreModuleHeaderView.trailingAnchor, constant: -16)
        let sizingPriority = UILayoutPriority(999)
        genreTitleLeadingConstraint.priority = sizingPriority
        genreTitleTrailingConstraint.priority = sizingPriority

        NSLayoutConstraint.activate([
            genreModuleTitleLabel.topAnchor.constraint(equalTo: genreModuleHeaderView.topAnchor, constant: 12),
            genreTitleLeadingConstraint,
            genreTitleTrailingConstraint,

            genreModuleSubtitleLabel.topAnchor.constraint(equalTo: genreModuleTitleLabel.bottomAnchor, constant: 2),
            genreModuleSubtitleLabel.leadingAnchor.constraint(equalTo: genreModuleTitleLabel.leadingAnchor),
            genreModuleSubtitleLabel.trailingAnchor.constraint(equalTo: genreModuleTitleLabel.trailingAnchor),

            genreCollectionView.topAnchor.constraint(equalTo: genreModuleSubtitleLabel.bottomAnchor, constant: 10),
            genreCollectionView.leadingAnchor.constraint(equalTo: genreModuleHeaderView.leadingAnchor),
            genreCollectionView.trailingAnchor.constraint(equalTo: genreModuleHeaderView.trailingAnchor),
            genreCollectionView.bottomAnchor.constraint(equalTo: genreModuleHeaderView.bottomAnchor, constant: -12)
        ])
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = Colours.surfacePrimary
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.register(SearchResultsTVC.self, forCellReuseIdentifier: "SearchResultCell")
        tableView.register(EarlyAccessSearchUpsellTVC.self, forCellReuseIdentifier: "EarlyAccessSearchUpsellCell")
        tableView.register(SearchDiscoveryEndOfFeedPromptTVC.self, forCellReuseIdentifier: "SearchDiscoveryEndOfFeedPromptCell")

        genreTagPreviewHeaderView.tappedTagHandler = { [weak self] tag in
            guard let self else { return }
            HapticFeedbackHelper.shared.triggerLightImpactFeedback()
            self.selectTag(tag)
        }
        genreTagPreviewHeaderView.tappedMoreHandler = { [weak self] in
            guard let self else { return }
            HapticFeedbackHelper.shared.triggerLightImpactFeedback()
            self.presentTagSelection()
        }

        view.addSubviewForConstraints(tableView)
    }

    private func setupEmptyState() {
        emptyStateView.actionHandler = { [weak self] in
            self?.clearAllRefinements()
        }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            topContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            topContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            headerView.leadingAnchor.constraint(equalTo: topContainerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: topContainerView.trailingAnchor),

            searchContainerView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            searchContainerView.leadingAnchor.constraint(equalTo: topContainerView.leadingAnchor, constant: 16),
            searchContainerView.trailingAnchor.constraint(equalTo: topContainerView.trailingAnchor, constant: -16),
            searchContainerView.heightAnchor.constraint(equalToConstant: 50),

            searchIcon.leadingAnchor.constraint(equalTo: searchContainerView.leadingAnchor, constant: 12),
            searchIcon.centerYAnchor.constraint(equalTo: searchContainerView.centerYAnchor),
            searchIcon.widthAnchor.constraint(equalToConstant: 20),
            searchIcon.heightAnchor.constraint(equalToConstant: 20),

            searchTextField.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 10),
            searchTextField.centerYAnchor.constraint(equalTo: searchContainerView.centerYAnchor),
            searchTextField.trailingAnchor.constraint(equalTo: searchContainerView.trailingAnchor, constant: -12),

            filterChipsScrollView.topAnchor.constraint(equalTo: searchContainerView.bottomAnchor, constant: 12),
            filterChipsScrollView.leadingAnchor.constraint(equalTo: topContainerView.leadingAnchor, constant: 16),
            filterChipsScrollView.trailingAnchor.constraint(equalTo: topContainerView.trailingAnchor),
            filterChipsScrollView.heightAnchor.constraint(equalToConstant: 36),
            filterChipsScrollView.bottomAnchor.constraint(equalTo: topContainerView.bottomAnchor, constant: -12),

            tableView.topAnchor.constraint(equalTo: topContainerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let borderView = UIView()
        borderView.backgroundColor = Colours.separator
        topContainerView.addSubviewForConstraints(borderView)
        NSLayoutConstraint.activate([
            borderView.leadingAnchor.constraint(equalTo: topContainerView.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: topContainerView.trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: topContainerView.bottomAnchor),
            borderView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    private func applyInitialFilters() {
        if let query = searchObject.query, !query.isEmpty {
            searchTextField.text = query
        }
        refreshSearchExperience()
    }

    private func loadStories() {
        allStories = CoreDataBookInternalManager.shared.getAll()
        recentlyViewedStories = ReadingUserDefaults.getRecentlyViewedBookInternals(limit: maxRecentlyViewedStories)
        rebuildGenreCardPresentations()
    }

    private func updateFilterChips() {
        filterChipsScrollView.configure(with: searchObject)
    }

    private func rebuildGenreCardPresentations() {
        genreCardPresentations = GenreCardPresentation.buildAll(from: allStories)
    }

    private func refreshSearchExperience(scrollToTop: Bool = false) {
        performSearch()
        updateFilterChips()
        updateDiscoveryHeaderContent()
        updateGenreTagPreview()
        applySearchUIStateIfNeeded(scrollToTop: scrollToTop)
    }

    private func updateGenreTagPreview() {
        guard let genre = searchObject.genre, searchObject.tag == nil else {
            genreTagPreviewGenre = nil
            genreTagPreviewTags = []
            isGenreTagPreviewLoading = false
            genreTagPreviewHeaderView.configure(tags: [])
            return
        }

        if genreTagPreviewGenre != genre {
            genreTagPreviewGenre = genre
            genreTagPreviewTags = []
        }

        isGenreTagPreviewLoading = true
        BookInternalTagManager.shared.ensureHomeEligibleTags(for: genre) { [weak self] _, tags in
            guard let self, self.searchObject.genre == genre, self.searchObject.tag == nil else { return }

            let rankedTags = PersonalizedHomeTagBrowserRanking.rankedTags(
                from: tags,
                visibleStories: self.searchResults,
                minimumBookCount: self.minimumGenreTagPreviewResultCount
            )
            let shouldAnimateCollapse = self.isGenreTagPreviewLoading && rankedTags.isEmpty
            self.isGenreTagPreviewLoading = false
            self.genreTagPreviewTags = Array(rankedTags.prefix(self.genreTagPreviewLimit))
            self.genreTagPreviewHeaderView.configure(tags: self.genreTagPreviewTags)
            self.updateDiscoveryHeaderVisibility(animateTagPreviewCollapse: shouldAnimateCollapse)
        }

        // Cached genres complete synchronously above, so only expose the loading state when the
        // manager actually has an outstanding request.
        if isGenreTagPreviewLoading,
           searchObject.genre == genre,
           searchObject.tag == nil {
            genreTagPreviewHeaderView.configureLoading()
        }
    }

    private func applySearchUIStateIfNeeded(scrollToTop: Bool) {
        let needsScrollToTop = scrollToTop || deferredScrollToTop
        guard isViewLoaded, view.window != nil else {
            hasDeferredDiscoveryLayoutUpdate = true
            deferredScrollToTop = needsScrollToTop
            // Keep discovery header state up-to-date to avoid visible snapping once shown.
            updateDiscoveryHeaderVisibility()
            updateEmptyState()
            return
        }

        hasDeferredDiscoveryLayoutUpdate = false
        deferredScrollToTop = false

        updateDiscoveryHeaderVisibility()
        view.layoutIfNeeded()
        if needsScrollToTop {
            scrollResultsToTop()
        }
        tableView.reloadData()
        genreCollectionView.reloadData()
        updateEmptyState()
    }

    /// Resets the results list to the top.
    ///
    /// This has to happen *before* reloadData(), not after. While the table is scrolled deep into
    /// self-sizing rows it holds a pending estimated-height correction anchored to the current
    /// offset, and applies that correction on the next layout pass — which silently undoes any
    /// reset made after the reload. Resetting first discards the anchor while the old rows are
    /// still in place, so there is no correction left to apply.
    private func scrollResultsToTop() {
        let topOffset = CGPoint(x: 0, y: -tableView.adjustedContentInset.top)
        guard tableView.contentOffset != topOffset else { return }
        tableView.setContentOffset(topOffset, animated: false)
    }

    private func updateDiscoveryHeaderLayoutIfNeeded() {
        guard tableView.window != nil else { return }
        guard tableView.tableHeaderView === discoveryHeaderView else { return }
        let targetWidth = tableView.bounds.width
        guard targetWidth > 0 else { return }

        let hasRecentlyViewed = !recentlyViewedStories.isEmpty
        let targetHeight = discoveryGenreModuleHeight +
            (hasRecentlyViewed ? discoveryRecentlyViewedModuleHeight : discoveryGenreTopSpacingWithoutRecentlyViewed)
        let currentFrame = discoveryHeaderView.frame
        if abs(currentFrame.width - targetWidth) > 0.5 || abs(currentFrame.height - targetHeight) > 0.5 {
            discoveryHeaderView.frame = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
            tableView.tableHeaderView = discoveryHeaderView
            genreCollectionView.collectionViewLayout.invalidateLayout()
        }
    }

    private func updateGenreTagPreviewHeaderLayoutIfNeeded() {
        guard tableView.window != nil else { return }
        guard tableView.tableHeaderView === genreTagPreviewHeaderView else { return }
        let targetWidth = tableView.bounds.width
        guard targetWidth > 0 else { return }

        let currentFrame = genreTagPreviewHeaderView.frame
        if abs(currentFrame.width - targetWidth) > 0.5 ||
            abs(currentFrame.height - SearchGenreTagPreviewHeaderView.Layout.height) > 0.5 {
            genreTagPreviewHeaderView.frame = CGRect(
                x: 0,
                y: 0,
                width: targetWidth,
                height: SearchGenreTagPreviewHeaderView.Layout.height
            )
            tableView.tableHeaderView = genreTagPreviewHeaderView
        }
    }

    private func updateDiscoveryHeaderContent() {
        recentlyViewedCarouselView.configure(
            title: "Recently viewed",
            stories: recentlyViewedStories,
            showsChevron: true
        )
    }

    private func updateDiscoveryHeaderVisibility(animateTagPreviewCollapse: Bool = false) {
        let isDiscovery = searchViewState == .discovery
        let hasRecentlyViewed = !recentlyViewedStories.isEmpty
        recentlyViewedModuleContainerView.isHidden = !hasRecentlyViewed
        recentlyViewedModuleHeightConstraint?.constant = hasRecentlyViewed ? discoveryRecentlyViewedModuleHeight : 0
        genreModuleTopConstraint?.constant = hasRecentlyViewed ? 0 : discoveryGenreTopSpacingWithoutRecentlyViewed

        if isDiscovery {
            let targetWidth = max(tableView.bounds.width, view.bounds.width)
            let targetHeight = discoveryGenreModuleHeight + (hasRecentlyViewed ? discoveryRecentlyViewedModuleHeight : discoveryGenreTopSpacingWithoutRecentlyViewed)
            if tableView.tableHeaderView !== discoveryHeaderView {
                discoveryHeaderView.frame = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
                tableView.tableHeaderView = discoveryHeaderView
            }
            updateDiscoveryHeaderLayoutIfNeeded()
        } else if searchObject.tag == nil,
                  searchObject.genre == genreTagPreviewGenre,
                  isGenreTagPreviewLoading || !genreTagPreviewTags.isEmpty {
            let targetWidth = max(tableView.bounds.width, view.bounds.width)
            if tableView.tableHeaderView !== genreTagPreviewHeaderView {
                genreTagPreviewHeaderView.alpha = 1
                genreTagPreviewHeaderView.frame = CGRect(
                    x: 0,
                    y: 0,
                    width: targetWidth,
                    height: SearchGenreTagPreviewHeaderView.Layout.height
                )
                tableView.tableHeaderView = genreTagPreviewHeaderView
            }
            updateGenreTagPreviewHeaderLayoutIfNeeded()
        } else if animateTagPreviewCollapse,
                  tableView.tableHeaderView === genreTagPreviewHeaderView {
            collapseGenreTagPreviewHeader()
        } else if tableView.tableHeaderView != nil {
            tableView.tableHeaderView = nil
        }
    }

    private func collapseGenreTagPreviewHeader() {
        let headerView = genreTagPreviewHeaderView
        var collapsedFrame = headerView.frame
        collapsedFrame.size.height = 0

        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.curveEaseInOut, .beginFromCurrentState],
            animations: {
                headerView.alpha = 0
                headerView.frame = collapsedFrame
                self.tableView.tableHeaderView = headerView
                self.tableView.layoutIfNeeded()
            },
            completion: { _ in
                guard self.tableView.tableHeaderView === headerView else { return }
                self.tableView.tableHeaderView = nil
                headerView.alpha = 1
            }
        )
    }

    private func showRecentlyViewedSeeAll() {
        let recentlyViewedVC = GenreResultsVC(source: .recentlyViewed)
        recentlyViewedVC.hidesBottomBarWhenPushed = true
        recentlyViewedVC.onBookSelectedWithSourceItems = { [weak self] book, sourceItems in
            guard let self else { return }
            AnalyticsManager.shared.trackSearchBookOpened(
                source: "discovery_recently_viewed_see_all",
                state: self.searchViewState.rawValue,
                genre: book.genre
            )
            if !book.isAvailableToUser {
                self.displayPaywall(placement: .earlyAccess, bookInternal: book)
            } else {
                self.showBookDetails(
                    book,
                                        sourceItems: sourceItems.map { $0 as ReadableContentMetadata }
                )
            }
        }
        navigationController?.pushViewController(recentlyViewedVC, animated: true)
    }

    private func updateEmptyState() {
        let shouldShowEmpty = searchResults.isEmpty && !shouldShowEarlyAccessSearchUpsell
        if shouldShowEmpty {
            emptyStateView.configure(isRefined: searchViewState == .refined)
            tableView.backgroundView = emptyStateView
        } else {
            tableView.backgroundView = nil
        }
    }

    private func clearAllRefinements() {
        searchObject.clearAll()
        searchTextField.text = ""
        AnalyticsManager.shared.trackSearchFiltersApplied(filterCount: 0, state: searchViewState.rawValue)
        refreshSearchExperience(scrollToTop: true)
    }

    // MARK: - Search

    @objc private func searchTextChanged() {
        let searchText = searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        searchObject.query = searchText.isEmpty ? nil : searchText
        refreshSearchExperience(scrollToTop: true)
    }

    private func performSearch() {
        let userIsSubscribed = AccountManager.shared.userIsSubscribed
        let allFilteredResults = searchObject.applyFiltersToStories(allStories)

        if let selectedGenre = searchObject.genre {
            let allEABooksForGenre = allStories.filter { story in
                guard !story.isAvailableToUser, story.genre == selectedGenre else { return false }
                guard let selectedTag = searchObject.tag else { return true }
                return story.tags.contains(selectedTag.tag)
            }
            earlyAccessBooksInSearch = allEABooksForGenre.shuffled()
        } else if searchObject.minReadingTime != nil || searchObject.maxReadingTime != nil {
            let allEABooksForReadingTime = allStories.filter { story in
                guard !story.isAvailableToUser else { return false }

                // Lower bound exclusive, upper bound inclusive — matches applyFiltersToStories.
                let listeningTime = story.listeningTimeMinutesRounded
                if let minTime = searchObject.minReadingTime, listeningTime <= minTime {
                    return false
                }
                if let maxTime = searchObject.maxReadingTime, listeningTime > maxTime {
                    return false
                }
                return true
            }
            earlyAccessBooksInSearch = allEABooksForReadingTime.shuffled()
        } else {
            earlyAccessBooksInSearch = []
        }

        let availableResults = allFilteredResults.filter { userIsSubscribed || $0.isAvailableToUser }
        let orderedResults = orderedResultsForCurrentSearch(from: availableResults)

        if searchViewState == .discovery {
            hasMoreDiscoveryResults = orderedResults.count > discoveryLatestReleasesLimit
            searchResults = Array(orderedResults.prefix(discoveryLatestReleasesLimit))
        } else {
            hasMoreDiscoveryResults = false
            searchResults = orderedResults
        }
    }

    private func orderedResultsForCurrentSearch(from results: [CDBookInternal]) -> [CDBookInternal] {
        // Preserve "latest releases" as the default discovery feed when no real refinements are active.
        let isDefaultDiscoverySort = searchViewState == .discovery &&
            searchObject.sortOption == .relevance &&
            searchObject.query == nil &&
            searchObject.activeFilterCount == 0

        if isDefaultDiscoverySort {
            return sortResults(results, option: .newest)
        }

        return sortResults(results, option: searchObject.sortOption)
    }

    private func sortResults(_ results: [CDBookInternal], option: CDBookInternalSearchSortOption) -> [CDBookInternal] {
        let normalizedQuery = (searchObject.query ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        switch option {
        case .relevance:
            if normalizedQuery.isEmpty {
                return sortResults(results, option: .popularity)
            }
            return results.sorted { lhs, rhs in
                let lhsScore = relevanceScore(for: lhs, query: normalizedQuery)
                let rhsScore = relevanceScore(for: rhs, query: normalizedQuery)
                if lhsScore != rhsScore { return lhsScore > rhsScore }
                if lhs.readerCount != rhs.readerCount { return lhs.readerCount > rhs.readerCount }
                let lhsDate = lhs.datePublished ?? .distantPast
                let rhsDate = rhs.datePublished ?? .distantPast
                if lhsDate != rhsDate { return lhsDate > rhsDate }
                return lhs.contentUUID > rhs.contentUUID
            }
        case .popularity:
            return results.sorted { lhs, rhs in
                if lhs.readerCount != rhs.readerCount { return lhs.readerCount > rhs.readerCount }
                let lhsDate = lhs.datePublished ?? .distantPast
                let rhsDate = rhs.datePublished ?? .distantPast
                if lhsDate != rhsDate { return lhsDate > rhsDate }
                return lhs.contentUUID > rhs.contentUUID
            }
        case .newest:
            return results.sorted { lhs, rhs in
                let lhsDate = lhs.datePublished ?? .distantPast
                let rhsDate = rhs.datePublished ?? .distantPast
                if lhsDate != rhsDate { return lhsDate > rhsDate }
                if lhs.readerCount != rhs.readerCount { return lhs.readerCount > rhs.readerCount }
                return lhs.contentUUID > rhs.contentUUID
            }
        case .highestRated:
            return results.sorted { lhs, rhs in
                if lhs.rating != rhs.rating { return lhs.rating > rhs.rating }
                if lhs.numberOfRatings != rhs.numberOfRatings { return lhs.numberOfRatings > rhs.numberOfRatings }
                if lhs.readerCount != rhs.readerCount { return lhs.readerCount > rhs.readerCount }
                let lhsDate = lhs.datePublished ?? .distantPast
                let rhsDate = rhs.datePublished ?? .distantPast
                if lhsDate != rhsDate { return lhsDate > rhsDate }
                return lhs.contentUUID > rhs.contentUUID
            }
        }
    }

    private func relevanceScore(for story: CDBookInternal, query: String) -> Int {
        let q = query.lowercased()
        let title = (story.title ?? "").lowercased()
        let author = (story.authorName ?? "").lowercased()
        let genre = (story.genreString ?? "").lowercased()
        let blurb = (story.blurb ?? "").lowercased()

        var score = 0

        if title == q {
            score += 1000
        } else if title.hasPrefix(q) {
            score += 800
        } else if title.contains(q) {
            score += 600
        }

        if author == q {
            score += 500
        } else if author.hasPrefix(q) {
            score += 350
        } else if author.contains(q) {
            score += 220
        }

        if genre.contains(q) {
            score += 120
        }

        if blurb.contains(q) {
            score += 80
        }

        return score
    }

    private func presentGenreSelection() {
        AnalyticsManager.shared.trackSearchFiltersOpened(state: searchViewState.rawValue)
        let genreVC = BookInternalGenreSelectionVC(selectedGenre: searchObject.genre)
        genreVC.preferredSheetSizing = .fit
        genreVC.delegate = self
        present(genreVC, animated: true)
    }

    private func presentTagSelection() {
        guard let genre = searchObject.genre else { return }
        AnalyticsManager.shared.trackSearchFiltersOpened(state: searchViewState.rawValue)
        let viewController = TagSelectionVC(
            genres: [genre],
            titleText: "\(genre.displayString) tags",
            selectedTag: searchObject.tag
        )
        viewController.didSelectTag = { [weak self] tag in
            self?.selectTag(tag)
        }
        viewController.didClearTag = { [weak self] in
            self?.searchObject.tag = nil
            self?.commitRefinementChange()
        }
        present(viewController, animated: true)
    }

    private func selectTag(_ tag: BookInternalTag) {
        guard searchObject.genre == tag.genre else { return }
        searchObject.tag = tag
        commitRefinementChange()
    }

    private func presentFormatSelection() {
        let values = CDBookInternalFormatFilter.filterDisplayOrder
        let options = values.map { value in
            SearchSingleRefinementOption(
                title: value == .any ? "Any format" : value.displayTitle,
                isSelected: searchObject.format == value
            )
        }
        presentSingleRefinementPicker(title: "Format", options: options) { [weak self] index in
            guard let self, values.indices.contains(index) else { return }
            self.searchObject.format = values[index]
            self.commitRefinementChange()
        }
    }

    private func presentLengthSelection() {
        let values: [CDBookInternalLengthBucket?] = [nil] +
            CDBookInternalLengthBucket.allCases.map { Optional($0) }
        let options = values.map { value in
            SearchSingleRefinementOption(
                title: lengthPickerTitle(for: value),
                isSelected: searchObject.selectedLengthBucket == value
            )
        }
        presentSingleRefinementPicker(title: "Listening Time", options: options) { [weak self] index in
            guard let self, values.indices.contains(index) else { return }
            self.searchObject.setLengthBucket(values[index])
            self.commitRefinementChange()
        }
    }

    private func lengthPickerTitle(for bucket: CDBookInternalLengthBucket?) -> String {
        switch bucket {
        case nil: return "Any listening time"
        case .short: return "Short (under 30 min)"
        case .medium: return "Medium (30–90 min)"
        case .long: return "Long (over 90 min)"
        }
    }

    private func presentRatingSelection() {
        let values = CDBookInternalMinimumRating.allCases
        let options = values.map { value in
            SearchSingleRefinementOption(
                title: value == .any ? "Any rating" : value.displayTitle,
                isSelected: searchObject.minimumRating == value
            )
        }
        presentSingleRefinementPicker(title: "Minimum rating", options: options) { [weak self] index in
            guard let self, values.indices.contains(index) else { return }
            self.searchObject.minimumRating = values[index]
            self.commitRefinementChange()
        }
    }

    private func presentAdultSelection() {
        guard searchObject.genre == .romance else { return }
        let values = [false, true]
        let options = [
            SearchSingleRefinementOption(
                title: "Exclude 18+ stories",
                isSelected: !searchObject.includeAdultContentForRomance
            ),
            SearchSingleRefinementOption(
                title: "Include 18+ stories",
                isSelected: searchObject.includeAdultContentForRomance
            )
        ]
        presentSingleRefinementPicker(title: "Adult content", options: options) { [weak self] index in
            guard let self, values.indices.contains(index) else { return }
            self.searchObject.includeAdultContentForRomance = values[index]
            self.commitRefinementChange()
        }
    }

    private func presentSortSelection() {
        let values = CDBookInternalSearchSortOption.allCases
        let options = values.map { value in
            SearchSingleRefinementOption(
                title: value.displayTitle,
                isSelected: searchObject.sortOption == value
            )
        }
        presentSingleRefinementPicker(title: "Sort", options: options) { [weak self] index in
            guard let self, values.indices.contains(index) else { return }
            self.searchObject.sortOption = values[index]
            self.commitRefinementChange()
        }
    }

    private func presentSingleRefinementPicker(
        title: String,
        options: [SearchSingleRefinementOption],
        didSelect: @escaping (Int) -> Void
    ) {
        AnalyticsManager.shared.trackSearchFiltersOpened(state: searchViewState.rawValue)
        let viewController = SearchSingleRefinementPickerVC(title: title, options: options)
        viewController.didSelectOption = didSelect
        present(viewController, animated: true)
    }

    private func commitRefinementChange() {
        AnalyticsManager.shared.trackSearchFiltersApplied(
            filterCount: searchObject.activeFilterCount,
            state: searchViewState.rawValue
        )
        refreshSearchExperience(scrollToTop: true)
    }
    
    private func removeFilter(chipId: String) {
        searchObject.removeFilter(byId: chipId)

        if searchObject.genre != .romance {
            searchObject.includeAdultContentForRomance = false
        }

        if chipId == "query" {
            searchTextField.text = ""
        }
        AnalyticsManager.shared.trackSearchFiltersApplied(
            filterCount: searchObject.activeFilterCount,
            state: searchViewState.rawValue
        )
        refreshSearchExperience(scrollToTop: true)
    }

    private func clearRefinementChip(_ control: SearchRefinementControl) {
        switch control {
        case .genre:
            removeFilter(chipId: "genre")
        case .tag:
            removeFilter(chipId: "tag")
        case .format:
            removeFilter(chipId: "format")
        case .length:
            removeFilter(chipId: "readingTime")
        case .rating:
            removeFilter(chipId: "rating")
        case .adult:
            removeFilter(chipId: "adult")
        case .sort:
            removeFilter(chipId: "sort")
        }
    }

    // MARK: - Actions

    private func showBookDetails(_ bookMetadata: ReadableContentMetadata,
                                 sourceItems: [ReadableContentMetadata]? = nil) {
        let bookDetailVC = BookDetailVC(contentMetadata: bookMetadata)
        bookDetailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(bookDetailVC, animated: true)
    }

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
        loadStories()
        refreshSearchExperience()
    }

    private func handleSaveStory<T: SaveableMetadataView>(story: CDBookInternal, view: T) {
        let bookID = story.contentUUID
        let isSavedAtStart = AccountManager.shared.user?.savedBookInternalUUIDs.contains(bookID) ?? false

        if isSavedAtStart {
            AccountManager.shared.user?.savedBookInternalUUIDs.removeAll { $0 == bookID }
        } else {
            AccountManager.shared.user?.savedBookInternalUUIDs.append(bookID)

            let newSavedCount = AccountManager.shared.user?.totalSavedBooksCount ?? 0
            let requiredLaunchCount = RCValues.shared.int(forKey: .requiredLaunchCountForSKReview) ?? 2
            if newSavedCount >= 3 && SKReviewManager.launchCount >= requiredLaunchCount {
                SKReviewManager.requestReview(venue: .savedBook)
            }
        }

        view.updateSaveElements()

        AccountManager.shared.handleSaveBookInternal(
            story,
            save: !isSavedAtStart,
            saveVenue: .shortStoriesHomepage
        ) { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                view.updateSaveElements()

                if !isSavedAtStart {
                    EmailOptInPromptManager.shared.handleTrigger(
                        .bookSaved,
                        genre: story.genre,
                        from: self
                    )
                }
            }
        }
    }

    private func tappedDownload<T: DownloadableMetadataView>(view: T) {
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

    private func handleDownload<T: DownloadableMetadataView>(bookMetadata: ReadableContentMetadata, view: T) {
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

    private func showDownloadError<T: DownloadableMetadataView>(bookMetadata: ReadableContentMetadata, view: T) {
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let retryAction = UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.handleDownload(bookMetadata: bookMetadata, view: view)
            }
        }

        let alertController = UIAlertController(
            title: "Network Error",
            message: "Please ensure you have an active internet connection and try again.",
            preferredStyle: .alert
        )
        alertController.addAction(cancelAction)
        alertController.addAction(retryAction)
        present(alertController, animated: true, completion: nil)
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
                        print("⚠️ Failed to delete audio content for book: \(cdBookInternal.contentUUID)")
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
}

// MARK: - UITableViewDataSource

extension SearchVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let baseCount = searchResults.count
        let upsellCount = shouldShowEarlyAccessSearchUpsell ? 1 : 0
        let promptCount = shouldShowDiscoveryEndOfFeedPrompt ? 1 : 0
        return baseCount + upsellCount + promptCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let upsellRow = earlyAccessUpsellTableRow, indexPath.row == upsellRow {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EarlyAccessSearchUpsellCell", for: indexPath) as! EarlyAccessSearchUpsellTVC
            cell.configure(with: earlyAccessBooksInSearch, totalCount: earlyAccessBooksInSearch.count)

            cell.tappedUnlockHandler = { [weak self] in
                guard let self else { return }
                DispatchQueue.main.async {
                    AnalyticsManager.shared.trackEarlyAccessSearchUpsellTapped()
                    self.displayPaywall(placement: .earlyAccessSearchResultsUpsell, bookInternal: nil)
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

        var resultIndex = indexPath.row
        if let upsellRow = earlyAccessUpsellTableRow, indexPath.row > upsellRow {
            resultIndex -= 1
        }

        if searchResults.indices.contains(resultIndex) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! SearchResultsTVC
            let cdBookInternal = searchResults[resultIndex]

            cell.set(contentMetadata: cdBookInternal, displayContext: .normal)

            cell.tappedHandler = { [weak self] in
                guard let self else { return }
                DispatchQueue.main.async {
                    AnalyticsManager.shared.trackSearchBookOpened(
                        source: self.searchResultSource,
                        state: self.searchViewState.rawValue,
                        genre: cdBookInternal.genre
                    )
                    if !cdBookInternal.isAvailableToUser {
                        self.displayPaywall(placement: .earlyAccess, bookInternal: cdBookInternal)
                    } else {
                        self.showBookDetails(
                            cdBookInternal,
                                                        sourceItems: self.searchResults.map { $0 as ReadableContentMetadata }
                        )
                    }
                }
            }

            cell.tappedSaveHandler = { [weak self] view in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.handleSaveStory(story: cdBookInternal, view: view)
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

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "SearchDiscoveryEndOfFeedPromptCell",
            for: indexPath
        ) as! SearchDiscoveryEndOfFeedPromptTVC
        cell.actionHandler = { [weak self] action in
            guard let self else { return }
            switch action {
            case .genre:
                self.presentGenreSelection()
            case .length:
                self.presentLengthSelection()
            case .search:
                self.searchTextField.becomeFirstResponder()
            }
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SearchVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension SearchVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        genreCardPresentations.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GenreTileCVC.reuseIdentifier, for: indexPath) as! GenreTileCVC
        let presentation = genreCardPresentations[indexPath.item]
        let isSelected = searchObject.genre == presentation.genre
        cell.configure(with: presentation, isSelected: isSelected)

        if !trackedGenreImpressions.contains(presentation.genre) {
            trackedGenreImpressions.insert(presentation.genre)
            AnalyticsManager.shared.trackSearchGenreCardImpression(
                genre: presentation.genre,
                state: searchViewState.rawValue
            )
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension SearchVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let previousGenre = searchObject.genre
        let selectedGenre = genreCardPresentations[indexPath.item].genre
        searchObject.genre = selectedGenre
        if previousGenre != selectedGenre {
            searchObject.tag = nil
        }
        if selectedGenre == .romance, previousGenre != .romance {
            searchObject.includeAdultContentForRomance = true
        } else if selectedGenre != .romance {
            searchObject.includeAdultContentForRomance = false
        }
        AnalyticsManager.shared.trackSearchGenreCardTapped(genre: selectedGenre, state: searchViewState.rawValue)
        refreshSearchExperience(scrollToTop: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SearchVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemHeight = max(96, collectionView.bounds.height)
        let itemWidth: CGFloat = 176
        return CGSize(width: itemWidth, height: itemHeight)
    }
}

// MARK: - UITextFieldDelegate

extension SearchVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        searchObject.query = nil
        searchTextField.text = ""
        AnalyticsManager.shared.trackSearchFiltersApplied(
            filterCount: searchObject.activeFilterCount,
            state: searchViewState.rawValue
        )
        refreshSearchExperience(scrollToTop: true)
        textField.resignFirstResponder()
        return false
    }
}

extension SearchVC: BookInternalGenreSelectionDelegate {
    func didSelectGenre(_ genre: BookInternalGenre) {
        let previousGenre = searchObject.genre
        searchObject.genre = genre
        if previousGenre != genre {
            searchObject.tag = nil
        }
        if genre == .romance, previousGenre != .romance {
            searchObject.includeAdultContentForRomance = true
        } else if genre != .romance {
            searchObject.includeAdultContentForRomance = false
        }
        AnalyticsManager.shared.trackSearchFiltersApplied(
            filterCount: searchObject.activeFilterCount,
            state: searchViewState.rawValue
        )
        refreshSearchExperience(scrollToTop: true)
    }

    func didClearGenre() {
        searchObject.genre = nil
        searchObject.tag = nil
        searchObject.includeAdultContentForRomance = false
        AnalyticsManager.shared.trackSearchFiltersApplied(
            filterCount: searchObject.activeFilterCount,
            state: searchViewState.rawValue
        )
        refreshSearchExperience(scrollToTop: true)
    }
}
