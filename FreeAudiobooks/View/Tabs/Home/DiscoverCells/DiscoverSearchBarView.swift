//
//  DiscoverSearchBarView.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 21/03/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

class DiscoverSearchBarView: UIView {

    // MARK: - Handlers

    var searchBarTappedHandler: (() -> Void)?
    var genreFilterTappedHandler: (() -> Void)?
    var readingTimeFilterTappedHandler: (() -> Void)?
    var moreFilterTappedHandler: (() -> Void)?

    // MARK: - UI Elements

    private let searchBarButton = UIButton(type: .system)
    private let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
    private let placeholderLabel = UILabel()
    private let filtersButton = UIButton(type: .system)
    private let filterPillsStack = UIStackView()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = Colours.backgroundGrey
        setupSearchBar()
        setupFilterPills()
        setupConstraints()
    }

    private func setupSearchBar() {
        searchBarButton.backgroundColor = Colours.surfaceCard
        searchBarButton.layer.cornerRadius = UIConstants.shared.cornerRadius
        searchBarButton.layer.borderWidth = 1
        searchBarButton.addTarget(self, action: #selector(searchBarTapped), for: .touchUpInside)
        updateSearchBarAppearance()

        addSubviewForConstraints(searchBarButton)

        searchIcon.tintColor = Colours.textSecondary
        searchIcon.contentMode = .scaleAspectFit
        searchIcon.isUserInteractionEnabled = false
        searchBarButton.addSubviewForConstraints(searchIcon)

        placeholderLabel.text = "Search stories..."
        placeholderLabel.font = Fonts.medium16
        placeholderLabel.textColor = Colours.textSecondary.withAlphaComponent(0.5)
        placeholderLabel.isUserInteractionEnabled = false
        searchBarButton.addSubviewForConstraints(placeholderLabel)

        let filtersButtonConfig = UIImage.SymbolConfiguration(pointSize: 18)
        filtersButton.setImage(UIImage(systemName: "line.3.horizontal.decrease", withConfiguration: filtersButtonConfig), for: .normal)
        filtersButton.tintColor = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
        filtersButton.addTarget(self, action: #selector(filtersIconTapped), for: .touchUpInside)
        addSubviewForConstraints(filtersButton)
    }

    private func setupFilterPills() {
        filterPillsStack.axis = .horizontal
        filterPillsStack.spacing = 8
        filterPillsStack.alignment = .center

        let genrePill = makeFilterPill(title: "+ Genre", action: #selector(genreTapped))
        let readingTimePill = makeFilterPill(title: "+ Listening Time", action: #selector(readingTimeTapped))
        let morePill = makeFilterPill(title: "+ More", action: #selector(moreTapped))

        filterPillsStack.addArrangedSubview(genrePill)
        filterPillsStack.addArrangedSubview(readingTimePill)
        filterPillsStack.addArrangedSubview(morePill)

        addSubviewForConstraints(filterPillsStack)
    }

    private func makeFilterPill(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIConstants.shared.filterChipFont
        let accent = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
        button.setTitleColor(accent, for: .normal)
        button.backgroundColor = accent.withAlphaComponent(0.1)
        button.layer.cornerRadius = 14
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        button.addTarget(self, action: action, for: .touchUpInside)
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 28)
        ])
        return button
    }

    private func updateSearchBarAppearance() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        searchBarButton.backgroundColor = Colours.surfaceCard
        searchBarButton.layer.borderColor = Colours.inputBorder.withAlphaComponent(isDark ? 0.6 : 0.5).cgColor
        searchBarButton.layer.shadowColor = Colours.shadowBase.withAlphaComponent(isDark ? 0.14 : 0.06).cgColor
        searchBarButton.layer.shadowOffset = CGSize(width: 0, height: isDark ? 1 : 2)
        searchBarButton.layer.shadowOpacity = 1
        searchBarButton.layer.shadowRadius = isDark ? 6 : 8
    }

    private func updateFilterPillAppearance() {
        let accent = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
        for case let button as UIButton in filterPillsStack.arrangedSubviews {
            button.backgroundColor = accent.withAlphaComponent(0.1)
        }
    }

    private func setupBottomBorder() {
        let border = UIView()
        border.backgroundColor = Colours.separator.withAlphaComponent(0.5)
        addSubviewForConstraints(border)
        NSLayoutConstraint.activate([
            border.leadingAnchor.constraint(equalTo: leadingAnchor),
            border.trailingAnchor.constraint(equalTo: trailingAnchor),
            border.bottomAnchor.constraint(equalTo: bottomAnchor),
            border.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    private func setupConstraints() {
        let margin: CGFloat = 16

        NSLayoutConstraint.activate([
            // Search bar
            searchBarButton.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            searchBarButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
            searchBarButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
            searchBarButton.heightAnchor.constraint(equalToConstant: 50),

            // Search icon (inside search bar)
            searchIcon.leadingAnchor.constraint(equalTo: searchBarButton.leadingAnchor, constant: 12),
            searchIcon.centerYAnchor.constraint(equalTo: searchBarButton.centerYAnchor),
            searchIcon.widthAnchor.constraint(equalToConstant: 20),
            searchIcon.heightAnchor.constraint(equalToConstant: 20),

            // Placeholder label
            placeholderLabel.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 10),
            placeholderLabel.centerYAnchor.constraint(equalTo: searchBarButton.centerYAnchor),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: filtersButton.leadingAnchor, constant: -8),

            // Filters button (overlays right edge of search bar)
            filtersButton.trailingAnchor.constraint(equalTo: searchBarButton.trailingAnchor),
            filtersButton.topAnchor.constraint(equalTo: searchBarButton.topAnchor),
            filtersButton.bottomAnchor.constraint(equalTo: searchBarButton.bottomAnchor),
            filtersButton.widthAnchor.constraint(equalToConstant: 50),

            // Filter pills stack
            filterPillsStack.topAnchor.constraint(equalTo: searchBarButton.bottomAnchor, constant: 12),
            filterPillsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
            filterPillsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])
    }

    // MARK: - Actions

    @objc private func searchBarTapped() {
        searchBarTappedHandler?()
    }

    @objc private func filtersIconTapped() {
        moreFilterTappedHandler?()
    }

    @objc private func genreTapped() {
        genreFilterTappedHandler?()
    }

    @objc private func readingTimeTapped() {
        readingTimeFilterTappedHandler?()
    }

    @objc private func moreTapped() {
        moreFilterTappedHandler?()
    }

    // MARK: - Appearance Updates

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateSearchBarAppearance()
        updateFilterPillAppearance()
    }
}
