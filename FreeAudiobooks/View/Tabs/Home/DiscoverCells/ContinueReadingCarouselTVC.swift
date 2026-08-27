//
//  ContinueReadingCarouselTVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 16/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

extension ContinueReadingCarouselTVC {
    struct Layout {
        static let topMargin: CGFloat = 20
        static let estimatedTitleHeight: CGFloat = 24
        static let titleToCollectionSpacing: CGFloat = 8
        static let bottomMargin: CGFloat = 8

        /// Half-spacing built into each cell's leading/trailing padding.
        /// Visual gap between adjacent cards = cellHorizontalPadding * 2.
        static let cellHorizontalPadding: CGFloat = UIConstants.shared.discoverCarouselMinimumLineSpacing / 2

        static let storyPreferredWidth: CGFloat = ContinueReadingStoryCVC.Layout.coverWidth + 2 * cellHorizontalPadding

        static let placeholderPreferredWidth: CGFloat = 180 + 2 * cellHorizontalPadding
        static let placeholderMinWidth: CGFloat = 96 + 2 * cellHorizontalPadding

        static let interItemSpacing: CGFloat = 0
        static let sectionInsets = UIEdgeInsets(top: 0, left: UIConstants.shared.standardMargin - cellHorizontalPadding, bottom: 0, right: UIConstants.shared.standardMargin - cellHorizontalPadding)

        static var collectionHeight: CGFloat {
            ContinueReadingStoryCVC.Layout.cardHeight
        }

        static var totalHeight: CGFloat {
            topMargin + estimatedTitleHeight + titleToCollectionSpacing + collectionHeight + bottomMargin
        }
    }
}

class ContinueReadingCarouselTVC: UITableViewCell {

    private enum ContinueDisplayMode {
        case audio
        case text

        var mixedCardLabel: String {
            switch self {
            case .audio: return "Listen"
            case .text:  return "Read"
            }
        }
    }

    private struct StoryPresentation {
        let story: CDBookInternal
        let mode: ContinueDisplayMode
        let isCompleted: Bool
        let progressPercentage: Int?
    }

    private enum DisplayItem {
        case story(StoryPresentation)
        case placeholder
    }

    // MARK: - Properties

    private var items: [DisplayItem] = []
    private var numberOfStories = 0
    private var usesMixedCardLabels = false

    // MARK: - UI Elements

    private let titleLabel = UILabel()
    private let flowLayout = UICollectionViewFlowLayout()
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(ContinueReadingStoryCVC.self, forCellWithReuseIdentifier: "ContinueReadingStoryCell")
        collectionView.register(ContinueReadingPlaceholderCVC.self, forCellWithReuseIdentifier: "ContinueReadingPlaceholderCell")
        return collectionView
    }()

    var tappedContinueHandler: ((CDBookInternal) -> Void)?
    var tappedBrowseStoriesHandler: (() -> Void)?

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = Layout.interItemSpacing
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.sectionInset = Layout.sectionInsets

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        flowLayout.invalidateLayout()
        updateCollectionScrollState()
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = Colours.surfacePrimary
        selectionStyle = .none

        setupTitleLabel()
        setupCollectionView()
        setupConstraints()
    }

    private func setupTitleLabel() {
        titleLabel.font = UIConstants.shared.carouselTitleFont
        titleLabel.textColor = Colours.textPrimary
        titleLabel.numberOfLines = 1
        titleLabel.backgroundColor = .clear

        contentView.addSubviewForConstraints(titleLabel)
    }

    private func setupCollectionView() {
        contentView.addSubviewForConstraints(collectionView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Layout.topMargin),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),

            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Layout.titleToCollectionSpacing),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Layout.bottomMargin),
            collectionView.heightAnchor.constraint(equalToConstant: Layout.collectionHeight)
        ])
    }

    // MARK: - Configuration

    func configure(with section: DiscoverSection, stories: [CDBookInternal]) {
        let storyModes = stories.map { ($0, continueDisplayMode(for: $0)) }
        let uniqueModes = Set(storyModes.map(\.1))
        usesMixedCardLabels = uniqueModes.count > 1
        titleLabel.text = resolvedTitle(for: section, modes: uniqueModes)
        numberOfStories = stories.count

        let completedBookUUIDs = Set(AccountManager.shared.user?.completedBookInternalUUIDs ?? [])
        let progressByBookUUID = ReadingUserDefaults.progressByBookUUID(for: stories)
        items = storyModes.map { storyMode in
            let (story, mode) = storyMode
            return .story(
                StoryPresentation(
                    story: story,
                    mode: mode,
                    isCompleted: completedBookUUIDs.contains(story.contentUUID),
                    progressPercentage: progressByBookUUID[story.contentUUID]
                )
            )
        }
        if shouldShowPlaceholder {
            items.append(.placeholder)
        }

        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
        updateCollectionScrollState()
    }

    private func continueDisplayMode(for story: CDBookInternal) -> ContinueDisplayMode {
        if let lastReadMode = ReadingUserDefaults.getLastReadMode(for: story.contentUUID) {
            switch lastReadMode {
            case .audio: return .audio
            case .text:  return .text
            }
        }

        return AudioPositionManager.shared.hasPosition(for: story.contentUUID) ? .audio : .text
    }

    private func resolvedTitle(for section: DiscoverSection, modes: Set<ContinueDisplayMode>) -> String {
        guard section.type == .continueReading else { return section.title }

        switch (modes.contains(.audio), modes.contains(.text)) {
        case (true, false):  return "Continue listening"
        case (false, true):  return "Continue reading"
        case (true, true):   return "Continue"
        case (false, false): return section.title
        }
    }

    private var shouldShowPlaceholder: Bool {
        numberOfStories == 1 || numberOfStories == 2
    }

    private func resolvedWidths(for collectionView: UICollectionView) -> (storyWidth: CGFloat, placeholderWidth: CGFloat, contentOverflows: Bool) {
        guard shouldShowPlaceholder, numberOfStories > 0 else {
            return (Layout.storyPreferredWidth, Layout.placeholderPreferredWidth, false)
        }

        let spacing = Layout.interItemSpacing * CGFloat(max(items.count - 1, 0))
        let contentWidth = collectionView.bounds.width -
            Layout.sectionInsets.left -
            Layout.sectionInsets.right -
            spacing

        guard contentWidth > 0 else {
            return (Layout.storyPreferredWidth, Layout.placeholderPreferredWidth, false)
        }

        let storyWidth = Layout.storyPreferredWidth
        let requiredMinimumWidth = (storyWidth * CGFloat(numberOfStories)) + Layout.placeholderMinWidth
        let availablePlaceholderWidth = contentWidth - (storyWidth * CGFloat(numberOfStories))
        let placeholderWidth = max(Layout.placeholderMinWidth, availablePlaceholderWidth)
        let contentOverflows = contentWidth < requiredMinimumWidth

        return (storyWidth, placeholderWidth, contentOverflows)
    }

    private func updateCollectionScrollState() {
        guard collectionView.bounds.width > 0 else { return }

        let shouldScrollForOverflow: Bool
        if shouldShowPlaceholder {
            shouldScrollForOverflow = resolvedWidths(for: collectionView).contentOverflows
        } else {
            shouldScrollForOverflow = false
        }

        let shouldScroll = numberOfStories >= 3 || shouldScrollForOverflow
        collectionView.isScrollEnabled = shouldScroll
        collectionView.alwaysBounceHorizontal = shouldScroll

        if !shouldScroll {
            collectionView.setContentOffset(.zero, animated: false)
        }
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        items.removeAll()
        numberOfStories = 0
        usesMixedCardLabels = false
        titleLabel.text = nil
        tappedContinueHandler = nil
        tappedBrowseStoriesHandler = nil
    }
}

// MARK: - UICollectionViewDataSource

extension ContinueReadingCarouselTVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch items[indexPath.item] {
        case .story(let presentation):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContinueReadingStoryCell", for: indexPath) as! ContinueReadingStoryCVC
            let cardLabel = usesMixedCardLabels ? presentation.mode.mixedCardLabel : "Continue"
            cell.configure(
                with: presentation.story,
                continueText: cardLabel,
                isCompleted: presentation.isCompleted,
                progressPercentage: presentation.progressPercentage
            )
            return cell
        case .placeholder:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContinueReadingPlaceholderCell", for: indexPath) as! ContinueReadingPlaceholderCVC
            cell.tappedBrowseStoriesHandler = { [weak self] in
                self?.tappedBrowseStoriesHandler?()
            }
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ContinueReadingCarouselTVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat
        if shouldShowPlaceholder {
            let widths = resolvedWidths(for: collectionView)
            switch items[indexPath.item] {
            case .story:
                width = widths.storyWidth
            case .placeholder:
                width = widths.placeholderWidth
            }
        } else {
            width = Layout.storyPreferredWidth
        }

        return CGSize(width: width, height: Layout.collectionHeight)
    }
}

// MARK: - UICollectionViewDelegate

extension ContinueReadingCarouselTVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard case .story(let presentation) = items[indexPath.item] else { return }
        tappedContinueHandler?(presentation.story)
    }
}
