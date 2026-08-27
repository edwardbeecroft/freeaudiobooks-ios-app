//
//  SlowResponseView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 14/02/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

class InfoView: UIView {
    private let messageLabel = UILabel()
    private let infoImageView = UIImageView()
    
    private let message: String
    init(message: String) {
        self.message = message
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        layer.borderColor = Colours.inputBorder.cgColor
    }
}

private extension InfoView {
    func setupView() {
        backgroundColor = Colours.surfaceCard
        layer.cornerRadius = UIConstants.shared.cornerRadius
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = Colours.inputBorder.cgColor
        
        setupInfoImageView()
        setupMessageLabel()
    }
    
    func setupInfoImageView() {
        addSubviewForConstraints(infoImageView)
        NSLayoutConstraint.activate([
            infoImageView.heightAnchor.constraint(equalToConstant: 20),
            infoImageView.widthAnchor.constraint(equalToConstant: 20),
            infoImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            infoImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        infoImageView.image = UIImage(named: "info")?.withRenderingMode(.alwaysTemplate)
        infoImageView.tintColor = Colours.textPrimary
    }
    
    func setupMessageLabel() {
        messageLabel.textColor = Colours.textPrimary
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.font = Fonts.medium15
        messageLabel.textAlignment = .left
        messageLabel.text = message
        
        addSubviewForConstraints(messageLabel)
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: infoImageView.trailingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])
    }
}
