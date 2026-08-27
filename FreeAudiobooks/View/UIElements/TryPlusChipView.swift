//
//  TryPlusChipView.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 23/02/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

class TryPlusChipView: UIView {

    var tappedHandler: (() -> Void)?

    private let containerView = UIView()
    private let boltImageView = UIImageView()
    private let titleLabel = UILabel()
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = containerView.bounds
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateGradientColors()
    }

    private func setupUI() {
        containerView.layer.cornerRadius = 14
        containerView.layer.masksToBounds = true

        gradientLayer.startPoint = CGPoint(x: 0, y: 0.4)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.6)
        gradientLayer.cornerRadius = 14
        containerView.layer.insertSublayer(gradientLayer, at: 0)
        updateGradientColors()

        addSubviewForConstraints(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 28)
        ])

        boltImageView.image = UIImage(named: "bolt-isolated")?.withRenderingMode(.alwaysTemplate)
        boltImageView.tintColor = .white
        containerView.addSubviewForConstraints(boltImageView)

        NSLayoutConstraint.activate([
            boltImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            boltImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            boltImageView.widthAnchor.constraint(equalToConstant: 12),
            boltImageView.heightAnchor.constraint(equalToConstant: 12)
        ])

        titleLabel.text = "Try Plus"
        titleLabel.font = Fonts.bold13
        titleLabel.textColor = .white
        containerView.addSubviewForConstraints(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: boltImageView.trailingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }

    @objc private func handleTap() {
        tappedHandler?()
    }

    private func updateGradientColors() {
        gradientLayer.colors = [
            Colours.freebooksGradientStart.cgColor,
            Colours.freebooksGradientEnd.cgColor
        ]
    }
}
