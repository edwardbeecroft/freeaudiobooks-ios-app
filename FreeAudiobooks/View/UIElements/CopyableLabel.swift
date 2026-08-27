//
//  CopyableLabel.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 01/07/2019.
//  Copyright © 2020 Radically Better Ltd. All rights reserved.
//

import UIKit

class CopyableLabel: UILabel {
	
	override var canBecomeFirstResponder: Bool { return true }
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		sharedInit()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		sharedInit()
	}
	
	override func copy(_ sender: Any?) {
		UIPasteboard.general.string = text
		UIMenuController.shared.setMenuVisible(false, animated: true)
	}
	
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		return action == #selector(copy(_:))
	}
}

// MARK: Actions methods
extension CopyableLabel {
	
	@objc func longPressGestureActionHandler(_ sender: UILongPressGestureRecognizer) {
		becomeFirstResponder()
		
		let menu = UIMenuController.shared
		
		if !menu.isMenuVisible {
			menu.setTargetRect(bounds, in: self)
			menu.setMenuVisible(true, animated: true)
		}
	}
}

// MARK: Helper methods
extension CopyableLabel {
	
	func sharedInit() {
		isUserInteractionEnabled = true
		addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureActionHandler(_:))))
	}
}
