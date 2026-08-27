//
//  ContinueReadingPlaceholderCVC.swift
//  FreeAudiobooks
//
//  Created by Codex on 20/02/2026.
//

import UIKit

final class ContinueReadingPlaceholderCVC: UICollectionViewCell {
    var tappedBrowseStoriesHandler: (() -> Void)?

    private let containerView = UIView()
    private let messageLabel = UILabel()
    private let browseButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        containerView.backgroundColor = Colours.surfaceCard
        containerView.layer.cornerRadius = UIConstants.shared.cardCornerRadius

        messageLabel.text = "Stories you're listening to\nwill appear here"
        messageLabel.font = Fonts.medium15
        messageLabel.textColor = Colours.textSecondary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 2

        browseButton.setTitle("Browse Stories", for: .normal)
        browseButton.setTitleColor(Colours.ctaForeground, for: .normal)
        browseButton.titleLabel?.font = Fonts.semiBold14
        browseButton.titleLabel?.lineBreakMode = .byTruncatingTail
        browseButton.backgroundColor = Colours.ctaBackground
        browseButton.layer.cornerRadius = 19
        browseButton.layer.masksToBounds = true
        browseButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        browseButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        browseButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        browseButton.addTarget(self, action: #selector(browseTapped), for: .touchUpInside)

        let searchImageConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        let searchImage = UIImage(systemName: "magnifyingglass", withConfiguration: searchImageConfig)
        browseButton.setImage(searchImage, for: .normal)
        browseButton.tintColor = Colours.ctaForeground
        browseButton.semanticContentAttribute = .forceLeftToRight
        browseButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)

        contentView.addSubviewForConstraints(containerView)
        containerView.addSubviewForConstraints(messageLabel)
        containerView.addSubviewForConstraints(browseButton)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ContinueReadingCarouselTVC.Layout.cellHorizontalPadding),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ContinueReadingCarouselTVC.Layout.cellHorizontalPadding),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            messageLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -22),
            messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16),

            browseButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16),
            browseButton.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 12),
            browseButton.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -12),
            browseButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            browseButton.heightAnchor.constraint(equalToConstant: 38),
            browseButton.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -18)
        ])
    }

    @objc private func browseTapped() {
        tappedBrowseStoriesHandler?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        tappedBrowseStoriesHandler = nil
    }
}
