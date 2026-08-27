//
//  ListeningQuotaDepletedSheetVC.swift
//  FreeAudiobooks
//
//  Created by Codex on 20/05/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import SuperwallKit

@MainActor
final class ListeningQuotaDepletedSheetVC: BottomSheetController {

    var onUnlocked: (() -> Void)?

    private enum PreviewLayout {
        static let tileCornerRadius: CGFloat = UIConstants.shared.cardCornerRadius
        static let coverHeight: CGFloat = 68
        static let coverCornerRadius: CGFloat = UIConstants.shared.bookCoverCornerRadius
    }

    private let metadata: ReadableContentMetadata
    private let ctaButton = Buttons.gradientButton(buttonTitle: "Start 7-Day Free Access")

    init(metadata: ReadableContentMetadata) {
        self.metadata = metadata
        super.init(nibName: nil, bundle: nil)
        preferredSheetSizing = .fit
        preferredSheetCornerRadius = 28
        tapToDismissEnabled = false
        panToDismissEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colours.surfacePrimary
        setupUI()
        AnalyticsManager.shared.trackListeningQuotaDepletedSheetViewed(
            cdBookInternal: metadata as? CDBookInternal
        )
    }

    private func setupUI() {
        let dragHandle = makeDragHandle()
        let previewTile = makePreviewTile()
        view.addSubviewForConstraints(dragHandle)

        let titleLabel = UILabel()
        titleLabel.text = "You've hit your weekly limit"
        titleLabel.font = Fonts.bold24
        titleLabel.textColor = Colours.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Join Audiobooks+ to keep listening now with unlimited audiobooks and ad-free listening."
        subtitleLabel.font = Fonts.medium15
        subtitleLabel.textColor = Colours.textSecondary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let previewPill = UIButton(type: .system)
        previewPill.setTitle("Join Audiobooks+", for: .normal)
        previewPill.titleLabel?.font = Fonts.medium13
        previewPill.setTitleColor(Colours.orangePrimary, for: .normal)
        previewPill.backgroundColor = Colours.orangePrimary.withAlphaComponent(0.12)
        previewPill.layer.cornerRadius = 18
        previewPill.layer.masksToBounds = true
        previewPill.addTarget(self, action: #selector(handleCTATapped), for: .touchUpInside)

        ctaButton.addTarget(self, action: #selector(handleCTATapped), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [
            previewTile,
            previewPill,
            titleLabel,
            subtitleLabel,
            ctaButton
        ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 14
        stackView.setCustomSpacing(18, after: previewPill)
        stackView.setCustomSpacing(8, after: titleLabel)
        stackView.setCustomSpacing(30, after: subtitleLabel)
        view.addSubviewForConstraints(stackView)

        NSLayoutConstraint.activate([
            dragHandle.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            dragHandle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dragHandle.widthAnchor.constraint(equalToConstant: 42),
            dragHandle.heightAnchor.constraint(equalToConstant: 5),

            stackView.topAnchor.constraint(equalTo: dragHandle.bottomAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.shared.standardMargin),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

            previewTile.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            previewTile.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),

            previewPill.widthAnchor.constraint(greaterThanOrEqualToConstant: 136),
            previewPill.heightAnchor.constraint(equalToConstant: 36),

            ctaButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            ctaButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
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

    private func makePreviewTile() -> UIView {
        let shadowView = ListeningQuotaPreviewTileShadowView(cornerRadius: PreviewLayout.tileCornerRadius)

        let tile = ListeningQuotaPreviewTileView(cornerRadius: PreviewLayout.tileCornerRadius)

        let coverImageView = CoverImageView(height: PreviewLayout.coverHeight, parentVenue: .smallMetadataView)
        coverImageView.coverCornerRadiusOverride = PreviewLayout.coverCornerRadius
        coverImageView.setImage(
            urlString: metadata.coverImageThumbnailURLString ?? metadata.coverImageURLString,
            isBookCompleted: false,
            progressPercentage: nil
        )

        let titleLabel = UILabel()
        titleLabel.text = metadata.title ?? "Untitled book"
        titleLabel.font = Fonts.semiBold16
        titleLabel.textColor = Colours.textPrimary
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail

        let summaryLabel = UILabel()
        summaryLabel.text = metadata.subtitleText
        summaryLabel.font = Fonts.medium13
        summaryLabel.textColor = Colours.textSecondary
        summaryLabel.numberOfLines = 1
        summaryLabel.lineBreakMode = .byTruncatingTail

        let textStack = UIStackView(arrangedSubviews: [titleLabel, summaryLabel])
        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.spacing = 5

        shadowView.addSubviewForConstraints(tile)
        tile.addSubviewForConstraints(coverImageView)
        tile.addSubviewForConstraints(textStack)

        NSLayoutConstraint.activate([
            tile.topAnchor.constraint(equalTo: shadowView.topAnchor),
            tile.leadingAnchor.constraint(equalTo: shadowView.leadingAnchor),
            tile.trailingAnchor.constraint(equalTo: shadowView.trailingAnchor),
            tile.bottomAnchor.constraint(equalTo: shadowView.bottomAnchor),

            coverImageView.leadingAnchor.constraint(equalTo: tile.leadingAnchor, constant: 12),
            coverImageView.topAnchor.constraint(equalTo: tile.topAnchor, constant: 12),
            coverImageView.bottomAnchor.constraint(equalTo: tile.bottomAnchor, constant: -12),

            textStack.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 14),
            textStack.trailingAnchor.constraint(equalTo: tile.trailingAnchor, constant: -14),
            textStack.centerYAnchor.constraint(equalTo: coverImageView.centerYAnchor)
        ])

        return shadowView
    }

    @objc private func handleCTATapped() {
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
                    AnalyticsManager.shared.trackPaywallUserSubscribed(
                        placement: placement,
                        cdBookInternal: self?.metadata as? CDBookInternal
                    )
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

private final class ListeningQuotaPreviewTileView: UIView {
    init(cornerRadius: CGFloat) {
        super.init(frame: .zero)
        backgroundColor = Self.tileBackgroundColor
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        layer.borderWidth = 1
        updateBorderColor()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        updateBorderColor()
    }

    private func updateBorderColor() {
        layer.borderColor = Colours.inputBorder.resolvedColor(with: traitCollection).cgColor
    }

    private static var tileBackgroundColor: UIColor {
        UIColor.dynamic(light: Colours.grey243, dark: UIColor(hexString: "2C2C2E"))
    }
}

private final class ListeningQuotaPreviewTileShadowView: UIView {
    private let tileCornerRadius: CGFloat

    init(cornerRadius: CGFloat) {
        self.tileCornerRadius = cornerRadius
        super.init(frame: .zero)
        backgroundColor = .clear
        layer.masksToBounds = false
        updateShadow()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: tileCornerRadius
        ).cgPath
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        updateShadow()
    }

    private func updateShadow() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        layer.shadowColor = Colours.shadowBase.cgColor
        layer.shadowOpacity = isDarkMode ? 0.24 : 0.08
        layer.shadowRadius = isDarkMode ? 18 : 14
        layer.shadowOffset = CGSize(width: 0, height: isDarkMode ? 8 : 6)
    }
}
