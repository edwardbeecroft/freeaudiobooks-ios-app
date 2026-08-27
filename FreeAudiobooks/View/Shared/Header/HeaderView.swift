//
//  HeaderView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 03/08/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import UIKit

class HeaderView: UIView {
    private let pageTitleLabel = UILabel()

    let upgradeChipView = TryPlusChipView()
    private let listeningQuotaPillView = ListeningQuotaPillView()
    private let userImageView = UserProfileImageView(venue: .dashboardHeader)

    var upgradeTappedHandler: (() -> Void)?
    var imageViewTappedHandler: (() -> Void)?
    var listeningQuotaTappedHandler: (() -> Void)?

    private let alwaysHideUpsell: Bool
    private let showBottomBorder: Bool
    private let showsListeningQuotaPill: Bool

    init(
        titleText: String,
        alwaysHideUpsell: Bool,
        showBottomBorder: Bool = true,
        showsListeningQuotaPill: Bool = false
    ) {
        self.alwaysHideUpsell = alwaysHideUpsell
        self.showBottomBorder = showBottomBorder
        self.showsListeningQuotaPill = showsListeningQuotaPill
        super.init(frame: .zero)

        isUserInteractionEnabled = true

        pageTitleLabel.text = titleText
        setupView()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleQuotaRefresh),
            name: .listeningQuotaDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleQuotaRefresh),
            name: .didUpdateSubscriberStatus,
            object: nil
        )

        update()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

private extension HeaderView {
    func setupView() {
        backgroundColor = Colours.chromeBackground
        setupTitleLabel()
        setupUserImageView()
        setupListeningQuotaPillView()
        if showBottomBorder {
            setupBottomBorderView()
        }
    }

    func setupTitleLabel() {
        pageTitleLabel.textColor = Colours.textPrimary
        pageTitleLabel.numberOfLines = 0
        pageTitleLabel.lineBreakMode = .byWordWrapping
        pageTitleLabel.font = Fonts.bold24
        pageTitleLabel.textAlignment = .left

        addSubviewForConstraints(pageTitleLabel)
        NSLayoutConstraint.activate([
            pageTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            pageTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UIConstants.shared.standardMargin),
            pageTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UIConstants.shared.standardMargin),
            pageTitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    func setupUserImageView() {
        addSubviewForConstraints(userImageView)
        NSLayoutConstraint.activate([
            userImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            userImageView.rightAnchor.constraint(equalTo: rightAnchor, constant: -UIConstants.shared.standardMargin)
        ])

        userImageView.isUserInteractionEnabled = true
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        userImageView.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc func profileImageTapped() {
        imageViewTappedHandler?()
    }

    func setupListeningQuotaPillView() {
        guard showsListeningQuotaPill else { return }

        addSubviewForConstraints(listeningQuotaPillView)
        NSLayoutConstraint.activate([
            listeningQuotaPillView.centerYAnchor.constraint(equalTo: centerYAnchor),
            listeningQuotaPillView.trailingAnchor.constraint(equalTo: userImageView.leadingAnchor, constant: -12)
        ])

        listeningQuotaPillView.addTarget(self, action: #selector(listeningQuotaTapped), for: .touchUpInside)
    }

    @objc func listeningQuotaTapped() {
        listeningQuotaTappedHandler?()
    }

    @objc func handleQuotaRefresh() {
        update()
    }
    
    func setupUpgradeView() {
        addSubviewForConstraints(upgradeChipView)
        NSLayoutConstraint.activate([
            upgradeChipView.centerYAnchor.constraint(equalTo: centerYAnchor),
            upgradeChipView.trailingAnchor.constraint(equalTo: userImageView.leadingAnchor, constant: -12)
        ])

        upgradeChipView.tappedHandler = { [weak self] in
            self?.upgradeTappedHandler?()
        }
        
        upgradeChipView.isHidden = AccountManager.shared.userIsSubscribed || alwaysHideUpsell
    }
    
    func setupBottomBorderView() {
        let border = UIView()
        border.backgroundColor = Colours.separator
        addSubviewForConstraints(border)
        NSLayoutConstraint.activate([
            border.leadingAnchor.constraint(equalTo: leadingAnchor),
            border.trailingAnchor.constraint(equalTo: trailingAnchor),
            border.bottomAnchor.constraint(equalTo: bottomAnchor),
            border.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
}

extension HeaderView {
    func update() {
        userImageView.update()

        upgradeChipView.isHidden = AccountManager.shared.userIsSubscribed || alwaysHideUpsell

        let shouldShowListeningQuota = showsListeningQuotaPill && ListeningQuotaManager.shared.isEnabledForCurrentUser
        listeningQuotaPillView.isHidden = !shouldShowListeningQuota
        if shouldShowListeningQuota {
            listeningQuotaPillView.configure(
                remaining: ListeningQuotaManager.shared.remaining,
                limit: ListeningQuotaManager.shared.weeklyLimit
            )
        }
    }
    
    func showImageLoadingIndicator(show: Bool) {
        userImageView.showImageLoadingIndicator(show: show)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        pageTitleLabel.textColor = Colours.textPrimary
    }
}
