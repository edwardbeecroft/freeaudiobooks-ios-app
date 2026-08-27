//
//  AccountProfileViewLoggedIn.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 24/06/2024.
//  Copyright © 2024 Radically Better. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class AccountProfileViewLoggedIn: BaseFormView {
    
    var imageTapHandler: (() -> Void)?
    
    private var loadingIndicatorView: NVActivityIndicatorView?
    
    private let userImageView = UserProfileImageView(venue: .profileVC)
    private let introLabel = UILabel()
    private let plusLabel = UILabel()
    private let memberSinceLabel = UILabel()
    private let labelsStackView = UIStackView()
    
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateAppearanceColors() {
        super.updateAppearanceColors()
        // Match the account form/card surfaces so the top profile container remains visibly grouped.
        backgroundColor = Colours.surfaceCard
    }
    
    func setupUI() {
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(didTapImage))
        userImageView.isUserInteractionEnabled = true
        userImageView.addGestureRecognizer(imageTap)

        introLabel.font = Fonts.semiBold17
        introLabel.textColor = Colours.textPrimary
        introLabel.numberOfLines = 0
        introLabel.lineBreakMode = .byWordWrapping
        introLabel.textAlignment = .left

        plusLabel.numberOfLines = 0
        plusLabel.lineBreakMode = .byWordWrapping
        plusLabel.font = Fonts.semiBold17
        plusLabel.textColor = Colours.orangePrimary
        plusLabel.textAlignment = .left
        plusLabel.text = "Audiobooks+"
        
        memberSinceLabel.font = Fonts.medium15
        memberSinceLabel.lineBreakMode = .byTruncatingTail
        memberSinceLabel.numberOfLines = 0
        memberSinceLabel.textColor = Colours.subtext
        memberSinceLabel.textAlignment = .left

        labelsStackView.axis = .vertical
        labelsStackView.spacing = 2
        labelsStackView.alignment = .leading
        labelsStackView.distribution = .fill

        labelsStackView.addArrangedSubview(introLabel)
        labelsStackView.addArrangedSubview(plusLabel)
        labelsStackView.addArrangedSubview(memberSinceLabel)

        addSubviewForConstraints(labelsStackView)
        addSubviewForConstraints(userImageView)

        NSLayoutConstraint.activate([
            userImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            userImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UIConstants.shared.standardMargin),

            labelsStackView.topAnchor.constraint(equalTo: topAnchor, constant: UIConstants.shared.standardMargin),
            labelsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UIConstants.shared.standardMargin),
            labelsStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UIConstants.shared.standardMargin),
        ])
    }
}

extension AccountProfileViewLoggedIn {
    func refreshData() {
        introLabel.text = AccountManager.shared.user?.fullName() ?? "Welcome to FreeAudiobooks"
        
        userImageView.update()

        if
            case .production = AppConstants.shared.developmentMode,
            AccountManager.shared.userIsSubscribed {
            plusLabel.isHidden = false
        } else {
            plusLabel.isHidden = true
        }
        
        guard let user = AccountManager.shared.user else { return }
        
        memberSinceLabel.text = "Joined \(user.memberSinceYear ?? 2024)"
    }
}

extension AccountProfileViewLoggedIn {
    func showImageLoadingIndicator(show: Bool) {
        userImageView.showImageLoadingIndicator(show: show)
    }
}

extension AccountProfileViewLoggedIn {
    @objc private func didTapImage() {
        imageTapHandler?()
    }
}
