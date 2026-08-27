
//
//  ChangePreferencesVC.swift
//  LiveCard
//
//  Created by Edward Beecroft on 08/10/2018.
//  Copyright © 2018 SnowDrift Labs. All rights reserved.
//

import UIKit
import BEMCheckBox
import PopupDialog
import NVActivityIndicatorView

class ChangePreferencesVC: UIViewController, BEMCheckBoxDelegate {
	
	let preferencesIntroLabel = UILabel()
	
	let updateButton = Buttons.primaryCTA(buttonTitle: "Unsubscribe")
    
	private var loadingIndicatorView: NVActivityIndicatorView?
	
	let successCheckBox = BEMCheckBox()
	let permissionsUpdatedSuccessfullyLabel = UILabel()

	let emailMarketingService = EmailMarketingService()

	private var isSubscribed: Bool = false

	override func viewDidLoad() {
		super.viewDidLoad()
		self.title = "Update Preferences"
		view.backgroundColor = Colours.surfacePrimary
		setupNavBar()
		setupPreferencesIntroLabel()
		setupUpdateButton()
		fetchSubscriptionStatus()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.setNavigationBarHidden(false, animated: animated)
	}

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard NavigationBarStyler.reapplyIfNeeded(on: self, previousTraitCollection: previousTraitCollection) else { return }
        setupNavBar()
    }
	
	func setupNavBar() {
		guard let navigationBar = self.navigationController?.navigationBar else {return}
        NavigationBarStyler.apply(to: navigationBar)
		
		let btnLeftMenu: UIButton = UIButton(type: .system)
		let backImage = UIImage(named: "backButtonNavIcon")?.withRenderingMode(.alwaysTemplate)
		btnLeftMenu.setImage(backImage, for: .normal)
		btnLeftMenu.tintColor = Colours.textPrimary
		
		btnLeftMenu.addTarget(self, action: #selector(popVC), for: .touchUpInside)
		btnLeftMenu.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
		let barButton = UIBarButtonItem(customView: btnLeftMenu)
		self.navigationItem.leftBarButtonItem = barButton
        
	}
	
	@objc func popVC() {
		self.navigationController?.popViewController(animated: true)
	}
	
	func setupPreferencesIntroLabel() {
		preferencesIntroLabel.font = Fonts.medium15
		preferencesIntroLabel.textColor = Colours.textPrimary
		preferencesIntroLabel.numberOfLines = 0
		preferencesIntroLabel.lineBreakMode = .byWordWrapping
		preferencesIntroLabel.textAlignment = .center
		preferencesIntroLabel.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(preferencesIntroLabel)
		NSLayoutConstraint.activate([
			preferencesIntroLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 25),
			preferencesIntroLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: UIConstants.shared.standardMargin),
			preferencesIntroLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -UIConstants.shared.standardMargin)
		])
	}
	
	func fetchSubscriptionStatus() {
		showLoadingIndicator(show: true)
		emailMarketingService.getSubscriptionStatus { [weak self] subscribed in
			guard let self = self else { return }
			DispatchQueue.main.async {
				if let subscribed = subscribed {
					self.isSubscribed = subscribed
					self.updatePreferencesUI()
				} else {
					self.showError()
				}
			}
		}
	}

	func updatePreferencesUI() {
		DispatchQueue.main.async {
			if self.isSubscribed {
				self.updateButton.setTitle("Unsubscribe", for: .normal)
				self.preferencesIntroLabel.text = RCValues.shared.string(forKey: .currentlySubscribedAB)
			} else {
				self.updateButton.setTitle("Subscribe", for: .normal)
				self.preferencesIntroLabel.text = RCValues.shared.string(forKey: .notCurrentlySubscribedAB)
			}
			self.showLoadingIndicator(show: false)
		}
	}
	
	func setupUpdateButton() {
		updateButton.addTarget(self, action: #selector(updatePressed), for: .touchUpInside)
		updateButton.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(updateButton)
		NSLayoutConstraint.activate([
			updateButton.topAnchor.constraint(equalTo: preferencesIntroLabel.bottomAnchor, constant: 20),
			updateButton.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: UIConstants.shared.standardMargin),
			updateButton.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -UIConstants.shared.standardMargin),
			updateButton.heightAnchor.constraint(equalToConstant: 50)
			])
	}
	
	func setupSuccessCheckboxAndLabel() {
		successCheckBox.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(successCheckBox)
		successCheckBox.topAnchor.constraint(equalTo: updateButton.bottomAnchor, constant: 80).isActive = true
		successCheckBox.heightAnchor.constraint(equalToConstant: 40).isActive = true
		successCheckBox.widthAnchor.constraint(equalToConstant: 40).isActive = true
		successCheckBox.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
		
		successCheckBox.onTintColor = Colours.brandBlack
		successCheckBox.onCheckColor = Colours.brandBlack
		
		successCheckBox.onFillColor = Colours.surfaceCard
		successCheckBox.offFillColor = Colours.surfaceCard
		successCheckBox.tintColor = UIColor(red: 202, green: 202, blue: 202)
		successCheckBox.alpha = 0
		successCheckBox.onAnimationType = .stroke
		successCheckBox.delegate = self
		
		permissionsUpdatedSuccessfullyLabel.text = "Preferences updated successfully!"
		permissionsUpdatedSuccessfullyLabel.font = Fonts.medium15
		permissionsUpdatedSuccessfullyLabel.textColor = Colours.textPrimary
		permissionsUpdatedSuccessfullyLabel.textAlignment = .center
		permissionsUpdatedSuccessfullyLabel.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(permissionsUpdatedSuccessfullyLabel)
		NSLayoutConstraint.activate([
			permissionsUpdatedSuccessfullyLabel.topAnchor.constraint(equalTo: successCheckBox.bottomAnchor, constant: 20),
			permissionsUpdatedSuccessfullyLabel.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: UIConstants.shared.standardMargin),
			permissionsUpdatedSuccessfullyLabel.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -UIConstants.shared.standardMargin),
			permissionsUpdatedSuccessfullyLabel.heightAnchor.constraint(equalToConstant: 20)
		])
		permissionsUpdatedSuccessfullyLabel.alpha = 0
	}
	
	@objc func updatePressed() {
		showLoadingIndicator(show: true)

		if isSubscribed {
			// Unsubscribe
			emailMarketingService.unsubscribeUser { [weak self] success in
				guard let self = self else { return }
				if success {
					AnalyticsManager.shared.trackUserUpdatedMarketingPreferences(subscribed: false)
					self.isSubscribed = false
					DispatchQueue.main.async {
						self.updatePreferencesUI()
					}
				} else {
					self.showError()
				}
			}
		} else {
			// Subscribe
			emailMarketingService.subscribeUser(
				trigger: .accountSettings,
				genre: resolvedEmailOptInGenre()
			) { [weak self] success in
				guard let self = self else { return }
				if success {
					AnalyticsManager.shared.trackUserUpdatedMarketingPreferences(subscribed: true)
					self.isSubscribed = true
					DispatchQueue.main.async {
						self.updatePreferencesUI()
					}
				} else {
					self.showError()
				}
			}
		}
	}

	private func resolvedEmailOptInGenre() -> BookInternalGenre {
		if let userGenre = AccountManager.shared.user?.favoriteGenres.first {
			return userGenre
		}
		if let newGenres = NewOnboardingUserDefaults.getSelectedGenres(),
		   let firstGenre = newGenres.first {
			return firstGenre
		}
		if let legacyGenres = OnboardingGenreUserDefaults.getSelectedGenres(),
		   let firstGenre = legacyGenres.first {
			return firstGenre
		}
		return .romance
	}
	
	func showLoadingIndicator(show: Bool) {
		updateButton.alpha = show ? 0 : 1
		if show {
			guard loadingIndicatorView == nil else { return }
			loadingIndicatorView = NVActivityIndicatorView(frame: CGRect.zero, type: NVActivityIndicatorType.circleStrokeSpin, color: Colours.textPrimary, padding: 0)
			guard let indicatorView = loadingIndicatorView else {return}
			
			indicatorView.translatesAutoresizingMaskIntoConstraints = false
			view.addSubview(indicatorView)
			NSLayoutConstraint.activate([
				indicatorView.centerYAnchor.constraint(equalTo: updateButton.centerYAnchor),
				indicatorView.centerXAnchor.constraint(equalTo: updateButton.centerXAnchor),
				indicatorView.widthAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight),
				indicatorView.heightAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight)
			])
			indicatorView.startAnimating()
		} else {
			loadingIndicatorView?.stopAnimating()
			loadingIndicatorView?.removeFromSuperview()
			loadingIndicatorView = nil
		}
	}
	
	func showError() {
		DispatchQueue.main.async {
			self.showLoadingIndicator(show: false)
			self.present(PopupHelper.noInternetPopup(), animated: true, completion: nil)
		}
	}
}
