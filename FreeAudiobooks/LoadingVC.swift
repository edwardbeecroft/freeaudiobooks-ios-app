//
//  LoadingVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 26/04/2019.
//  Copyright © 2020 Radically Better Ltd All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import PopupDialog
import NVActivityIndicatorView
import Kingfisher
import FirebaseFirestore
import UserNotifications
import FirebaseMessaging


class LoadingVC: UIViewController {
    
    var loadingIndicatorView: NVActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colours.surfacePrimary
        setupUI()
        
        syncContent()
    }
    
    var userFetchErrors: Int = 0
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        showLoadingIndicator(show: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //Auth.auth().removeStateDidChangeListener(handle!)
        self.showLoadingIndicator(show: false)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    func setupUI() {
        let companyNameImageView = UIImageView()
        companyNameImageView.contentMode = .scaleAspectFit
        companyNameImageView.image = UIImage(named: "logo-rounded-100.png")
        view.addSubviewForConstraints(companyNameImageView)
        NSLayoutConstraint.activate([
            companyNameImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            companyNameImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            companyNameImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
            companyNameImageView.heightAnchor.constraint(equalTo: companyNameImageView.widthAnchor)
        ])
        
        let companyNameLabel = UILabel()
        companyNameLabel.numberOfLines = 0
        companyNameLabel.lineBreakMode = .byWordWrapping
        companyNameLabel.textColor = Colours.textPrimary
        companyNameLabel.textAlignment = .center
        companyNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        view.addSubviewForConstraints(companyNameLabel)
        NSLayoutConstraint.activate([
            companyNameLabel.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 60),
            companyNameLabel.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -60),
            companyNameLabel.topAnchor.constraint(equalTo: companyNameImageView.bottomAnchor, constant: 20)
        ])
        companyNameLabel.text = "FreeAudiobooks"
        
        let introLabel = UILabel()
        introLabel.numberOfLines = 0
        introLabel.lineBreakMode = .byWordWrapping
        introLabel.textColor = Colours.textSecondary
        introLabel.textAlignment = .center
        introLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        view.addSubviewForConstraints(introLabel)
        NSLayoutConstraint.activate([
            introLabel.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 60),
            introLabel.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -60),
            introLabel.topAnchor.constraint(equalTo: companyNameLabel.bottomAnchor, constant: 8)
        ])
        
        // IMPORTANT - If this is changed, the LaunchStoryboard must also be changed to match it
        // As these screens are intended to look identical.
        introLabel.text = "Escape into thousands of addictive stories."
    }
    
    func showLoadingIndicator(show: Bool) {
        if show {
            loadingIndicatorView = NVActivityIndicatorView(frame: CGRect.zero, type: NVActivityIndicatorType.circleStrokeSpin, color: Colours.textPrimary, padding: 0)
            guard let indicatorView = loadingIndicatorView else {return}
            
            view.addSubviewForConstraints(indicatorView)
            NSLayoutConstraint.activate([
                indicatorView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
                indicatorView.widthAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight),
                indicatorView.heightAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight),
                indicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
            indicatorView.startAnimating()
        } else {
            loadingIndicatorView?.stopAnimating()
            loadingIndicatorView?.removeFromSuperview()
        }
    }
    
    func syncContent() {
        
        showLoadingIndicator(show: true)
        
        let dispatchGroup = DispatchGroup()
        
        // Timeout for this initial fetch set to 15 minutes. We refresh for the incident view whilst in the app
        let expirationDuration: TimeInterval = 900
        dispatchGroup.enter()
        RCValues.shared.fetchCloudValues(expirationDuration: expirationDuration) {
            dispatchGroup.leave()
        }
        
        var userFetchSuccess: Bool = true
        if let uid = Auth.auth().currentUser?.uid {
            dispatchGroup.enter()

            AccountManager.shared.syncFullUserWithId(uid) { [weak self] success in
                guard let self = self else { return }
                if !success {
                    self.userFetchErrors += 1
                    userFetchSuccess = false
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {

            if userFetchSuccess {
                AccountManager.shared.updateSuperwallUserAttributes()
            }

            self.showLoadingIndicator(show: false)

            if self.appNeedsUpdating() {
                self.showUpdateAlert()
            } else if !userFetchSuccess {
                self.showUserFetchError()
            } else if
                let user = AccountManager.shared.user,
                AccountManager.shared.userIsLoggedInToFirebase() {
                // Existing logged-in user: check if profile needs completion
                if user.needsProfileCompletion {
                    self.presentConfirmDetails()
                } else {
                    self.launchApp()
                }
            } else {
                self.presentNewOnboardingFlow()
            }
        }
    }

    private func presentNewOnboardingFlow() {
        let variant = OnboardingVariant.current
        NewOnboardingCoordinator.shared.set(
            delegate: self,
            variant: variant
        )

        let containerVC = NewOnboardingCoordinator.shared.createContainerVC()
        containerVC.modalPresentationStyle = .fullScreen

        present(containerVC, animated: false) {
            NewOnboardingCoordinator.shared.start()
        }
    }
}

extension LoadingVC {
	func launchApp() {
		DispatchQueue.main.async {
			let customTabBarController = AppTabBarController()
			if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
				appDelegate.tabBarController = customTabBarController
			}
			self.navigationController?.pushViewController(customTabBarController, animated: true)
		}
	}

	private func appNeedsUpdating() -> Bool {
		let minimumAppVersion = RCValues.shared.string(forKey: .minimumAppVersionAB)
		if
			!minimumAppVersion.isEmpty,
			let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
			let compare = currentVersion.compare(minimumAppVersion, options: .numeric)
			// Descending means current version is greater than minimum version
			// Same means current version is same as minimum version
			// Ascending means current version is less than minimum version
			switch compare {
			case .orderedAscending:
				return true
			case .orderedSame, .orderedDescending:
				return false
			}
		}
		return false
	}
	
	private func showUpdateAlert() {
		let updateAction = UIAlertAction(title: "Update", style: .default) { [weak self] cancelTapped in
			guard let self = self else { return }
			self.openAppStorePage()
		}
		let alertController = UIAlertController(title: "FreeAudiobooks requires an update", message: "There is an important new version of FreeAudiobooks available. Please visit the App Store to update.", preferredStyle: .alert)
		alertController.addAction(updateAction)
		DispatchQueue.main.async {
			self.present(alertController, animated: true, completion: nil)
		}
	}
	
	private func openAppStorePage() {
		let appStoreURL = RCValues.shared.string(forKey: .appStoreURLAB)
		if
			!appStoreURL.isEmpty,
			let url = URL(string: appStoreURL),
			UIApplication.shared.canOpenURL(url) {
			UIApplication.shared.open(url)
		} else {
			print("Can't Open URL on Simulator")
		}
	}
	
    private func showUserFetchError() {
        let style = PopupDialogDefaultView.customStyle.defaultCustomStyle
        PopupHelper.setAppearanceForStyle(style: style)
        
        let title = "Network Error"
        var message = "Please ensure you have an active internet connection and try again.\n\nIf this issue persists, and you are sure you have an internet connection, please tap \"Retry\" three times, then tap \"Cancel\" to logout."
        if userFetchErrors >= 3 {
            message = "Please ensure you have an active internet connection and try again.\n\nAlternatively, tap \"Cancel\" to logout of your account and proceed into the app."
        }
        
        let popup = PopupDialog(title: title, message: message, buttonAlignment: .horizontal, transitionStyle: .fadeIn, tapGestureDismissal: false, panGestureDismissal: false)
        
        let buttonOne = DefaultButton(title: "Retry", action: { [weak self] in
            guard let self = self else { return }
            self.syncContent()
        })
        
        if userFetchErrors >= 3 {
            let buttonTwo = DefaultButton(title: "Cancel", action: { [weak self] in
                guard let self = self else { return }
                
                // Something is clearly going wrong with their user, sign them out
                DispatchQueue.main.async {
                    if AccountManager.shared.userIsLoggedInToFirebase() {
                        AccountManager.signOut(tabBarController: nil)
                    }
                    self.presentNewOnboardingFlow()
                }
            })
            
            // Button two because order is vertical
            buttonTwo.titleColor = Colours.grey140
            buttonTwo.buttonColor = nil
            
            popup.addButtons([buttonTwo, buttonOne])
        } else {
            popup.addButtons([buttonOne])
        }
        self.present(popup, animated: true, completion: nil)
    }
}

// MARK: - Profile Completion

extension LoadingVC: ConfirmDetailsDelegate {
    func presentConfirmDetails() {
        let confirmDetailsVC = ConfirmDetailsVC(isInRegistration: false, delegate: self)
        let nav = UINavigationController(rootViewController: confirmDetailsVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    func completedPersonalDetails() {
        dismiss(animated: true) {
            self.launchApp()
        }
    }
}

// MARK: - NewOnboardingCoordinatorDelegate

extension LoadingVC: NewOnboardingCoordinatorDelegate {
    func didCompleteNewOnboarding(didSubscribe: Bool) {
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                self.launchApp()
            }
        }
    }

    func didExitNewOnboarding() {
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                self.launchApp()
            }
        }
    }
}
