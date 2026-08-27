//
//  ViewAllCVC.swift
//  FreeAudiobooks
//
//  Created by Claude on 07/12/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

extension ViewAllCVC {
    struct Layout {
        static let containerTopBottomPadding: CGFloat = 8
        static let height: CGFloat = UIConstants.shared.coverImageHeight
        static let width: CGFloat = 120
        static let spacing: CGFloat = 8
        static let chevronSize: CGFloat = 20

        // Match the card height from ShortStoryCVC for consistency
        static var cardHeight: CGFloat {
            return ShortStoryCVC.Layout.cardHeight
        }
    }
}

class ViewAllCVC: UICollectionViewCell {

    // MARK: - UI Elements

    private let containerView = UIView()
    private let contentStackView = UIStackView()
    private let viewAllLabel = UILabel()
    private let chevronImageView = UIImageView()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .clear

        setupContainerView()
        setupStackView()
        setupViewAllLabel()
        setupChevronImageView()
        setupConstraints()
    }

    private func setupContainerView() {
        containerView.backgroundColor = UIColor.systemGray6
        containerView.layer.cornerRadius = UIConstants.shared.bookCoverCornerRadius
        containerView.layer.masksToBounds = true

        contentView.addSubviewForConstraints(containerView)
    }

    private func setupStackView() {
        contentStackView.axis = .vertical
        contentStackView.alignment = .center
        contentStackView.distribution = .fill
        contentStackView.spacing = Layout.spacing

        containerView.addSubviewForConstraints(contentStackView)
    }

    private func setupViewAllLabel() {
        viewAllLabel.text = "View all"
        viewAllLabel.font = Fonts.semiBold15
        viewAllLabel.textColor = Colours.textPrimary
        viewAllLabel.textAlignment = .center
        viewAllLabel.numberOfLines = 1

        contentStackView.addArrangedSubview(viewAllLabel)
    }

    private func setupChevronImageView() {
        chevronImageView.image = UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate)
        chevronImageView.tintColor = Colours.textPrimary
        chevronImageView.contentMode = .scaleAspectFit

        contentStackView.addArrangedSubview(chevronImageView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view fills the cell
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Layout.containerTopBottomPadding),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Stack view centered in container
            contentStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            contentStackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            contentStackView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 12),
            contentStackView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -12),

            // Chevron size
            chevronImageView.widthAnchor.constraint(equalToConstant: Layout.chevronSize),
            chevronImageView.heightAnchor.constraint(equalToConstant: Layout.chevronSize)
        ])
    }

    // MARK: - Configuration

    func configure() {
        // No dynamic configuration needed - static "View all" cell
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        // Nothing to reset for this static cell
    }
}
