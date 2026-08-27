//
//  RoadmapTVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 06/03/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

class RoadmapTVC: UITableViewCell {
    private let inactiveUpvoteColor = UIColor.dynamic(
        light: Colours.textSecondary.withAlphaComponent(0.5),
        dark: Colours.textSecondary.withAlphaComponent(0.5)
    )

    var roadmapItem: RoadmapItem? {
        didSet {
            guard let roadmapItem = roadmapItem else { return }
            titleLabel.text = roadmapItem.title
            descriptionLabel.text = roadmapItem.description
            updatePills()
            updateUpvoteElements()
        }
    }

    // Card container
    private let cardView = UIView()

    // Content stack
    private let contentStack = UIStackView()
    private let titleLabel = UILabel()
    private let pillsStack = UIStackView()
    private let typePill = PaddedLabel()
    private let statusPill = PaddedLabel()
    private let versionPill = PaddedLabel()
    private let descriptionLabel = UILabel()

    // Upvote
    private let upvoteContainerView = UIView()
    private let upvoteArrowImageView = UIImageView()
    private let upvoteCountLabel = UILabel()

    var tappedUpvoteHandler: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
        descriptionLabel.text = ""
        upvoteCountLabel.text = ""
        typePill.isHidden = true
        statusPill.isHidden = true
        versionPill.isHidden = true
        tappedUpvoteHandler = nil
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateAppearanceColors()
        updateUpvoteElements()
    }
}

// MARK: - UI Setup
private extension RoadmapTVC {
    func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        setupCard()
        setupUpvoteCard()
        setupLeftContent()
    }

    func setupCard() {
        cardView.backgroundColor = Colours.surfaceCard
        cardView.layer.cornerRadius = UIConstants.shared.cardCornerRadius
        cardView.layer.shadowColor = Colours.shadowBase.cgColor
        cardView.layer.shadowOpacity = 0.06
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4

        contentView.addSubviewForConstraints(cardView)
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }

    func setupUpvoteCard() {
        upvoteContainerView.layer.borderWidth = 1.5
        upvoteContainerView.layer.cornerRadius = 8
        upvoteContainerView.layer.borderColor = inactiveUpvoteColor.cgColor

        cardView.addSubviewForConstraints(upvoteContainerView)
        NSLayoutConstraint.activate([
            upvoteContainerView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            upvoteContainerView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            upvoteContainerView.widthAnchor.constraint(equalToConstant: 48),
            upvoteContainerView.heightAnchor.constraint(equalToConstant: 52)
        ])

        let upvoteImage = UIImage(named: "upvote.png")?.withRenderingMode(.alwaysTemplate)
        upvoteArrowImageView.image = upvoteImage
        upvoteArrowImageView.contentMode = .scaleAspectFit
        upvoteArrowImageView.tintColor = inactiveUpvoteColor

        upvoteContainerView.addSubviewForConstraints(upvoteArrowImageView)
        NSLayoutConstraint.activate([
            upvoteArrowImageView.topAnchor.constraint(equalTo: upvoteContainerView.topAnchor, constant: 8),
            upvoteArrowImageView.centerXAnchor.constraint(equalTo: upvoteContainerView.centerXAnchor),
            upvoteArrowImageView.widthAnchor.constraint(equalToConstant: 14),
            upvoteArrowImageView.heightAnchor.constraint(equalToConstant: 14)
        ])

        upvoteCountLabel.font = Fonts.semiBold13
        upvoteCountLabel.textAlignment = .center
        upvoteCountLabel.textColor = inactiveUpvoteColor

        upvoteContainerView.addSubviewForConstraints(upvoteCountLabel)
        NSLayoutConstraint.activate([
            upvoteCountLabel.topAnchor.constraint(equalTo: upvoteArrowImageView.bottomAnchor, constant: 2),
            upvoteCountLabel.centerXAnchor.constraint(equalTo: upvoteContainerView.centerXAnchor),
            upvoteCountLabel.leadingAnchor.constraint(equalTo: upvoteContainerView.leadingAnchor, constant: 2),
            upvoteCountLabel.trailingAnchor.constraint(equalTo: upvoteContainerView.trailingAnchor, constant: -2)
        ])

        upvoteContainerView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tappedUpvoteButton))
        upvoteContainerView.addGestureRecognizer(tap)
    }

    func setupLeftContent() {
        // Title
        titleLabel.textColor = Colours.textPrimary
        titleLabel.font = Fonts.semiBold15
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail

        // Pills
        configurePill(typePill)
        configurePill(statusPill)
        configurePill(versionPill)

        pillsStack.axis = .horizontal
        pillsStack.spacing = 6
        pillsStack.alignment = .center
        pillsStack.addArrangedSubview(typePill)
        pillsStack.addArrangedSubview(statusPill)
        pillsStack.addArrangedSubview(versionPill)

        // Description
        descriptionLabel.textColor = Colours.textSecondary
        descriptionLabel.font = Fonts.regular14
        descriptionLabel.numberOfLines = 1
        descriptionLabel.lineBreakMode = .byTruncatingTail

        // Stack
        contentStack.axis = .vertical
        contentStack.spacing = 4
        contentStack.alignment = .leading
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(pillsStack)
        contentStack.addArrangedSubview(descriptionLabel)

        cardView.addSubviewForConstraints(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: upvoteContainerView.leadingAnchor, constant: -12),
            contentStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12)
        ])
    }

    func configurePill(_ pill: PaddedLabel) {
        pill.font = Fonts.medium12
        pill.layer.cornerRadius = 4
        pill.layer.masksToBounds = true
        pill.topInset = 2
        pill.bottomInset = 2
        pill.leftInset = 6
        pill.rightInset = 6
        pill.isHidden = true
    }
}

// MARK: - Update Methods
extension RoadmapTVC {
    @objc private func tappedUpvoteButton() {
        tappedUpvoteHandler?()
    }

    func updateUpvoteElements() {
        guard let roadmapItem = roadmapItem else { return }
        let isUpvoted = RoadmapVotingUserDefaults.roadmapUpvotedUUIDs.contains(roadmapItem.uuid)
        let color = isUpvoted ? Colours.orangePrimary : inactiveUpvoteColor

        upvoteContainerView.layer.borderColor = color.cgColor
        upvoteArrowImageView.tintColor = color
        upvoteCountLabel.textColor = color
        upvoteCountLabel.text = "\(roadmapItem.upvoteCount)"
    }

    func updatePills() {
        guard let roadmapItem = roadmapItem else { return }

        // Type pill (always show unless uncategorized)
        if roadmapItem.itemType != .uncategorized {
            typePill.isHidden = false
            typePill.text = roadmapItem.itemType.displayString
            typePill.textColor = Colours.textSecondary
            typePill.backgroundColor = Colours.surfaceSecondary
        } else {
            typePill.isHidden = true
        }

        // Status pill (show for non-released items)
        if roadmapItem.status != .released {
            statusPill.isHidden = false
            statusPill.text = roadmapItem.status.displayString
            if roadmapItem.status == .requested {
                statusPill.textColor = Colours.textSecondary
                statusPill.backgroundColor = Colours.surfaceSecondary
            } else {
                statusPill.textColor = statusColor(for: roadmapItem.status)
                statusPill.backgroundColor = statusColor(for: roadmapItem.status).withAlphaComponent(0.1)
            }
            versionPill.isHidden = true
        } else {
            // Released: show version pill instead of status
            statusPill.isHidden = true
            if let version = roadmapItem.releaseVersion, !version.isEmpty {
                versionPill.isHidden = false
                versionPill.text = "v\(version)"
                versionPill.textColor = Colours.orangePrimary
                versionPill.backgroundColor = Colours.orangePrimary.withAlphaComponent(0.1)
            } else {
                versionPill.isHidden = true
            }
        }
    }

    private func statusColor(for status: RoadmapItemStatus) -> UIColor {
        switch status {
        case .requested:
            return Colours.textSecondary
        case .planned:
            return UIColor.systemBlue
        case .inProgress:
            return UIColor.systemOrange
        case .released:
            return Colours.orangePrimary
        case .declined:
            return UIColor.systemRed
        }
    }

    private func updateAppearanceColors() {
        cardView.backgroundColor = Colours.surfaceCard
        cardView.layer.shadowColor = Colours.shadowBase.cgColor
    }
}
