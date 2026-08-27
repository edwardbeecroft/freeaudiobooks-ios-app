//
//  EarlyAccessCarouselTVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 11/11/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

extension ShortStoryEarlyAccessCarouselTVC {
    struct Layout {
        static let topMargin: CGFloat = 22
        static let estimatedTitleHeight: CGFloat = 24 // Approximate height for title label
        static let titleToCollectionSpacing: CGFloat = 6
        static let bottomMargin: CGFloat = 4
        static let horizontalInset: CGFloat = UIConstants.shared.standardMargin

        // Use the card height from the dedicated early-access card.
        static var collectionHeight: CGFloat {
            return EarlyAccessShortStoryCVC.Layout.cardHeight(forCoverWidth: EarlyAccessShortStoryCVC.Layout.coverImageWidth)
        }

        static var totalHeight: CGFloat {
            return topMargin + estimatedTitleHeight + titleToCollectionSpacing + collectionHeight + bottomMargin
        }
    }
}

class ShortStoryEarlyAccessCarouselTVC: UITableViewCell {

    enum Mode {
        case upsell
        case subscriberExclusive
    }

    // MARK: - Properties

    private var stories: [CDBookInternal] = []
    private var section: DiscoverSection?

    // MARK: - UI Elements

    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let chevronButton = UIButton(type: .system)
    private var titleTapGesture: UITapGestureRecognizer!
    private let unlockButton = Buttons.gradientButton(buttonTitle: nil, cornerRadius: 14)
    private let seeAllButton = UIButton(type: .system)

    private let collectionView: UICollectionView

    var tappedBookInternalHandler: ((CDBookInternal) -> Void)?
    var tappedUnlockPlusHandler: (() -> Void)?
    var tappedViewAllHandler: (() -> Void)?

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = UIConstants.shared.discoverCarouselMinimumLineSpacing
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: Layout.horizontalInset, bottom: 0, right: Layout.horizontalInset)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = Colours.surfacePrimary
        selectionStyle = .none

        setupContainerView()
        setupTitleLabel()
        setupChevronButton()
        setupUnlockButton()
        setupSeeAllButton()
        setupCollectionView()
        setupConstraints()
    }

    private func setupContainerView() {
        contentView.addSubviewForConstraints(containerView)
    }

    private func setupTitleLabel() {
        titleLabel.font = UIConstants.shared.carouselTitleFont
        titleLabel.textColor = UIConstants.shared.carouselTitleTextColour
        titleLabel.numberOfLines = 1
        titleLabel.backgroundColor = .clear
        titleLabel.isUserInteractionEnabled = true

        titleTapGesture = UITapGestureRecognizer(target: self, action: #selector(chevronTapped))
        titleLabel.addGestureRecognizer(titleTapGesture)

        containerView.addSubviewForConstraints(titleLabel)
    }

    private func setupChevronButton() {
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 8, weight: .bold)
        let chevronImage = UIImage(systemName: "chevron.right", withConfiguration: chevronConfig)
        chevronButton.setImage(chevronImage, for: .normal)
        chevronButton.tintColor = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)

        chevronButton.addTarget(self, action: #selector(chevronTapped), for: .touchUpInside)

        containerView.addSubviewForConstraints(chevronButton)
    }

    @objc private func chevronTapped() {
        tappedViewAllHandler?()
    }

    private func setupUnlockButton() {
        unlockButton.isHidden = true // Hidden by default, shown for non-subscribers
        unlockButton.setTitle("Try Free", for: .normal)
        unlockButton.titleLabel?.font = Fonts.semiBold13
        unlockButton.setTitleColor(.white, for: .normal)

        let arrowIcon = UIImage(systemName: "arrow.right.circle.fill")?.withRenderingMode(.alwaysTemplate)
        unlockButton.setImage(arrowIcon, for: .normal)
        unlockButton.tintColor = .white
        unlockButton.semanticContentAttribute = .forceRightToLeft
        unlockButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 8)
        unlockButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)

        unlockButton.addTarget(self, action: #selector(unlockTapped), for: .touchUpInside)

        containerView.addSubviewForConstraints(unlockButton)
    }

    @objc private func unlockTapped() {
        tappedUnlockPlusHandler?()
    }

    private func setupSeeAllButton() {
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 8, weight: .bold)
        let chevronImage = UIImage(systemName: "chevron.right", withConfiguration: chevronConfig)
        let seeAllColor = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
        seeAllButton.setTitle("See all", for: .normal)
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
        seeAllButton.isHidden = true // Hidden by default, shown for subscribers
        seeAllButton.addTarget(self, action: #selector(seeAllButtonTapped), for: .touchUpInside)

        containerView.addSubviewForConstraints(seeAllButton)
    }

    @objc private func seeAllButtonTapped() {
        tappedViewAllHandler?()
    }

    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(EarlyAccessShortStoryCVC.self, forCellWithReuseIdentifier: "BookInternalCVC")

        containerView.addSubviewForConstraints(collectionView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view - full width
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Title label
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Layout.topMargin),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Layout.horizontalInset),

            // Chevron button (to the right of title)
            chevronButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor, constant: 1),
            chevronButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: -2),
            chevronButton.widthAnchor.constraint(equalToConstant: 24),
            chevronButton.heightAnchor.constraint(equalToConstant: 24),

            // Unlock button (right-aligned with title, for non-subscribers)
            unlockButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            unlockButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Layout.horizontalInset),
            unlockButton.heightAnchor.constraint(equalToConstant: 28),

            // See all button (right-aligned with title, for subscribers)
            seeAllButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor, constant: 1),
            seeAllButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12),
            seeAllButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Layout.horizontalInset),
            seeAllButton.widthAnchor.constraint(lessThanOrEqualToConstant: 110),
            seeAllButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 84),
            seeAllButton.heightAnchor.constraint(equalToConstant: 30),

            // Collection view
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Layout.titleToCollectionSpacing),
            collectionView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: Layout.collectionHeight),
            collectionView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Layout.bottomMargin)
        ])
    }

    // MARK: - Configuration

    func configure(with section: DiscoverSection, stories: [CDBookInternal]) {
        let isSubscribed = AccountManager.shared.userIsSubscribed
        let mode: Mode = isSubscribed ? .subscriberExclusive : .upsell
        let titleText = isSubscribed ? "Audiobooks+ Early Access" : section.title
        configure(title: titleText, stories: stories, mode: mode)
        self.section = section
    }

    func configure(title: String, stories: [CDBookInternal], mode: Mode) {
        self.section = nil
        self.stories = stories

        let linkColour = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
        
        let titleAdapted = title.replacingOccurrences(of: "FreeBooks+", with: "Audiobooks+")
        // Apply attributed string if title contains "Audiobooks+"
        if titleAdapted.contains("Audiobooks+") {
            let attributedString = NSMutableAttributedString(string: titleAdapted)

            // Set default color for entire string
            attributedString.addAttribute(.foregroundColor,
                                         value: linkColour,
                                         range: NSRange(location: 0, length: titleAdapted.count))

            // Find range of "Audiobooks+" and apply gradient color
            if let range = titleAdapted.range(of: "Audiobooks+") {
                let nsRange = NSRange(range, in: titleAdapted)
                attributedString.addAttribute(.foregroundColor,
                                            value: Colours.orangePrimary,
                                            range: nsRange)
            }

            titleLabel.attributedText = attributedString
        } else {
            titleLabel.attributedText = nil
            titleLabel.textColor = Colours.textPrimary
            titleLabel.text = titleAdapted
        }

        switch mode {
        case .upsell:
            unlockButton.isHidden = false
            seeAllButton.isHidden = true
            chevronButton.isHidden = false
            titleTapGesture.isEnabled = true
            titleLabel.isUserInteractionEnabled = true
        case .subscriberExclusive:
            unlockButton.isHidden = true
            seeAllButton.isHidden = false
            chevronButton.isHidden = true
            titleTapGesture.isEnabled = false
            titleLabel.isUserInteractionEnabled = false
        }

        collectionView.reloadData()
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        stories.removeAll()
        section = nil
        titleLabel.text = nil
        titleLabel.attributedText = nil
        chevronButton.isHidden = false
        titleTapGesture.isEnabled = true
        titleLabel.isUserInteractionEnabled = true
        unlockButton.isHidden = true
        seeAllButton.isHidden = true
    }
}

// MARK: - UICollectionViewDataSource

extension ShortStoryEarlyAccessCarouselTVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BookInternalCVC", for: indexPath) as! EarlyAccessShortStoryCVC
        let cdBookInternal = stories[indexPath.item]
        cell.configure(with: cdBookInternal)

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ShortStoryEarlyAccessCarouselTVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let coverWidth = EarlyAccessShortStoryCVC.Layout.coverImageWidth
        return CGSize(
            width: coverWidth,
            height: EarlyAccessShortStoryCVC.Layout.cardHeight(forCoverWidth: coverWidth)
        )
    }
}

// MARK: - UICollectionViewDelegate

extension ShortStoryEarlyAccessCarouselTVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cdBookInternal = stories[indexPath.item]
        tappedBookInternalHandler?(cdBookInternal)
    }
}
