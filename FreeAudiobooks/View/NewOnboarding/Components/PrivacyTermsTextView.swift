//
//  PrivacyTermsTextView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 21/07/2020.
//  Copyright © 2020 Radically Better Ltd. All rights reserved.
//

import UIKit

class PrivacyTermsTextView: UITextView {
	
	override init(frame: CGRect, textContainer: NSTextContainer?) {
		super.init(frame: frame, textContainer: textContainer)
		configure()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func configure() {
		let font = Fonts.medium13
        let textColor = Colours.textSecondary
		
		let fullString = "By creating an account, I agree to FreeAudiobooks's Privacy Policy and Terms"
		let regularAttrs = [
			NSAttributedString.Key.font : font,
            NSAttributedString.Key.foregroundColor : textColor]
		let attributedString = NSMutableAttributedString(string: fullString, attributes: regularAttrs)
		
		let privacyLinkAttrs = [NSAttributedString.Key.font : font,
								NSAttributedString.Key.foregroundColor : textColor,
								NSAttributedString.Key.underlineStyle : 1,
								NSAttributedString.Key.link: URL(string: "privacy")!] as [NSAttributedString.Key : Any]
		let termsLinkAttrs = [NSAttributedString.Key.font : font,
							  NSAttributedString.Key.foregroundColor : textColor,
							  NSAttributedString.Key.underlineStyle : 1,
							  NSAttributedString.Key.link: URL(string: "terms")!] as [NSAttributedString.Key : Any]
		
		linkTextAttributes = regularAttrs
		
		let privacyRange = (fullString as NSString).range(of: "Privacy Policy")
		let termsRange = (fullString as NSString).range(of: "Terms")
		
		attributedString.addAttributes(privacyLinkAttrs, range: privacyRange)
		attributedString.addAttributes(termsLinkAttrs, range: termsRange)
		
		attributedText = attributedString
		centerText()
		isEditable = false
		backgroundColor = .clear
	}

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        configure()
    }
}

extension UITextView {
    func centerText() {
        self.textAlignment = .center
        let fittingSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        let topOffset = (bounds.size.height - size.height * zoomScale) / 2
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = -positiveTopOffset
    }
}
