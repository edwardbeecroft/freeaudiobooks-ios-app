//
//  RoadmapItemDetailVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 06/03/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

final class RoadmapItemDetailVC: BottomSheetController {

    var dismissHandler: (() -> Void)?
    var upvoteHandler: (() -> Void)?

    private let roadmapItem: RoadmapItem

    // Upvote UI
    private let upvoteContainerView = UIView()
    private let upvoteArrowImageView = UIImageView()
    private let upvoteCountLabel = UILabel()

    // Content
    private let titleLabel = UILabel()
    private let pillsStack = UIStackView()
    private let typePill = PaddedLabel()
    private let statusPill = PaddedLabel()
    private let descriptionLabel = UILabel()

    // Dismiss
    private lazy var dismissButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = Colours.textSecondary
        button.backgroundColor = Colours.surfaceSecondary
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        return button
    }()

    init(roadmapItem: RoadmapItem) {
        self.roadmapItem = roadmapItem
        super.init(nibName: nil, bundle: nil)
        createView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateAppearanceColors()
        updatePills()
        updateUpvoteUI()
    }

    func createView() {
        view = UIView()
        view.backgroundColor = Colours.surfacePrimary

        setupDismissButton()
        setupUpvoteUI()
        setupContent()
        setupLayout()
        populateData()
        updateAppearanceColors()
    }
}

// MARK: - Setup
private extension RoadmapItemDetailVC {
    func setupUpvoteUI() {
        upvoteContainerView.layer.borderWidth = 1.5
        upvoteContainerView.layer.cornerRadius = 8
        upvoteContainerView.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(upvoteTapped))
        upvoteContainerView.addGestureRecognizer(tap)

        let upvoteImage = UIImage(named: "upvote.png")?.withRenderingMode(.alwaysTemplate)
        upvoteArrowImageView.image = upvoteImage
        upvoteArrowImageView.contentMode = .scaleAspectFit

        upvoteCountLabel.font = Fonts.semiBold16
        upvoteCountLabel.textAlignment = .center

        upvoteContainerView.addSubviewForConstraints(upvoteArrowImageView)
        upvoteContainerView.addSubviewForConstraints(upvoteCountLabel)
    }

    func setupContent() {
        titleLabel.font = Fonts.semiBold18
        titleLabel.textColor = Colours.textPrimary
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center

        // Pills
        configurePill(typePill)
        configurePill(statusPill)

        pillsStack.axis = .horizontal
        pillsStack.spacing = 6
        pillsStack.alignment = .center
        pillsStack.addArrangedSubview(typePill)
        pillsStack.addArrangedSubview(statusPill)

        descriptionLabel.font = Fonts.regular15
        descriptionLabel.textColor = Colours.textSecondary
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
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

    func setupDismissButton() {
        // Configured in lazy var
    }

    func setupLayout() {
        view.addSubviewForConstraints(dismissButton)
        view.addSubviewForConstraints(upvoteContainerView)
        view.addSubviewForConstraints(titleLabel)
        view.addSubviewForConstraints(pillsStack)
        view.addSubviewForConstraints(descriptionLabel)

        NSLayoutConstraint.activate([
            // Dismiss button (top-right)
            dismissButton.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 16),
            dismissButton.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -UIConstants.shared.standardMargin),
            dismissButton.widthAnchor.constraint(equalToConstant: 32),
            dismissButton.heightAnchor.constraint(equalToConstant: 32),

            // Upvote container (centered at top)
            upvoteContainerView.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 20),
            upvoteContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            upvoteContainerView.widthAnchor.constraint(equalToConstant: 60),
            upvoteContainerView.heightAnchor.constraint(equalToConstant: 64),

            upvoteArrowImageView.topAnchor.constraint(equalTo: upvoteContainerView.topAnchor, constant: 10),
            upvoteArrowImageView.centerXAnchor.constraint(equalTo: upvoteContainerView.centerXAnchor),
            upvoteArrowImageView.widthAnchor.constraint(equalToConstant: 18),
            upvoteArrowImageView.heightAnchor.constraint(equalToConstant: 18),

            upvoteCountLabel.topAnchor.constraint(equalTo: upvoteArrowImageView.bottomAnchor, constant: 4),
            upvoteCountLabel.centerXAnchor.constraint(equalTo: upvoteContainerView.centerXAnchor),
            upvoteCountLabel.leadingAnchor.constraint(equalTo: upvoteContainerView.leadingAnchor, constant: 4),
            upvoteCountLabel.trailingAnchor.constraint(equalTo: upvoteContainerView.trailingAnchor, constant: -4),

            // Title
            titleLabel.topAnchor.constraint(equalTo: upvoteContainerView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: UIConstants.shared.standardMargin),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -UIConstants.shared.standardMargin),

            // Pills
            pillsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            pillsStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Description
            descriptionLabel.topAnchor.constraint(equalTo: pillsStack.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: UIConstants.shared.standardMargin),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -UIConstants.shared.standardMargin),
            descriptionLabel.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -24)
        ])
    }

    func populateData() {
        titleLabel.text = roadmapItem.title
        descriptionLabel.text = roadmapItem.description
        updateUpvoteUI()
        updatePills()
    }

    func updateUpvoteUI() {
        let isUpvoted = RoadmapVotingUserDefaults.roadmapUpvotedUUIDs.contains(roadmapItem.uuid)
        let color = isUpvoted ? Colours.orangePrimary : Colours.textSecondary.withAlphaComponent(0.5)

        upvoteContainerView.layer.borderColor = color.cgColor
        upvoteArrowImageView.tintColor = color
        upvoteCountLabel.textColor = color
        upvoteCountLabel.text = "\(roadmapItem.upvoteCount)"
    }

    func updatePills() {
        // Type pill
        if roadmapItem.itemType != .uncategorized {
            typePill.isHidden = false
            typePill.text = roadmapItem.itemType.displayString
            typePill.textColor = Colours.textSecondary
            typePill.backgroundColor = Colours.surfaceSecondary
        } else {
            typePill.isHidden = true
        }

        // Status pill
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
        } else {
            // Show version for released items
            if let version = roadmapItem.releaseVersion, !version.isEmpty {
                statusPill.isHidden = false
                statusPill.text = "v\(version)"
                statusPill.textColor = Colours.orangePrimary
                statusPill.backgroundColor = Colours.orangePrimary.withAlphaComponent(0.1)
            } else {
                statusPill.isHidden = true
            }
        }
    }

    func statusColor(for status: RoadmapItemStatus) -> UIColor {
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
}

private extension RoadmapItemDetailVC {
    func updateAppearanceColors() {
        dismissButton.layer.borderColor = Colours.inputBorder.cgColor
    }
}

// MARK: - Actions
extension RoadmapItemDetailVC {
    @objc func upvoteTapped() {
        upvoteHandler?()
        updateUpvoteUI()

        HapticFeedbackHelper.shared.prepareLightFeedbackGenerator()
        HapticFeedbackHelper.shared.triggerLightImpactFeedback()
    }

    @objc func dismissTapped() {
        dismissHandler?()
    }
}
