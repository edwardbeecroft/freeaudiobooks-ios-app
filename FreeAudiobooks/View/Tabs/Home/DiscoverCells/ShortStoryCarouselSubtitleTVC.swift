//
//  ShortStoryCarouselSubtitleTVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 08/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import Kingfisher

extension ShortStoryCarouselSubtitleTVC {
    struct Layout {
        static let topMargin: CGFloat = 14
        static let estimatedSubtitleHeight: CGFloat = 20
        static let subtitleToTitleSpacing: CGFloat = 2
        static let estimatedTitleHeight: CGFloat = 24 // Approximate height for title label
        static let titleToCollectionSpacing: CGFloat = 0
        static let bottomMargin: CGFloat = 4
        
        // Use the card height from BookInternalCVC plus a bit of padding to prevent clipping
        static var collectionHeight: CGFloat {
            return ShortStoryCVC.Layout.cardHeight
        }
        
        static var totalHeight: CGFloat {
            return topMargin + estimatedSubtitleHeight + subtitleToTitleSpacing + estimatedTitleHeight + titleToCollectionSpacing + collectionHeight + bottomMargin
        }
    }
}

class ShortStoryCarouselSubtitleTVC: UITableViewCell {
    
    // MARK: - Properties

    private var stories: [CDBookInternal] = []
    private var section: DiscoverSection?
    private var shouldShowChevron: Bool = false
    
    // MARK: - UI Elements

    private let subtitleLabel = UILabel()
    private let titleLabel = UILabel()
    private let seeAllButton = UIButton(type: .system)
    private let editButton = UIButton(type: .system)
    private let collectionView: UICollectionView

    var tappedBookInternalHandler: ((CDBookInternal) -> Void)?
    var tappedShowMoreChevronHandler: (() -> Void)?
    var tappedEditHandler: (() -> Void)?
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = UIConstants.shared.discoverCarouselMinimumLineSpacing
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: UIConstants.shared.standardMargin, bottom: 0, right: UIConstants.shared.standardMargin)
        
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

        setupSubtitleLabel()
        setupTitleLabel()
        setupSeeAllButton()
        setupEditButton()
        setupCollectionView()
        setupConstraints()
    }

    private func setupSubtitleLabel() {
        subtitleLabel.font = UIConstants.shared.carouselSubtitleKickerFont
        subtitleLabel.textColor = UIConstants.shared.carouselSubtitleKickerTextColour
        subtitleLabel.numberOfLines = 1
        subtitleLabel.backgroundColor = .clear
        subtitleLabel.isHidden = true

        contentView.addSubviewForConstraints(subtitleLabel)
    }
    
    private func setupTitleLabel() {
        titleLabel.font = UIConstants.shared.carouselTitleFont
        titleLabel.textColor = UIConstants.shared.carouselTitleTextColour
        titleLabel.numberOfLines = 1
        titleLabel.backgroundColor = .clear

        contentView.addSubviewForConstraints(titleLabel)
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
        seeAllButton.isHidden = true // Hidden by default
        seeAllButton.addTarget(self, action: #selector(seeAllTapped), for: .touchUpInside)

        contentView.addSubviewForConstraints(seeAllButton)
    }

    @objc private func seeAllTapped() {
        tappedShowMoreChevronHandler?()
    }

    private func setupEditButton() {
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 8, weight: .bold)
        let chevronImage = UIImage(systemName: "chevron.right", withConfiguration: chevronConfig)
        let editButtonColor = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
        editButton.setTitle("Edit", for: .normal)
        editButton.titleLabel?.font = Fonts.medium15
        editButton.setTitleColor(editButtonColor, for: .normal)
        editButton.setImage(chevronImage, for: .normal)
        editButton.tintColor = editButtonColor
        editButton.semanticContentAttribute = .forceRightToLeft
        editButton.contentHorizontalAlignment = .right
        editButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 2)
        editButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
        editButton.setContentHuggingPriority(.required, for: .horizontal)
        editButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        editButton.isHidden = true // Hidden by default
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)

        contentView.addSubviewForConstraints(editButton)
    }

    @objc private func editButtonTapped() {
        tappedEditHandler?()
    }

    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(ShortStoryCVC.self, forCellWithReuseIdentifier: "BookInternalCVC")
        collectionView.register(TopTenShortStoryCVC.self, forCellWithReuseIdentifier: "TopTenBookInternalCVC")
        collectionView.register(ViewAllCVC.self, forCellWithReuseIdentifier: "ViewAllCVC")

        contentView.addSubviewForConstraints(collectionView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Subtitle label
            subtitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Layout.topMargin),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),

            // Title label
            titleLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: Layout.subtitleToTitleSpacing),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: seeAllButton.leadingAnchor, constant: -12),
            {
                let c = titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin)
                c.priority = .defaultLow
                return c
            }(),

            // See all button (right-aligned)
            seeAllButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor, constant: 1),
            seeAllButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12),
            seeAllButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            seeAllButton.widthAnchor.constraint(lessThanOrEqualToConstant: 110),
            seeAllButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 84),
            seeAllButton.heightAnchor.constraint(equalToConstant: 30),

            // Edit button (right-aligned)
            editButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            editButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12),
            editButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            editButton.widthAnchor.constraint(lessThanOrEqualToConstant: 110),
            editButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 84),
            editButton.heightAnchor.constraint(equalToConstant: 30),

            // Collection view
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Layout.titleToCollectionSpacing),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Layout.bottomMargin),
            collectionView.heightAnchor.constraint(equalToConstant: Layout.collectionHeight)
        ])
    }
    
    // MARK: - Configuration
    
    func setContentOffset(_ offset: CGPoint) {
        collectionView.setContentOffset(offset, animated: false)
    }

    func getContentOffset() -> CGPoint {
        return collectionView.contentOffset
    }

    func configure(with section: DiscoverSection, stories: [CDBookInternal]) {
        self.section = section
        self.stories = stories
        let subtitleText = (section.subtitle ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        subtitleLabel.text = subtitleText
        subtitleLabel.isHidden = subtitleText.isEmpty

        // Apply attributed string if title contains "Audiobooks+"
        // Use dynamicTitle if available, otherwise fall back to section title
        var titleText = section.dynamicTitle ?? section.type.localizedTitle ?? section.title
        titleText = titleText.replacingOccurrences(of: "FreeBooks+", with: "Audiobooks+")
        if titleText.contains("Audiobooks+") {
            let attributedString = NSMutableAttributedString(string: titleText)

            // Set default color for entire string
            attributedString.addAttribute(.foregroundColor,
                                          value: UIConstants.shared.carouselTitleTextColour,
                                          range: NSRange(location: 0, length: titleText.count))

            // Find range of "Audiobooks+" and apply gradient color
            if let range = titleText.range(of: "Audiobooks+") {
                let nsRange = NSRange(range, in: titleText)
                attributedString.addAttribute(.foregroundColor,
                                            value: Colours.orangePrimary,
                                            range: nsRange)
            }

            titleLabel.attributedText = attributedString
        } else {
            titleLabel.attributedText = nil
            titleLabel.textColor = UIConstants.shared.carouselTitleTextColour
            titleLabel.text = titleText
        }

        // Show edit button only for forYou section
        let shouldShowEditButton = section.type == .forYou
        editButton.isHidden = !shouldShowEditButton

        // Show chevron for browsable sections (reading time and genre sections)
        switch section.type {
        case .zeroToThirtyMinutes, .thirtyToNinetyMinutes, .ninetyPlusMinutes, .genre:
            shouldShowChevron = true
        default:
            shouldShowChevron = false
        }
        seeAllButton.isHidden = !shouldShowChevron

        collectionView.reloadData()
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        stories.removeAll()
        section = nil
        shouldShowChevron = false
        subtitleLabel.text = nil
        subtitleLabel.isHidden = true
        titleLabel.text = nil
        titleLabel.attributedText = nil
        editButton.isHidden = true
        seeAllButton.isHidden = true
        setContentOffset(.zero)
    }
}

// MARK: - UICollectionViewDataSource

extension ShortStoryCarouselSubtitleTVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Add 1 for the "View all" cell when chevron is shown
        return shouldShowChevron ? stories.count + 1 : stories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Check if this is the "View all" cell
        if shouldShowChevron && indexPath.item == stories.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ViewAllCVC", for: indexPath) as! ViewAllCVC
            cell.configure()
            return cell
        }

        let cdBookInternal = stories[indexPath.item]

        // Use TopTenShortStoryCVC for thisWeeksTopTen section
        if section?.type == .thisWeeksTopTen {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopTenBookInternalCVC", for: indexPath) as! TopTenShortStoryCVC
            let ranking = indexPath.item + 1 // Convert 0-indexed to 1-indexed ranking
            cell.configure(with: cdBookInternal, ranking: ranking, section: section)
            return cell
        } else {
            // Use standard ShortStoryCVC for all other sections
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BookInternalCVC", for: indexPath) as! ShortStoryCVC
            cell.configure(with: cdBookInternal, section: section)
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ShortStoryCarouselSubtitleTVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Use wider cells for Top Ten section to accommodate the ranking number
        if section?.type == .thisWeeksTopTen {
            // Add extra width for the ranking number that appears on the left
            let extraWidthForNumber: CGFloat = 35
            return CGSize(
                width: TopTenShortStoryCVC.Layout.coverImageWidth + extraWidthForNumber,
                height: TopTenShortStoryCVC.Layout.cardHeight
            )
        } else {
            return CGSize(width: ShortStoryCVC.Layout.coverImageWidth, height: ShortStoryCVC.Layout.cardHeight)
        }
    }
}

// MARK: - UICollectionViewDelegate

extension ShortStoryCarouselSubtitleTVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Check if this is the "View all" cell
        if shouldShowChevron && indexPath.item == stories.count {
            tappedShowMoreChevronHandler?()
            return
        }

        let cdBookInternal = stories[indexPath.item]
        tappedBookInternalHandler?(cdBookInternal)
    }
}
