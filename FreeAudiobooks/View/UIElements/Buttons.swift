//
//  Buttons.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 05/01/2019.
//  Copyright © 2019 Ed Beecroft. All rights reserved.
//

import UIKit

class Buttons {
	
	static func transparentButtonWithBorder(borderColor: CGColor?, buttonTitle: String?, titleColor: UIColor?) -> UIButton {
		let button = UIButton(type: .system)
		button.setTitle(buttonTitle, for: .normal)
		button.setTitleColor(titleColor, for: .normal)
		button.titleLabel?.font = Fonts.semiBold16
		button.layer.borderColor = borderColor
        
        if borderColor == nil {
            button.layer.borderWidth = 0
        } else {
            button.layer.borderWidth = 1.0
        }

		button.layer.cornerRadius = UIConstants.shared.fullButtonCornerRadius
		button.clipsToBounds = true
		button.backgroundColor = .clear
		return button
	}
	
	static func primaryCTA(buttonTitle: String) -> UIButton {
		let button = UIButton(type: .system)
		button.backgroundColor = Colours.orangePrimary
		button.setTitle(buttonTitle, for: .normal)
		button.setTitleColor(Colours.pinkCTATitle, for: .normal)
		button.titleLabel?.font = Fonts.semiBold16
		button.layer.cornerRadius = UIConstants.shared.fullButtonCornerRadius
		button.clipsToBounds = true
		return button
	}
    
    static func filledButtonWithImage(backgroundColor: UIColor,
                                      image: UIImage) -> UIButton {
        
        let button = UIButton(type: .system)
        
        let insets: CGFloat = 8
        button.setImage(image.withRenderingMode(.alwaysTemplate), for: [])
        button.imageEdgeInsets = UIEdgeInsets(top: insets, left: insets, bottom: insets, right: insets)
        button.backgroundColor = backgroundColor
        button.tintColor = .white
        
        button.layer.cornerRadius = UIConstants.shared.fullButtonCornerRadius
        button.clipsToBounds = true
        
        return button
    }
    static func gradientButton(buttonTitle: String?, cornerRadius: CGFloat = UIConstants.shared.fullButtonCornerRadius) -> UIButton {
        
        let button = GradientButton(cornerRadius: cornerRadius)
        button.setTitle(buttonTitle, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = Fonts.semiBold16
        button.layer.cornerRadius = cornerRadius
        button.clipsToBounds = true
        
        return button
    }
    static func negativeCTAButton(buttonTitle: String?) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(buttonTitle, for: .normal)
        button.setTitleColor(Colours.negativeButtonTitle, for: .normal)
        button.titleLabel?.font = Fonts.medium15
        button.layer.borderColor = nil
        button.layer.borderWidth = 0

        button.layer.cornerRadius = 0//UIConstants.shared.cornerRadius
        button.clipsToBounds = true
        button.backgroundColor = .clear
        return button
    }
}

private class GradientButton: UIButton {

    lazy var gradientLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        l.frame = self.bounds
        l.startPoint = CGPoint(x: 0, y: 0.4)
        l.endPoint = CGPoint(x: 1, y: 0.6)
        l.cornerRadius = cornerRadius
        layer.insertSublayer(l, at: 0)
        return l
    }()
    
    private let cornerRadius: CGFloat
    init(cornerRadius: CGFloat = UIConstants.shared.fullButtonCornerRadius) {
        self.cornerRadius = cornerRadius
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        updateGradientColors()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateGradientColors()
    }

    private func updateGradientColors() {
        gradientLayer.colors = [
            Colours.freebooksGradientStart.cgColor,
            Colours.freebooksGradientEnd.cgColor
        ]
    }
}

class CircularNonGradientButton: UIButton {

    var overrideBackgroundColor: UIColor? { didSet { applyBaseAppearance() } }
    var overrideTintColor: UIColor? { didSet { applyBaseAppearance() } }
    var overrideBorderColor: UIColor? { didSet { applyBaseAppearance() } }

    private var ctaForegroundTint: UIColor {
        overrideTintColor ?? Colours.pinkCTATitle
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        applyBaseAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        applyBaseAppearance()
    }

    private var loadingIndicator: CAShapeLayer?
    private var progressLayer: CAShapeLayer?

    override var isHighlighted: Bool {
        didSet {
            // Prevent the default grey tint on press while preserving the CTA foreground color.
            updateTintForCurrentState()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
        clipsToBounds = true
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        applyBaseAppearance()
    }

    private func applyBaseAppearance() {
        backgroundColor = overrideBackgroundColor ?? Colours.orangePrimary
        if let overrideBorderColor {
            layer.borderColor = overrideBorderColor.cgColor
        }
        updateTintForCurrentState()
    }

    private func updateTintForCurrentState() {
        tintColor = isHighlighted ? ctaForegroundTint.withAlphaComponent(0.7) : ctaForegroundTint
    }

    func startLoadingAnimation() {
        isEnabled = false

        // Create loading indicator
        let indicatorLayer = CAShapeLayer()
        let radius = min(bounds.width, bounds.height) / 4
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)

        indicatorLayer.path = path.cgPath
        indicatorLayer.fillColor = UIColor.clear.cgColor
        indicatorLayer.strokeColor = ctaForegroundTint.cgColor
        indicatorLayer.lineWidth = 2
        indicatorLayer.lineCap = .round

        // Add animation
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = 0
        animation.toValue = 2 * CGFloat.pi
        animation.duration = 1.0
        animation.repeatCount = .infinity
        indicatorLayer.add(animation, forKey: "rotation")

        layer.addSublayer(indicatorLayer)
        loadingIndicator = indicatorLayer

        // Hide the icon
        imageView?.alpha = 0
    }

    func startProgressIndicator() {
        // Create progress circle
        let progressCircle = CAShapeLayer()
        let radius = min(bounds.width, bounds.height) / 2 - 4
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: -.pi / 2, endAngle: 3 * .pi / 2, clockwise: true)

        progressCircle.path = path.cgPath
        progressCircle.fillColor = UIColor.clear.cgColor
        progressCircle.strokeColor = ctaForegroundTint.cgColor
        progressCircle.lineWidth = 3
        progressCircle.lineCap = .round
        progressCircle.strokeEnd = 0

        layer.addSublayer(progressCircle)
        progressLayer = progressCircle
    }

    func updateProgress(_ progress: Float) {
        // Disable implicit animations to prevent glitchy jumping
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        progressLayer?.strokeEnd = CGFloat(progress)
        CATransaction.commit()
    }

    func stopLoadingAnimation() {
        isEnabled = true
        loadingIndicator?.removeFromSuperlayer()
        loadingIndicator = nil
        progressLayer?.removeFromSuperlayer()
        progressLayer = nil

        // Restore icon visibility (for startLoadingAnimation which hides it)
        imageView?.alpha = 1
    }
}

class CircularGradientButton: CircularNonGradientButton {

    private lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0, y: 0.4)
        layer.endPoint = CGPoint(x: 1, y: 0.6)
        self.layer.insertSublayer(layer, at: 0)
        return layer
    }()

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = min(bounds.width, bounds.height) / 2
        updateGradientColors()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateGradientColors()
    }

    private func updateGradientColors() {
        gradientLayer.colors = [
            Colours.freebooksGradientStart.cgColor,
            Colours.freebooksGradientEnd.cgColor
        ]
    }
}
