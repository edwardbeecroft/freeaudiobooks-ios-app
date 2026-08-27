//
//  PopupHelper.swift
//  LiveCard
//
//  Created by Edward Beecroft on 19/08/2018.
//  Copyright © 2018 SnowDrift Labs. All rights reserved.
//

import Foundation
import PopupDialog
import NVActivityIndicatorView
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth


class PopupHelper {
	
	static func defaultPopup(title: String, message: String?) -> PopupDialog {
		
		let style = PopupDialogDefaultView.customStyle.defaultCustomStyle
		setAppearanceForStyle(style: style)
		
		var messageString: String
		
		if let message = message {
			messageString = message
		} else {
			messageString = "Unable to complete request. Please try again."
		}
		
		let popup = PopupDialog(title: title, message: messageString, buttonAlignment: .horizontal, transitionStyle: .fadeIn, panGestureDismissal: true)

        let buttonOne = DefaultButton(title: L10n.ok, action: {
			//
		})
		
		popup.addButtons([buttonOne])
		return popup
	}
	
	static func noInternetPopup(withRetry: Bool = false, gestureDismissal: Bool = true) -> PopupDialog {
		
		let style = PopupDialogDefaultView.customStyle.defaultCustomStyle
		PopupHelper.setAppearanceForStyle(style: style)
		
        let title = L10n.networkError
		let message = "Please ensure you have an active internet connection and try again."
		
		let popup = PopupDialog(title: title, message: message, buttonAlignment: .horizontal, transitionStyle: .fadeIn, panGestureDismissal: gestureDismissal)
		
        let buttonOne = DefaultButton(title: L10n.ok, action: {
			//
		})
		
		popup.addButtons([buttonOne])
		return popup
	}
	
	static func networkErrorPopup(withRetry: Bool = false, gestureDismissal: Bool = true) -> PopupDialog {
		
		let style = PopupDialogDefaultView.customStyle.defaultCustomStyle
		PopupHelper.setAppearanceForStyle(style: style)
		
        let title = L10n.networkError
		let message = "Please ensure you have an active internet connection and try again. Please contact hello@freeaudiobooksapp.com if this problem persists, and we'll aim to resolve in 24 hours."
		
		let popup = PopupDialog(title: title, message: message, buttonAlignment: .horizontal, transitionStyle: .fadeIn, panGestureDismissal: gestureDismissal)
		
        let buttonOne = DefaultButton(title: L10n.ok, action: {
			//
		})
		
		popup.addButtons([buttonOne])
		return popup
	}
	
	static func setAppearanceForStyle(style: PopupDialogDefaultView.customStyle) {
		
		switch style {
		case .defaultCustomStyle:
			
			let dialogAppearance = PopupDialogDefaultView.appearance()
			dialogAppearance.backgroundColor = Colours.surfaceCard
			
            dialogAppearance.titleFont = Fonts.semiBold16
            dialogAppearance.messageFont = Fonts.medium16
			
			dialogAppearance.titleColor           = Colours.textPrimary
			dialogAppearance.titleTextAlignment   = .center
			dialogAppearance.messageColor         = Colours.textSecondary
			dialogAppearance.messageTextAlignment = .center
			
			let buttonAppearance = DefaultButton.appearance()
			
            buttonAppearance.titleFont = Fonts.semiBold15
			buttonAppearance.titleColor     = Colours.ctaForeground
			buttonAppearance.buttonColor    = Colours.ctaBackground
			buttonAppearance.separatorColor = Colours.separator
		
		case .boldCustomStyle:
			print("Bold!")
		}
	}
}

extension PopupDialogDefaultView {
	enum customStyle {
		case defaultCustomStyle
		case boldCustomStyle
	}
}



