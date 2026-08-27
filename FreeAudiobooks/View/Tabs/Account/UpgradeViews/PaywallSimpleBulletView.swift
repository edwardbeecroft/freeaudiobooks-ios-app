//
//  PaywallSimpleBulletView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 13/08/2025.
//  Copyright © 2025 Radically Better. All rights reserved.
//

import UIKit

class PaywallSimpleBulletView: UIView {
    
    static let labelFont = Fonts.medium14
    let label = UILabel()
    let tickImageView = UIImageView()
    
    let bullet: Bullet
    init(bullet: Bullet) {
        self.bullet = bullet
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PaywallSimpleBulletView {
    func setupUI() {
        label.font = PaywallSimpleBulletView.labelFont
        label.textColor = Colours.subtext
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .left
        label.text = bullet.title

        tickImageView.image = bullet.image
        tickImageView.contentMode = .scaleAspectFit

        addSubviewForConstraints(tickImageView)
        addSubviewForConstraints(label)
        NSLayoutConstraint.activate([
            tickImageView.widthAnchor.constraint(equalToConstant: 16),
            tickImageView.heightAnchor.constraint(equalToConstant: 16),
            tickImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tickImageView.topAnchor.constraint(equalTo: topAnchor, constant: 1),

            label.leadingAnchor.constraint(equalTo: tickImageView.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
