//
//  PaywallDetailedBulletView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 13/08/2025.
//  Copyright © 2025 Radically Better. All rights reserved.
//

import UIKit

class PaywallDetailedBulletView: UIView {
    
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let containerView = UIView()
    
    let bullet: Bullet
    init(bullet: Bullet) {
        self.bullet = bullet
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        containerView.backgroundColor = Colours.surfaceCard
        containerView.layer.borderColor = Colours.inputBorder.cgColor
    }
}

extension PaywallDetailedBulletView {
    func setupUI() {
        containerView.layer.cornerRadius = UIConstants.shared.cardCornerRadius
        containerView.layer.masksToBounds = true
        containerView.layer.borderColor = Colours.inputBorder.cgColor
        containerView.layer.borderWidth = 1
        
        containerView.backgroundColor = Colours.surfaceCard
        addSubviewForConstraints(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        let bulletImageView = UIImageView()
        
        let imageSize: CGFloat = 26
        bulletImageView.image = bullet.image
        
        bulletImageView.contentMode = .scaleAspectFit
        containerView.addSubviewForConstraints(bulletImageView)
        
        NSLayoutConstraint.activate([
            bulletImageView.widthAnchor.constraint(equalToConstant: imageSize),
            bulletImageView.heightAnchor.constraint(equalToConstant: imageSize),
            bulletImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            bulletImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        titleLabel.font = Fonts.medium15
        titleLabel.textColor = Colours.textPrimary
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.textAlignment = .left
        titleLabel.text = bullet.title
        
        let padding: CGFloat = 14
        
        containerView.addSubviewForConstraints(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: padding),
            titleLabel.leadingAnchor.constraint(equalTo: bulletImageView.trailingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
        ])
        
        subtitleLabel.font = Fonts.medium15
        subtitleLabel.textColor = Colours.textSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.textAlignment = .left
        subtitleLabel.text = bullet.subtitle
        
        containerView.addSubviewForConstraints(subtitleLabel)
        NSLayoutConstraint.activate([
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -padding)
        ])
    }
}
