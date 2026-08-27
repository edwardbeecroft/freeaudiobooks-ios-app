//
//  ResizableButton.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 19/06/2019.
//  Copyright © 2020 Radically Better Ltd. All rights reserved.
//

import UIKit

class ResizableButton: UIButton {
	override var intrinsicContentSize: CGSize {
		let labelSize = titleLabel?.sizeThatFits(CGSize(width: frame.size.width, height: CGFloat.greatestFiniteMagnitude)) ?? .zero
		let desiredButtonSize = CGSize(width: labelSize.width + titleEdgeInsets.left + titleEdgeInsets.right + 20, height: labelSize.height + titleEdgeInsets.top + titleEdgeInsets.bottom)
		
		return desiredButtonSize
	}
	
	override func setTitle(_ title: String?, for state: UIControl.State) {
		super.setTitle(title, for: state)
		layoutIfNeeded()
	}
}
