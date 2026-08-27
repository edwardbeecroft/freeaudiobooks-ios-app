//
//  BookPickCell.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 28/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import Kingfisher

/// Collection view cell displaying a book cover and title
/// Used in PersonalizedPicksVC to show personalized book recommendations
class BookPickCell: UICollectionViewCell {

    static let reuseIdentifier = "BookPickCell"

    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = Colours.surfaceSecondary
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.medium13
        label.textColor = Colours.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubviewForConstraints(coverImageView)
        contentView.addSubviewForConstraints(titleLabel)

        NSLayoutConstraint.activate([
            coverImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            coverImageView.heightAnchor.constraint(equalTo: coverImageView.widthAnchor, multiplier: 1.5),

            titleLabel.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    func configure(with book: CDBookInternal) {
        titleLabel.text = book.title

        if let urlString = book.coverImageURL, let url = URL(string: urlString) {
            coverImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = nil
        titleLabel.text = nil
    }
}
