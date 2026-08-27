//
//  FormView.swift
//  VaultX
//
//  Created by Ed Beecroft on 30/12/2023.
//  Copyright © 2023 Radically Better. All rights reserved.
//

import UIKit

class BaseFormView: UIView {
    
    private let splitterView = BorderView()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let padding: CGFloat = 16
    func configure() {
        updateAppearanceColors()
        
        addSubviewForConstraints(splitterView)
        
        NSLayoutConstraint.activate([
            splitterView.heightAnchor.constraint(equalToConstant: 1),
            splitterView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            splitterView.trailingAnchor.constraint(equalTo: trailingAnchor),
            splitterView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateAppearanceColors()
    }

    func updateAppearanceColors() {
        backgroundColor = Colours.surfaceCard
        splitterView.backgroundColor = Colours.separator
    }
    
    func roundAllCorners() {
        layer.cornerRadius = UIConstants.shared.cardCornerRadius
        layer.masksToBounds = true
    }
    func roundTopCorners() {
        layer.cornerRadius = UIConstants.shared.cardCornerRadius
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    func roundBottomCorners() {
        layer.cornerRadius = UIConstants.shared.cardCornerRadius
        layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }
    func resetRoundedCorners() {
        layer.maskedCorners = []
    }
    func showBottomSplitter() {
        splitterView.isHidden = false
    }
    func hideBottomSplitter() {
        splitterView.isHidden = true
    }
}
