//
//  AudiobookStoreOfflineSelectionVC.swift
//  FreeAudiobooks
//
//  Created by Codex on 03/07/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

final class AudiobookStoreOfflineSelectionVC: BottomSheetController {

    var dismissHandler: (() -> Void)?
    var downloadHandler: (() -> Void)?
    var onlineOnlyHandler: (() -> Void)?

    private var borderedButton: UIButton?
    private var borderedButtonColor: UIColor?

    init() {
        super.init(nibName: nil, bundle: nil)
        createView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        borderedButton?.layer.borderColor = borderedButtonColor?.resolvedColor(with: traitCollection).cgColor
    }

    private func createView() {
        view = UIView()

        var arrangedSubviews: [UIView] = []

        let titleLabel = UILabel()
        titleLabel.font = Fonts.semiBold16
        titleLabel.textColor = Colours.textPrimary
        titleLabel.text = "Choose how to listen"
        titleLabel.textAlignment = .center
        arrangedSubviews.append(titleLabel)

        let splitter = SplitterView()
        splitter.heightAnchor.constraint(equalToConstant: 1).isActive = true
        arrangedSubviews.append(splitter)

        arrangedSubviews.append(ribbonPremiumButton(title: "Listen Offline & Ad-Free", action: #selector(downloadTapped)))
        arrangedSubviews.append(helperLabel(text: "Try it free for 7 days"))

        let listenOnlineButton = Buttons.transparentButtonWithBorder(
            borderColor: Colours.ctaBackground.cgColor,
            buttonTitle: "Listen Online",
            titleColor: Colours.ctaBackground
        )
        prepareButton(listenOnlineButton, action: #selector(listenOnlineTapped))
        borderedButton = listenOnlineButton
        borderedButtonColor = Colours.ctaBackground
        arrangedSubviews.append(listenOnlineButton)
        arrangedSubviews.append(helperLabel(text: "With ads · needs a connection"))

        let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 16
        applyCustomSpacing(to: stackView)

        view.addSubviewForConstraints(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: UIConstants.shared.standardMargin),
            stackView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -UIConstants.shared.standardMargin),
            stackView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -28)
        ])

        view.backgroundColor = .systemBackground
    }

    private func applyCustomSpacing(to stackView: UIStackView) {
        let arrangedSubviews = stackView.arrangedSubviews
        for index in arrangedSubviews.indices {
            guard index + 1 < arrangedSubviews.count else { continue }

            if arrangedSubviews[index] is UIButton, arrangedSubviews[index + 1] is UILabel {
                stackView.setCustomSpacing(4, after: arrangedSubviews[index])
            }
        }

        guard arrangedSubviews.count > 2 else { return }
        stackView.setCustomSpacing(4, after: arrangedSubviews[2])
    }

    private func primaryButton(title: String, action: Selector) -> UIButton {
        let button = Buttons.primaryCTA(buttonTitle: title)
        prepareButton(button, action: action)
        return button
    }

    private func ribbonPremiumButton(title: String, action: Selector) -> UIView {
        let button = primaryButton(title: title, action: action)
        let badge = recommendedBadge()
        badge.isUserInteractionEnabled = false

        let wrapper = UIView()
        wrapper.addSubviewForConstraints(button)
        wrapper.addSubviewForConstraints(badge)

        NSLayoutConstraint.activate([
            badge.topAnchor.constraint(equalTo: wrapper.topAnchor),
            badge.centerYAnchor.constraint(equalTo: button.topAnchor, constant: -8),
            badge.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            badge.leadingAnchor.constraint(greaterThanOrEqualTo: wrapper.leadingAnchor),
            badge.trailingAnchor.constraint(lessThanOrEqualTo: wrapper.trailingAnchor),

            button.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
        ])

        return wrapper
    }

    private func prepareButton(_ button: UIButton, action: Selector) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    private func helperLabel(text: String) -> UILabel {
        let label = UILabel()
        label.font = Fonts.medium13
        label.textColor = Colours.textSecondary.withAlphaComponent(0.62)
        label.text = text
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    private func recommendedBadge() -> UIView {
        let label = UILabel()
        label.font = Fonts.semiBold12
        label.textColor = Colours.orangePrimary
        label.text = "Recommended"
        label.textAlignment = .center

        let badge = UIView()
        badge.backgroundColor = UIColor.dynamic(
            light: UIColor(hexString: "#FFEDE0"),
            dark: UIColor(hexString: "#4A2410")
        )
        badge.layer.cornerRadius = 13
        badge.layer.masksToBounds = true
        badge.addSubviewForConstraints(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: badge.topAnchor, constant: 5),
            label.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -12),
            label.bottomAnchor.constraint(equalTo: badge.bottomAnchor, constant: -5)
        ])

        return badge
    }
}

extension AudiobookStoreOfflineSelectionVC {
    @objc func listenOnlineTapped() {
        onlineOnlyHandler?()
    }

    @objc func downloadTapped() {
        downloadHandler?()
    }
}
