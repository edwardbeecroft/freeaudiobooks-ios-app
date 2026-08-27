//
//  EarlyAccessSearchUpsellTVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 12/07/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import Kingfisher

extension EarlyAccessSearchUpsellTVC {
    struct Layout {
        static let bottomWhiteMargin: CGFloat = 16
        static let topMargin: CGFloat = 18
        static let horizontalInset: CGFloat = UIConstants.shared.standardMargin
        static let titleToSubtitleSpacing: CGFloat = 4
        static let subtitleToCollectionSpacing: CGFloat = 10
        static let collectionToCTASpacing: CGFloat = 12
        static let coverHeight: CGFloat = 90
        static let bottomMargin: CGFloat = 16
        static let buttonHeight: CGFloat = 32

        static var collectionHeight: CGFloat {
            return coverHeight
        }
    }
}

class EarlyAccessSearchUpsellTVC: UITableViewCell {

    // MARK: - Properties

    private var earlyAccessBooks: [CDBookInternal] = []
    private var bookCount: Int = 0

    // MARK: - UI Elements

    private let bottomMarginView = UIView()
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let chevronButton = UIButton(type: .system)
    private let subtitleLabel = UILabel()
    private let collectionView: UICollectionView
    private let unlockButton = Buttons.gradientButton(buttonTitle: nil, cornerRadius: 16)

    var tappedUnlockHandler: (() -> Void)?
    var tappedChevronHandler: (() -> Void)?

    private var neutralAccentTextColor: UIColor {
        UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
    }

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8
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
        contentView.backgroundColor = Colours.surfacePrimary
        selectionStyle = .none

        setupBottomMarginView()
        setupContainerView()
        setupTitleLabel()
        setupChevronButton()
        setupSubtitleLabel()
        setupCollectionView()
        setupUnlockButton()
        setupConstraints()
    }

    private func setupBottomMarginView() {
        bottomMarginView.backgroundColor = Colours.surfacePrimary
        contentView.addSubviewForConstraints(bottomMarginView)
    }

    private func setupContainerView() {
        containerView.backgroundColor = Colours.surfaceCard
        containerView.layer.cornerRadius = 0
        contentView.addSubviewForConstraints(containerView)
    }

    private func setupTitleLabel() {
        titleLabel.font = Fonts.semiBold16
        titleLabel.textColor = neutralAccentTextColor
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.backgroundColor = .clear
        titleLabel.isUserInteractionEnabled = true

        let titleTapGesture = UITapGestureRecognizer(target: self, action: #selector(chevronTapped))
        titleLabel.addGestureRecognizer(titleTapGesture)

        containerView.addSubviewForConstraints(titleLabel)
    }

    private func setupChevronButton() {
        let chevronImage = UIImage(named: "chevron-right.png")?.withRenderingMode(.alwaysTemplate)
        chevronButton.setImage(chevronImage, for: .normal)
        chevronButton.tintColor = neutralAccentTextColor

        let insets: CGFloat = 6
        chevronButton.imageEdgeInsets = UIEdgeInsets(top: insets, left: insets, bottom: insets, right: insets)

        chevronButton.addTarget(self, action: #selector(chevronTapped), for: .touchUpInside)

        containerView.addSubviewForConstraints(chevronButton)
    }

    @objc private func chevronTapped() {
        tappedChevronHandler?()
    }

    private func setupSubtitleLabel() {
        subtitleLabel.font = Fonts.medium15
        subtitleLabel.textColor = Colours.textSecondary
        subtitleLabel.numberOfLines = 1
        subtitleLabel.text = "Unlock early access, unlimited listening & no ads"
        subtitleLabel.backgroundColor = .clear

        containerView.addSubviewForConstraints(subtitleLabel)
    }

    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(EarlyAccessCoverCell.self, forCellWithReuseIdentifier: "EarlyAccessCoverCell")

        containerView.addSubviewForConstraints(collectionView)
    }

    private func setupUnlockButton() {
        unlockButton.titleLabel?.font = Fonts.semiBold14
        unlockButton.setTitleColor(.white, for: .normal)
        unlockButton.setTitle("Start 7-Day Free Access", for: .normal)
        unlockButton.layer.cornerRadius = 16
        unlockButton.clipsToBounds = true

        // Add icon
        let arrowIcon = UIImage(systemName: "arrow.right.circle.fill")?.withRenderingMode(.alwaysTemplate)
        unlockButton.setImage(arrowIcon, for: .normal)
        unlockButton.tintColor = .white
        unlockButton.semanticContentAttribute = .forceRightToLeft
        unlockButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 10)
        unlockButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: -6)

        unlockButton.addTarget(self, action: #selector(unlockButtonTapped), for: .touchUpInside)

        containerView.addSubviewForConstraints(unlockButton)
    }

    @objc private func unlockButtonTapped() {
        tappedUnlockHandler?()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Bottom margin view - white space below card
            bottomMarginView.topAnchor.constraint(equalTo: containerView.bottomAnchor),
            bottomMarginView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomMarginView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomMarginView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bottomMarginView.heightAnchor.constraint(equalToConstant: Layout.bottomWhiteMargin),

            // Title label
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Layout.topMargin),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Layout.horizontalInset),

            // Chevron button (to the right of title)
            chevronButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor, constant: 1),
            chevronButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: -2),
            chevronButton.widthAnchor.constraint(equalToConstant: 20),
            chevronButton.heightAnchor.constraint(equalToConstant: 20),

            // Subtitle label
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Layout.titleToSubtitleSpacing),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Layout.horizontalInset),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Layout.horizontalInset),

            // Collection view
            collectionView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: Layout.subtitleToCollectionSpacing),
            collectionView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: Layout.collectionHeight),

            // Unlock button - below collection view, aligned to leading edge
            unlockButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: Layout.collectionToCTASpacing),
            unlockButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Layout.horizontalInset),
            unlockButton.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -Layout.horizontalInset),
            unlockButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight),

            // Bottom constraint
            containerView.bottomAnchor.constraint(equalTo: unlockButton.bottomAnchor, constant: Layout.bottomMargin)
        ])
    }

    // MARK: - Configuration

    func configure(with books: [CDBookInternal], totalCount: Int) {
        self.earlyAccessBooks = books
        self.bookCount = totalCount

        // Set title with same formatting as ShortStoryEarlyAccessCarouselTVC
        let titleText = "Audiobooks+ Early Access"
        if titleText.contains("Audiobooks+") {
            let attributedString = NSMutableAttributedString(string: titleText)

            // Set default color for entire string
            attributedString.addAttribute(.foregroundColor,
                                         value: neutralAccentTextColor,
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
            titleLabel.textColor = neutralAccentTextColor
            titleLabel.text = titleText
        }

        collectionView.reloadData()
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        earlyAccessBooks.removeAll()
        bookCount = 0
        titleLabel.text = nil
        titleLabel.attributedText = nil
    }
}

// MARK: - UICollectionViewDataSource

extension EarlyAccessSearchUpsellTVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return earlyAccessBooks.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EarlyAccessCoverCell", for: indexPath) as! EarlyAccessCoverCell
        let book = earlyAccessBooks[indexPath.item]
        cell.configure(with: book)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        tappedUnlockHandler?()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension EarlyAccessSearchUpsellTVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = Layout.coverHeight * UIConstants.shared.bookInternalCoverImageWidthToHeightRatio
        return CGSize(width: width, height: Layout.coverHeight)
    }
}

// MARK: - Early Access Cover Cell

class EarlyAccessCoverCell: UICollectionViewCell {

    private let coverImageView = UIImageView()
    private let adultContentBadge = AdultContentBadge()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.layer.cornerRadius = UIConstants.shared.bookCoverCornerRadiusSmall
        coverImageView.backgroundColor = Colours.backgroundGrey

        contentView.addSubviewForConstraints(coverImageView)

        // Setup adult content badge
        adultContentBadge.isHidden = true
        coverImageView.addSubviewForConstraints(adultContentBadge)

        NSLayoutConstraint.activate([
            coverImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            coverImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Adult content badge (top-left corner)
            adultContentBadge.topAnchor.constraint(equalTo: coverImageView.topAnchor, constant: 6),
            adultContentBadge.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor, constant: 6),
            adultContentBadge.widthAnchor.constraint(equalToConstant: 36),
            adultContentBadge.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    func configure(with book: CDBookInternal) {
        if
            let coverImageURLThumbnail = book.coverImageURLThumbnail,
            let imageURL = URL(string: coverImageURLThumbnail) {
            coverImageView.kf.indicatorType = .activity
            coverImageView.kf.setImage(
                with: imageURL,
                placeholder: nil,
                options: [.transition(.fade(0.2))]
            )
        } else {
            // Set placeholder image
            coverImageView.image = UIImage(systemName: "book.fill")?
                .withRenderingMode(.alwaysTemplate)
            coverImageView.tintColor = Colours.textSecondary.withAlphaComponent(0.5)
        }

        // Update adult content badge visibility
        adultContentBadge.isHidden = !book.shouldShowAdultContentBadgeOnCovers
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = nil
        adultContentBadge.isHidden = true
    }
}
