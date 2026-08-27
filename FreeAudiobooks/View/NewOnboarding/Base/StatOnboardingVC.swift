//
//  StatOnboardingVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

/// Base view controller for stat/social proof screens in onboarding
/// Displays a large statistic number with title and subtitle
class StatOnboardingVC: BaseNewOnboardingVC {

    // MARK: - Configuration (Override in subclasses)

    /// The large stat number to display (e.g., "86%")
    func getStatNumber() -> String {
        fatalError("Subclasses must override getStatNumber()")
    }

    /// Title text below the stat
    func getStatTitle() -> String {
        fatalError("Subclasses must override getStatTitle()")
    }

    /// Optional subtitle text
    func getStatSubtitle() -> String? {
        return nil
    }

    /// Optional image name for visual element
    func getImageName() -> String? {
        return nil
    }

    // MARK: - UI Elements

    private let statLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 72, weight: .bold)
        label.textColor = Colours.orangePrimary
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.semiBold21
        label.textColor = Colours.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.medium16
        label.textColor = Colours.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = Colours.orangePrimary
        return iv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupStatUI()
    }

    // MARK: - Setup

    private func setupStatUI() {
        statLabel.text = getStatNumber()
        titleLabel.text = getStatTitle()

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Add image if provided
        if let imageName = getImageName(), let image = UIImage(named: imageName) ?? UIImage(systemName: imageName) {
            imageView.image = image
            stackView.addArrangedSubview(imageView)
            imageView.heightAnchor.constraint(equalToConstant: 80).isActive = true
            imageView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        }

        stackView.addArrangedSubview(statLabel)
        stackView.addArrangedSubview(titleLabel)

        if let subtitle = getStatSubtitle(), !subtitle.isEmpty {
            subtitleLabel.text = subtitle
            stackView.addArrangedSubview(subtitleLabel)
        }

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30)
        ])
    }
}
