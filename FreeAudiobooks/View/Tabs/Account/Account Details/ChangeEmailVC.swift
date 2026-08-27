//
//  ChangeEmailVC.swift
//  LiveCard
//
//  Created by Edward Beecroft on 07/10/2018.
//  Copyright © 2018 SnowDrift Labs. All rights reserved.
//

import UIKit
import TextFieldEffects
import FirebaseCore
import FirebaseAuth
import BEMCheckBox
import PopupDialog
import FirebaseFirestore

class ChangeEmailVC: UIViewController, UITextFieldDelegate, BEMCheckBoxDelegate {
	
	let currentEmaillabel = UILabel()
	
	let emailAddressTextField: CustomHoshiTextField = {
		let tf = CustomHoshiTextField(placeHolderText: "New Email Address")
		tf.returnKeyType = .done
		tf.keyboardType = .emailAddress
		tf.autocapitalizationType = .none
		return tf
	}()
	
	let updateButton = Buttons.primaryCTA(buttonTitle: "Save")
	
	let successCheckBox = BEMCheckBox()
	let emailUpdatedSuccessfullyLabel = UILabel()
	
	var timer = Timer()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.title = "Update Email Address"
		view.backgroundColor = Colours.surfacePrimary
		setupNavBar()
		setupCurrentEmailLabel()
		setupEmailTextField()
		setupUpdateButton()
		setupSuccessCheckboxAndLabel()
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
	
	func setupCurrentEmailLabel() {
		guard let email = Auth.auth().currentUser?.email else {return}
		currentEmaillabel.text = "Current email: \(email)"
		currentEmaillabel.font = Fonts.medium15
		currentEmaillabel.textColor = Colours.textPrimary
		currentEmaillabel.numberOfLines = 0
		currentEmaillabel.lineBreakMode = .byWordWrapping
		currentEmaillabel.textAlignment = .center
		currentEmaillabel.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(currentEmaillabel)
		NSLayoutConstraint.activate([
			currentEmaillabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 25),
			currentEmaillabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: UIConstants.shared.standardMargin),
			currentEmaillabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -UIConstants.shared.standardMargin)
			])
	}
	
	func setupEmailTextField() {
		emailAddressTextField.delegate = self
		emailAddressTextField.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(emailAddressTextField)
		NSLayoutConstraint.activate([
			emailAddressTextField.topAnchor.constraint(equalTo: currentEmaillabel.bottomAnchor, constant: 20),
			emailAddressTextField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: UIConstants.shared.standardMargin),
			emailAddressTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -UIConstants.shared.standardMargin),
			emailAddressTextField.heightAnchor.constraint(equalToConstant: 50)
			])
	}
	
	func setupUpdateButton() {
		updateButton.addTarget(self, action: #selector(updatePressed), for: .touchUpInside)
		updateButton.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(updateButton)
		NSLayoutConstraint.activate([
			updateButton.topAnchor.constraint(equalTo: emailAddressTextField.bottomAnchor, constant: 20),
			updateButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: UIConstants.shared.standardMargin),
			updateButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -UIConstants.shared.standardMargin),
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
		
		emailUpdatedSuccessfullyLabel.text = "Email updated successfully!"
		emailUpdatedSuccessfullyLabel.font = Fonts.medium15
		emailUpdatedSuccessfullyLabel.textColor = Colours.textPrimary
		emailUpdatedSuccessfullyLabel.textAlignment = .center
		emailUpdatedSuccessfullyLabel.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(emailUpdatedSuccessfullyLabel)
		NSLayoutConstraint.activate([
			emailUpdatedSuccessfullyLabel.topAnchor.constraint(equalTo: successCheckBox.bottomAnchor, constant: 20),
			emailUpdatedSuccessfullyLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: UIConstants.shared.standardMargin),
			emailUpdatedSuccessfullyLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -UIConstants.shared.standardMargin),
			emailUpdatedSuccessfullyLabel.heightAnchor.constraint(equalToConstant: 20)
			])
		emailUpdatedSuccessfullyLabel.alpha = 0
	}
	
	@objc func updatePressed() {
		self.view.endEditing(true)
		self.view.isUserInteractionEnabled = false
		
        if Reachability.isConnectedToNetwork() {
            DispatchQueue.main.async {
                guard let uid = Auth.auth().currentUser?.uid, let email = self.emailAddressTextField.text else {return}
                Auth.auth().currentUser?.updateEmail(to: email) { (error) in
                    self.view.isUserInteractionEnabled = true
                    if error != nil {
                        if let errCode = AuthErrorCode(rawValue: (error! as NSError).code) {
                            switch errCode {
                            case .invalidEmail:
                                self.present(PopupHelper.defaultPopup(title: "Invalid email", message: "Please enter a valid email and try again."), animated: true, completion: nil)
                            case .requiresRecentLogin:
                                self.showReauthVC(newEmail: email)
                            default:
                                print("Create User Error: \(error!)")
                            }
                        }
                    } else {
                    
                        AccountManager.shared.user?.emailAddress = email
                        let userTypePath = FirebasePaths.users.rawValue
                        Firestore.firestore().collection(userTypePath).document(uid).setData([FirebaseUserVariables.emailAddress.rawValue: email], merge: true)
                        self.currentEmaillabel.text = "Current email: \(email)"
                        self.updateFinished()
                    }
                }
                return
            }
        } else {
            DispatchQueue.main.async {
                self.present(PopupHelper.noInternetPopup(), animated: true, completion: nil)
                self.view.isUserInteractionEnabled = true
                return
            }
        }
	}
	
	func showReauthVC(newEmail: String) {
		// Create a custom view controller
		let reauthenticateVC = ReauthenticateVC()
		// Create the dialog
		let popup = PopupDialog(viewController: reauthenticateVC, buttonAlignment: .horizontal, transitionStyle: .zoomIn, panGestureDismissal: false)
		
		let buttonOne = CancelButton(title: "Cancel") {}
		
		// Create first button
		let buttonTwo = DefaultButton(title: "Update") {
			self.view.isUserInteractionEnabled = false
			if let emailAddress = reauthenticateVC.emailTextField.text, let password = reauthenticateVC.passwordTextField.text {
				let credential = EmailAuthProvider.credential(withEmail: emailAddress, password: password)
				Auth.auth().currentUser?.reauthenticate(with: credential, completion: { (user, error) in
					if error != nil {
						self.view.isUserInteractionEnabled = true
                        if let errCode = AuthErrorCode(rawValue: (error! as NSError).code) {
							switch errCode {
							case .invalidEmail:
								self.present(PopupHelper.defaultPopup(title: "Invalid email", message: "Please enter a valid email and try again."), animated: true, completion: nil)
							default:
								print("Create User Error: \(error!)")
							}
						}
					} else {
						// User re-authenticated.
						
						Auth.auth().currentUser?.updateEmail(to: newEmail) { (error) in
							self.view.isUserInteractionEnabled = true
							if error != nil {
                                if let errCode = AuthErrorCode(rawValue: (error! as NSError).code) {
									switch errCode {
									case .invalidEmail:
										self.present(PopupHelper.defaultPopup(title: "Invalid email", message: "Please enter a valid email and try again."), animated: true, completion: nil)
									default:
										print("Create User Error: \(error!)")
									}
								}
								return
							}
							guard let uid = Auth.auth().currentUser?.uid else {return}
						
							let userTypePath = FirebasePaths.users.rawValue
							Firestore.firestore().collection(userTypePath).document(uid).setData([FirebaseUserVariables.emailAddress.rawValue: newEmail], merge: true)
							self.currentEmaillabel.text = "Current email: \(newEmail)"
							self.updateFinished()
						}
					}
				})
			} else {
				self.view.isUserInteractionEnabled = true
				self.present(PopupHelper.defaultPopup(title: "Invalid email", message: "Please enter a valid email and try again."), animated: true, completion: nil)
			}
		}
		buttonOne.titleColor = Colours.grey140
		buttonOne.buttonColor = nil
		
		popup.addButtons([buttonOne, buttonTwo])
		present(popup, animated: true, completion: nil)
	}
	
	func updateFinished() {
		AnalyticsManager.shared.trackChangedEmail()
		emailAddressTextField.text = ""
		successCheckBox.setOn(true, animated: true)
		
		UIView.animate(withDuration: 0.1) {
			self.emailUpdatedSuccessfullyLabel.alpha = 1
			self.successCheckBox.alpha = 1
		}
	}
	
	func animationDidStop(for checkBox: BEMCheckBox) {
		timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(popVC), userInfo: nil, repeats: false)
	}
	
//	@objc func hideCheckbox() {
//		UIView.animate(withDuration: 1.0) {
//			self.successCheckBox.alpha = 0
//			self.emailUpdatedSuccessfullyLabel.alpha = 0
//			self.updateButton.isUserInteractionEnabled = true
//		}
//	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.view.endEditing(true)
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		updatePressed()
		textField.resignFirstResponder()
		return true
		
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}
