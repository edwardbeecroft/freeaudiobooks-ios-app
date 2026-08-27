//
//  PaddedLabel.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 07/01/2023.
//  Copyright © 2023 Radically Better Ltd. All rights reserved.
//

import UIKit

class PaddedLabel: UILabel {
    
    @IBInspectable var topInset: CGFloat = 8.0
    @IBInspectable var bottomInset: CGFloat = 8.0
    @IBInspectable var leftInset: CGFloat = 8.0
    @IBInspectable var rightInset: CGFloat = 8.0
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }
    
    override var intrinsicContentSize: CGSize {
        get {
            var contentSize = super.intrinsicContentSize
            contentSize.height += topInset + bottomInset
            contentSize.width += leftInset + rightInset
            return contentSize
        }
    }
}
