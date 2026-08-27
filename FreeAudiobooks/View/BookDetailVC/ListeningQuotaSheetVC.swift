//
//  ListeningQuotaSheetVC.swift
//  FreeAudiobooks
//
//  Created by Codex on 20/05/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import SuperwallKit

@MainActor
final class ListeningQuotaSheetVC: BottomSheetController {

    var onUnlocked: (() -> Void)?

    private let manager = ListeningQuotaManager.shared
    private let booksRow = UIStackView()
    private let counterLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let ctaButton = Buttons.gradientButton(buttonTitle: "Unlock Unlimited Listening")

    init() {
        super.init(nibName: nil, bundle: nil)
        preferredSheetSizing = .fit
        preferredSheetCornerRadius = 28
        tapToDismissEnabled = true
        panToDismissEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colours.surfacePrimary
        setupUI()
        renderFromManager()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleQuotaChange),
            name: .listeningQuotaDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupUI() {
        let dragHandle = makeDragHandle()
        view.addSubviewForConstraints(dragHandle)

        booksRow.axis = .horizontal
        booksRow.spacing = 18
        booksRow.alignment = .center
        booksRow.distribution = .fill

        let booksWrap = UIView()
        booksWrap.addSubviewForConstraints(booksRow)
        NSLayoutConstraint.activate([
            booksRow.topAnchor.constraint(equalTo: booksWrap.topAnchor),
            booksRow.bottomAnchor.constraint(equalTo: booksWrap.bottomAnchor),
            booksRow.centerXAnchor.constraint(equalTo: booksWrap.centerXAnchor),
            booksRow.leadingAnchor.constraint(greaterThanOrEqualTo: booksWrap.leadingAnchor),
            booksRow.trailingAnchor.constraint(lessThanOrEqualTo: booksWrap.trailingAnchor)
        ])

        counterLabel.font = Fonts.bold24
        counterLabel.textColor = Colours.textPrimary
        counterLabel.textAlignment = .center
        counterLabel.numberOfLines = 0

        subtitleLabel.font = Fonts.medium15
        subtitleLabel.textColor = Colours.textSecondary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        ctaButton.addTarget(self, action: #selector(handleCTA), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [booksWrap, counterLabel, subtitleLabel, ctaButton])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.setCustomSpacing(10, after: counterLabel)
        stackView.setCustomSpacing(32, after: subtitleLabel)
        view.addSubviewForConstraints(stackView)

        NSLayoutConstraint.activate([
            dragHandle.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            dragHandle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dragHandle.widthAnchor.constraint(equalToConstant: 42),
            dragHandle.heightAnchor.constraint(equalToConstant: 5),

            stackView.topAnchor.constraint(equalTo: dragHandle.bottomAnchor, constant: 32),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.shared.standardMargin),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),
            ctaButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight)
        ])
    }

    private func makeDragHandle() -> UIView {
        let handle = UIView()
        handle.backgroundColor = Colours.inputBorder
        handle.layer.cornerRadius = 2.5
        handle.layer.masksToBounds = true
        return handle
    }

    @objc private func handleQuotaChange() {
        renderFromManager()
    }

    private func renderFromManager() {
        let limit = manager.weeklyLimit
        rebuildBooks(remaining: manager.remaining, limit: limit)

        let firstLine = "\(manager.remaining) of \(limit) weekly\n"
        let secondLine = "audiobooks remaining"
        let attributed = NSMutableAttributedString(
            string: firstLine,
            attributes: [
                .foregroundColor: Colours.orangePrimary,
                .font: Fonts.bold24
            ]
        )
        attributed.append(NSAttributedString(
            string: secondLine,
            attributes: [
                .foregroundColor: Colours.textPrimary,
                .font: Fonts.bold24
            ]
        ))
        counterLabel.attributedText = attributed
        subtitleLabel.text = subtitleCopy()
    }

    private func rebuildBooks(remaining: Int, limit: Int) {
        booksRow.arrangedSubviews.forEach {
            booksRow.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for index in 0..<limit {
            let imageView = UIImageView(image: UIImage(systemName: "headphones"))
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = index < remaining
                ? Colours.orangePrimary
                : Colours.orangePrimary.withAlphaComponent(0.18)
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: 26),
                imageView.heightAnchor.constraint(equalToConstant: 26)
            ])
            booksRow.addArrangedSubview(imageView)
        }
    }

    private func subtitleCopy() -> String {
        let days = manager.daysUntilReset
        switch days {
        case 0: return "Resets today."
        case 1: return "Resets in 1 day."
        default: return "Resets in \(days) days."
        }
    }

    @objc private func handleCTA() {
        HapticFeedbackHelper.shared.triggerLightImpactFeedback()
        presentPaywall()
    }

    private func presentPaywall() {
        let placement = PaywallPlacement.listeningQuota
        let handler = PaywallPresentationHandler()
        handler.onPresent { paywallInfo in
            DispatchQueue.main.async {
                AnalyticsManager.shared.trackPaywallViewedForPlacement(placement, paywallInfo: paywallInfo)
            }
        }
        handler.onDismiss { [weak self] _, result in
            DispatchQueue.main.async {
                switch result {
                case .purchased:
                    AnalyticsManager.shared.trackPaywallUserSubscribed(placement: placement, cdBookInternal: nil)
                    self?.finishUnlocked()
                case .restored:
                    AnalyticsManager.shared.trackPaywallRestorePurchasesSuccess()
                    self?.finishUnlocked()
                case .declined:
                    break
                }
            }
        }
        Superwall.shared.register(placement: placement.rawValue, params: nil, handler: handler)
    }

    private func finishUnlocked() {
        dismiss(animated: true) { [onUnlocked] in
            onUnlocked?()
        }
    }
}
