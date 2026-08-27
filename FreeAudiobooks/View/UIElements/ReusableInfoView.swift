//
//  ReusableInfoView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 31/01/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

class ReusableInfoView: UIView {
    private let containerView = UIView()
    private let subtitleLabel = UILabel()

    init(viewBackgroundColour: UIColor, labelText: String) {
        super.init(frame: .zero)
        containerView.backgroundColor = viewBackgroundColour
        subtitleLabel.text = labelText
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ReusableInfoView {
    func setupView() {
        setupContainerView()
        setupSubtitleLabel()
    }
    func setupContainerView() {
        addSubviewForConstraints(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        containerView.layer.masksToBounds = true
        containerView.layer.cornerRadius = UIConstants.shared.cornerRadius
    }
    
    func setupSubtitleLabel() {
        subtitleLabel.textColor = .white
        subtitleLabel.numberOfLines = 0
        subtitleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.font = Fonts.medium16
        subtitleLabel.textAlignment = .left
        
        containerView.addSubviewForConstraints(subtitleLabel)
        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            subtitleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
}
