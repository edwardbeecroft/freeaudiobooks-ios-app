//
//  ChangeNameUsernameVC.swift
//  FreeAudiobooks
//
//  Created by Codex on 02/04/2026.
//

import UIKit
import NVActivityIndicatorView

final class ChangeNameUsernameVC: UIViewController, UITextFieldDelegate {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let firstNameRow = FormTextEntryView()
    private let lastNameRow = FormTextEntryView()
    private let usernameRow = FormTextEntryView()

    private let usernameHintLabel = UILabel()
    private let saveButton = Buttons.primaryCTA(buttonTitle: "Save")
    private var loadingIndicatorView: NVActivityIndicatorView?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Change Name / Username"
        setupNavBar()
        setupUI()
        populateFields()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard NavigationBarStyler.reapplyIfNeeded(on: self, previousTraitCollection: previousTraitCollection) else { return }
        setupNavBar()
        updateAppearanceColors()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
}

private extension ChangeNameUsernameVC {
    func setupNavBar() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        NavigationBarStyler.apply(to: navigationBar)

        let backButton = UIButton(type: .system)
        let backImage = UIImage(named: "backButtonNavIcon")?.withRenderingMode(.alwaysTemplate)
        backButton.setImage(backImage, for: .normal)
        backButton.tintColor = Colours.textPrimary
        backButton.addTarget(self, action: #selector(popVC), for: .touchUpInside)
        backButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
    }

    @objc func popVC() {
        navigationController?.popViewController(animated: true)
    }

    func setupUI() {
        updateAppearanceColors()

        view.addSubviewForConstraints(scrollView)
        scrollView.addSubviewForConstraints(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 24, right: 0)

        configure(textEntryView: firstNameRow, title: "First name", returnKeyType: .next, autocapitalization: .words)
        configure(textEntryView: lastNameRow, title: "Last name", returnKeyType: .next, autocapitalization: .words)
        configure(textEntryView: usernameRow, title: "Username", returnKeyType: .done, autocapitalization: .none)
        usernameRow.textField.autocorrectionType = .no
        usernameRow.textField.keyboardType = .asciiCapable
        usernameRow.setPlaceholderText("Optional")

        firstNameRow.roundTopCorners()
        lastNameRow.resetRoundedCorners()
        usernameRow.roundBottomCorners()
        usernameRow.hideBottomSplitter()

        usernameHintLabel.font = Fonts.medium13
        usernameHintLabel.textColor = Colours.textTertiary
        usernameHintLabel.numberOfLines = 0
        usernameHintLabel.text = "Usernames must be 4-20 characters and can only use lowercase letters, numbers, and underscores. Leave this blank to use your first name."

        saveButton.addTarget(self, action: #selector(tappedSave), for: .touchUpInside)

        [
            firstNameRow,
            lastNameRow,
            usernameRow,
            usernameHintLabel,
            saveButton
        ].forEach {
            contentView.addSubviewForConstraints($0)
        }

        let sideInset = UIConstants.shared.standardMargin
        NSLayoutConstraint.activate([
            firstNameRow.topAnchor.constraint(equalTo: contentView.topAnchor),
            firstNameRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: sideInset),
            firstNameRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -sideInset),

            lastNameRow.topAnchor.constraint(equalTo: firstNameRow.bottomAnchor),
            lastNameRow.leadingAnchor.constraint(equalTo: firstNameRow.leadingAnchor),
            lastNameRow.trailingAnchor.constraint(equalTo: firstNameRow.trailingAnchor),

            usernameRow.topAnchor.constraint(equalTo: lastNameRow.bottomAnchor),
            usernameRow.leadingAnchor.constraint(equalTo: firstNameRow.leadingAnchor),
            usernameRow.trailingAnchor.constraint(equalTo: firstNameRow.trailingAnchor),

            usernameHintLabel.topAnchor.constraint(equalTo: usernameRow.bottomAnchor, constant: 16),
            usernameHintLabel.leadingAnchor.constraint(equalTo: firstNameRow.leadingAnchor, constant: 16),
            usernameHintLabel.trailingAnchor.constraint(equalTo: usernameRow.textField.trailingAnchor),

            saveButton.topAnchor.constraint(equalTo: usernameHintLabel.bottomAnchor, constant: 24),
            saveButton.leadingAnchor.constraint(equalTo: firstNameRow.leadingAnchor),
            saveButton.trailingAnchor.constraint(equalTo: firstNameRow.trailingAnchor),
            saveButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(textEntryView: FormTextEntryView,
                   title: String,
                   returnKeyType: UIReturnKeyType,
                   autocapitalization: UITextAutocapitalizationType) {
        textEntryView.setIntroText(title)
        textEntryView.textField.delegate = self
        textEntryView.textField.returnKeyType = returnKeyType
        textEntryView.textField.autocapitalizationType = autocapitalization
    }

    func updateAppearanceColors() {
        view.backgroundColor = Colours.surfacePrimary
        contentView.backgroundColor = .clear
    }

    func populateFields() {
        firstNameRow.setTextFieldText(AccountManager.shared.user?.firstName ?? "")
        lastNameRow.setTextFieldText(AccountManager.shared.user?.lastName ?? "")
        usernameRow.setTextFieldText(AccountManager.shared.user?.username ?? "")
    }

    func normalizedUsername(_ rawValue: String?) -> String? {
        let trimmed = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return nil }
        return trimmed.lowercased()
    }

    func isValidUsername(_ username: String) -> Bool {
        let pattern = "^[a-z0-9_]{4,20}$"
        return username.range(of: pattern, options: .regularExpression) != nil
    }

    func showError(message: String) {
        let controller = UIAlertController(title: "Unable to Save Profile", message: message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .default))
        present(controller, animated: true)
    }

    func showSuccess() {
        let controller = UIAlertController(title: "Saved", message: "Your name details have been updated.", preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .default))
        present(controller, animated: true)
    }

    func setSaving(_ isSaving: Bool) {
        [firstNameRow.textField, lastNameRow.textField, usernameRow.textField].forEach {
            $0.isUserInteractionEnabled = !isSaving
        }
        saveButton.isEnabled = !isSaving

        if isSaving {
            saveButton.setTitle("", for: .normal)
            loadingIndicatorView = NVActivityIndicatorView(frame: .zero,
                                                           type: .circleStrokeSpin,
                                                           color: Colours.textPrimary,
                                                           padding: 0)
            guard let loadingIndicatorView else { return }
            view.addSubviewForConstraints(loadingIndicatorView)
            NSLayoutConstraint.activate([
                loadingIndicatorView.centerXAnchor.constraint(equalTo: saveButton.centerXAnchor),
                loadingIndicatorView.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor),
                loadingIndicatorView.widthAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight),
                loadingIndicatorView.heightAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight)
            ])
            loadingIndicatorView.startAnimating()
        } else {
            saveButton.setTitle("Save", for: .normal)
            loadingIndicatorView?.stopAnimating()
            loadingIndicatorView?.removeFromSuperview()
            loadingIndicatorView = nil
        }
    }

    @objc func tappedSave() {
        view.endEditing(true)

        let firstName = firstNameRow.getUserEnteredText()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lastName = lastNameRow.getUserEnteredText()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let username = normalizedUsername(usernameRow.getUserEnteredText())

        guard !firstName.isEmpty else {
            showError(message: "Please enter your first name.")
            return
        }

        guard !lastName.isEmpty else {
            showError(message: "Please enter your last name.")
            return
        }

        if let username, !isValidUsername(username) {
            showError(message: AccountProfileUpdateError.invalidUsername.localizedDescription)
            return
        }

        setSaving(true)
        AccountManager.shared.updateProfile(firstName: firstName,
                                            lastName: lastName,
                                            username: username) { [weak self] result in
            guard let self else { return }

            DispatchQueue.main.async {
                self.setSaving(false)

                switch result {
                case .success(let response):
                    AccountManager.shared.user?.firstName = response.firstName
                    AccountManager.shared.user?.lastName = response.lastName
                    AccountManager.shared.user?.username = response.username
                    self.populateFields()
                    self.showSuccess()
                case .failure(let error):
                    self.showError(message: error.localizedDescription)
                }
            }
        }
    }
}

extension ChangeNameUsernameVC {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === firstNameRow.textField {
            lastNameRow.textField.becomeFirstResponder()
        } else if textField === lastNameRow.textField {
            usernameRow.textField.becomeFirstResponder()
        } else if textField === usernameRow.textField {
            tappedSave()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
