//
//  TextSizeView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 08/08/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//


import Foundation
import UIKit
import NVActivityIndicatorView

class TextSizeView: UIView {

    private let textSizeLabel = UILabel()
    
    var tappedTextSizeHandler: (() -> Void)?

    private let textSize: ReadingTextSize
    init(textSize: ReadingTextSize) {
        self.textSize = textSize
        super.init(frame: .zero)
        
        setupUI()
        update()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TextSizeView {
    func setupUI() {
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
        
        heightAnchor.constraint(equalToConstant: 36).isActive = true
        
        layer.cornerRadius = UIConstants.shared.cornerRadius
        layer.masksToBounds = true
        layer.borderWidth = 1
        
        textSizeLabel.textAlignment = .center
        textSizeLabel.textColor = Colours.textPrimary
        addSubviewForConstraints(textSizeLabel)
        NSLayoutConstraint.activate([
            textSizeLabel.topAnchor.constraint(equalTo: topAnchor),
            textSizeLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            textSizeLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            textSizeLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        textSizeLabel.font = Fonts.medium16
        textSizeLabel.text = "\(Int(textSize.rawValue))"
    }
    @objc func tapped() {
        tappedTextSizeHandler?()
    }
}

extension TextSizeView {
    func update(selectedTextSize: ReadingTextSize? = nil) {
        let currentTextSize = selectedTextSize ?? ReadingUserDefaults.textSize
        if textSize.rawValue == currentTextSize.rawValue {
            layer.borderColor = Colours.orangePrimary.cgColor
        } else {
            layer.borderColor = Colours.inputBorder.cgColor
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        textSizeLabel.textColor = Colours.textPrimary
        update()
    }
}
