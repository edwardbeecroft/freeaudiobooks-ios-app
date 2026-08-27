//
//  SignInEmailVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 28/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

enum EmailAuthMode {
    case signIn
    case onboardingRegistration

    var emailTitle: String {
        switch self {
        case .signIn:
            return "Sign In"
        case .onboardingRegistration:
            return "Create Account"
        }
    }
}

/// Email entry screen for sign-in flow (matches onboarding design)
final class SignInEmailVC: UIViewController {

    // MARK: - Properties

    private let mode: EmailAuthMode
    var signInSuccessHandler: (() -> Void)?

    // Cal AI colors (matching onboarding)
    private let borderColor = Colours.separator
    private let backButtonBg = UIColor.dynamic(
        light: UIColor(red: 248/255, green: 248/255, blue: 253/255, alpha: 1),
        dark: Colours.surfaceCard
    )
    private let ctaAreaBg = Colours.surfacePrimary

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
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = Colours.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email"
        textField.font = Fonts.regular17
        textField.textColor = Colours.textPrimary
        textField.backgroundColor = Colours.inputBackground
        textField.layer.cornerRadius = UIConstants.shared.cardCornerRadius
        textField.layer.borderWidth = 1
        textField.layer.borderColor = Colours.inputBorder.cgColor
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.keyboardType = .emailAddress
        textField.textContentType = .emailAddress
        textField.returnKeyType = .continue
        textField.delegate = self

        // Add padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftView = paddingView
        textField.leftViewMode = .always

        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
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
        let button = Buttons.primaryCTA(buttonTitle: "Continue")
        button.layer.cornerRadius = UIConstants.shared.onboardingButtonCornerRadius
        button.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()

    // MARK: - Initialization

    init(mode: EmailAuthMode = .signIn) {
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
        applyAppearanceColors()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        emailTextField.becomeFirstResponder()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        applyAppearanceColors()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = Colours.surfacePrimary
        titleLabel.text = mode.emailTitle

        view.addSubview(backButtonContainer)
        backButtonContainer.addSubviewForConstraints(backButton)
        view.addSubviewForConstraints(titleLabel)
        view.addSubviewForConstraints(emailTextField)
        view.addSubview(bottomContainerView)
        bottomContainerView.addSubviewForConstraints(topBorderView)
        bottomContainerView.addSubviewForConstraints(continueButton)

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

            // Email text field
            emailTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            emailTextField.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: margin),
            emailTextField.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -margin),
            emailTextField.heightAnchor.constraint(equalToConstant: 56),

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
            continueButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -margin)
        ])
    }

    private func applyAppearanceColors() {
        view.backgroundColor = Colours.surfacePrimary
        backButtonContainer.backgroundColor = backButtonBg
        titleLabel.textColor = Colours.textPrimary
        emailTextField.textColor = Colours.textPrimary
        emailTextField.backgroundColor = Colours.inputBackground
        emailTextField.layer.borderColor = Colours.inputBorder.cgColor
        bottomContainerView.backgroundColor = ctaAreaBg
        topBorderView.backgroundColor = borderColor
    }

    // MARK: - Actions

    @objc private func backTapped() {
        // Dismiss the entire navigation flow
        dismiss(animated: true)
    }

    @objc private func textFieldDidChange() {
        let email = emailTextField.text ?? ""
        let isValid = isValidEmail(email)
        continueButton.isEnabled = isValid
        continueButton.alpha = isValid ? 1.0 : 0.5
    }

    @objc private func continueTapped() {
        guard let email = emailTextField.text, isValidEmail(email) else { return }

        HapticFeedbackHelper.shared.triggerLightImpactFeedback()

        let passwordVC = SignInPasswordVC(email: email, mode: mode)
        passwordVC.signInSuccessHandler = signInSuccessHandler
        navigationController?.pushViewController(passwordVC, animated: true)
    }

    // MARK: - Validation

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - UITextFieldDelegate

extension SignInEmailVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if continueButton.isEnabled {
            continueTapped()
        }
        return true
    }
}
