//
//  HeroCarouselTVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 21/02/2026.
//  Copyright © 2026 Kneady Technologies. All rights reserved.
//

import Foundation
import UIKit

enum HeroCarouselLayout: String, CaseIterable {
    case coverLeading
    case coverTrailing
    case coverLeadingTextCentered
    case coverTrailingTextCentered
    case coverLeadingDiagonal
    case coverTrailingDiagonal

    var displayName: String {
        switch self {
        case .coverLeading: return "Cover Left"
        case .coverTrailing: return "Cover Right"
        case .coverLeadingTextCentered: return "Cover Left Text Centered"
        case .coverTrailingTextCentered: return "Cover Right Text Centered"
        case .coverLeadingDiagonal: return "Cover Left Diagonal"
        case .coverTrailingDiagonal: return "Cover Right Diagonal"
        }
    }
}

private struct HeroCarouselCardLayoutConfig {
    enum Placement {
        case coverLeadingCentered
        case coverTrailingCentered
        case coverLeadingAngledTextCentered
        case coverTrailingAngledTextCentered
        case coverLeadingDiagonal
        case coverTrailingDiagonal
    }

    enum TextAlignmentStyle {
        case leading
        case centered
    }

    let placement: Placement
    let coverHeight: CGFloat
    let coverRotationAngle: CGFloat
    let textAlignmentStyle: TextAlignmentStyle
    let contentInset: CGFloat
    let textToCoverSpacing: CGFloat
    let diagonalCoverLeading: CGFloat
    let diagonalCoverCenterYOffset: CGFloat
    let centeredTextCenterXOffset: CGFloat

    var coverWidth: CGFloat {
        coverHeight * UIConstants.shared.bookInternalCoverImageWidthToHeightRatio
    }
}

private extension HeroCarouselLayout {
    var cardLayoutConfig: HeroCarouselCardLayoutConfig {
        switch self {
        case .coverLeading:
            return HeroCarouselCardLayoutConfig(
                placement: .coverLeadingCentered,
                coverHeight: 120,
                coverRotationAngle: 0,
                textAlignmentStyle: .leading,
                contentInset: 14,
                textToCoverSpacing: 16,
                diagonalCoverLeading: 0,
                diagonalCoverCenterYOffset: 0,
                centeredTextCenterXOffset: 0
            )
        case .coverTrailing:
            return HeroCarouselCardLayoutConfig(
                placement: .coverTrailingCentered,
                coverHeight: 120,
                coverRotationAngle: 0,
                textAlignmentStyle: .leading,
                contentInset: 14,
                textToCoverSpacing: 16,
                diagonalCoverLeading: 0,
                diagonalCoverCenterYOffset: 0,
                centeredTextCenterXOffset: 0
            )
        case .coverLeadingTextCentered:
            return HeroCarouselCardLayoutConfig(
                placement: .coverLeadingAngledTextCentered,
                coverHeight: 110,
                coverRotationAngle: -.pi / 14,
                textAlignmentStyle: .centered,
                contentInset: 14,
                textToCoverSpacing: 12,
                diagonalCoverLeading: 16,
                diagonalCoverCenterYOffset: 0,
                centeredTextCenterXOffset: 0
            )
        case .coverTrailingTextCentered:
            return HeroCarouselCardLayoutConfig(
                placement: .coverTrailingAngledTextCentered,
                coverHeight: 110,
                coverRotationAngle: .pi / 14,
                textAlignmentStyle: .centered,
                contentInset: 14,
                textToCoverSpacing: 12,
                diagonalCoverLeading: 16,
                diagonalCoverCenterYOffset: 0,
                centeredTextCenterXOffset: 0
            )
        case .coverLeadingDiagonal:
            return HeroCarouselCardLayoutConfig(
                placement: .coverLeadingDiagonal,
                coverHeight: 150,
                coverRotationAngle: -.pi / 10,
                textAlignmentStyle: .centered,
                contentInset: 14,
                textToCoverSpacing: 16,
                diagonalCoverLeading: 12,
                diagonalCoverCenterYOffset: 2,
                centeredTextCenterXOffset: 0
            )
        case .coverTrailingDiagonal:
            return HeroCarouselCardLayoutConfig(
                placement: .coverTrailingDiagonal,
                coverHeight: 150,
                coverRotationAngle: .pi / 10,
                textAlignmentStyle: .centered,
                contentInset: 14,
                textToCoverSpacing: 16,
                diagonalCoverLeading: 12,
                diagonalCoverCenterYOffset: 2,
                centeredTextCenterXOffset: 0
            )
        }
    }
}

extension CDBookInternal {
    var heroCarouselLayout: HeroCarouselLayout? {
        guard let heroLayout, !heroLayout.isEmpty else { return nil }
        return HeroCarouselLayout(rawValue: heroLayout)
    }

    var isValidHeroCarouselStory: Bool {
        guard
            let heroBackgroundImageURL,
            !heroBackgroundImageURL.isEmpty,
            let heroBackgroundImageURLXL,
            !heroBackgroundImageURLXL.isEmpty,
            let coverImageURL,
            !coverImageURL.isEmpty,
            let heroTitle,
            !heroTitle.isEmpty,
            let heroSubtitle,
            !heroSubtitle.isEmpty,
            heroCarouselLayout != nil else {
            return false
        }
        return true
    }
}

extension HeroCarouselTVC {
    struct Layout {
        static let topMargin: CGFloat = 22
        static let bottomMargin: CGFloat = 10
        static let sectionInset = UIEdgeInsets(top: 0, left: UIConstants.shared.standardMargin, bottom: 0, right: UIConstants.shared.standardMargin)
        static let lineSpacing: CGFloat = 12
        static let cardCornerRadius: CGFloat = UIConstants.shared.cardCornerRadius
        static let cardHeight: CGFloat = UIDevice().iPad ? 220 : 172

        static var totalHeight: CGFloat {
            topMargin + cardHeight + bottomMargin
        }
    }
}

final class HeroCarouselTVC: UITableViewCell {

    private var stories: [CDBookInternal] = []
    private var autoScrollTimer: Timer?

    private let flowLayout = UICollectionViewFlowLayout()
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = .fast
        collectionView.register(HeroCarouselCardCVC.self, forCellWithReuseIdentifier: "HeroCarouselCardCell")
        return collectionView
    }()

    var tappedBookInternalHandler: ((CDBookInternal) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = Layout.lineSpacing
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.sectionInset = Layout.sectionInset

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopAutoScrollTimer()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        flowLayout.invalidateLayout()
    }

    private func setupUI() {
        backgroundColor = Colours.surfacePrimary
        selectionStyle = .none

        contentView.addSubviewForConstraints(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Layout.topMargin),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Layout.bottomMargin),
            collectionView.heightAnchor.constraint(equalToConstant: Layout.cardHeight)
        ])
    }

    func setContentOffset(_ offset: CGPoint) {
        collectionView.setContentOffset(offset, animated: false)
    }

    func getContentOffset() -> CGPoint {
        collectionView.contentOffset
    }

    func pauseAutoScroll() {
        stopAutoScrollTimer()
    }

    func resumeAutoScrollIfNeeded() {
        guard autoScrollTimer == nil, stories.count > 1 else { return }
        startAutoScrollTimer()
    }

    func configure(with stories: [CDBookInternal]) {
        self.stories = stories.filter { $0.isValidHeroCarouselStory }

        collectionView.setContentOffset(.zero, animated: false)
        collectionView.reloadData()

        if self.stories.count > 1 {
            startAutoScrollTimer()
        } else {
            stopAutoScrollTimer()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopAutoScrollTimer()
        stories.removeAll()
        tappedBookInternalHandler = nil
    }

    private func startAutoScrollTimer() {
        stopAutoScrollTimer()
        autoScrollTimer = Timer.scheduledTimer(timeInterval: 4.0,
                                               target: self,
                                               selector: #selector(autoScrollToNextCard),
                                               userInfo: nil,
                                               repeats: true)
    }

    private func stopAutoScrollTimer() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    @objc private func autoScrollToNextCard() {
        guard stories.count > 1 else { return }
        let nextIndex = (currentIndex() + 1) % stories.count
        let targetOffsetX = contentOffsetX(for: nextIndex)
        collectionView.setContentOffset(CGPoint(x: targetOffsetX, y: collectionView.contentOffset.y), animated: true)
    }

    private func currentIndex() -> Int {
        indexForContentOffsetX(collectionView.contentOffset.x)
    }

    private func resolvedCardWidth() -> CGFloat {
        let totalHorizontalInset = Layout.sectionInset.left + Layout.sectionInset.right
        let visiblePeek: CGFloat = 12
        return max(collectionView.bounds.width - totalHorizontalInset - visiblePeek, 0)
    }

    private func cardSpan() -> CGFloat {
        resolvedCardWidth() + Layout.lineSpacing
    }

    private func clampedIndex(_ index: Int) -> Int {
        max(0, min(index, max(stories.count - 1, 0)))
    }

    private func indexForContentOffsetX(_ x: CGFloat, rounding: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> Int {
        let span = cardSpan()
        guard span > 0 else { return 0 }

        let normalizedX = x + collectionView.adjustedContentInset.left
        let rawIndex = Int((normalizedX / span).rounded(rounding))
        return clampedIndex(rawIndex)
    }

    private func contentOffsetX(for index: Int) -> CGFloat {
        let span = cardSpan()
        guard span > 0 else { return 0 }

        let clamped = clampedIndex(index)
        return CGFloat(clamped) * span - collectionView.adjustedContentInset.left
    }

    private func snapToNearestCard(targetOffset: UnsafeMutablePointer<CGPoint>) {
        let nearestIndex = indexForContentOffsetX(targetOffset.pointee.x)
        targetOffset.pointee.x = contentOffsetX(for: nearestIndex)
    }
}

extension HeroCarouselTVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        stories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let story = stories[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HeroCarouselCardCell", for: indexPath) as! HeroCarouselCardCVC
        cell.configure(with: story)
        return cell
    }
}

extension HeroCarouselTVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: resolvedCardWidth(), height: Layout.cardHeight)
    }
}

extension HeroCarouselTVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < stories.count else { return }
        tappedBookInternalHandler?(stories[indexPath.item])
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopAutoScrollTimer()
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let velocityThresholdX: CGFloat = 0.35

        guard stories.count > 0 else {
            snapToNearestCard(targetOffset: targetContentOffset)
            return
        }

        let current = currentIndex()
        let proposedNearest = indexForContentOffsetX(targetContentOffset.pointee.x)

        let targetIndex: Int
        if abs(velocity.x) < velocityThresholdX {
            targetIndex = proposedNearest
        } else if velocity.x > 0 {
            targetIndex = max(proposedNearest, current + 1)
        } else {
            targetIndex = min(proposedNearest, current - 1)
        }

        targetContentOffset.pointee.x = contentOffsetX(for: targetIndex)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if stories.count > 1 {
            startAutoScrollTimer()
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate, stories.count > 1 {
            startAutoScrollTimer()
        }
    }
}

final class HeroCarouselCardPreviewView: UIView {

    struct Layout {
        static let cornerRadius: CGFloat = 12
        static let coverCornerRadius: CGFloat = UIConstants.shared.bookCoverCornerRadius
        static let overlayHeight: CGFloat = 90
        static let preferredHeight: CGFloat = UIDevice().iPad ? 220 : 172
    }

    private let imageView = UIImageView()
    private let overlayView = UIView()
    private let overlayGradientLayer = CAGradientLayer()
    private let textLegibilityScrimLayer = CAGradientLayer()
    private let textAndCTAStackView = UIStackView()
    private let coverImageShadowView = UIView()
    private let coverImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let ctaButton = UIButton(type: .system)
    private let ctaButtonHeight: CGFloat = 34
    private var activeLayoutConstraints: [NSLayoutConstraint] = []
    private var coverWidthConstraint: NSLayoutConstraint!
    private var coverHeightConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        coverImageShadowView.layer.shadowPath = UIBezierPath(roundedRect: coverImageShadowView.bounds, cornerRadius: Layout.coverCornerRadius).cgPath
        overlayGradientLayer.frame = overlayView.bounds
        textLegibilityScrimLayer.frame = overlayView.bounds
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateLayerChromeColors()
    }

    private func setupUI() {
        addSubviewForConstraints(imageView)
        addSubviewForConstraints(overlayView)
        addSubviewForConstraints(textAndCTAStackView)
        addSubviewForConstraints(coverImageShadowView)
        coverImageShadowView.addSubviewForConstraints(coverImageView)

        textAndCTAStackView.axis = .vertical
        textAndCTAStackView.spacing = 6
        textAndCTAStackView.alignment = .leading
        textAndCTAStackView.distribution = .fill

        titleLabel.font = Fonts.semiBold15
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        titleLabel.layer.shadowOpacity = 0.28
        titleLabel.layer.shadowRadius = 3
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 1.5)

        subtitleLabel.font =  Fonts.regular14
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.95)
        subtitleLabel.numberOfLines = 2
        subtitleLabel.layer.shadowOpacity = 0.18
        subtitleLabel.layer.shadowRadius = 2
        subtitleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)

        ctaButton.setTitle("Listen Now", for: .normal)
        ctaButton.setTitleColor(Colours.brandBlack, for: .normal)
        ctaButton.titleLabel?.font = Fonts.semiBold14
        ctaButton.backgroundColor = UIColor.dynamic(light: .white, dark: Colours.ctaBackground)
        ctaButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 24, bottom: 8, right: 24)
        ctaButton.layer.cornerRadius = ctaButtonHeight / 2
        ctaButton.isUserInteractionEnabled = false

        [titleLabel, subtitleLabel, ctaButton].forEach { textAndCTAStackView.addArrangedSubview($0) }
        textAndCTAStackView.setCustomSpacing(10, after: subtitleLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: bottomAnchor),
            overlayView.topAnchor.constraint(equalTo: topAnchor),

            textAndCTAStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -14),

            coverImageView.topAnchor.constraint(equalTo: coverImageShadowView.topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: coverImageShadowView.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: coverImageShadowView.trailingAnchor),
            coverImageView.bottomAnchor.constraint(equalTo: coverImageShadowView.bottomAnchor),

            ctaButton.heightAnchor.constraint(equalToConstant: ctaButtonHeight)
        ])
        let defaultCoverConfig = HeroCarouselLayout.coverLeading.cardLayoutConfig
        coverWidthConstraint = coverImageShadowView.widthAnchor.constraint(equalToConstant: defaultCoverConfig.coverWidth)
        coverHeightConstraint = coverImageShadowView.heightAnchor.constraint(equalToConstant: defaultCoverConfig.coverHeight)
        NSLayoutConstraint.activate([coverWidthConstraint, coverHeightConstraint])

        layer.cornerRadius = Layout.cornerRadius
        clipsToBounds = true
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Layout.cornerRadius
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .clear

        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.14)
        overlayView.isUserInteractionEnabled = false
        overlayView.layer.cornerRadius = Layout.cornerRadius
        overlayView.clipsToBounds = true

        overlayGradientLayer.type = .axial
        overlayGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        overlayGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        overlayView.layer.insertSublayer(overlayGradientLayer, at: 0)

        textLegibilityScrimLayer.type = .axial
        textLegibilityScrimLayer.startPoint = CGPoint(x: 0, y: 0.5)
        textLegibilityScrimLayer.endPoint = CGPoint(x: 1, y: 0.5)
        overlayView.layer.insertSublayer(textLegibilityScrimLayer, above: overlayGradientLayer)

        coverImageShadowView.backgroundColor = .clear
        coverImageShadowView.layer.shadowOpacity = 0.28
        coverImageShadowView.layer.shadowRadius = 10
        coverImageShadowView.layer.shadowOffset = CGSize(width: 0, height: 6)
        coverImageShadowView.layer.cornerRadius = Layout.coverCornerRadius
        coverImageShadowView.layer.masksToBounds = false

        coverImageView.clipsToBounds = true
        coverImageView.layer.cornerRadius = Layout.coverCornerRadius
        coverImageView.layer.borderWidth = 1
        coverImageView.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.backgroundColor = UIColor.clear

        updateLayerChromeColors()
        apply(layout: .coverLeading)
    }

    private func updateLayerChromeColors() {
        let shadowCGColor = Colours.shadowBase.cgColor
        titleLabel.layer.shadowColor = shadowCGColor
        subtitleLabel.layer.shadowColor = shadowCGColor
        coverImageShadowView.layer.shadowColor = shadowCGColor
        coverImageView.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
    }

    private func apply(layout: HeroCarouselLayout) {
        let config = layout.cardLayoutConfig
        NSLayoutConstraint.deactivate(activeLayoutConstraints)
        coverWidthConstraint.constant = config.coverWidth
        coverHeightConstraint.constant = config.coverHeight
        coverImageShadowView.transform = CGAffineTransform(rotationAngle: config.coverRotationAngle)
        applyTextAlignmentStyle(config.textAlignmentStyle)
        applyOverlayGradient(for: layout)
        applyTextLegibilityScrim(for: layout)
        activeLayoutConstraints = makeLayoutConstraints(for: config)
        NSLayoutConstraint.activate(activeLayoutConstraints)
    }

    private func applyOverlayGradient(for layout: HeroCarouselLayout) {
        let colors: [UIColor]
        let locations: [NSNumber]

        switch layout {
        case .coverLeading, .coverLeadingDiagonal:
            colors = [
                UIColor.black.withAlphaComponent(0.08),
                UIColor.black.withAlphaComponent(0.14),
                UIColor.black.withAlphaComponent(0.28),
                UIColor.black.withAlphaComponent(0.44)
            ]
            locations = [0.0, 0.28, 0.62, 1.0]

        case .coverTrailing, .coverTrailingDiagonal:
            colors = [
                UIColor.black.withAlphaComponent(0.44),
                UIColor.black.withAlphaComponent(0.28),
                UIColor.black.withAlphaComponent(0.14),
                UIColor.black.withAlphaComponent(0.08)
            ]
            locations = [0.0, 0.38, 0.72, 1.0]

        case .coverLeadingTextCentered, .coverTrailingTextCentered:
            colors = [
                UIColor.black.withAlphaComponent(0.10),
                UIColor.black.withAlphaComponent(0.18),
                UIColor.black.withAlphaComponent(0.32),
                UIColor.black.withAlphaComponent(0.32),
                UIColor.black.withAlphaComponent(0.18),
                UIColor.black.withAlphaComponent(0.10)
            ]
            locations = [0.0, 0.18, 0.38, 0.62, 0.82, 1.0]
        }

        overlayGradientLayer.colors = colors.map(\.cgColor)
        overlayGradientLayer.locations = locations
    }

    private func applyTextLegibilityScrim(for layout: HeroCarouselLayout) {
        let scrimColors = [
            UIColor.black.withAlphaComponent(0.46).cgColor,
            UIColor.black.withAlphaComponent(0.32).cgColor,
            UIColor.black.withAlphaComponent(0.16).cgColor,
            UIColor.black.withAlphaComponent(0.0).cgColor
        ]

        switch layout {
        case .coverTrailing, .coverTrailingDiagonal:
            textLegibilityScrimLayer.startPoint = CGPoint(x: 0, y: 0.5)
            textLegibilityScrimLayer.endPoint = CGPoint(x: 1, y: 0.5)
            textLegibilityScrimLayer.colors = scrimColors
            textLegibilityScrimLayer.locations = [0.0, 0.28, 0.58, 1.0]

        case .coverLeading, .coverLeadingDiagonal:
            textLegibilityScrimLayer.startPoint = CGPoint(x: 1, y: 0.5)
            textLegibilityScrimLayer.endPoint = CGPoint(x: 0, y: 0.5)
            textLegibilityScrimLayer.colors = scrimColors
            textLegibilityScrimLayer.locations = [0.0, 0.28, 0.58, 1.0]

        case .coverLeadingTextCentered, .coverTrailingTextCentered:
            textLegibilityScrimLayer.startPoint = CGPoint(x: 0, y: 0.5)
            textLegibilityScrimLayer.endPoint = CGPoint(x: 1, y: 0.5)
            textLegibilityScrimLayer.colors = [
                UIColor.black.withAlphaComponent(0.10).cgColor,
                UIColor.black.withAlphaComponent(0.24).cgColor,
                UIColor.black.withAlphaComponent(0.34).cgColor,
                UIColor.black.withAlphaComponent(0.24).cgColor,
                UIColor.black.withAlphaComponent(0.10).cgColor
            ]
            textLegibilityScrimLayer.locations = [0.0, 0.24, 0.50, 0.76, 1.0]
        }
    }

    private func applyTextAlignmentStyle(_ style: HeroCarouselCardLayoutConfig.TextAlignmentStyle) {
        switch style {
        case .leading:
            textAndCTAStackView.alignment = .leading
            titleLabel.textAlignment = .left
            subtitleLabel.textAlignment = .left
        case .centered:
            textAndCTAStackView.alignment = .center
            titleLabel.textAlignment = .center
            subtitleLabel.textAlignment = .center
        }
    }

    private func makeLayoutConstraints(for config: HeroCarouselCardLayoutConfig) -> [NSLayoutConstraint] {
        switch config.placement {
        case .coverLeadingCentered:
            return [
                coverImageShadowView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: config.contentInset),
                coverImageShadowView.centerYAnchor.constraint(equalTo: centerYAnchor),
                textAndCTAStackView.leadingAnchor.constraint(equalTo: coverImageShadowView.trailingAnchor, constant: config.textToCoverSpacing),
                textAndCTAStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
            ]

        case .coverTrailingCentered:
            return [
                coverImageShadowView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -config.contentInset),
                coverImageShadowView.centerYAnchor.constraint(equalTo: centerYAnchor),
                textAndCTAStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: config.contentInset),
                textAndCTAStackView.trailingAnchor.constraint(lessThanOrEqualTo: coverImageShadowView.leadingAnchor, constant: -config.textToCoverSpacing),
                textAndCTAStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
            ]

        case .coverLeadingAngledTextCentered:
            return [
                coverImageShadowView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: config.diagonalCoverLeading),
                coverImageShadowView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: config.diagonalCoverCenterYOffset),
                textAndCTAStackView.leadingAnchor.constraint(greaterThanOrEqualTo: coverImageShadowView.trailingAnchor, constant: config.textToCoverSpacing),
                textAndCTAStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -config.contentInset),
                textAndCTAStackView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: config.centeredTextCenterXOffset),
                textAndCTAStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
            ]

        case .coverTrailingAngledTextCentered:
            return [
                coverImageShadowView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -config.diagonalCoverLeading),
                coverImageShadowView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: config.diagonalCoverCenterYOffset),
                textAndCTAStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: config.contentInset),
                textAndCTAStackView.trailingAnchor.constraint(lessThanOrEqualTo: coverImageShadowView.leadingAnchor, constant: -config.textToCoverSpacing),
                textAndCTAStackView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: config.centeredTextCenterXOffset),
                textAndCTAStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
            ]

        case .coverLeadingDiagonal:
            return [
                coverImageShadowView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: config.diagonalCoverLeading),
                coverImageShadowView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: config.diagonalCoverCenterYOffset),
                textAndCTAStackView.leadingAnchor.constraint(greaterThanOrEqualTo: coverImageShadowView.trailingAnchor, constant: config.textToCoverSpacing),
                textAndCTAStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                textAndCTAStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
            ]

        case .coverTrailingDiagonal:
            return [
                coverImageShadowView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -config.diagonalCoverLeading),
                coverImageShadowView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: config.diagonalCoverCenterYOffset),
                textAndCTAStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                textAndCTAStackView.trailingAnchor.constraint(lessThanOrEqualTo: coverImageShadowView.leadingAnchor, constant: -config.textToCoverSpacing),
                textAndCTAStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
            ]
        }
    }

    func configure(layout: HeroCarouselLayout, image: UIImage?, imageURLString: String?, coverImage: UIImage?, coverImageURLString: String?, title: String?, subtitle: String?, ctaTitle: String = "Listen Now") {
        apply(layout: layout)
        if let image {
            imageView.kf.cancelDownloadTask()
            imageView.image = image
            imageView.contentMode = .scaleAspectFill
        } else if
            let imageURLString = imageURLString,
            !imageURLString.isEmpty,
            let imageURL = URL(string: imageURLString) {
            imageView.kf.indicatorType = .activity
            imageView.contentMode = .scaleAspectFill
            imageView.kf.setImage(with: imageURL, options: [.transition(.fade(0.2))])
        } else {
            imageView.kf.cancelDownloadTask()
            imageView.image = nil
            imageView.contentMode = .scaleAspectFill
        }

        if let coverImage {
            coverImageView.kf.cancelDownloadTask()
            coverImageView.image = coverImage
            coverImageView.isHidden = false
        } else if
            let coverImageURLString = coverImageURLString,
            !coverImageURLString.isEmpty,
            let coverImageURL = URL(string: coverImageURLString) {
            coverImageView.kf.indicatorType = .activity
            coverImageView.kf.setImage(with: coverImageURL, options: [.transition(.fade(0.2))])
            coverImageView.isHidden = false
        } else {
            coverImageView.kf.cancelDownloadTask()
            coverImageView.image = nil
            coverImageView.isHidden = true
        }

        titleLabel.text = title
        titleLabel.isHidden = title?.isEmpty != false

        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle?.isEmpty != false

        ctaButton.setTitle(ctaTitle, for: .normal)

        let hasText = !titleLabel.isHidden || !subtitleLabel.isHidden
        overlayView.isHidden = !hasText
        textAndCTAStackView.isHidden = !hasText
        ctaButton.isHidden = !hasText
    }

    func reset() {
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        imageView.contentMode = .scaleAspectFill
        coverImageShadowView.transform = .identity
        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = nil
        coverImageView.isHidden = false
        titleLabel.text = nil
        subtitleLabel.text = nil
        overlayView.isHidden = false
        textAndCTAStackView.isHidden = false
        ctaButton.isHidden = false
    }
}

final class HeroCarouselCardCVC: UICollectionViewCell {

    private let cardView = HeroCarouselCardPreviewView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubviewForConstraints(cardView)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(with story: CDBookInternal) {
        guard let layout = story.heroCarouselLayout else {
            cardView.reset()
            return
        }
        let backgroundImageURL = story.heroBackgroundImageURL
        let backgroundImageURLXL = story.heroBackgroundImageURLXL
        let selectedImageURL = UIDevice().iPad ? backgroundImageURLXL : backgroundImageURL

        let coverImageURL = story.coverImageURL
        let title = story.heroTitle
        let subtitle = story.heroSubtitle

        cardView.configure(layout: layout,
                           image: nil,
                           imageURLString: selectedImageURL,
                           coverImage: nil,
                           coverImageURLString: coverImageURL,
                           title: title,
                           subtitle: subtitle)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cardView.reset()
    }
}
