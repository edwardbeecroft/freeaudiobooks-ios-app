//
//  ParagraphStyleView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 16/02/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import UIKit

class ParagraphStyleView: UIView {

    private let label = UILabel()

    var tappedHandler: (() -> Void)?

    private let paragraphStyle: ReadingParagraphStyle
    init(paragraphStyle: ReadingParagraphStyle) {
        self.paragraphStyle = paragraphStyle
        super.init(frame: .zero)

        setupUI()
        update()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ParagraphStyleView {
    func setupUI() {
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)

        heightAnchor.constraint(equalToConstant: 36).isActive = true

        layer.cornerRadius = UIConstants.shared.cornerRadius
        layer.masksToBounds = true
        layer.borderWidth = 1

        label.textAlignment = .center
        label.textColor = Colours.textPrimary
        label.font = Fonts.medium16
        addSubviewForConstraints(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        switch paragraphStyle {
        case .indented: label.text = "Indented"
        case .spaced: label.text = "Spaced"
        }
    }

    @objc func tapped() {
        tappedHandler?()
    }
}

extension ParagraphStyleView {
    func update(selectedParagraphStyle: ReadingParagraphStyle? = nil) {
        let current = selectedParagraphStyle ?? ReadingUserDefaults.paragraphStyle
        if paragraphStyle == current {
            layer.borderColor = Colours.orangePrimary.cgColor
        } else {
            layer.borderColor = Colours.inputBorder.cgColor
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        label.textColor = Colours.textPrimary
        update()
    }
}
