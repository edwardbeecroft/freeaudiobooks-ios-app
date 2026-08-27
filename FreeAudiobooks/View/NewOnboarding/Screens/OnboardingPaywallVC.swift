//
//  OnboardingPaywallVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import SuperwallKit
import NVActivityIndicatorView

/// Paywall screen (Screen 20)
/// Uses Superwall to display the paywall
class OnboardingPaywallVC: BaseNewOnboardingVC {

    override var step: NewOnboardingStep { .paywall }
    override var showsProgressBar: Bool { false }
    override var showsBackButton: Bool { false }
    override var showsContinueButton: Bool { false }

    private var loadingIndicatorView: NVActivityIndicatorView?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colours.surfacePrimary
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        displayPaywall()
    }

    // MARK: - Paywall

    private func displayPaywall() {
        let placement = PaywallPlacement.onboarding

        let handler = PaywallPresentationHandler()
        handler.onSkip { [weak self] skippedReason in
            guard let self else { return }
            DispatchQueue.main.async {
                // This shouldn't happen, but just to be safe
                AnalyticsManager.shared.trackOnbPaywallDeclined()
                self.coordinator.dataStore.didSubscribe = false
                self.coordinator.goToNextScreen()
            }
        }
        handler.onError { [weak self] error in
            guard let self else { return }
            DispatchQueue.main.async {
                // This shouldn't happen, but just to be safe
                AnalyticsManager.shared.trackOnbPaywallDeclined()
                self.coordinator.dataStore.didSubscribe = false
                self.coordinator.goToNextScreen()
            }
        }
        
        handler.onPresent { [weak self] paywallInfo in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let dataStore = self.coordinator.dataStore
                dataStore.superwallPaywallName = paywallInfo.name
                dataStore.superwallPaywallIdentifier = paywallInfo.identifier
                dataStore.superwallExperimentId = paywallInfo.experiment?.id
                dataStore.superwallVariantId = paywallInfo.experiment?.variant.id
                dataStore.superwallVariantType = paywallInfo.experiment.map {
                    $0.variant.type == .holdout ? "holdout" : "treatment"
                }

                AnalyticsManager.shared.trackPaywallViewedForPlacement(
                    placement,
                    paywallInfo: paywallInfo
                )
                self.trackScreenViewed()
            }
        }

        handler.onDismiss { [weak self] _, result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.showLoadingIndicator(show: true)

                // Mark paywall as completed regardless of outcome
                self.coordinator.dataStore.didCompletePaywall = true

                switch result {
                case .declined:
                    AnalyticsManager.shared.trackOnbPaywallDeclined()
                    self.coordinator.dataStore.didSubscribe = false
                    self.coordinator.goToNextScreen()

                case .purchased:
                    
                    AnalyticsManager.shared.trackPaywallUserSubscribed(placement: placement, cdBookInternal: nil)
                    
                    AnalyticsManager.shared.trackOnbPaywallSubscribed()
                    self.coordinator.dataStore.didSubscribe = true
                    self.coordinator.goToNextScreen()

                case .restored:
                    AnalyticsManager.shared.trackPaywallRestorePurchasesSuccess()
                    self.coordinator.dataStore.didSubscribe = true
                    self.coordinator.goToNextScreen()
                }
            }
        }

        Superwall.shared.register(placement: placement.rawValue, params: nil, handler: handler)
    }

    private func showLoadingIndicator(show: Bool) {
        if show {
            loadingIndicatorView = NVActivityIndicatorView(
                frame: .zero,
                type: .circleStrokeSpin,
                color: Colours.textPrimary,
                padding: 0
            )
            guard let indicatorView = loadingIndicatorView else { return }

            view.addSubviewForConstraints(indicatorView)
            NSLayoutConstraint.activate([
                indicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                indicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                indicatorView.widthAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight),
                indicatorView.heightAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight)
            ])
            indicatorView.startAnimating()
        } else {
            loadingIndicatorView?.stopAnimating()
            loadingIndicatorView?.removeFromSuperview()
        }
    }
}
