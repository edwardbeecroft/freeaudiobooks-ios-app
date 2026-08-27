//
//  AlertControllers.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 04/09/2020.
//  Copyright © 2020 Radically Better Ltd. All rights reserved.
//

import UIKit


struct AlertControllers {
	static func inappropriateContentAlert(multipleImageUpload: Bool) -> UIAlertController {
		var message = RCValues.shared.string(forKey: .singleImageInappropriateContentMessage)
		if multipleImageUpload {
			message = RCValues.shared.string(forKey: .multipleImagesInappropriateContentMessage)
		}
		let alertController = UIAlertController(title: RCValues.shared.string(forKey: .inappropriateContentImageTitle),
												message: message,
												preferredStyle: .alert)
        let okAction = UIAlertAction(title: L10n.ok, style: .default, handler: nil)
		alertController.addAction(okAction)
		return alertController
	}
	
	static func showPermissionsRequiredToUseCameraPopup() -> UIAlertController? {
		guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return nil }
		
		let title = "Photos Permission Required"
		let message = "To share photos of your exquisite bakes, you must enable camera & photo library access in your iOS notification settings."
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		let enableNotificationsAction = UIAlertAction(title: "Go to Settings", style: .default) { enableTapped in
			DispatchQueue.main.async {
				UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
			}
		}
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alertController.addAction(cancelAction)
		alertController.addAction(enableNotificationsAction)
		
		return alertController
	}
	
	static func networkErrorAlert() -> UIAlertController {
        let title = L10n.networkError
        let message = "Please ensure you have an active internet connection and try again."
		
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: L10n.ok, style: .default, handler: nil)
		alertController.addAction(okAction)
		return alertController
	}
}
