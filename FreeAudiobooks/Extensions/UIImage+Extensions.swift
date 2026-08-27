//
//  UIImage+Extensions.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 17/01/2019.
//  Copyright © 2019 Ed Beecroft. All rights reserved.
//

import UIKit

extension UIImage {
	func resizeImage(newWidth: CGFloat) -> UIImage? {
		let image = self
		let scale = newWidth / image.size.width
		let newHeight = image.size.height * scale
		UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
		image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return newImage
	}
    
    func resizeImageConstrainingLongestSide(maxLongestSide: CGFloat) -> UIImage? {
        let image = self
        let longestSide = max(image.size.width, image.size.height)
        
        // Don't upscale - only downscale if needed
        guard longestSide > maxLongestSide else {
            return image
        }
        
        let scale = maxLongestSide / longestSide
        // Round to integer pixels to avoid fractional pixel issues
        let newWidth = round(image.size.width * scale)
        let newHeight = round(image.size.height * scale)
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        // Use high quality context with explicit 1.0 scale to avoid device scaling
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}

//extension UIImage {
//    public convenience init?(bounds: CGRect, colors: [UIColor], orientation: GradientOrientation = .horizontal) {
//        let gradientLayer = CAGradientLayer()
//        gradientLayer.frame = bounds
//        gradientLayer.colors = colors.map({ $0.cgColor })
//        
//        if orientation == .horizontal {
//            gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5);
//            gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5);
//        }
//        
//        UIGraphicsBeginImageContext(gradientLayer.bounds.size)
//        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
//        let image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        
//        guard let cgImage = image?.cgImage else { return nil }
//        self.init(cgImage: cgImage)
//    }
//}

extension UIImage {
    public convenience init?(bounds: CGRect, colors: [UIColor], orientation: GradientOrientation = .horizontal) {
        guard bounds.width > 0 && bounds.height > 0 else { return nil }

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map { $0.cgColor }
        if orientation == .horizontal {
            gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        }

        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        let image = renderer.image { ctx in
            gradientLayer.render(in: ctx.cgContext)
        }
        
        guard let cgImage = image.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}
