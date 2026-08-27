//
//  HomeSkeletonView.swift
//  FreeBooks
//
//  Created by Claude on 10/02/2026.
//  Copyright © 2026 FreeBooks Technologies. All rights reserved.
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
        static let headerUpgradeWidth: CGFloat = 96
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
        static let coverCornerRadius: CGFloat = UIConstants.shared.discoverCardCoverCornerRadius

        // Carousel layout
        static let cardSpacing: CGFloat = UIConstants.shared.discoverCarouselMinimumLineSpacing
        static let leadingInset: CGFloat = UIConstants.shared.standardMargin
        static let numberOfCards: Int = 5
    }

    // MARK: - UI Elements

    private let headerSkeletonView = SkeletonHeaderView()
    private let stackView = UIStackView()
    private let sectionTitleWidths: [CGFloat] = [160, 120, 140]

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
        backgroundColor = UIColor.systemBackground
        isSkeletonable = true

        headerSkeletonView.isSkeletonable = true
        addSubviewForConstraints(headerSkeletonView)

        stackView.axis = .vertical
        stackView.isSkeletonable = true
        addSubviewForConstraints(stackView)
        NSLayoutConstraint.activate([
            headerSkeletonView.topAnchor.constraint(equalTo: safeTopAnchor),
            headerSkeletonView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerSkeletonView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerSkeletonView.heightAnchor.constraint(equalToConstant: Layout.headerContentHeight),

            stackView.topAnchor.constraint(equalTo: headerSkeletonView.bottomAnchor, constant: Layout.headerBottomSpacing),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])

        for titleWidth in sectionTitleWidths {
            let section = SkeletonSectionView(titleWidth: titleWidth)
            stackView.addArrangedSubview(section)
        }
    }

    // MARK: - Public API

    func startAnimating() {
        let gradient = SkeletonGradient(
            baseColor: Colours.surfaceSecondary,
            secondaryColor: Colours.surfaceCard
        )
        showAnimatedGradientSkeleton(usingGradient: gradient)
    }

    func stopAnimating() {
        hideSkeleton()
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
        titleBar.backgroundColor = Colours.surfaceSecondary
        titleBar.layer.cornerRadius = HomeSkeletonView.Layout.titleBarCornerRadius
        addSubviewForConstraints(titleBar)

        let avatarPlaceholder = UIView()
        avatarPlaceholder.isSkeletonable = true
        avatarPlaceholder.backgroundColor = Colours.surfaceSecondary
        avatarPlaceholder.layer.cornerRadius = HomeSkeletonView.Layout.headerRightElementHeight / 2
        addSubviewForConstraints(avatarPlaceholder)

        let upgradePlaceholder = UIView()
        upgradePlaceholder.isSkeletonable = true
        upgradePlaceholder.backgroundColor = Colours.surfaceSecondary
        upgradePlaceholder.layer.cornerRadius = HomeSkeletonView.Layout.headerRightElementHeight / 2
        addSubviewForConstraints(upgradePlaceholder)

        NSLayoutConstraint.activate([
            avatarPlaceholder.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -HomeSkeletonView.Layout.leadingInset),
            avatarPlaceholder.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarPlaceholder.widthAnchor.constraint(equalToConstant: HomeSkeletonView.Layout.headerRightElementHeight),
            avatarPlaceholder.heightAnchor.constraint(equalToConstant: HomeSkeletonView.Layout.headerRightElementHeight),

            upgradePlaceholder.trailingAnchor.constraint(equalTo: avatarPlaceholder.leadingAnchor, constant: -HomeSkeletonView.Layout.headerRightElementSpacing),
            upgradePlaceholder.centerYAnchor.constraint(equalTo: centerYAnchor),
            upgradePlaceholder.widthAnchor.constraint(equalToConstant: HomeSkeletonView.Layout.headerUpgradeWidth),
            upgradePlaceholder.heightAnchor.constraint(equalToConstant: HomeSkeletonView.Layout.headerRightElementHeight),

            titleBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: HomeSkeletonView.Layout.leadingInset),
            titleBar.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleBar.widthAnchor.constraint(equalToConstant: HomeSkeletonView.Layout.headerTitleWidth),
            titleBar.heightAnchor.constraint(equalToConstant: HomeSkeletonView.Layout.headerTitleHeight),
            titleBar.trailingAnchor.constraint(lessThanOrEqualTo: upgradePlaceholder.leadingAnchor, constant: -HomeSkeletonView.Layout.headerRightElementSpacing)
        ])
    }
}

// MARK: - SkeletonSectionView

private class SkeletonSectionView: UIView {

    private let titleWidth: CGFloat

    init(titleWidth: CGFloat) {
        self.titleWidth = titleWidth
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
        titleBar.backgroundColor = Colours.surfaceSecondary
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
        for i in 0..<HomeSkeletonView.Layout.numberOfCards {
            let card = SkeletonCardView()
            containerView.addSubviewForConstraints(card)

            let leadingConstant = i == 0 ? HomeSkeletonView.Layout.leadingInset : HomeSkeletonView.Layout.cardSpacing

            NSLayoutConstraint.activate([
                card.topAnchor.constraint(equalTo: containerView.topAnchor, constant: HomeSkeletonView.Layout.cardTopBottomPadding),
                card.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -HomeSkeletonView.Layout.cardTopBottomPadding),
                card.widthAnchor.constraint(equalToConstant: HomeSkeletonView.Layout.coverImageWidth)
            ])

            if let previous = previousCard {
                card.leadingAnchor.constraint(equalTo: previous.trailingAnchor, constant: leadingConstant).isActive = true
            } else {
                card.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: leadingConstant).isActive = true
            }

            if i == HomeSkeletonView.Layout.numberOfCards - 1 {
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
        coverPlaceholder.backgroundColor = Colours.surfaceSecondary
        coverPlaceholder.layer.cornerRadius = HomeSkeletonView.Layout.coverCornerRadius
        addSubviewForConstraints(coverPlaceholder)
        NSLayoutConstraint.activate([
            coverPlaceholder.topAnchor.constraint(equalTo: topAnchor),
            coverPlaceholder.leadingAnchor.constraint(equalTo: leadingAnchor),
            coverPlaceholder.trailingAnchor.constraint(equalTo: trailingAnchor),
            coverPlaceholder.heightAnchor.constraint(equalToConstant: HomeSkeletonView.Layout.coverImageHeight),
            coverPlaceholder.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])
    }
}
