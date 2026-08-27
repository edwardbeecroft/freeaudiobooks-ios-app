//
//  FormTextEntryView.swift
//  VaultX
//
//  Created by Ed Beecroft on 30/12/2023.
//  Copyright © 2023 Radically Better. All rights reserved.
//

import UIKit

class NonEditableTextField: UITextField {
    override func caretRect(for position: UITextPosition) -> CGRect {
      return .zero
    }

    override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
      return []
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
      return false
    }
}

class FormTextEntryView: BaseFormView {
    
    private var placeholderText = "Required"
    private let introLabel = UILabel()
    let textField: UITextField
    
    init(allowTextEditing: Bool = true) {
        textField = allowTextEditing ? UITextField() : NonEditableTextField()
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        
        introLabel.font = Fonts.medium16
        introLabel.lineBreakMode = .byTruncatingTail
        introLabel.numberOfLines = 1
        introLabel.textColor = Colours.textPrimary
        introLabel.textAlignment = .left
        introLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        textField.textColor = Colours.textPrimary
        textField.font = Fonts.medium15
        textField.returnKeyType = .done
        textField.textAlignment = .right
        applyPlaceholderAppearance()
        textField.tintColor = Colours.textPrimary
        
        addSubviewForConstraints(textField)
        addSubviewForConstraints(introLabel)
        
        NSLayoutConstraint.activate([
            introLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            introLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            introLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
            introLabel.trailingAnchor.constraint(equalTo: textField.leadingAnchor, constant: -20),
            
            textField.heightAnchor.constraint(equalToConstant: 40),
            textField.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            textField.centerYAnchor.constraint(equalTo: introLabel.centerYAnchor),
        ])
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        applyPlaceholderAppearance()
    }

    private func applyPlaceholderAppearance() {
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholderText,
            attributes: [.foregroundColor: Colours.textTertiary]
        )
    }
    
    func setIntroText(_ introText: String) {
        introLabel.text = introText
    }
    func setTextFieldText(_ text: String) {
        textField.text = text
    }

    func setPlaceholderText(_ text: String) {
        placeholderText = text
        applyPlaceholderAppearance()
    }
}

extension FormTextEntryView {
    func getUserEnteredText() -> String? {
        textField.text
    }
}
