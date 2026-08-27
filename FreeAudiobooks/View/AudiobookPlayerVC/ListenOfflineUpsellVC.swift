//
//  ListenOfflineUpsellVC.swift
//  FreeAudiobooks
//
//  Created by Codex on 03/07/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

private final class ListenOfflineUpsellHitTargetButton: UIButton {
    var minimumHitSize = CGSize(width: 44, height: 44)

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let widthDelta = max(0, minimumHitSize.width - bounds.width)
        let heightDelta = max(0, minimumHitSize.height - bounds.height)
        let extendedBounds = bounds.insetBy(dx: -widthDelta / 2, dy: -heightDelta / 2)
        return extendedBounds.contains(point)
    }
}

final class ListenOfflineUpsellVC: UIViewController {
    private let dimmingView = UIView()
    private let cardView = UIView()
    private var hasAnimatedIn = false
    private var isDismissing = false

    // Elevated in dark mode so the card stands out against the black player + dim.
    private let cardBackgroundColor = UIColor.dynamic(
        light: Colours.surfacePrimary,
        dark: UIColor(hexString: "2C2C2E")
    )
    private let cardBorderColor = UIColor.dynamic(
        light: .clear,
        dark: UIColor.white.withAlphaComponent(0.14)
    )

    var subscribeHandler: (() -> Void)?
    var dismissHandler: (() -> Void)?

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        createView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        cardView.layer.borderColor = cardBorderColor.resolvedColor(with: traitCollection).cgColor
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !hasAnimatedIn else { return }
        hasAnimatedIn = true

        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.dimmingView.alpha = 1
            self.cardView.alpha = 1
            self.cardView.transform = .identity
        }
    }

    private func createView() {
        view = UIView()
        view.backgroundColor = .clear

        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.58)
        dimmingView.alpha = 0

        cardView.backgroundColor = cardBackgroundColor
        cardView.layer.cornerRadius = 20
        cardView.layer.cornerCurve = .continuous
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = cardBorderColor.resolvedColor(with: traitCollection).cgColor
        cardView.layer.shadowColor = Colours.shadowBase.cgColor
        cardView.layer.shadowOpacity = 0.18
        cardView.layer.shadowRadius = 18
        cardView.layer.shadowOffset = CGSize(width: 0, height: 12)
        cardView.alpha = 0
        cardView.transform = CGAffineTransform(translationX: 0, y: 8)

        let iconWrapper = makeCenteredIconWrapper(symbolName: "wifi.slash")
        let titleLabel = makeTitleLabel(text: "Keep listening offline")
        let bodyLabel = makeBodyLabel(
            text: "You're offline, but this audiobook is ready to go. Unlock offline listening to pick up right where you left off, no signal needed."
        )

        let subscribeButton = Buttons.gradientButton(buttonTitle: "Unlock & Keep Listening")
        subscribeButton.translatesAutoresizingMaskIntoConstraints = false
        subscribeButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight).isActive = true
        subscribeButton.addTarget(self, action: #selector(subscribeTapped), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [
            iconWrapper,
            titleLabel,
            bodyLabel,
            subscribeButton
        ])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 14
        stackView.setCustomSpacing(18, after: bodyLabel)

        view.addSubviewForConstraints(dimmingView)
        view.addSubviewForConstraints(cardView)
        cardView.addSubviewForConstraints(stackView)
        let cardWidthConstraint = cardView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -48)
        cardWidthConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            cardView.centerYAnchor.constraint(equalTo: view.safeCenterYAnchor),
            cardView.centerXAnchor.constraint(equalTo: view.safeCenterXAnchor),
            cardView.topAnchor.constraint(greaterThanOrEqualTo: view.safeTopAnchor, constant: 24),
            cardView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeBottomAnchor, constant: -24),
            cardView.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeLeadingAnchor, constant: 24),
            cardView.trailingAnchor.constraint(lessThanOrEqualTo: view.safeTrailingAnchor, constant: -24),
            cardWidthConstraint,
            cardView.widthAnchor.constraint(lessThanOrEqualToConstant: 380),

            stackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 34),
            stackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -24)
        ])

        let dismissButton = ListenOfflineUpsellHitTargetButton(type: .system)
        let closeImage = UIImage(
            systemName: "xmark",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        )
        dismissButton.minimumHitSize = CGSize(width: 44, height: 44)
        dismissButton.setImage(closeImage, for: [])
        dismissButton.tintColor = Colours.textSecondary.withAlphaComponent(0.50)
        dismissButton.backgroundColor = Colours.textSecondary.withAlphaComponent(0.07)
        dismissButton.layer.cornerRadius = 15
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        cardView.addSubviewForConstraints(dismissButton)
        NSLayoutConstraint.activate([
            dismissButton.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            dismissButton.heightAnchor.constraint(equalToConstant: 30),
            dismissButton.widthAnchor.constraint(equalToConstant: 30),
            dismissButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10)
        ])
    }

    private func makeTitleLabel(text: String) -> UILabel {
        let titleLabel = UILabel()
        titleLabel.font = Fonts.semiBold20
        titleLabel.textColor = Colours.textPrimary
        titleLabel.text = text
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        return titleLabel
    }

    private func makeBodyLabel(text: String) -> UILabel {
        let bodyLabel = UILabel()
        bodyLabel.font = Fonts.medium15
        bodyLabel.textColor = Colours.textSecondary
        bodyLabel.text = text
        bodyLabel.textAlignment = .center
        bodyLabel.numberOfLines = 0
        return bodyLabel
    }

    private func makeCenteredIconWrapper(symbolName: String, diameter: CGFloat = 48, iconSize: CGFloat = 24) -> UIView {
        let iconContainer = makeIconContainer(symbolName: symbolName, diameter: diameter, iconSize: iconSize)
        let iconWrapper = UIView()
        iconWrapper.addSubviewForConstraints(iconContainer)
        NSLayoutConstraint.activate([
            iconContainer.topAnchor.constraint(equalTo: iconWrapper.topAnchor),
            iconContainer.centerXAnchor.constraint(equalTo: iconWrapper.centerXAnchor),
            iconContainer.bottomAnchor.constraint(equalTo: iconWrapper.bottomAnchor)
        ])
        return iconWrapper
    }

    private func makeIconContainer(symbolName: String, diameter: CGFloat, iconSize: CGFloat) -> UIView {
        let iconContainer = UIView()
        iconContainer.backgroundColor = Colours.orangePrimary.withAlphaComponent(0.12)
        iconContainer.layer.cornerRadius = diameter / 2

        let iconImageView = UIImageView(image: UIImage(systemName: symbolName))
        iconImageView.tintColor = Colours.orangePrimary
        iconImageView.contentMode = .scaleAspectFit

        iconContainer.addSubviewForConstraints(iconImageView)
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: iconSize),
            iconContainer.widthAnchor.constraint(equalToConstant: diameter),
            iconContainer.heightAnchor.constraint(equalToConstant: diameter)
        ])
        return iconContainer
    }

    @objc private func subscribeTapped() {
        fadeOutAndDismiss { [weak self] in
            self?.subscribeHandler?()
        }
    }

    @objc private func dismissTapped() {
        fadeOutAndDismiss { [weak self] in
            self?.dismissHandler?()
        }
    }

    private func fadeOutAndDismiss(completion: (() -> Void)? = nil) {
        guard !isDismissing else { return }
        isDismissing = true

        UIView.animate(withDuration: 0.14, delay: 0, options: [.curveEaseIn, .allowUserInteraction]) {
            self.dimmingView.alpha = 0
            self.cardView.alpha = 0
        } completion: { _ in
            self.dismiss(animated: false) {
                completion?()
            }
        }
    }
}
