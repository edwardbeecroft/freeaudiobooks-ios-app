//
//  PercentileBadgeView.swift
//  FreeAudiobooks
//
//  Created by FreeAudiobooks on 15/11/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

enum PercentileBadgeState {
    case percentile(Int)
    case gettingStarted
    case inProgress
}

class PercentileBadgeView: UIView {

    private let containerView = UIView()
    private let iconLabel = UILabel()
    private let textLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.cornerRadius = containerView.bounds.height / 2
    }

    private func setupView() {
        addSubviewForConstraints(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        containerView.layer.masksToBounds = true

        iconLabel.font = Fonts.regular14
        iconLabel.textAlignment = .center

        textLabel.font = Fonts.medium12
        textLabel.numberOfLines = 1

        let stack = UIStackView(arrangedSubviews: [iconLabel, textLabel])
        stack.axis = .horizontal
        stack.spacing = 5
        stack.alignment = .center

        containerView.addSubviewForConstraints(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 5),
            stack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -5)
        ])
    }

    func configure(state: PercentileBadgeState) {
        let (icon, color, textColor, message) = style(for: state)

        iconLabel.text = icon
        iconLabel.textColor = textColor
        textLabel.text = message
        textLabel.textColor = textColor
        containerView.backgroundColor = color
    }

    func configure(percentile: Int) {
        configure(state: .percentile(percentile))
    }

    private func style(for state: PercentileBadgeState) -> (icon: String, backgroundColor: UIColor, textColor: UIColor, message: String) {
        switch state {
        case .percentile(let percentile):
            switch percentile {
            case 1...5:
                return ("🏆", UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.12), UIColor(red: 0.82, green: 0.64, blue: 0.15, alpha: 1.0), "Top \(percentile)%")
            case 6...10:
                return ("🏆", UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.1), UIColor(red: 0.82, green: 0.64, blue: 0.15, alpha: 1.0), "Top \(percentile)%")
            case 11...25:
                return ("🥈", UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 0.12), UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0), "Top \(percentile)%")
            case 26...50:
                return ("🥉", UIColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 0.1), UIColor(red: 0.65, green: 0.4, blue: 0.15, alpha: 1.0), "Top \(percentile)%")
            case 51...99:
                return ("📊", UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 0.07), UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0), "Top \(percentile)%")
            default:
                return style(for: .gettingStarted)
            }
        case .gettingStarted:
            return ("🌱", UIColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 0.1), UIColor(red: 0.15, green: 0.65, blue: 0.3, alpha: 1.0), "Getting started")
        case .inProgress:
            return ("🌱", UIColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 0.1), UIColor(red: 0.15, green: 0.65, blue: 0.3, alpha: 1.0), "In progress")
        }
    }
}
