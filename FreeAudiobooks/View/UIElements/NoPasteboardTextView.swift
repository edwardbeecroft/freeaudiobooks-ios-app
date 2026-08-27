//
//  NoPasteboardTextView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 24/02/2021.
//  Copyright © 2021 Radically Better Ltd. All rights reserved.
//

import UIKit

class NoPasteboardTextView: UITextView {
	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {

		guard let pos = closestPosition(to: point) else { return false }

		guard let range = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: .layout(.left)) else { return false }

		let startIndex = offset(from: beginningOfDocument, to: range.start)

		return attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
	}
}
