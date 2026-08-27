//
//  SaveProgressAuthVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import AuthenticationServices
import GoogleSignIn
import FirebaseAuth
import CryptoKit
import NVActivityIndicatorView

/// Save your progress / sign in screen (Screen 19)
/// Mandatory authentication - no skip option
class SaveProgressAuthVC: BaseNewOnboardingVC {

    override var step: NewOnboardingStep { .saveProgressAuth }
    override var showsContinueButton: Bool { false }

    private let emailButtonInkColor = UIColor.dynamic(
        light: UIColor.black.withAlphaComponent(0.56),
        dark: UIColor.white.withAlphaComponent(0.58)
    )
    private let googleButtonBackgroundColor = UIColor.dynamic(
        light: UIColor(hexString: "F1F1F4"),
        dark: Colours.surfaceCard
    )
    private let googleButtonBorderColor = UIColor.dynamic(
        light: UIColor(hexString: "D1D1D6"),
        dark: Colours.inputBorder
    )

    // For Apple Sign In nonce
    private var currentNonce: String?

    // Loading indicator
    private var loadingIndicatorView: NVActivityIndicatorView?

    // MARK: - UI Elements

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = Colours.textPrimary
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    private lazy var appleSignInButton: ASAuthorizationAppleIDButton = {
        let style: ASAuthorizationAppleIDButton.Style = traitCollection.userInterfaceStyle == .dark ? .white : .black
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: style)
        button.addTarget(self, action: #selector(appleSignInTapped), for: .touchUpInside)
        button.cornerRadius = UIConstants.shared.onboardingButtonCornerRadius
        return button
    }()

    private lazy var googleSignInButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign in with Google", for: .normal)
        button.setTitleColor(Colours.textPrimary, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 21, weight: .medium)
        button.backgroundColor = googleButtonBackgroundColor
        button.layer.cornerRadius = UIConstants.shared.onboardingButtonCornerRadius
        button.layer.borderWidth = 1
        button.layer.borderColor = googleButtonBorderColor.cgColor

        if let googleLogo = UIImage(named: "google-onboarding") {
            // Resize the image to fit nicely in the button
            let targetSize = CGSize(width: 22, height: 22)
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            let resizedImage = renderer.image { _ in
                googleLogo.draw(in: CGRect(origin: .zero, size: targetSize))
            }
            button.setImage(resizedImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }

        // Adjust insets to position logo more to the left like Apple button
        button.contentHorizontalAlignment = .center
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 8)
        button.addTarget(self, action: #selector(googleSignInTapped), for: .touchUpInside)
        return button
    }()

    private lazy var emailSignInButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign in with Email", for: .normal)
        button.setTitleColor(emailButtonInkColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 21, weight: .medium)
        button.backgroundColor = .clear
        button.tintColor = emailButtonInkColor
        button.layer.cornerRadius = UIConstants.shared.onboardingButtonCornerRadius
        button.layer.borderWidth = 1
        button.layer.borderColor = emailButtonInkColor.cgColor

        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let envelope = UIImage(systemName: "envelope", withConfiguration: config)
        button.setImage(envelope, for: .normal)
        button.contentHorizontalAlignment = .center
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 8)
        button.addTarget(self, action: #selector(emailSignInTapped), for: .touchUpInside)
        return button
    }()

    private lazy var authButtonsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [appleSignInButton, googleSignInButton, emailSignInButton])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 12
        return stackView
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applyAppearanceColors()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        applyAppearanceColors()
    }

    // MARK: - Setup

    private func setupUI() {
        titleLabel.text = RCValues.shared.string(forKey: .onbSaveProgressAuthTitle)

        contentView.addSubviewForConstraints(titleLabel)
        contentView.addSubviewForConstraints(authButtonsStackView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),

            authButtonsStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            authButtonsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            authButtonsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            appleSignInButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.onboardingButtonHeight),
            googleSignInButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.onboardingButtonHeight),
            emailSignInButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.onboardingButtonHeight)
        ])
    }

    // MARK: - Loading Indicator

    private func showLoadingIndicator(show: Bool) {
        view.isUserInteractionEnabled = !show
        appleSignInButton.alpha = show ? 0 : 1
        googleSignInButton.alpha = show ? 0 : 1
        emailSignInButton.alpha = show ? 0 : 1

        if show {
            loadingIndicatorView = NVActivityIndicatorView(
                frame: .zero,
                type: .circleStrokeSpin,
                color: Colours.textPrimary,
                padding: 0
            )
            guard let indicatorView = loadingIndicatorView else { return }

            contentView.addSubviewForConstraints(indicatorView)
            NSLayoutConstraint.activate([
                indicatorView.centerXAnchor.constraint(equalTo: googleSignInButton.centerXAnchor),
                indicatorView.centerYAnchor.constraint(equalTo: googleSignInButton.centerYAnchor),
                indicatorView.widthAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight),
                indicatorView.heightAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight)
            ])
            indicatorView.startAnimating()
        } else {
            loadingIndicatorView?.stopAnimating()
            loadingIndicatorView?.removeFromSuperview()
        }
    }

    // MARK: - Apple Sign In

    @objc private func appleSignInTapped() {
        AnalyticsManager.shared.trackOnbSaveProgressAuthAppleTapped()

        let nonce = randomNonceString()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email, .fullName]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // MARK: - Google Sign In

    @objc private func googleSignInTapped() {
        AnalyticsManager.shared.trackOnbSaveProgressAuthGoogleTapped()
        showLoadingIndicator(show: true)

        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                print("Google Sign In Error: \(error.localizedDescription)")
                self.showLoadingIndicator(show: false)
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self.showLoadingIndicator(show: false)
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            self.signInToFirebase(
                with: credential,
                firstName: user.profile?.givenName,
                lastName: user.profile?.familyName,
                email: user.profile?.email,
                signInMethod: SignInMethod.google.rawValue
            )
        }
    }

    // MARK: - Email Sign In

    @objc private func emailSignInTapped() {
        AnalyticsManager.shared.trackOnbSaveProgressAuthEmailTapped()

        let emailVC = SignInEmailVC(mode: .onboardingRegistration)
        emailVC.signInSuccessHandler = { [weak self] in
            self?.completeAuth(with: SignInMethod.manual.rawValue)
        }

        let navController = UINavigationController(rootViewController: emailVC)
        navController.modalPresentationStyle = .fullScreen
        navController.setNavigationBarHidden(true, animated: false)
        present(navController, animated: true)
    }

    // MARK: - Firebase Auth

    private func signInToFirebase(
        with credential: AuthCredential,
        firstName: String?,
        lastName: String?,
        email: String?,
        signInMethod: String,
        appleUserIdentifier: String? = nil
    ) {
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            guard let self = self else { return }

            if let error = error {
                print("Firebase Auth Error: \(error.localizedDescription)")
                self.showLoadingIndicator(show: false)
                return
            }

            // Check if user already exists
            AccountManager.shared.userAlreadyHasDocumentInDatabase { hasAccount in
                if hasAccount {
                    // Existing user - just sync and proceed
                    DispatchQueue.main.async {
                        AnalyticsManager.shared.trackUserLoggedIn()
                        self.completeAuth(with: signInMethod)
                    }
                } else {
                    // New user - create Firestore document (onboarding data pulled from UserDefaults)
                    AccountManager.shared.addNewDBUserForSocialLogin(
                        firstName: firstName ?? "",
                        lastName: lastName ?? "",
                        email: email ?? "",
                        signupMethod: signInMethod,
                        appleUserIdentifier: appleUserIdentifier
                    ) { success in
                        DispatchQueue.main.async {
                            if success {
                                self.completeAuth(with: signInMethod)
                            } else {
                                print("Failed to create user document")
                                self.showLoadingIndicator(show: false)
                            }
                        }
                    }
                }
            }
        }
    }

    private func completeAuth(with authMethod: String) {
        coordinator.dataStore.authMethod = authMethod
        AnalyticsManager.shared.trackOnbSaveProgressAuthComplete(authMethod: authMethod)
        coordinator.goToNextScreen()
    }

    // MARK: - Nonce Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }

    private func applyAppearanceColors() {
        titleLabel.textColor = Colours.textPrimary
        googleSignInButton.backgroundColor = googleButtonBackgroundColor
        googleSignInButton.setTitleColor(Colours.textPrimary, for: .normal)
        googleSignInButton.layer.borderColor = googleButtonBorderColor.cgColor
        emailSignInButton.backgroundColor = .clear
        emailSignInButton.setTitleColor(emailButtonInkColor, for: .normal)
        emailSignInButton.tintColor = emailButtonInkColor
        emailSignInButton.layer.borderColor = emailButtonInkColor.cgColor
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension SaveProgressAuthVC: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        showLoadingIndicator(show: true)

        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            showLoadingIndicator(show: false)
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        let userIdentifier = appleIDCredential.user
        AppleSignInUserDefaults.appleUserId = userIdentifier

        // Store name in UserDefaults in case Apple doesn't return it on subsequent sign-ins
        if let givenName = appleIDCredential.fullName?.givenName {
            AppleSignInUserDefaults.givenName = givenName
        }
        if let familyName = appleIDCredential.fullName?.familyName {
            AppleSignInUserDefaults.familyName = familyName
        }

        signInToFirebase(
            with: credential,
            firstName: appleIDCredential.fullName?.givenName ?? AppleSignInUserDefaults.givenName,
            lastName: appleIDCredential.fullName?.familyName ?? AppleSignInUserDefaults.familyName,
            email: appleIDCredential.email,
            signInMethod: SignInMethod.apple.rawValue,
            appleUserIdentifier: userIdentifier
        )
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign In Error: \(error.localizedDescription)")
        showLoadingIndicator(show: false)
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension SaveProgressAuthVC: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}
