//
//  ConfirmDetailsVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 25/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import PopupDialog
import SafariServices
import BetterSegmentedControl

protocol ConfirmDetailsDelegate: AnyObject {
    func completedPersonalDetails()
}

class ConfirmDetailsVC: UIViewController {
    
    private var loadingIndicatorView: NVActivityIndicatorView?
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let emailFormView = FormTextEntryView()
    private let firstNameFormView = FormTextEntryView()
    private let lastNameFormView = FormTextEntryView()
    
    let continueButton = Buttons.primaryCTA(buttonTitle: "Continue")

    private let isInRegistration: Bool
    private var shouldIncludeEmailField: Bool = true
    weak var delegate: ConfirmDetailsDelegate?
    init(isInRegistration: Bool,
         delegate: ConfirmDetailsDelegate) {
        self.isInRegistration = isInRegistration
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colours.surfacePrimary
        setupNavBar()
        setupCTAButton()
        setupScrollView()
        setupStackView()
        
        hideKeyboardWhenTappedAround()
        setupKeyboardAvoiding(forScrollView: scrollView)
        
        populateFields()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard NavigationBarStyler.reapplyIfNeeded(on: self, previousTraitCollection: previousTraitCollection) else { return }
        setupNavBar()
    }
}

extension ConfirmDetailsVC {
    func populateFields() {
        guard let user = AccountManager.shared.user else {
            // Should never be here
            return
        }
        emailFormView.setTextFieldText(user.emailAddress)
        firstNameFormView.setTextFieldText(user.firstName)
        lastNameFormView.setTextFieldText(user.lastName)
    }
}

extension ConfirmDetailsVC {

    func setupNavBar() {
        guard let navigationBar = self.navigationController?.navigationBar else {return}
        navigationBar.tintColor = Colours.textPrimary
        navigationBar.barTintColor = Colours.chromeBackground
        
        navigationController?.view.backgroundColor = Colours.chromeBackground

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Colours.chromeBackground
        appearance.titleTextAttributes = Fonts.navBarTitleTextAttributes
        //            appearance.shadowColor = .white
        appearance.shadowImage = nil//UIImage()
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
        
        title = "Confirm Details"
    }
    
    @objc func popVC() {
        self.navigationController?.popViewController(animated: true)
    }
}

extension ConfirmDetailsVC {
    @objc func saveTapped() {
        var emailAddress: String = AccountManager.shared.user?.emailAddress ?? ""

        if shouldIncludeEmailField {
            guard let enteredEmail = emailFormView.getUserEnteredText(),
                  !enteredEmail.isEmpty else {
                emailFormView.textField.becomeFirstResponder()
                return
            }
            guard enteredEmail.isValidEmailAddress() else {
                showInvalidEmailError()
                return
            }
            emailAddress = enteredEmail
        }

        guard
            let firstName = firstNameFormView.getUserEnteredText(),
            !firstName.isEmpty else {
            firstNameFormView.textField.becomeFirstResponder()
            return
        }
        guard
            let lastName = lastNameFormView.getUserEnteredText(),
            !lastName.isEmpty else {
            lastNameFormView.textField.becomeFirstResponder()
            return
        }
        
        showLoadingIndicator(show: true)
        
        // Continue
        let data: [String: Any] = [
            FirebaseUserVariables.emailAddress.rawValue: emailAddress,
            FirebaseUserVariables.firstName.rawValue: firstName,
            FirebaseUserVariables.lastName.rawValue: lastName
        ]
        AccountManager.shared.updateUserWithData(data) { success in
            if success {
                DispatchQueue.main.async {
                    AccountManager.shared.user?.emailAddress = emailAddress
                    AccountManager.shared.user?.firstName = firstName
                    AccountManager.shared.user?.lastName = lastName
                    self.delegate?.completedPersonalDetails()
                }
            } else {
                DispatchQueue.main.async {
                    self.showLoadingIndicator(show: false)
                    self.showDataSaveError()
                }
            }
        }
    }
    func showInvalidEmailError() {
        let okAction = UIAlertAction(title: "Ok", style: .default) { [weak self] okTapped in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.emailFormView.becomeFirstResponder()
            }
        }
        let alertController = UIAlertController(title: "Email Invalid",
                                                message: "The email address you have entered appears to be invalid. Please double check your entry and try again.", preferredStyle: .alert)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    func showDataSaveError() {
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let retryAction = UIAlertAction(title: "Retry", style: .default) { [weak self] retryTapped in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.saveTapped()
            }
        }
        let alertController = UIAlertController(title: "Network Error",
                                                message: "Please ensure you have an active internet connection and try again.", preferredStyle: .alert)
        alertController.addAction(cancelAction)
        alertController.addAction(retryAction)
        present(alertController, animated: true, completion: nil)
    }
    func showLoadingIndicator(show: Bool) {
        if show {
            guard loadingIndicatorView == nil else { return }
            
            continueButton.alpha = 0
            
            loadingIndicatorView = NVActivityIndicatorView(frame: CGRect.zero, type: NVActivityIndicatorType.circleStrokeSpin, color: Colours.textPrimary, padding: 0)
            guard let indicatorView = loadingIndicatorView else { return }
            
            indicatorView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(indicatorView)
            NSLayoutConstraint.activate([
                indicatorView.centerYAnchor.constraint(equalTo: continueButton.centerYAnchor),
                indicatorView.centerXAnchor.constraint(equalTo: continueButton.centerXAnchor),
                indicatorView.widthAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight),
                indicatorView.heightAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight),
            ])
            indicatorView.startAnimating()
        } else {
            
            loadingIndicatorView?.stopAnimating()
            loadingIndicatorView?.removeFromSuperview()
            loadingIndicatorView = nil
            
            continueButton.alpha = 1
        }
    }
}

extension ConfirmDetailsVC: UIScrollViewDelegate {
    func setupScrollView() {
        scrollView.alwaysBounceVertical = true
        view.addSubviewForConstraints(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -20)
        ])
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false

//         scrollView.contentInsetAdjustmentBehavior = .never
//         scrollView.contentInset = UIEdgeInsets(top: 88, left: 0, bottom: 34, right: 0)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
            contentView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
}

extension ConfirmDetailsVC {
    func setupCTAButton() {
        continueButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        
        view.addSubviewForConstraints(continueButton)
        NSLayoutConstraint.activate([
            continueButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -UIConstants.shared.standardMargin),
            continueButton.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: UIConstants.shared.standardMargin),
            continueButton.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -UIConstants.shared.standardMargin),
            continueButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    func setupStackView() {
        if let user = AccountManager.shared.user {
            shouldIncludeEmailField = !user.emailAddress.isValidEmailAddress()
        }
        
        var subviewsToAdd = [firstNameFormView, lastNameFormView]
        if shouldIncludeEmailField {
            emailFormView.setIntroText("Email address")
            emailFormView.roundTopCorners()
            emailFormView.textField.keyboardType = .emailAddress
            emailFormView.textField.autocapitalizationType = .none
            emailFormView.textField.delegate = self
            subviewsToAdd.insert(emailFormView, at: 0)
        } else {
            firstNameFormView.roundTopCorners()
        }
        
        firstNameFormView.setIntroText("First name")
        firstNameFormView.textField.delegate = self
        firstNameFormView.textField.autocapitalizationType = .words
        
        lastNameFormView.setIntroText("Last name")
        lastNameFormView.textField.delegate = self
        lastNameFormView.textField.autocapitalizationType = .words
        
        lastNameFormView.roundBottomCorners()
        lastNameFormView.hideBottomSplitter()
        
        let stackView = UIStackView(arrangedSubviews: subviewsToAdd)
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 20
        
        [emailFormView, firstNameFormView, lastNameFormView].forEach {
            stackView.setCustomSpacing(0, after: $0)
        }
        
        contentView.addSubviewForConstraints(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UIConstants.shared.standardMargin),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UIConstants.shared.standardMargin)
        ])
    }
}

extension ConfirmDetailsVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let textFieldText: NSString = (textField.text ?? "") as NSString
        let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string)
        
        if
            let text = textField.text,
            txtAfterUpdate.count < text.count {
            return true
        }
        let numberOfChars = txtAfterUpdate.count
        
        if textField == firstNameFormView.textField || textField == lastNameFormView.textField {
            let maxLength = 40
            return numberOfChars <= maxLength
        } else {
            // For the email - just a safety net
            let maxLength = 50
            return numberOfChars <= maxLength
        }
    }
}
