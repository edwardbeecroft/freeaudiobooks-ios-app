//
//  HomeSkeletonView.swift
//  FreeAudiobooks
//
//  Created by Claude on 10/02/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import SkeletonView

class HomeSkeletonView: UIView {

    // MARK: - Constants

    fileprivate enum Layout {
        // Header skeleton layout (from HeaderView)
        static let headerContentHeight: CGFloat = 52
        static let headerBottomSpacing: CGFloat = 8
        static let headerTitleWidth: CGFloat = 104
        static let headerTitleHeight: CGFloat = 24
        static let headerRightElementHeight: CGFloat = 28
        static let headerStatsPillWidth: CGFloat = 82
        static let headerRightElementSpacing: CGFloat = 12

        // Section dimensions (from ShortStoryCarouselTVC.Layout)
        static let sectionTopMargin: CGFloat = 22
        static let titleToCollectionSpacing: CGFloat = 0
        static let sectionBottomMargin: CGFloat = 4
        static let titleBarHeight: CGFloat = 20
        static let titleBarCornerRadius: CGFloat = 4

        // Card dimensions (from ShortStoryCVC.Layout)
        static let cardTopBottomPadding: CGFloat = 8
        static let coverImageWidth: CGFloat = ShortStoryCVC.Layout.coverImageWidth
        static let coverImageHeight: CGFloat = ShortStoryCVC.Layout.coverImageHeight
        static let coverCornerRadius: CGFloat = UIConstants.shared.bookCoverCornerRadius

        // Carousel layout
        static let cardSpacing: CGFloat = UIConstants.shared.discoverCarouselMinimumLineSpacing
        static let leadingInset: CGFloat = UIConstants.shared.standardMargin
        static let minimumNumberOfCards: Int = 5
        static let maximumNumberOfCards: Int = 12
        static let cardCountBuffer: Int = 1

        // Hero carousel skeleton (from HeroCarouselTVC.Layout)
        static let heroTopMargin: CGFloat = HeroCarouselTVC.Layout.topMargin
        static let heroBottomMargin: CGFloat = HeroCarouselTVC.Layout.bottomMargin
        static let heroCardHeight: CGFloat = HeroCarouselTVC.Layout.cardHeight
        static let heroCardCornerRadius: CGFloat = HeroCarouselTVC.Layout.cardCornerRadius

        // Top 10 card dimensions
        static let topTenCardWidth: CGFloat = TopTenShortStoryCVC.Layout.coverImageWidth + 35
        static let minimumSectionCount: Int = 3
        static let topTenSectionIndex: Int = 1
        static let topTenTitleWidth: CGFloat = 120
        static let standardTitleWidths: [CGFloat] = [160, 100, 140]
    }

    // MARK: - UI Elements

    private let headerSkeletonView = SkeletonHeaderView()
    private let bodyScrollView = UIScrollView()
    private let stackView = UIStackView()
    private let heroCarouselView = SkeletonHeroCarouselView()
    private var sectionViews: [SkeletonSectionView] = []
    private var renderedSectionConfig: (sectionCount: Int, standardCards: Int, topTenCards: Int)?
    private var currentInterfaceStyle: UIUserInterfaceStyle = .light

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        isSkeletonable = true

        headerSkeletonView.isSkeletonable = true
        addSubviewForConstraints(headerSkeletonView)

        bodyScrollView.showsVerticalScrollIndicator = false
        bodyScrollView.isUserInteractionEnabled = false
        bodyScrollView.isSkeletonable = true
        addSubviewForConstraints(bodyScrollView)

        stackView.axis = .vertical
        stackView.isSkeletonable = true
        bodyScrollView.addSubviewForConstraints(stackView)
        NSLayoutConstraint.activate([
            headerSkeletonView.topAnchor.constraint(equalTo: safeTopAnchor),
            headerSkeletonView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerSkeletonView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerSkeletonView.heightAnchor.constraint(equalToConstant: Layout.headerContentHeight),

            bodyScrollView.topAnchor.constraint(equalTo: headerSkeletonView.bottomAnchor, constant: Layout.headerBottomSpacing),
            bodyScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bodyScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bodyScrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stackView.topAnchor.constraint(equalTo: bodyScrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: bodyScrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: bodyScrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bodyScrollView.contentLayoutGuide.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: bodyScrollView.frameLayoutGuide.widthAnchor)
        ])

        // Hero carousel placeholder
        stackView.addArrangedSubview(heroCarouselView)
        _ = rebuildSectionsIfNeeded()
    }

    // MARK: - Public API

    func startAnimating(interfaceStyle: UIUserInterfaceStyle) {
        currentInterfaceStyle = interfaceStyle
        let didRebuildSections = rebuildSectionsIfNeeded()
        let gradient = resolvedGradient(for: interfaceStyle)

        if sk.isSkeletonActive {
            if didRebuildSections {
                hideSkeleton(transition: .none)
                showAnimatedGradientSkeleton(usingGradient: gradient, transition: .crossDissolve(0.15))
            } else {
                updateAnimatedGradientSkeleton(usingGradient: gradient)
            }
        } else {
            showAnimatedGradientSkeleton(usingGradient: gradient, transition: .crossDissolve(0.15))
        }
    }

    func stopAnimating() {
        hideSkeleton(transition: .none)
    }

    private func resolvedGradient(for interfaceStyle: UIUserInterfaceStyle) -> SkeletonGradient {
        let style: UIUserInterfaceStyle = interfaceStyle == .dark ? .dark : .light
        let traitCollection = UITraitCollection(userInterfaceStyle: style)

        let baseColor = Colours.surfaceSecondary.resolvedColor(with: traitCollection)
        let secondaryColor = Colours.surfaceCard.resolvedColor(with: traitCollection)

        return SkeletonGradient(baseColor: baseColor, secondaryColor: secondaryColor)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let didRebuildSections = rebuildSectionsIfNeeded()
        guard didRebuildSections, sk.isSkeletonActive else { return }

        let gradient = resolvedGradient(for: currentInterfaceStyle)
        hideSkeleton(transition: .none)
        showAnimatedGradientSkeleton(usingGradient: gradient, transition: .crossDissolve(0.15))
    }

    @discardableResult
    private func rebuildSectionsIfNeeded() -> Bool {
        guard bounds.width > 0, bounds.height > 0 else { return false }

        let sectionCount = resolvedSectionCount()
        let standardCards = resolvedCardCount(cardWidth: Layout.coverImageWidth)
        let topTenCards = resolvedCardCount(cardWidth: Layout.topTenCardWidth)
        let newConfig = (sectionCount: sectionCount, standardCards: standardCards, topTenCards: topTenCards)

        if let existingConfig = renderedSectionConfig,
           existingConfig.sectionCount == newConfig.sectionCount,
           existingConfig.standardCards == newConfig.standardCards,
           existingConfig.topTenCards == newConfig.topTenCards {
            return false
        }

        sectionViews.forEach { section in
            stackView.removeArrangedSubview(section)
            section.removeFromSuperview()
        }
        sectionViews.removeAll()

        var standardTitleIndex = 0

        for sectionIndex in 0..<sectionCount {
            let sectionView: SkeletonSectionView

            if sectionIndex == Layout.topTenSectionIndex {
                sectionView = SkeletonSectionView(
                    titleWidth: Layout.topTenTitleWidth,
                    cardWidth: Layout.topTenCardWidth,
                    numberOfCards: topTenCards
                )
            } else {
                let titleWidth = Layout.standardTitleWidths[standardTitleIndex % Layout.standardTitleWidths.count]
                standardTitleIndex += 1
                sectionView = SkeletonSectionView(
                    titleWidth: titleWidth,
                    numberOfCards: standardCards
                )
            }

            sectionViews.append(sectionView)
            stackView.addArrangedSubview(sectionView)
        }

        renderedSectionConfig = newConfig
        return true
    }

    private func resolvedCardCount(cardWidth: CGFloat) -> Int {
        let availableWidth = max(0, bounds.width - (2 * Layout.leadingInset))
        let rawCount = Int(floor((availableWidth + Layout.cardSpacing) / (cardWidth + Layout.cardSpacing)))
        let withMinimum = max(rawCount, Layout.minimumNumberOfCards)
        let withBuffer = withMinimum + Layout.cardCountBuffer
        return min(withBuffer, Layout.maximumNumberOfCards)
    }

    private func resolvedSectionCount() -> Int {
        let sectionBlockEstimate = Layout.sectionTopMargin
            + Layout.titleBarHeight
            + Layout.titleToCollectionSpacing
            + ShortStoryCVC.Layout.cardHeight
            + Layout.sectionBottomMargin

        let heroBlockEstimate = Layout.heroTopMargin + Layout.heroCardHeight + Layout.heroBottomMargin
        let availableHeight = max(0, bounds.height - Layout.headerContentHeight - Layout.headerBottomSpacing - heroBlockEstimate)
        let computedCount = Int(ceil(availableHeight / sectionBlockEstimate))
        return max(computedCount, Layout.minimumSectionCount)
    }
}

// MARK: - SkeletonHeaderView

private class SkeletonHeaderView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        isSkeletonable = true

        let titleBar = UIView()
        titleBar.isSkeletonable = true
        titleBar.layer.cornerRadius = HomeSkeletonView.Layout.titleBarCornerRadius
        addSubviewForConstraints(titleBar)

        let avatarPlaceholder = UIView()
        avatarPlaceholder.isSkeletonable = true
        avatarPlaceholder.layer.cornerRadius = HomeSkeletonView.Layout.headerRightElementHeight / 2
        addSubviewForConstraints(avatarPlaceholder)

        let statsPlaceholder = UIView()
        statsPlaceholder.isSkeletonable = true
        statsPlaceholder.layer.cornerRadius = HomeSkeletonView.Layout.headerRightElementHeight / 2
        addSubviewForConstraints(statsPlaceholder)

        NSLayoutConstraint.activate([
            avatarPlaceholder.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -HomeSkeletonView.Layout.leadingInset),
            avatarPlaceholder.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarPlaceholder.widthAnchor.constraint(equalToConstant: HomeSkeletonView.Layout.headerRightElementHeight),
            avatarPlaceholder.heightAnchor.constraint(equalToConstant: HomeSkeletonView.Layout.headerRightElementHeight),

            statsPlaceholder.trailingAnchor.constraint(equalTo: avatarPlaceholder.leadingAnchor, constant: -HomeSkeletonView.Layout.headerRightElementSpacing),
            statsPlaceholder.centerYAnchor.constraint(equalTo: centerYAnchor),
            statsPlaceholder.widthAnchor.constraint(equalToConstant: HomeSkeletonView.Layout.headerStatsPillWidth),
            statsPlaceholder.heightAnchor.constraint(equalToConstant: HomeSkeletonView.Layout.headerRightElementHeight),

            titleBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: HomeSkeletonView.Layout.leadingInset),
            titleBar.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleBar.widthAnchor.constraint(equalToConstant: HomeSkeletonView.Layout.headerTitleWidth),
            titleBar.heightAnchor.constraint(equalToConstant: HomeSkeletonView.Layout.headerTitleHeight),
            titleBar.trailingAnchor.constraint(lessThanOrEqualTo: statsPlaceholder.leadingAnchor, constant: -HomeSkeletonView.Layout.headerRightElementSpacing)
        ])
    }
}

// MARK: - SkeletonHeroCarouselView

private class SkeletonHeroCarouselView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        isSkeletonable = true

        let heroCard = UIView()
        heroCard.isSkeletonable = true
        //heroCard.backgroundColor = Colours.surfaceSecondary
        heroCard.layer.cornerRadius = HomeSkeletonView.Layout.heroCardCornerRadius
        heroCard.clipsToBounds = true
        addSubviewForConstraints(heroCard)

        NSLayoutConstraint.activate([
            heroCard.topAnchor.constraint(equalTo: topAnchor, constant: HomeSkeletonView.Layout.heroTopMargin),
            heroCard.leadingAnchor.constraint(equalTo: leadingAnchor, constant: HomeSkeletonView.Layout.leadingInset),
            heroCard.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -HomeSkeletonView.Layout.leadingInset),
            heroCard.heightAnchor.constraint(equalToConstant: HomeSkeletonView.Layout.heroCardHeight),
            heroCard.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -HomeSkeletonView.Layout.heroBottomMargin)
        ])
    }
}

// MARK: - SkeletonSectionView

private class SkeletonSectionView: UIView {

    private let titleWidth: CGFloat
    private let cardWidth: CGFloat
    private let numberOfCards: Int

    init(
        titleWidth: CGFloat,
        cardWidth: CGFloat = HomeSkeletonView.Layout.coverImageWidth,
        numberOfCards: Int
    ) {
        self.titleWidth = titleWidth
        self.cardWidth = cardWidth
        self.numberOfCards = numberOfCards
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        isSkeletonable = true

        // Title bar
        let titleBar = UIView()
        titleBar.isSkeletonable = true
        //titleBar.backgroundColor = Colours.surfaceSecondary
        titleBar.layer.cornerRadius = HomeSkeletonView.Layout.titleBarCornerRadius
        addSubviewForConstraints(titleBar)
        NSLayoutConstraint.activate([
            titleBar.topAnchor.constraint(equalTo: topAnchor, constant: HomeSkeletonView.Layout.sectionTopMargin),
            titleBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: HomeSkeletonView.Layout.leadingInset),
            titleBar.heightAnchor.constraint(equalToConstant: HomeSkeletonView.Layout.titleBarHeight),
            titleBar.widthAnchor.constraint(equalToConstant: titleWidth)
        ])

        // Horizontal scroll view for cards
        let scrollView = UIScrollView()
        scrollView.isSkeletonable = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isUserInteractionEnabled = false
        addSubviewForConstraints(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: titleBar.bottomAnchor, constant: HomeSkeletonView.Layout.titleToCollectionSpacing),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -HomeSkeletonView.Layout.sectionBottomMargin),
            scrollView.heightAnchor.constraint(equalToConstant: ShortStoryCVC.Layout.cardHeight)
        ])

        // Container view inside scroll view
        let containerView = UIView()
        containerView.isSkeletonable = true
        scrollView.addSubviewForConstraints(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])

        // Add card placeholders
        var previousCard: SkeletonCardView?
        for i in 0..<numberOfCards {
            let card = SkeletonCardView()
            containerView.addSubviewForConstraints(card)

            let leadingConstant = i == 0 ? HomeSkeletonView.Layout.leadingInset : HomeSkeletonView.Layout.cardSpacing

            NSLayoutConstraint.activate([
                card.topAnchor.constraint(equalTo: containerView.topAnchor, constant: HomeSkeletonView.Layout.cardTopBottomPadding),
                card.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -HomeSkeletonView.Layout.cardTopBottomPadding),
                card.widthAnchor.constraint(equalToConstant: cardWidth)
            ])

            if let previous = previousCard {
                card.leadingAnchor.constraint(equalTo: previous.trailingAnchor, constant: leadingConstant).isActive = true
            } else {
                card.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: leadingConstant).isActive = true
            }

            if i == numberOfCards - 1 {
                card.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -HomeSkeletonView.Layout.leadingInset).isActive = true
            }

            previousCard = card
        }
    }
}

// MARK: - SkeletonCardView

private class SkeletonCardView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        isSkeletonable = true

        // Cover image placeholder
        let coverPlaceholder = UIView()
        coverPlaceholder.isSkeletonable = true
        coverPlaceholder.layer.cornerRadius = HomeSkeletonView.Layout.coverCornerRadius
        addSubviewForConstraints(coverPlaceholder)

        // Title placeholder (2-line title area)
        let titlePlaceholder = UIView()
        titlePlaceholder.isSkeletonable = true
        titlePlaceholder.layer.cornerRadius = HomeSkeletonView.Layout.titleBarCornerRadius
        addSubviewForConstraints(titlePlaceholder)

        // Genre placeholder
        let genrePlaceholder = UIView()
        genrePlaceholder.isSkeletonable = true
        genrePlaceholder.layer.cornerRadius = HomeSkeletonView.Layout.titleBarCornerRadius
        addSubviewForConstraints(genrePlaceholder)

        NSLayoutConstraint.activate([
            coverPlaceholder.topAnchor.constraint(equalTo: topAnchor),
            coverPlaceholder.leadingAnchor.constraint(equalTo: leadingAnchor),
            coverPlaceholder.trailingAnchor.constraint(equalTo: trailingAnchor),
            coverPlaceholder.heightAnchor.constraint(equalToConstant: HomeSkeletonView.Layout.coverImageHeight),

            titlePlaceholder.topAnchor.constraint(equalTo: coverPlaceholder.bottomAnchor, constant: ShortStoryCVC.Layout.metaTopSpacing),
            titlePlaceholder.leadingAnchor.constraint(equalTo: leadingAnchor),
            titlePlaceholder.trailingAnchor.constraint(equalTo: trailingAnchor),
            titlePlaceholder.heightAnchor.constraint(equalToConstant: ShortStoryCVC.Layout.titleLabelHeight),

            genrePlaceholder.topAnchor.constraint(equalTo: titlePlaceholder.bottomAnchor, constant: ShortStoryCVC.Layout.metaLabelSpacing),
            genrePlaceholder.leadingAnchor.constraint(equalTo: leadingAnchor),
            genrePlaceholder.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6),
            genrePlaceholder.heightAnchor.constraint(equalToConstant: ShortStoryCVC.Layout.metaLabelHeight),
            genrePlaceholder.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])
    }
}
