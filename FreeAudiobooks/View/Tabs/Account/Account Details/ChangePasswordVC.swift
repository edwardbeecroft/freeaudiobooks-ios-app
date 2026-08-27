//
//  ChangePasswordVC.swift
//  LiveCard
//
//  Created by Edward Beecroft on 08/10/2018.
//  Copyright © 2018 SnowDrift Labs. All rights reserved.
//

import UIKit
import TextFieldEffects
import FirebaseCore
import FirebaseAuth
import BEMCheckBox
import PopupDialog
import FirebaseFirestore

class ChangePasswordVC: UIViewController, UITextFieldDelegate, BEMCheckBoxDelegate {

	let passwordTextField: CustomHoshiTextField = {
        let tf = CustomHoshiTextField(placeHolderText: "New Password")
        tf.returnKeyType = .done
        tf.keyboardType = .default
        tf.autocapitalizationType = .none
        tf.isSecureTextEntry = true
        return tf
	}()
	
	let updateButton = Buttons.primaryCTA(buttonTitle: "Save")
	
	let successCheckBox = BEMCheckBox()
	let passwordUpdatedSuccessfullyLabel = UILabel()
	
	var timer = Timer()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.title = "Update Password"
		view.backgroundColor = Colours.surfacePrimary
		setupNavBar()
		setupPasswordTextField()
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
	
	func setupPasswordTextField() {
		passwordTextField.delegate = self
		passwordTextField.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(passwordTextField)
		NSLayoutConstraint.activate([
			passwordTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
			passwordTextField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: UIConstants.shared.standardMargin),
			passwordTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -UIConstants.shared.standardMargin),
			passwordTextField.heightAnchor.constraint(equalToConstant: 50)
		])
	}
	
	func setupUpdateButton() {
		updateButton.addTarget(self, action: #selector(updatePressed), for: .touchUpInside)
		updateButton.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(updateButton)
		NSLayoutConstraint.activate([
			updateButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20),
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
		
		passwordUpdatedSuccessfullyLabel.text = "Password updated successfully!"
		passwordUpdatedSuccessfullyLabel.font = Fonts.medium15
		passwordUpdatedSuccessfullyLabel.textColor = Colours.textPrimary
		passwordUpdatedSuccessfullyLabel.textAlignment = .center
		passwordUpdatedSuccessfullyLabel.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(passwordUpdatedSuccessfullyLabel)
		NSLayoutConstraint.activate([
			passwordUpdatedSuccessfullyLabel.topAnchor.constraint(equalTo: successCheckBox.bottomAnchor, constant: UIConstants.shared.standardMargin),
			passwordUpdatedSuccessfullyLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: UIConstants.shared.standardMargin),
			passwordUpdatedSuccessfullyLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -UIConstants.shared.standardMargin),
			passwordUpdatedSuccessfullyLabel.heightAnchor.constraint(equalToConstant: 20)
			])
		passwordUpdatedSuccessfullyLabel.alpha = 0
	}
	
	@objc func updatePressed() {
		self.view.endEditing(true)
		guard let password = passwordTextField.text else {return}
		self.view.isUserInteractionEnabled = false
		
        if Reachability.isConnectedToNetwork() {
            DispatchQueue.main.async {
                Auth.auth().currentUser?.updatePassword(to: password) { (error) in
                    self.view.isUserInteractionEnabled = true
                    if error != nil {
                        if let errCode = AuthErrorCode(rawValue: (error! as NSError).code) {
                            switch errCode {
                            case .weakPassword:
                                self.present(PopupHelper.defaultPopup(title: "Weak password", message: "Please enter a stronger password and try again."), animated: true, completion: nil)
                            case .requiresRecentLogin:
                                self.showReauthVC(newPassword: password)
                            default:
                                print("Create User Error: \(error!)")
                            }
                            return
                        }
                    } else {
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
	
	func showReauthVC(newPassword: String) {
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
					Auth.auth().currentUser?.reauthenticate(with: credential, completion: { (result, error) in
						if error != nil {
							self.view.isUserInteractionEnabled = true
                            if let errCode = AuthErrorCode(rawValue: (error! as NSError).code) {
								switch errCode {
								case .weakPassword:
									self.present(PopupHelper.defaultPopup(title: "Weak password", message: "Please enter a stronger password and try again."), animated: true, completion: nil)
								default:
									print("Create User Error: \(error!)")
								}
							}
							return
						} else {
							// User re-authenticated.
							
							Auth.auth().currentUser?.updatePassword(to: newPassword) { (error) in
								self.view.isUserInteractionEnabled = true
								if error != nil {
                                    if let errCode = AuthErrorCode(rawValue: (error! as NSError).code) {
										switch errCode {
										case .weakPassword:
											self.present(PopupHelper.defaultPopup(title: "Weak password", message: "Please enter a stronger password and try again."), animated: true, completion: nil)
										default:
											print("Create User Error: \(error!)")
										}
									}
									return
								} else {
									self.updateFinished()
								}
							}
						}
					})
			} else {
				self.view.isUserInteractionEnabled = true
				self.present(PopupHelper.defaultPopup(title: "Unable to update password", message: "Please try again."), animated: true, completion: nil)
				return
			}
		}
		buttonOne.titleColor = Colours.grey140
		buttonOne.buttonColor = nil
		
		popup.addButtons([buttonOne, buttonTwo])
		present(popup, animated: true, completion: nil)
	}
	
	func updateFinished() {
		AnalyticsManager.shared.trackChangedPassword()
		passwordTextField.text = ""
		successCheckBox.setOn(true, animated: true)
		
		UIView.animate(withDuration: 0.1) {
			self.passwordUpdatedSuccessfullyLabel.alpha = 1
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
