//
//  ReauthenticateVC.swift
//  LiveCard
//
//  Created by Edward Beecroft on 07/10/2018.
//  Copyright © 2018 SnowDrift Labs. All rights reserved.
//

import UIKit
import TextFieldEffects

class ReauthenticateVC: UIViewController {
	
	let titleLabel = UILabel()
	let titleSplitterView = UIView()
	
	let emailTextField: CustomHoshiTextField = {
        let tf = CustomHoshiTextField(placeHolderText: "Current email address")
        tf.returnKeyType = .done
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
	}()
	
	let passwordTextField: CustomHoshiTextField = {
        let tf = CustomHoshiTextField(placeHolderText: "Current password")
        tf.returnKeyType = .done
        tf.keyboardType = .default
        tf.autocapitalizationType = .none
        tf.isSecureTextEntry = true
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//		view.translatesAutoresizingMaskIntoConstraints = false
		//		view.widthAnchor.constraint(equalToConstant: 40).isActive = true
		view.heightAnchor.constraint(equalToConstant: 210).isActive = true
		
		titleLabel.text = "Reauthentication required"
		titleLabel.font = Fonts.semiBold15
		titleLabel.textColor = Colours.textPrimary
		titleLabel.textAlignment = .center
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		
		view.addSubview(titleLabel)
		titleLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
		titleLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: UIConstants.shared.standardMargin).isActive = true
		titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
		titleLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -UIConstants.shared.standardMargin).isActive = true
		
		titleSplitterView.backgroundColor = Colours.grey210
		titleSplitterView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(titleSplitterView)
		NSLayoutConstraint.activate([
			titleSplitterView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2),
			titleSplitterView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
			titleSplitterView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			titleSplitterView.heightAnchor.constraint(equalToConstant: 1)
			])
		
		view.addSubview(emailTextField)
		emailTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
		emailTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
		emailTextField.topAnchor.constraint(equalTo: titleSplitterView.bottomAnchor, constant: 15).isActive = true
		emailTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
		
		view.addSubview(passwordTextField)
		passwordTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
		passwordTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
		passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 10).isActive = true
		passwordTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
		passwordTextField.isSecureTextEntry = true
		
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}
