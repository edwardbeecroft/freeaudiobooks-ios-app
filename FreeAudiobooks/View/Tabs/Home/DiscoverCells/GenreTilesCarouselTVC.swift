//
//  GenreTilesCarouselTVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 22/03/2026.
//  Copyright © 2026 Kneady Technologies. All rights reserved.
//

import UIKit

extension GenreTilesCarouselTVC {
    struct Layout {
        static let topMargin: CGFloat = 22
        static let estimatedTitleHeight: CGFloat = 24
        static let titleToCollectionSpacing: CGFloat = 8
        static let collectionHeight: CGFloat = 110
        static let bottomMargin: CGFloat = 16

        static var totalHeight: CGFloat {
            return topMargin + estimatedTitleHeight + titleToCollectionSpacing + collectionHeight + bottomMargin
        }
    }
}

class GenreTilesCarouselTVC: UITableViewCell {

    // MARK: - Properties

    private var presentations: [GenreCardPresentation] = []

    // MARK: - UI Elements

    private let titleLabel = UILabel()
    private let collectionView: UICollectionView

    var tappedGenreHandler: ((BookInternalGenre) -> Void)?

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
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

        setupTitleLabel()
        setupCollectionView()
        setupConstraints()
    }

    private func setupTitleLabel() {
        titleLabel.font = UIConstants.shared.carouselTitleFont
        titleLabel.textColor = UIConstants.shared.carouselTitleTextColour
        titleLabel.numberOfLines = 1
        titleLabel.backgroundColor = .clear

        contentView.addSubviewForConstraints(titleLabel)
    }

    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(GenreTileCVC.self, forCellWithReuseIdentifier: GenreTileCVC.reuseIdentifier)

        contentView.addSubviewForConstraints(collectionView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title label
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Layout.topMargin),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),

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

    func configure(with section: DiscoverSection, presentations: [GenreCardPresentation]) {
        titleLabel.text = section.title
        self.presentations = presentations
        collectionView.reloadData()
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        presentations.removeAll()
        titleLabel.text = nil
        setContentOffset(.zero)
    }
}

// MARK: - UICollectionViewDataSource

extension GenreTilesCarouselTVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return presentations.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GenreTileCVC.reuseIdentifier, for: indexPath) as! GenreTileCVC
        let presentation = presentations[indexPath.item]
        cell.configure(with: presentation, isSelected: false)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension GenreTilesCarouselTVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let genre = presentations[indexPath.item].genre
        tappedGenreHandler?(genre)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension GenreTilesCarouselTVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemHeight = max(96, collectionView.bounds.height)
        let itemWidth: CGFloat = 176
        return CGSize(width: itemWidth, height: itemHeight)
    }
}
