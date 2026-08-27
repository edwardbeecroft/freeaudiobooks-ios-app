//
//  OfflineBannerView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 03/10/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

class OfflineBannerView: UIView {

    private let messageLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private let containerView = UIView()

    static let offlineText: String = "You're currently offline. Functionality will be limited. Your downloaded audiobooks are available in \"Library\"."
    var retryTappedHandler: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = Colours.negativeRed.withAlphaComponent(0.95)

        // Container for content with padding
        addSubviewForConstraints(containerView)
        containerView.backgroundColor = .clear

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])

        // Message label
        containerView.addSubviewForConstraints(messageLabel)
        messageLabel.text = OfflineBannerView.offlineText
        messageLabel.textColor = .white
        messageLabel.font = Fonts.medium14
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .left

        // Retry button
        containerView.addSubviewForConstraints(retryButton)
        retryButton.setTitle("Retry", for: .normal)
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.titleLabel?.font = Fonts.medium14
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        retryButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        retryButton.layer.borderWidth = 1
        retryButton.layer.borderColor = UIColor.white.cgColor
        retryButton.layer.cornerRadius = 8
        
        retryButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            messageLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: retryButton.leadingAnchor, constant: -12),

            retryButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            retryButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            retryButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
            retryButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    @objc private func retryTapped() {
        retryTappedHandler?()
    }

    func updateStatus(isOffline: Bool) {
        if isOffline {
            backgroundColor = Colours.negativeRed.withAlphaComponent(0.95)
            messageLabel.text = OfflineBannerView.offlineText
            retryButton.isHidden = false
        } else {
            backgroundColor = UIColor.systemGreen.withAlphaComponent(0.95)
            messageLabel.text = "Back online! Refreshing..."
            retryButton.isHidden = true
        }
    }
}
