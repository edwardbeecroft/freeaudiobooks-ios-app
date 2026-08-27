//
//  UIViewController+Extensions.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 15/01/2019.
//  Copyright © 2019 Ed Beecroft. All rights reserved.
//

import UIKit
import PopupDialog
import SuperwallKit

extension UIViewController {
	
	func hideKeyboardWhenTappedAround() {
		let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
		tap.cancelsTouchesInView = false
		view.addGestureRecognizer(tap)
	}
	
	@objc func dismissKeyboard() {
		view.endEditing(true)
	}
}

extension UIViewController {
    func goToAccountVC() {
        tabBarController?.selectedIndex = Tab.account.rawValue
    }
}

private var scrollViewKey: UInt8 = 0

extension UIViewController {
	public func setupKeyboardAvoiding(forScrollView scrollView: UIScrollView) {
		NotificationCenter.default.addObserver(self, selector: #selector(UIViewController.keyboardWillShowForScrollView(_:)),
											   name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(UIViewController.keyboardWillHideForScrollView(_:)),
											   name: UIResponder.keyboardWillHideNotification, object: nil)
		internalScrollView = scrollView
		
		let dismissKeyboardOnTappedOutside = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
		dismissKeyboardOnTappedOutside.cancelsTouchesInView = false
		scrollView.addGestureRecognizer(dismissKeyboardOnTappedOutside)
	}
	
	public func removeKeyboardNotificationListenersForKeyboardAvoiding() {
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	fileprivate var internalScrollView: UIScrollView! {
		get {
			return objc_getAssociatedObject(self, &scrollViewKey) as? UIScrollView
		}
		set(newValue) {
			objc_setAssociatedObject(self, &scrollViewKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
		}
	}

	@objc private func keyboardWillShowForScrollView(_ notification: Notification) {
		guard let notificationUserInfo = notification.userInfo,
			let keyboardAnimationDuration = notificationUserInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
				return
		}
		let keyboardFrame = (notificationUserInfo[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
		let keyboardFrameConvertedToViewFrame = view.convert(keyboardFrame!, from: nil)
		let options = UIView.AnimationOptions.beginFromCurrentState
		UIView.animate(withDuration: keyboardAnimationDuration, delay: 0, options: options, animations: {
			let insetHeight = (self.internalScrollView.frame.height + self.internalScrollView.frame.origin.y) -
				keyboardFrameConvertedToViewFrame.origin.y
			self.internalScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: insetHeight, right: 0)
			self.internalScrollView.scrollIndicatorInsets  = UIEdgeInsets(top: 0, left: 0, bottom: insetHeight, right: 0)
		})
	}
	
	@objc private func keyboardWillHideForScrollView(_ notification: Notification) {
		guard let notificationUserInfo = notification.userInfo,
			let keyboardAnimationDuration = notificationUserInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
				return
		}
		let options = UIView.AnimationOptions.beginFromCurrentState
		UIView.animate(withDuration: keyboardAnimationDuration, delay: 0, options: options, animations: {
			self.internalScrollView.contentInset = .zero
			self.internalScrollView.scrollIndicatorInsets = .zero
		})
	}
}

extension UIViewController {

    /**
     *  Height of status bar + navigation bar (if navigation bar exist)
     */

    var topbarHeight: CGFloat {
        return (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0) +
            (self.navigationController?.navigationBar.frame.height ?? 0.0)
    }
}

extension UIViewController {

    @discardableResult
    func resumeCachedAudiobookIfAllowed(
        bookInternal: CDBookInternal,
        navigationController: UINavigationController?,
        onBeforePush: (() -> Void)? = nil
    ) -> Bool {
        guard let audioData = bookInternal.cachedAudio else { return false }
        guard let navigationController else { return false }

        if AccountManager.shared.userIsSubscribed, audioData.isTemporaryDownload {
            CoreDataBookInternalAudioManager.shared.promoteTemporaryDownload(bookUUID: bookInternal.contentUUID)
        }

        let audiobookPlayerVC = AudiobookPlayerVC(bookInternal: bookInternal, audioData: audioData)
        audiobookPlayerVC.hidesBottomBarWhenPushed = true
        onBeforePush?()
        navigationController.pushViewController(audiobookPlayerVC, animated: true)
        return true
    }
}

extension UIViewController {
    func presentReadingModePaywall(bookInternal: CDBookInternal?, onUnlocked: @escaping () -> Void) {
        if AccountManager.shared.userIsSubscribed {
            onUnlocked()
            return
        }

        let placement = PaywallPlacement.readingMode
        let handler = PaywallPresentationHandler()
        handler.onPresent { _ in
            DispatchQueue.main.async {
                AnalyticsManager.shared.trackPaywallViewedForPlacement(placement)
            }
        }
        handler.onDismiss { [weak self] _, result in
            guard self != nil else { return }
            DispatchQueue.main.async {
                switch result {
                case .declined:
                    print("No purchased occurred.")
                case .purchased(let product):
                    print("Purchased \(product.productIdentifier)")
                    AnalyticsManager.shared.trackPaywallUserSubscribed(placement: placement, cdBookInternal: bookInternal)
                    onUnlocked()
                case .restored:
                    print("Restored purchases.")
                    AnalyticsManager.shared.trackPaywallRestorePurchasesSuccess()
                    onUnlocked()
                }
            }
        }
        Superwall.shared.register(placement: placement.rawValue, params: nil, handler: handler)
    }

    func showSubscribeSuccessPopup() {
//        HapticFeedbackHelper.shared.triggerSuccessHaptic()
        //
        
        let containerAppearance = PopupDialogContainerView.appearance()
        containerAppearance.cornerRadius = Float(UIConstants.shared.cardCornerRadius)
        
        let subscribeSuccessPopupVC = SubscribeSuccessPopupVC()
        let popup = PopupDialog(viewController: subscribeSuccessPopupVC,
                                buttonAlignment: .horizontal,
                                transitionStyle: .zoomIn,
                                tapGestureDismissal: false,
                                panGestureDismissal: false)
        self.present(popup, animated: true, completion: nil)
    }
    func showPurchasesRestoredSuccessfullyAlert() {
        let okAction = UIAlertAction(title: L10n.ok, style: .default)
        let alertController = UIAlertController(title: "Subscription Restored Successfully",
                                                message: "We have successfully restored your purchases. You may now continue to use the app with your unlocked content!",
                                                preferredStyle: .alert)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
