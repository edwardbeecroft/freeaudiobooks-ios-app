//
//  RoundedProgressView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 23/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

class RoundedProgressView: UIProgressView {

    override func layoutSubviews() {
        super.layoutSubviews()

        // Apply rounded corners (pill shape)
        layer.cornerRadius = bounds.height / 2
        clipsToBounds = true
        subviews.forEach { subview in
            subview.layer.cornerRadius = bounds.height / 2
            subview.clipsToBounds = true
        }
    }
}
