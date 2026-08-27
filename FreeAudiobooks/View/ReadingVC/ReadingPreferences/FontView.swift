//
//  FontView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 08/08/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView

class FontView: UIView {

    private let fontTextLabel = UILabel()
    
    var tappedFontHandler: (() -> Void)?

    private let font: ReadingFont
    init(font: ReadingFont) {
        self.font = font
        super.init(frame: .zero)
        
        setupUI()
        update()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FontView {
    func setupUI() {
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
        
        heightAnchor.constraint(equalToConstant: 36).isActive = true
        
        layer.cornerRadius = UIConstants.shared.cornerRadius
        layer.masksToBounds = true
        layer.borderWidth = 1
        
        fontTextLabel.text = "Aa"
        fontTextLabel.textAlignment = .center
        fontTextLabel.textColor = Colours.textPrimary
        addSubviewForConstraints(fontTextLabel)
        NSLayoutConstraint.activate([
            fontTextLabel.topAnchor.constraint(equalTo: topAnchor),
            fontTextLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            fontTextLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            fontTextLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        fontTextLabel.font = font.withSize(.eighteen)
    }
    @objc func tapped() {
        print("Selected font: \(font.rawValue)")
        tappedFontHandler?()
    }
}

extension FontView {
    func update(selectedFont: ReadingFont? = nil) {
        let currentFont = selectedFont ?? ReadingUserDefaults.font
        if font.rawValue == currentFont.rawValue {
            layer.borderColor = Colours.orangePrimary.cgColor
        } else {
            layer.borderColor = Colours.inputBorder.cgColor
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        fontTextLabel.textColor = Colours.textPrimary
        update()
    }
}
