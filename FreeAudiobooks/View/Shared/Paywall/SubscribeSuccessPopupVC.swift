//
//  SubscribeSuccessPopupVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 17/01/2021.
//  Copyright © 2021 Radically Better Ltd. All rights reserved.
//

import Foundation
import UIKit
import Lottie

class SubscribeSuccessPopupVC: UIViewController {

	private lazy var lockAnimationView: LottieAnimationView = {
		let animationView = LottieAnimationView(name: "subscribe-unlock")
        animationView.loopMode = .playOnce
		animationView.backgroundColor = nil
		animationView.backgroundBehavior = .pauseAndRestore
		animationView.contentMode = .scaleAspectFit
        animationView.animationSpeed = 1.4
		return animationView
	}()
	
	let introLabel = UILabel()
	let subtitleLabel = UILabel()
	
	let fullContainerView = UIView()
    let ctaButton = Buttons.gradientButton(buttonTitle: L10n.getStarted)
    
    override func viewDidLoad() {
        super.viewDidLoad()
		view.backgroundColor = Colours.surfacePrimary
		setupAllContainerView()
		setupLottieView()
		setupIntroLabel()
		setupSubtitleLabel()
		setupCTAButton()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		lockAnimationView.play()
	}
}

extension SubscribeSuccessPopupVC {
	
	func setupAllContainerView() {
		fullContainerView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(fullContainerView)
		NSLayoutConstraint.activate([
			fullContainerView.leftAnchor.constraint(equalTo: view.leftAnchor),
			fullContainerView.rightAnchor.constraint(equalTo: view.rightAnchor),
//			fullContainerView.heightAnchor.constraint(equalToConstant: 500),
			fullContainerView.topAnchor.constraint(equalTo: view.topAnchor),
			fullContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		])
	}
}

extension SubscribeSuccessPopupVC {
	func setupLottieView() {
		fullContainerView.addSubviewForConstraints(lockAnimationView)
		NSLayoutConstraint.activate([
			lockAnimationView.widthAnchor.constraint(equalToConstant: 100),
			lockAnimationView.heightAnchor.constraint(equalTo: lockAnimationView.widthAnchor),
			lockAnimationView.topAnchor.constraint(equalTo: fullContainerView.topAnchor, constant: 20),
			lockAnimationView.centerXAnchor.constraint(equalTo: fullContainerView.centerXAnchor)
		])
		lockAnimationView.alpha = 1
	}
}

extension SubscribeSuccessPopupVC {
	func setupIntroLabel() {
		introLabel.translatesAutoresizingMaskIntoConstraints = false
		introLabel.font = Fonts.semiBold18
		introLabel.textColor = Colours.textPrimary
		introLabel.textAlignment = .center
		
        introLabel.text = L10n.subscribeSuccessTitle
        
		fullContainerView.addSubview(introLabel)
		NSLayoutConstraint.activate([
			introLabel.topAnchor.constraint(equalTo: lockAnimationView.bottomAnchor, constant: 20),
			introLabel.leftAnchor.constraint(equalTo: fullContainerView.leftAnchor, constant: UIConstants.shared.standardMargin),
			introLabel.rightAnchor.constraint(equalTo: fullContainerView.rightAnchor, constant: -UIConstants.shared.standardMargin),
		])
	}
}

extension SubscribeSuccessPopupVC {
	func setupSubtitleLabel() {
		subtitleLabel.font = Fonts.medium15
		subtitleLabel.textColor = Colours.textSecondary
		subtitleLabel.numberOfLines = 0
		subtitleLabel.lineBreakMode = .byWordWrapping
		subtitleLabel.textAlignment = .center
		
		fullContainerView.addSubviewForConstraints(subtitleLabel)
		
		NSLayoutConstraint.activate([
			subtitleLabel.topAnchor.constraint(equalTo: introLabel.bottomAnchor, constant: 16),
			subtitleLabel.leadingAnchor.constraint(equalTo: fullContainerView.leadingAnchor, constant: UIConstants.shared.standardMargin),
			subtitleLabel.trailingAnchor.constraint(equalTo: fullContainerView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
		])
		
        subtitleLabel.text = RCValues.shared.string(forKey: .subscribeSuccessBodyAB)
	}
}

extension SubscribeSuccessPopupVC {
	func setupCTAButton() {
		ctaButton.translatesAutoresizingMaskIntoConstraints = false
		fullContainerView.addSubview(ctaButton)
		NSLayoutConstraint.activate([
			ctaButton.leftAnchor.constraint(equalTo: fullContainerView.leftAnchor, constant: 20),
			ctaButton.rightAnchor.constraint(equalTo: fullContainerView.rightAnchor, constant: -20),
			ctaButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
			ctaButton.bottomAnchor.constraint(equalTo: fullContainerView.bottomAnchor, constant: -32),
			ctaButton.heightAnchor.constraint(equalToConstant: 50),
		])
		
		ctaButton.addTarget(self, action: #selector(ctaButtonTapped), for: .touchUpInside)
	}
}

extension SubscribeSuccessPopupVC {
	@objc private func ctaButtonTapped() {
		self.dismiss(animated: true)
	}
}
