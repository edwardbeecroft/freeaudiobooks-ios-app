//
//  UIStackView+Extensions.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 23/10/2025.
//  Copyright © 2025 Kneady Technologies. All rights reserved.
//

import UIKit

extension UIStackView {
    func removeAllArrangedSubviews() {
        arrangedSubviews.forEach {
            removeArrangedSubview($0)
            NSLayoutConstraint.deactivate($0.constraints)
            $0.removeFromSuperview()
        }
    }
}
