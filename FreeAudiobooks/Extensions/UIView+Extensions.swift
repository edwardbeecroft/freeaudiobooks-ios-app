//
//  UIView+Extensions.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 15/01/2019.
//  Copyright © 2019 Ed Beecroft. All rights reserved.
//

import UIKit

extension UIView {
	func addIphoneXBottomView(colour: UIColor) {
		let iPhoneXBottomView = UIView()
		iPhoneXBottomView.backgroundColor = colour
		iPhoneXBottomView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(iPhoneXBottomView)
		NSLayoutConstraint.activate([
			iPhoneXBottomView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
			iPhoneXBottomView.leftAnchor.constraint(equalTo: leftAnchor),
			iPhoneXBottomView.rightAnchor.constraint(equalTo: rightAnchor),
			iPhoneXBottomView.bottomAnchor.constraint(equalTo: bottomAnchor)
		])
	}
	
	func addSubviewForConstraints(_ subview: UIView) {
		subview.translatesAutoresizingMaskIntoConstraints = false
		addSubview(subview)
	}
	
	public var safeTopAnchor: NSLayoutYAxisAnchor {
		return safeAreaLayoutGuide.topAnchor
	}
	
	public var safeBottomAnchor: NSLayoutYAxisAnchor {
		return safeAreaLayoutGuide.bottomAnchor
	}
	
	public var safeTrailingAnchor: NSLayoutXAxisAnchor {
		return safeAreaLayoutGuide.trailingAnchor
	}
	
	public var safeLeadingAnchor: NSLayoutXAxisAnchor {
		return safeAreaLayoutGuide.leadingAnchor
	}
	
	public var safeCenterYAnchor: NSLayoutYAxisAnchor {
		return safeAreaLayoutGuide.centerYAnchor
	}
	
	public var safeCenterXAnchor: NSLayoutXAxisAnchor {
		return safeAreaLayoutGuide.centerXAnchor
	}
    
    func addBottomBorderView() {
        let borderView = BorderView()
        addSubviewForConstraints(borderView)
        NSLayoutConstraint.activate([
            borderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: bottomAnchor),
            borderView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
}

extension UIView {
    func removeBlurFromView() {
        for subview in subviews {
            if subview is UIVisualEffectView {
                subview.removeFromSuperview()
            }
        }
    }
}
