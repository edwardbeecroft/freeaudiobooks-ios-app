//
//  CustomHoshiTextField.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 10/01/2023.
//  Copyright © 2023 Radically Better. All rights reserved.
//

import TextFieldEffects

class CustomHoshiTextField: HoshiTextField {
    init(placeHolderText: String) {
        super.init(frame: .zero)
        self.placeholder = placeHolderText
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        configure()
    }
    
    func configure() {
        placeholderColor = Colours.textSecondary
        textColor = Colours.textPrimary
        autocorrectionType = .no
        borderInactiveColor = Colours.inputBorder
        borderActiveColor = Colours.textPrimary
        placeholderFontScale = 1.0
        
        font = Fonts.medium16
    }
    
    func setEditingAllowed(editingAllowed: Bool, lastSetPrice: String?) {
        text = editingAllowed ? lastSetPrice ?? "" : ""
        backgroundColor = editingAllowed ? Colours.inputBackground : Colours.surfaceSecondary
        isUserInteractionEnabled = editingAllowed ? true : false
    }
}
