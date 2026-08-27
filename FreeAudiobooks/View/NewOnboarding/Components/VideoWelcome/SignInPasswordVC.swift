//
//  SignInPasswordVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 28/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import FirebaseAuth
import Darwin

/// Password entry screen for sign-in flow (matches onboarding design)
final class SignInPasswordVC: UIViewController {

    // MARK: - Properties

    private let email: String
    private let mode: EmailAuthMode
    var signInSuccessHandler: (() -> Void)?

    // Cal AI colors (matching onboarding)
    private let borderColor = Colours.separator
    private let backButtonBg = UIColor.dynamic(
        light: UIColor(red: 248/255, green: 248/255, blue: 253/255, alpha: 1),
        dark: Colours.surfaceCard
    )
    private let ctaAreaBg = Colours.surfacePrimary
    private let errorColor = UIColor(red: 220/255, green: 53/255, blue: 69/255, alpha: 1) // Red for errors

    // MARK: - UI Elements

    private lazy var backButtonContainer: UIView = {
        let view = UIView()
        view.backgroundColor = backButtonBg
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "back-arrow-full"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter Password"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = Colours.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.regular15
        label.textColor = Colours.subtext
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Password"
        textField.font = Fonts.regular17
        textField.textColor = Colours.textPrimary
        textField.backgroundColor = Colours.inputBackground
        textField.layer.cornerRadius = UIConstants.shared.cardCornerRadius
        textField.layer.borderWidth = 1
        textField.layer.borderColor = Colours.inputBorder.cgColor
        textField.isSecureTextEntry = true
        textField.textContentType = mode == .onboardingRegistration ? .newPassword : .password
        textField.returnKeyType = .done
        textField.delegate = self

        // Add padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftView = paddingView
        textField.leftViewMode = .always

        // Add show/hide password button with right padding
        let toggleButton = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        toggleButton.setImage(UIImage(systemName: "eye", withConfiguration: config), for: .normal)
        toggleButton.setImage(UIImage(systemName: "eye.slash", withConfiguration: config), for: .selected)
        toggleButton.tintColor = Colours.subtext
        toggleButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        toggleButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)

        // Wrap in container for right padding
        let rightPadding: CGFloat = 8
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 44 + rightPadding, height: 44))
        toggleButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        containerView.addSubview(toggleButton)
        textField.rightView = containerView
        textField.rightViewMode = .always

        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.regular14
        label.textColor = UIColor(red: 220/255, green: 53/255, blue: 69/255, alpha: 1)
        label.numberOfLines = 0
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var forgotPasswordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Forgot password?", for: .normal)
        button.setTitleColor(Colours.textSecondary, for: .normal)
        button.titleLabel?.font = Fonts.medium14
        button.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var bottomContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = ctaAreaBg
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var topBorderView: UIView = {
        let view = UIView()
        view.backgroundColor = borderColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var continueButton: UIButton = {
        let button = Buttons.primaryCTA(buttonTitle: primaryButtonTitle)
        button.layer.cornerRadius = UIConstants.shared.onboardingButtonCornerRadius
        button.addTarget(self, action: #selector(primaryActionTapped), for: .touchUpInside)
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    // MARK: - Initialization

    init(email: String, mode: EmailAuthMode = .signIn) {
        self.email = email
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        emailLabel.text = email
        configureForMode()
        applyAppearanceColors()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        passwordTextField.becomeFirstResponder()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        applyAppearanceColors()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = Colours.surfacePrimary

        view.addSubview(backButtonContainer)
        backButtonContainer.addSubviewForConstraints(backButton)
        view.addSubviewForConstraints(titleLabel)
        view.addSubviewForConstraints(emailLabel)
        view.addSubviewForConstraints(passwordTextField)
        view.addSubviewForConstraints(errorLabel)
        view.addSubviewForConstraints(forgotPasswordButton)
        view.addSubview(bottomContainerView)
        bottomContainerView.addSubviewForConstraints(topBorderView)
        bottomContainerView.addSubviewForConstraints(continueButton)
        continueButton.addSubview(loadingIndicator)

        let margin = UIConstants.shared.standardMargin

        NSLayoutConstraint.activate([
            // Back button
            backButtonContainer.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: margin),
            backButtonContainer.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 16),
            backButtonContainer.widthAnchor.constraint(equalToConstant: 40),
            backButtonContainer.heightAnchor.constraint(equalToConstant: 40),

            backButton.centerXAnchor.constraint(equalTo: backButtonContainer.centerXAnchor),
            backButton.centerYAnchor.constraint(equalTo: backButtonContainer.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 20),
            backButton.heightAnchor.constraint(equalToConstant: 20),

            // Title
            titleLabel.topAnchor.constraint(equalTo: backButtonContainer.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: margin),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -margin),

            // Email label
            emailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            emailLabel.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: margin),
            emailLabel.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -margin),

            // Password text field
            passwordTextField.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 24),
            passwordTextField.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: margin),
            passwordTextField.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -margin),
            passwordTextField.heightAnchor.constraint(equalToConstant: 56),

            // Error label
            errorLabel.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 8),
            errorLabel.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: margin),
            errorLabel.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -margin),

            // Forgot password button
            forgotPasswordButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 12),
            forgotPasswordButton.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: margin),

            // Bottom container
            bottomContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            topBorderView.topAnchor.constraint(equalTo: bottomContainerView.topAnchor),
            topBorderView.leadingAnchor.constraint(equalTo: bottomContainerView.leadingAnchor),
            topBorderView.trailingAnchor.constraint(equalTo: bottomContainerView.trailingAnchor),
            topBorderView.heightAnchor.constraint(equalToConstant: 1),

            continueButton.topAnchor.constraint(equalTo: bottomContainerView.topAnchor, constant: 16),
            continueButton.leadingAnchor.constraint(equalTo: bottomContainerView.leadingAnchor, constant: margin),
            continueButton.trailingAnchor.constraint(equalTo: bottomContainerView.trailingAnchor, constant: -margin),
            continueButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.onboardingButtonHeight),
            continueButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -margin),

            // Loading indicator centered in button
            loadingIndicator.centerXAnchor.constraint(equalTo: continueButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: continueButton.centerYAnchor)
        ])
    }

    // MARK: - Actions

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func togglePasswordVisibility(_ sender: UIButton) {
        sender.isSelected.toggle()
        passwordTextField.isSecureTextEntry = !sender.isSelected
    }

    @objc private func textFieldDidChange() {
        let password = passwordTextField.text ?? ""
        let isValid = !password.isEmpty
        continueButton.isEnabled = isValid
        continueButton.alpha = isValid ? 1.0 : 0.5

        // Hide error when user starts typing again
        if errorLabel.alpha > 0 {
            UIView.animate(withDuration: 0.2) {
                self.errorLabel.alpha = 0
            }
            passwordTextField.layer.borderColor = Colours.inputBorder.cgColor
        }
    }

    @objc private func forgotPasswordTapped() {
        guard mode == .signIn else { return }

        // Send password reset email
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let error = error {
                    self.showError(error.localizedDescription)
                } else {
                    self.showSuccessAlert()
                }
            }
        }
    }

    @objc private func primaryActionTapped() {
        guard let password = passwordTextField.text, !password.isEmpty else { return }

        HapticFeedbackHelper.shared.triggerLightImpactFeedback()
        setLoading(true)

        if mode == .onboardingRegistration {
            registerForOnboarding(with: password)
        } else if AppConstants.isDebugAuthRegistrationEnabled {
            registerForDebug(with: password)
        } else {
            signIn(with: password)
        }
    }

    private func signIn(with password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.setLoading(false)

                if let error = error as NSError? {
                    self.handleAuthError(error)
                    return
                }

                // Success - sync user data and call handler
                AccountManager.shared.syncFullUserWithId(authResult?.user.uid ?? "") { _ in
                    DispatchQueue.main.async {
                        self.completeAuthFlow()
                    }
                }
            }
        }
    }

    private func registerForOnboarding(with password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let error = error as NSError? {
                    let errorCode = AuthErrorCode(rawValue: error.code)
                    if errorCode == .emailAlreadyInUse {
                        self.signIn(with: password)
                    } else {
                        self.setLoading(false)
                        self.handleRegistrationError(error)
                    }
                    return
                }

                AccountManager.shared.addNewDBUserForEmailRegistration(
                    firstName: "",
                    lastName: "",
                    email: authResult?.user.email ?? self.email
                ) { success in
                    DispatchQueue.main.async {
                        if success {
                            self.completeAuthFlow()
                        } else {
                            self.setLoading(false)
                            self.showError("We couldn't finish creating your account. Please try again.")
                        }
                    }
                }
            }
        }
    }

    private func registerForDebug(with password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.setLoading(false)

                if let error = error as NSError? {
                    self.handleRegistrationError(error)
                    return
                }

                AccountManager.shared.userAlreadyHasDocumentInDatabase { hasAccount in
                    DispatchQueue.main.async {
                        if hasAccount {
                            self.showDebugRegistrationCompleteAlert()
                            return
                        }

                        AccountManager.shared.addNewDBUserForEmailRegistration(
                            firstName: "Kelly",
                            lastName: "Fox",
                            email: authResult?.user.email ?? self.email
                        ) { success in
                            DispatchQueue.main.async {
                                if success {
                                    self.showDebugRegistrationCompleteAlert()
                                } else {
                                    self.showError("We couldn't finish creating your account. Please try again.")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var primaryButtonTitle: String {
        switch mode {
        case .signIn:
            return "Sign In"
        case .onboardingRegistration:
            return "Create Account"
        }
    }

    private var titleText: String {
        switch mode {
        case .signIn:
            return "Enter Password"
        case .onboardingRegistration:
            return "Create Password"
        }
    }

    private func configureForMode() {
        titleLabel.text = titleText
        forgotPasswordButton.isHidden = mode == .onboardingRegistration
        continueButton.setTitle(primaryButtonTitle, for: .normal)
    }

    private func completeAuthFlow() {
        dismiss(animated: true) {
            self.signInSuccessHandler?()
        }
    }

    // MARK: - Error Handling

    private func handleAuthError(_ error: NSError) {
        let errorCode = AuthErrorCode(rawValue: error.code)

        switch errorCode {
        case .userNotFound:
            showError("No account found with this email")
        case .wrongPassword, .invalidCredential:
            showError("Incorrect password")
        case .tooManyRequests:
            showError("Too many attempts. Please try again later.")
        case .networkError:
            showError("Network error. Please check your connection.")
        default:
            showError(error.localizedDescription)
        }
    }

    private func handleRegistrationError(_ error: NSError) {
        let errorCode = AuthErrorCode(rawValue: error.code)

        switch errorCode {
        case .emailAlreadyInUse:
            showError("An account already exists with this email")
        case .weakPassword:
            showError("Password must be at least 6 characters")
        case .invalidEmail:
            showError("Please enter a valid email address")
        case .networkError:
            showError("Network error. Please check your connection.")
        default:
            showError(error.localizedDescription)
        }
    }

    private func showError(_ message: String) {
        errorLabel.text = message
        passwordTextField.layer.borderColor = errorColor.cgColor

        UIView.animate(withDuration: 0.2) {
            self.errorLabel.alpha = 1
        }

        HapticFeedbackHelper.shared.triggerLightImpactFeedback()
    }

    private func showSuccessAlert() {
        let alert = UIAlertController(
            title: "Password Reset Email Sent",
            message: "Check your inbox for instructions to reset your password.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showDebugRegistrationCompleteAlert() {
        let alert = UIAlertController(
            title: "Account Created",
            message: "Please close and restart the app, and adjust the debug toggle.",
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(title: "Close App", style: .destructive) { _ in
                UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    exit(0)
                }
            }
        )
        present(alert, animated: true)
    }

    // MARK: - Loading State

    private func setLoading(_ loading: Bool) {
        continueButton.isEnabled = !loading
        continueButton.setTitle(loading ? "" : primaryButtonTitle, for: .normal)

        if loading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }

        passwordTextField.isEnabled = !loading
        backButton.isEnabled = !loading
    }

    private func applyAppearanceColors() {
        view.backgroundColor = Colours.surfacePrimary
        backButtonContainer.backgroundColor = backButtonBg
        titleLabel.textColor = Colours.textPrimary
        emailLabel.textColor = Colours.textSecondary
        passwordTextField.textColor = Colours.textPrimary
        passwordTextField.backgroundColor = Colours.inputBackground
        if errorLabel.alpha == 0 {
            passwordTextField.layer.borderColor = Colours.inputBorder.cgColor
        }
        forgotPasswordButton.setTitleColor(Colours.textSecondary, for: .normal)
        bottomContainerView.backgroundColor = ctaAreaBg
        topBorderView.backgroundColor = borderColor
    }
}

// MARK: - UITextFieldDelegate

extension SignInPasswordVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if continueButton.isEnabled {
            primaryActionTapped()
        }
        return true
    }
}
