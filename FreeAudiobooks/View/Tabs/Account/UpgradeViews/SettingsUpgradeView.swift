//
//  SettingsUpgradeView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 24/06/2024.
//  Copyright © 2024 Radically Better. All rights reserved.
//

import UIKit

class SettingsUpgradeView: BaseFormView {
    
    var upgradeTappedHandler: (() -> Void)?
    
    private let freebooksLabel = UILabel()
    
    private let upgradeIntroLabel = UILabel()
    private let sellingPointsView = PaywallSellingPointsView(venue: .settings)
    private let upgradeButton = Buttons.gradientButton(buttonTitle: "Start 7-Day Free Access")

    private var upsellPanelBackgroundColor: UIColor {
        Colours.surfaceCard
    }
    
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        backgroundColor = upsellPanelBackgroundColor
        layer.borderColor = Colours.orangePrimary.withAlphaComponent(0.15).cgColor
    }

    func setupUI() {
        backgroundColor = upsellPanelBackgroundColor
        layer.borderColor = Colours.orangePrimary.withAlphaComponent(0.15).cgColor
        layer.borderWidth = 1
        
        freebooksLabel.numberOfLines = 0
        freebooksLabel.lineBreakMode = .byWordWrapping
        freebooksLabel.font = Fonts.semiBold21
        freebooksLabel.textColor = Colours.textPrimary
        freebooksLabel.textAlignment = .center

        addSubviewForConstraints(freebooksLabel)
        
        freebooksLabel.attributedText = attributedUpgradeTitle()

        upgradeIntroLabel.font = Fonts.medium16
        upgradeIntroLabel.textColor = Colours.textPrimary
        upgradeIntroLabel.lineBreakMode = .byTruncatingTail
        upgradeIntroLabel.numberOfLines = 0
        upgradeIntroLabel.textAlignment = .center
        upgradeIntroLabel.text = "Listen without limits."
        
        upgradeButton.addTarget(self, action: #selector(tappedUpgrade), for: .touchUpInside)
        
        addSubviewForConstraints(upgradeIntroLabel)
        addSubviewForConstraints(sellingPointsView)
        addSubviewForConstraints(upgradeButton)
        
        NSLayoutConstraint.activate([
            freebooksLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            freebooksLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            freebooksLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            
            upgradeIntroLabel.topAnchor.constraint(equalTo: freebooksLabel.bottomAnchor, constant: 10),
            upgradeIntroLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            upgradeIntroLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            
            sellingPointsView.topAnchor.constraint(equalTo: upgradeIntroLabel.bottomAnchor, constant: padding),
            sellingPointsView.leadingAnchor.constraint(equalTo: leadingAnchor),
            sellingPointsView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            upgradeButton.topAnchor.constraint(equalTo: sellingPointsView.bottomAnchor, constant: padding),
            upgradeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            upgradeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            upgradeButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight),
            upgradeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
        ])
    }
}

extension SettingsUpgradeView {
    @objc func tappedUpgrade() {
        upgradeTappedHandler?()
    }

    private func attributedUpgradeTitle() -> NSAttributedString {
        let title = RCValues.shared.string(forKey: .upsellTitleAB)
        let attributedTitle = NSMutableAttributedString(
            string: title,
            attributes: [
                .font: Fonts.semiBold21,
                .foregroundColor: Colours.textPrimary
            ]
        )

        if let productRange = title.range(of: "Audiobooks+") {
            let nsRange = NSRange(productRange, in: title)
            attributedTitle.addAttributes([
                .font: Fonts.semiBold21,
                .foregroundColor: Colours.orangePrimary
            ], range: nsRange)
        }

        return attributedTitle
    }
}
