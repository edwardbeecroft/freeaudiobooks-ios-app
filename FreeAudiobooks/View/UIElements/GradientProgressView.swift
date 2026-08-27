//
//  GradientProgressView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 10/10/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

public enum GradientOrientation {
    case vertical
    case horizontal
}

class GradientProgressView: UIProgressView {
    @IBInspectable var firstColor: UIColor = .white {
        didSet { updateGradientIfNeeded() }
    }
    @IBInspectable var secondColor: UIColor = .black {
        didSet { updateGradientIfNeeded() }
    }

    private var lastBounds: CGRect = .zero
    private var cachedGradientImage: UIImage?

    override func layoutSubviews() {
        super.layoutSubviews()
        
        print("layout called")

        // Apply rounded corners (pill shape)
        layer.cornerRadius = bounds.height / 2
        clipsToBounds = true
        subviews.forEach { subview in
            subview.layer.cornerRadius = bounds.height / 2
            subview.clipsToBounds = true
        }

        // Only update gradient if bounds changed
        if bounds != lastBounds {
            lastBounds = bounds
            updateGradientIfNeeded()
        }
    }

    private func updateGradientIfNeeded() {
        guard bounds.width > 0 && bounds.height > 0 else { return }

        // Only regenerate if colors or bounds changed
        if cachedGradientImage == nil || cachedGradientImage?.size != bounds.size {
            cachedGradientImage = UIImage(bounds: bounds, colors: [firstColor, secondColor])
        }

        progressImage = cachedGradientImage
    }
}
