//
//  FormSectionTitleView.swift
//  VaultX
//
//  Created by Ed Beecroft on 01/01/2024.
//  Copyright © 2024 Radically Better. All rights reserved.
//

import UIKit

class FormSectionTitleView: BaseFormView {
    
    private let introLabel = UILabel()
    
    var infoButtonTappedHandler: (() -> Void)?
    
    init(includeInfoButton: Bool) {
        super.init(frame: .zero)
        setupUI(includeInfoButton: includeInfoButton)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateAppearanceColors() {
        super.updateAppearanceColors()
        backgroundColor = .clear
    }
    
    func setupUI(includeInfoButton: Bool) {
        backgroundColor = .clear
        
        introLabel.font = Fonts.medium13
        introLabel.lineBreakMode = .byTruncatingTail
        introLabel.numberOfLines = 0
        introLabel.textColor = Colours.textSecondary
        introLabel.textAlignment = .left
        introLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        addSubviewForConstraints(introLabel)
        
        NSLayoutConstraint.activate([
            introLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            introLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            introLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            introLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)
        ])
        
        if includeInfoButton {
            let infoButton: UIButton = UIButton(type: .system)
            let backImage = UIImage(named: "info")?.withRenderingMode(.alwaysTemplate)
            infoButton.setImage(backImage, for: .normal)
            infoButton.tintColor = Colours.textTertiary
            
            let insets: CGFloat = 8
            infoButton.imageEdgeInsets = UIEdgeInsets(top: insets, left: insets, bottom: insets, right: insets)
            
            let trailingPadding = padding - (insets)
            addSubviewForConstraints(infoButton)
            NSLayoutConstraint.activate([
                infoButton.centerYAnchor.constraint(equalTo: introLabel.centerYAnchor),
                infoButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -trailingPadding),
                infoButton.heightAnchor.constraint(equalToConstant: 32),
                infoButton.widthAnchor.constraint(equalToConstant: 32)
            ])
            infoButton.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        }
        
        hideBottomSplitter()
    }
    
    func setIntroText(_ introText: String) {
        introLabel.text = introText.uppercased()
    }

}

private extension FormSectionTitleView {
    @objc func infoButtonTapped() {
        infoButtonTappedHandler?()
    }
}
