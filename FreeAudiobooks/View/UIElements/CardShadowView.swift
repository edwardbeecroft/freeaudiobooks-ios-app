//
//  CardShadowView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 13/08/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

class CardShadowView: UIView {
    let shadowContainerView = UIView()
    let containerView = UIView()
    
    let sideInset: CGFloat
    let topBottomInset: CGFloat
    
    init(sideInset: CGFloat = 20,
         topBottomInset: CGFloat = 10) {
        self.sideInset = sideInset
        self.topBottomInset = topBottomInset
        
        super.init(frame: .zero)
        setupShadowContainerView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateAppearanceColors()
    }
    
    func setupShadowContainerView() {
        addSubviewForConstraints(shadowContainerView)
        NSLayoutConstraint.activate([
            shadowContainerView.leftAnchor.constraint(equalTo: leftAnchor, constant: sideInset),
            shadowContainerView.rightAnchor.constraint(equalTo: rightAnchor, constant: -sideInset),
            shadowContainerView.topAnchor.constraint(equalTo: topAnchor, constant: topBottomInset),
            shadowContainerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -topBottomInset)
        ])
        shadowContainerView.backgroundColor = UIColor.clear
        shadowContainerView.layer.shadowOffset = CGSize(width: 2, height: 2)
        shadowContainerView.layer.shadowOpacity = 0.8
        shadowContainerView.layer.shadowRadius = 7.0
        
        containerView.backgroundColor = Colours.surfaceCard
        containerView.translatesAutoresizingMaskIntoConstraints = false
        shadowContainerView.addSubview(containerView)
        containerView.layer.cornerRadius = 22
        containerView.layer.masksToBounds = true
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: shadowContainerView.topAnchor),
            containerView.leftAnchor.constraint(equalTo: shadowContainerView.leftAnchor),
            containerView.rightAnchor.constraint(equalTo: shadowContainerView.rightAnchor),
            containerView.bottomAnchor.constraint(equalTo: shadowContainerView.bottomAnchor)
        ])

        updateAppearanceColors()
    }

    private func updateAppearanceColors() {
        let shadowOpacity: CGFloat = traitCollection.userInterfaceStyle == .dark ? 0.24 : 0.2
        shadowContainerView.layer.shadowColor = Colours.shadowBase.withAlphaComponent(shadowOpacity).cgColor
        containerView.backgroundColor = Colours.surfaceCard
    }
}
