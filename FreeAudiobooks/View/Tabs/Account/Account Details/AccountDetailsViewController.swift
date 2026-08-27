//
//  AccountDetailsViewController.swift
//  LiveCard
//
//  Created by Edward Beecroft on 06/10/2018.
//  Copyright © 2018 SnowDrift Labs. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import FirebaseAuth


protocol AccountDetailsVCDelegate {
    func accountDeleted()
}

class AccountDetailsViewController: UIViewController {

    let viewModel = AccountDetailsViewModel()
    var delegate: AccountDetailsVCDelegate?
    private let emailMarketingService = EmailMarketingService()
    
    let nameLabel = UILabel()
    let emailAddressLabel = UILabel()
    let labelsSplitterView = UIView()

    private let changeNameUsernameButton = Buttons.primaryCTA(buttonTitle: "Change Name / Username")
    
    let changeEmailButton = Buttons.primaryCTA(buttonTitle: "Change Email")
    let changePasswordButton = Buttons.primaryCTA(buttonTitle: "Change Password")
    let changePermissionsButton = Buttons.primaryCTA(buttonTitle: "FreeAudiobooks Newsletter")
    
    private let deleteAccountButton = Buttons.transparentButtonWithBorder(borderColor: nil,
                                                                          buttonTitle: "Delete Account",
                                                                          titleColor: Colours.ctaBackground.withAlphaComponent(0.4))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = viewModel.navTitle
        setupNavBar()
        setupUI()
        setupRetryFetchUI()
    }
    
    // Don't show the change password/change email fields if registered with FB?
    // Or V1 just show the popup?
    func userRegisteredWithEmail() -> Bool {
        return AccountManager.shared.userRegisteredWithEmail()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        fetchUserIfNecessary()
        setTexts()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        self.showLoadingIndicator(show: false)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard NavigationBarStyler.reapplyIfNeeded(on: self, previousTraitCollection: previousTraitCollection) else { return }
        setupNavBar()
        retryButton.layer.borderColor = Colours.inputBorder.cgColor
    }
    
    let retryButton = UIButton(type: .system)
    var loadingIndicatorView: NVActivityIndicatorView?
    
    func fetchUserIfNecessary() {
        if AccountManager.shared.userIsLoggedInButNotYetFetched() {
            attemptUserFetch()
        }
    }
    
    func attemptUserFetch() {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        showLoadingIndicator(show: true)
        hideNormalUI()
        AccountManager.shared.syncFullUserWithId(uid) { [weak self] (success) in
            
            guard let strongSelf = self else {return}
            
            strongSelf.showLoadingIndicator(show: false)
            if success {
                strongSelf.setTexts()
                strongSelf.showRetryUI(show: false)
            } else {
                AccountManager.shared.user = nil
                strongSelf.showRetryUI(show: true)
            }
        }
    }
    
    func showRetryUI(show: Bool) {
        if show {
            hideNormalUI()
            retryButton.alpha = 1
        } else {
            nameLabel.alpha = 1
            emailAddressLabel.alpha = 1
            labelsSplitterView.alpha = 1
            changeNameUsernameButton.alpha = 1
            
            changePermissionsButton.alpha = 1
            
            if !AccountManager.shared.userIsLoggedInButNotYetFetched() && userRegisteredWithEmail() {
                changeEmailButton.alpha = 1
                changePasswordButton.alpha = 1
            }
            
            retryButton.alpha = 0
        }
    }
    
    func hideNormalUI() {
        nameLabel.alpha = 0
        emailAddressLabel.alpha = 0
        labelsSplitterView.alpha = 0
        changeNameUsernameButton.alpha = 0
        
        changeEmailButton.alpha = 0
        changePasswordButton.alpha = 0
        changePermissionsButton.alpha = 0
    }
    
    func setupRetryFetchUI() {
        retryButton.setTitle("Retry", for: .normal)
        retryButton.setTitleColor(Colours.textPrimary, for: .normal)
        retryButton.titleLabel?.font = Fonts.medium16
        retryButton.layer.borderColor = Colours.inputBorder.cgColor
        retryButton.layer.borderWidth = 1
        retryButton.layer.cornerRadius = UIConstants.shared.cornerRadius
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(retryButton)
        let height: CGFloat = 30
        NSLayoutConstraint.activate([
            retryButton.widthAnchor.constraint(equalToConstant: 100),
            retryButton.heightAnchor.constraint(equalToConstant: height),
            retryButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            retryButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        retryButton.alpha = 0
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
    }
    
    @objc func retryTapped() {
        retryButton.alpha = 0
        attemptUserFetch()
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
    
    func setTexts() {
        nameLabel.text = AccountManager.shared.user?.fullName()
        emailAddressLabel.text = AccountManager.shared.user?.emailAddress ?? ""
    }
    
    func setupUI() {
        view.backgroundColor = Colours.surfacePrimary
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
        nameLabel.font = Fonts.semiBold16
        nameLabel.textColor = Colours.textPrimary
        nameLabel.textAlignment = .center
        NSLayoutConstraint.activate([
            nameLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: UIConstants.shared.standardMargin),
            nameLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -UIConstants.shared.standardMargin),
            nameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        
        emailAddressLabel.translatesAutoresizingMaskIntoConstraints = false
        emailAddressLabel.font = Fonts.medium15
        emailAddressLabel.textColor = Colours.subtext
        emailAddressLabel.textAlignment = .center
        view.addSubview(emailAddressLabel)
        NSLayoutConstraint.activate([
            emailAddressLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: UIConstants.shared.standardMargin),
            emailAddressLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -UIConstants.shared.standardMargin),
            emailAddressLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6)
        ])
        
        //		setTexts()
        
        labelsSplitterView.translatesAutoresizingMaskIntoConstraints = false
        labelsSplitterView.backgroundColor = Colours.orangePrimary
        view.addSubview(labelsSplitterView)
        NSLayoutConstraint.activate([
            labelsSplitterView.heightAnchor.constraint(equalToConstant: 1),
            labelsSplitterView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            labelsSplitterView.topAnchor.constraint(equalTo: emailAddressLabel.bottomAnchor, constant: 15),
            labelsSplitterView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.15)
        ])

        changeNameUsernameButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(changeNameUsernameButton)
        NSLayoutConstraint.activate([
            changeNameUsernameButton.topAnchor.constraint(equalTo: labelsSplitterView.bottomAnchor, constant: 20),
            changeNameUsernameButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: UIConstants.shared.standardMargin),
            changeNameUsernameButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -UIConstants.shared.standardMargin),
            changeNameUsernameButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight)
        ])
        changeNameUsernameButton.addTarget(self, action: #selector(tappedChangeNameUsername), for: .touchUpInside)
        
        changePermissionsButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(changePermissionsButton)
        NSLayoutConstraint.activate([
            changePermissionsButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight),
            changePermissionsButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: UIConstants.shared.standardMargin),
            changePermissionsButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -UIConstants.shared.standardMargin),
            changePermissionsButton.topAnchor.constraint(equalTo: changeNameUsernameButton.bottomAnchor, constant: 10)
        ])
        changePermissionsButton.addTarget(self, action: #selector(tappedChangePermissions), for: .touchUpInside)
        
        changeEmailButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(changeEmailButton)
        NSLayoutConstraint.activate([
            changeEmailButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight),
            changeEmailButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: UIConstants.shared.standardMargin),
            changeEmailButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -UIConstants.shared.standardMargin),
            changeEmailButton.topAnchor.constraint(equalTo: changePermissionsButton.bottomAnchor, constant: 10)
        ])
        changeEmailButton.addTarget(self, action: #selector(tappedChangeEmail), for: .touchUpInside)
        
        changePasswordButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(changePasswordButton)
        NSLayoutConstraint.activate([
            changePasswordButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight),
            changePasswordButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: UIConstants.shared.standardMargin),
            changePasswordButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -UIConstants.shared.standardMargin),
            changePasswordButton.topAnchor.constraint(equalTo: changeEmailButton.bottomAnchor, constant: 10)
        ])
        changePasswordButton.addTarget(self, action: #selector(tappedChangePassword), for: .touchUpInside)
        
        if !AccountManager.shared.userIsLoggedInButNotYetFetched() && userRegisteredWithEmail() {
            changeEmailButton.alpha = 1
            changePasswordButton.alpha = 1
        } else {
            changeEmailButton.alpha = 0
            changePasswordButton.alpha = 0
        }
        
        deleteAccountButton.addTarget(self, action: #selector(tappedDeleteAccount), for: .touchUpInside)
        view.addSubviewForConstraints(deleteAccountButton)
        NSLayoutConstraint.activate([
            deleteAccountButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -UIConstants.shared.standardMargin),
            deleteAccountButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            deleteAccountButton.heightAnchor.constraint(equalToConstant: 36),
            deleteAccountButton.widthAnchor.constraint(equalToConstant: 140)
        ])
    }
}

extension AccountDetailsViewController {
    @objc private func tappedChangeNameUsername() {
        let changeNameUsernameVC = ChangeNameUsernameVC()
        navigationController?.pushViewController(changeNameUsernameVC, animated: true)
    }

    @objc func tappedChangeEmail() {
        // If button was visible for user to tap, they registered using email, but let's include a safety catch here.
        if userRegisteredWithEmail() {
            let changeEmailVC = ChangeEmailVC()
            self.navigationController?.pushViewController(changeEmailVC, animated: true)
        }
    }
    
    @objc func tappedChangePassword() {
        // If button was visible for user to tap, they registered using email, but let's include a safety catch here.
        if userRegisteredWithEmail() {
            let changePasswordVC = ChangePasswordVC()
            self.navigationController?.pushViewController(changePasswordVC, animated: true)
        }
    }
    
    @objc func tappedChangePermissions() {
        let changePermissionsVC = ChangePreferencesVC()
        self.navigationController?.pushViewController(changePermissionsVC, animated: true)
    }
}

extension AccountDetailsViewController {
    @objc func tappedDeleteAccount() {
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] deleteTapped in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.handleDeleteAccount()
            }
        }
        let message = "Are you sure you wish to permanently delete your account?\n\nAll data relating to your account will be deleted.\n\nThis action cannot be undone."
        let alertController = UIAlertController(title: "Delete Account", message: message, preferredStyle: .alert)
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func handleDeleteAccount() {

        guard let currentUser = Auth.auth().currentUser else {
            showUnableToDeleteError()
            return
        }
        showLoadingIndicator(show: true)

        // Step 1: Delete from Brevo first (needs auth + Firestore doc to exist)
        // We don't fail account deletion if this fails
        emailMarketingService.unsubscribeUser { [weak self] _ in
            guard let self = self else { return }

            // Step 2: Delete Firestore data
            AccountManager.shared.deleteAllDataForCurrentUser(userUUID: currentUser.uid) { success in
                guard success else {
                    DispatchQueue.main.async {
                        self.showLoadingIndicator(show: false)
                        self.showUnableToDeleteError()
                    }
                    return
                }

                // Step 3: Delete Firebase Auth user (may require reauthentication)
                self.deleteFirebaseAuthUser()
            }
        }
    }

    private func deleteFirebaseAuthUser() {
        Auth.auth().currentUser?.delete { [weak self] error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let error = error {
                    // Check if reauthentication is required
                    if let errCode = AuthErrorCode(rawValue: (error as NSError).code),
                       errCode == .requiresRecentLogin {
                        self.showLoadingIndicator(show: false)
                        self.handleReauthenticationRequired()
                    } else {
                        self.showLoadingIndicator(show: false)
                        self.showUnableToDeleteError()
                    }
                } else {
                    self.showAccountDeletedPopup()
                }
            }
        }
    }

    private func handleReauthenticationRequired() {
        // Determine sign-in method for user-friendly message
        let signInMethod = ReauthenticationService.shared.getCurrentSignInMethod()
        let methodDescription: String
        switch signInMethod {
        case .manual:
            methodDescription = "your email and password"
        case .google:
            methodDescription = "Google"
        case .apple:
            methodDescription = "Apple"
        case .none:
            methodDescription = "your account"
        }

        let title = "Verification Required"
        let message = "For security, please verify your identity with \(methodDescription) to complete account deletion."

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let continueAction = UIAlertAction(title: "Continue", style: .default) { [weak self] _ in
            self?.performReauthenticationAndDelete()
        }

        alertController.addAction(cancelAction)
        alertController.addAction(continueAction)

        present(alertController, animated: true)
    }

    private func performReauthenticationAndDelete() {
        showLoadingIndicator(show: true)

        ReauthenticationService.shared.reauthenticate(from: self) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Reauthentication successful, now delete the account
                    self.deleteFirebaseAuthUser()

                case .failure(let error):
                    self.showLoadingIndicator(show: false)

                    switch error {
                    case .cancelled:
                        // User cancelled, do nothing
                        break
                    case .unknownSignInMethod:
                        self.showReauthenticationError(message: "Unable to determine your sign-in method. Please contact support.")
                    case .missingCredential:
                        self.showReauthenticationError(message: "Please enter your credentials and try again.")
                    case .reauthenticationFailed(let underlyingError):
                        self.showReauthenticationError(message: "Verification failed: \(underlyingError.localizedDescription)")
                    case .userNotLoggedIn:
                        self.showReauthenticationError(message: "You are not logged in. Please log in and try again.")
                    }
                }
            }
        }
    }

    private func showReauthenticationError(message: String) {
        let controller = UIAlertController(
            title: "Verification Failed",
            message: message,
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "OK", style: .default)
        controller.addAction(okAction)
        present(controller, animated: true)
    }
    
    func showUnableToDeleteError() {
        let title = L10n.networkError
        let message = "We were unable to delete your account. Please check you have an internet connection and try again."
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let noAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let retryAction = UIAlertAction(title: "Retry", style: .default) { tappedYes in
            self.handleDeleteAccount()
        }
        
        controller.addAction(noAction)
        controller.addAction(retryAction)
        
        self.present(controller, animated: true, completion: nil)
    }
    
    func showAccountDeletedPopup() {
        let title = "Account Deleted"
        let message = "Your account and all related data has been deleted. You have also been logged out."
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: L10n.ok, style: .default) { tappedYes in
            DispatchQueue.main.async {
                self.delegate?.accountDeleted()
            }
        }
        controller.addAction(okAction)
        self.present(controller, animated: true, completion: nil)
    }
}

extension AccountDetailsViewController {
    func showLoadingIndicator(show: Bool) {
        if show {
            loadingIndicatorView = NVActivityIndicatorView(frame: CGRect.zero, type: NVActivityIndicatorType.circleStrokeSpin, color: Colours.textPrimary, padding: 0)
            guard let indicatorView = loadingIndicatorView else { return }
            
            deleteAccountButton.isHidden = true
            
            indicatorView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(indicatorView)
            NSLayoutConstraint.activate([
                indicatorView.centerYAnchor.constraint(equalTo: deleteAccountButton.centerYAnchor),
                indicatorView.widthAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight),
                indicatorView.heightAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight),
                indicatorView.centerXAnchor.constraint(equalTo: deleteAccountButton.centerXAnchor)
                ])
            indicatorView.startAnimating()
        } else {
            loadingIndicatorView?.stopAnimating()
            loadingIndicatorView?.removeFromSuperview()
            loadingIndicatorView = nil
            
            deleteAccountButton.isHidden = false
        }
    }
}

struct AccountDetailsViewModel {
	let navTitle = "Your Account"
}
