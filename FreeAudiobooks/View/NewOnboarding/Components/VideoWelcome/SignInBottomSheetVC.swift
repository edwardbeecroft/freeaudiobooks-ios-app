//
//  SignInBottomSheetVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 27/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import AuthenticationServices
import GoogleSignIn
import FirebaseAuth
import CryptoKit
import SafariServices

/// Bottom sheet modal for sign-in options (Apple, Google, Email)
/// Presented from WelcomeVideoVC for returning users
final class SignInBottomSheetVC: BottomSheetController {

    // MARK: - Properties

    weak var coordinator: NewOnboardingCoordinator?
    var signInSuccessHandler: (() -> Void)?

    private var currentNonce: String?

    // MARK: - UI Elements

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.textColor = Colours.textPrimary
        label.text = "Sign In"
        return label
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = Colours.textSecondary
        button.backgroundColor = UIColor(red: 248/255, green: 248/255, blue: 253/255, alpha: 1)
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return button
    }()

    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 233/255, green: 233/255, blue: 235/255, alpha: 1)
        return view
    }()

    private lazy var appleSignInButton: ASAuthorizationAppleIDButton = {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.addTarget(self, action: #selector(appleSignInTapped), for: .touchUpInside)
        button.cornerRadius = UIConstants.shared.onboardingButtonCornerRadius
        return button
    }()

    private lazy var googleSignInButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign in with Google", for: .normal)
        button.setTitleColor(Colours.textPrimary, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 21, weight: .medium)
        button.backgroundColor = Colours.surfaceCard
        button.layer.cornerRadius = UIConstants.shared.onboardingButtonCornerRadius
        button.layer.borderWidth = 1
        button.layer.borderColor = Colours.inputBorder.cgColor

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
        button.setTitle("Continue with email", for: .normal)
        button.setTitleColor(Colours.textPrimary, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 21, weight: .medium)
        button.backgroundColor = Colours.surfaceCard
        button.layer.cornerRadius = UIConstants.shared.onboardingButtonCornerRadius
        button.layer.borderWidth = 1
        button.layer.borderColor = Colours.inputBorder.cgColor

        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let envelope = UIImage(systemName: "envelope", withConfiguration: config)
        button.setImage(envelope, for: .normal)
        button.tintColor = Colours.textPrimary

        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 8)
        button.addTarget(self, action: #selector(emailSignInTapped), for: .touchUpInside)
        return button
    }()

    private let privacyTermsTextView = PrivacyTermsTextView()

    // MARK: - Initialization

    init(coordinator: NewOnboardingCoordinator) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
        self.preferredSheetSizing = .fit
        self.tapToDismissEnabled = true
        self.panToDismissEnabled = true
        self.preferredSheetCornerRadius = 16
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        view.backgroundColor = Colours.surfacePrimary

        view.addSubviewForConstraints(titleLabel)
        view.addSubviewForConstraints(closeButton)
        view.addSubviewForConstraints(dividerView)
        view.addSubviewForConstraints(appleSignInButton)
        view.addSubviewForConstraints(googleSignInButton)
        view.addSubviewForConstraints(emailSignInButton)
        view.addSubviewForConstraints(privacyTermsTextView)
        privacyTermsTextView.delegate = self

        let buttonHeight = UIConstants.shared.onboardingButtonHeight

        NSLayoutConstraint.activate([
            // Header
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            // Divider
            dividerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            dividerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1),

            // Apple button
            appleSignInButton.topAnchor.constraint(equalTo: dividerView.bottomAnchor, constant: 24),
            appleSignInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.shared.standardMargin),
            appleSignInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            appleSignInButton.heightAnchor.constraint(equalToConstant: buttonHeight),

            // Google button
            googleSignInButton.topAnchor.constraint(equalTo: appleSignInButton.bottomAnchor, constant: 12),
            googleSignInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.shared.standardMargin),
            googleSignInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            googleSignInButton.heightAnchor.constraint(equalToConstant: buttonHeight),

            // Email button
            emailSignInButton.topAnchor.constraint(equalTo: googleSignInButton.bottomAnchor, constant: 12),
            emailSignInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.shared.standardMargin),
            emailSignInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            emailSignInButton.heightAnchor.constraint(equalToConstant: buttonHeight),

            // Privacy terms text
            privacyTermsTextView.topAnchor.constraint(equalTo: emailSignInButton.bottomAnchor, constant: 16),
            privacyTermsTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            privacyTermsTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60),
            privacyTermsTextView.heightAnchor.constraint(equalToConstant: 44),
            privacyTermsTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func applyAppearanceColors() {
        titleLabel.textColor = Colours.textPrimary
        closeButton.tintColor = Colours.textSecondary
        closeButton.backgroundColor = Colours.surfaceSecondary
        dividerView.backgroundColor = Colours.separator

        googleSignInButton.backgroundColor = Colours.surfaceCard
        googleSignInButton.setTitleColor(Colours.textPrimary, for: .normal)
        googleSignInButton.layer.borderColor = Colours.inputBorder.cgColor

        emailSignInButton.backgroundColor = Colours.surfaceCard
        emailSignInButton.setTitleColor(Colours.textPrimary, for: .normal)
        emailSignInButton.tintColor = Colours.textPrimary
        emailSignInButton.layer.borderColor = Colours.inputBorder.cgColor
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func appleSignInTapped() {
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

    @objc private func googleSignInTapped() {
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                print("Google Sign In Error: \(error.localizedDescription)")
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
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

    @objc private func emailSignInTapped() {
        // Dismiss bottom sheet first, then present email flow from container
        let successHandler = signInSuccessHandler
        let presentingVC = presentingViewController

        dismiss(animated: true) {
            let emailVC = SignInEmailVC()
            emailVC.signInSuccessHandler = successHandler

            let navController = UINavigationController(rootViewController: emailVC)
            navController.modalPresentationStyle = .fullScreen
            navController.setNavigationBarHidden(true, animated: false)

            presentingVC?.present(navController, animated: true)
        }
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
                return
            }

            // Check if user already exists
            AccountManager.shared.userAlreadyHasDocumentInDatabase { hasAccount in
                DispatchQueue.main.async {
                    if hasAccount {
                        // Existing user - sync and complete
                        AccountManager.shared.syncFullUserWithId(authResult?.user.uid ?? "") { _ in
                            self.dismiss(animated: true) {
                                self.signInSuccessHandler?()
                            }
                        }
                    } else {
                        // New user signing in from welcome - mark auth complete and let them continue onboarding
                        self.coordinator?.dataStore.authMethod = signInMethod
                        AccountManager.shared.addNewDBUserForSocialLogin(
                            firstName: firstName ?? "",
                            lastName: lastName ?? "",
                            email: email ?? "",
                            signupMethod: signInMethod,
                            appleUserIdentifier: appleUserIdentifier
                        ) { success in
                            DispatchQueue.main.async {
                                if success {
                                    // Dismiss and advance to next onboarding step
                                    // saveProgressAuth step will be auto-skipped since authMethod is set
                                    self.dismiss(animated: true) {
                                        self.coordinator?.goToNextScreen()
                                    }
                                } else {
                                    print("Failed to create user document")
                                }
                            }
                        }
                    }
                }
            }
        }
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
}

// MARK: - ASAuthorizationControllerDelegate

extension SignInBottomSheetVC: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
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
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension SignInBottomSheetVC: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}

// MARK: - UITextViewDelegate

extension SignInBottomSheetVC: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if url.absoluteString == "terms" {
            if let termsURL = URL(string: AppConstants.shared.termsURL) {
                let svc = SFSafariViewController(url: termsURL)
                svc.modalPresentationStyle = .formSheet
                present(svc, animated: true)
            }
        } else if url.absoluteString == "privacy" {
            if let privacyURL = URL(string: AppConstants.shared.privacyURL) {
                let svc = SFSafariViewController(url: privacyURL)
                svc.modalPresentationStyle = .formSheet
                present(svc, animated: true)
            }
        }
        return false
    }
}
