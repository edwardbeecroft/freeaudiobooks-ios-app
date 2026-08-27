//
//  AdultContentBadge.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 24/11/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

class AdultContentBadge: UILabel {

    enum Style {
        case overlay
        case inlineMetadata
    }

    var style: Style = .overlay {
        didSet {
            applyStyle()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBadge()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBadge()
    }

    private func setupBadge() {
        text = "18+"
        font = Fonts.semiBold11
        textAlignment = .center
        layer.cornerRadius = UIConstants.shared.smallCornerRadius
        layer.masksToBounds = true
        applyStyle()
    }

    private func applyStyle() {
        let badgeRed = Colours.negativeRed

        switch style {
        case .overlay:
            textColor = .white
            backgroundColor = badgeRed
            layer.borderWidth = 0
            layer.borderColor = UIColor.clear.cgColor
        case .inlineMetadata:
            textColor = badgeRed.withAlphaComponent(0.95)
            backgroundColor = badgeRed.withAlphaComponent(0.10)
            layer.borderWidth = 1
            layer.borderColor = badgeRed.withAlphaComponent(0.18).cgColor
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 36, height: 20)
    }
}
