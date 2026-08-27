//
//  FloatingRecapButton.swift
//  FreeAudiobooks
//
//  Copyright © 2025 Kneady Technologies. All rights reserved.
//

import UIKit

final class FloatingRecapButton: UIView {

    // MARK: - UI Elements

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = ReadingUserDefaults.theme.buttonBackgroundColor
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        imageView.image = UIImage(systemName: "arrow.counterclockwise.circle.fill", withConfiguration: config)
        imageView.tintColor = ReadingUserDefaults.theme.buttonTitleColor
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Recap"
        label.font = Fonts.semiBold16
        label.textColor = ReadingUserDefaults.theme.buttonTitleColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Callbacks

    var onTap: (() -> Void)?

    // MARK: - State

    private(set) var isShowing = false

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 42),

            // Icon
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),

            // Title
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])

        // Shadow with navy tint for cohesion
        layer.shadowColor = ReadingUserDefaults.theme.buttonBackgroundColor.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 6)

        // Tap gesture for main button area
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        containerView.addGestureRecognizer(tapGesture)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.cornerRadius = containerView.bounds.height / 2
    }

    // MARK: - Actions

    @objc private func handleTap() {
        // Scale animation feedback
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
            self.onTap?()
        }
    }

    // MARK: - Animation Methods

    func animateIn() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.alpha = 1
            self.transform = .identity
        }
        isShowing = true
    }

    func animateOut() {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self.alpha = 0
            self.transform = CGAffineTransform(translationX: 0, y: -60)
        }
        isShowing = false
    }

    func updateTheme(_ theme: ReadingTheme) {
        containerView.backgroundColor = theme.buttonBackgroundColor
        iconImageView.tintColor = theme.buttonTitleColor
        titleLabel.textColor = theme.buttonTitleColor
        layer.shadowColor = theme.buttonBackgroundColor.cgColor
    }
}
