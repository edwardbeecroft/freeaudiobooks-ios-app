//
//  NoPaddingTextView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 20/10/2020.
//  Copyright © 2020 Radically Better Ltd Technologies. All rights reserved.
//

import UIKit

class NoPaddingTextView: UITextView {
	
	override init(frame: CGRect, textContainer: NSTextContainer?) {
		super.init(frame: frame, textContainer: textContainer)
        
        textContainerInset = UIEdgeInsets.zero
        self.textContainer.lineFragmentPadding = 0
        isScrollEnabled = false
        isEditable = false
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
	}

	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		return false
	}
}
