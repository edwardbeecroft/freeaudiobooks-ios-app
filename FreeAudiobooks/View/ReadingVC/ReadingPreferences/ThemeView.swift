//
//  ThemeView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 08/08/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView

class ThemeView: UIView {

    private let themeTextLabel = UILabel()
    
    var tappedThemeHandler: (() -> Void)?

    private let theme: ReadingTheme
    init(theme: ReadingTheme) {
        self.theme = theme
        super.init(frame: .zero)
        
        setupUI()
        update()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ThemeView {
    func setupUI() {
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
        
        layer.cornerRadius = UIConstants.shared.cornerRadius
        layer.masksToBounds = true
        layer.borderWidth = 1
        
        heightAnchor.constraint(equalToConstant: 36).isActive = true
        
        themeTextLabel.text = "T"
        themeTextLabel.textAlignment = .center
        themeTextLabel.font = Fonts.medium16
        addSubviewForConstraints(themeTextLabel)
        NSLayoutConstraint.activate([
            themeTextLabel.topAnchor.constraint(equalTo: topAnchor),
            themeTextLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            themeTextLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            themeTextLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        backgroundColor = theme.backgroundColor
        themeTextLabel.textColor = theme.textColor
    }
    @objc func tapped() {
        tappedThemeHandler?()
    }
}

extension ThemeView {
    func update(selectedTheme: ReadingTheme? = nil) {
        let currentTheme = selectedTheme ?? ReadingUserDefaults.theme
        if theme.rawValue == currentTheme.rawValue {
            layer.borderColor = Colours.orangePrimary.cgColor
        } else {
            layer.borderColor = Colours.inputBorder.cgColor
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        update()
    }
}
