//
//  UIColor+Extensions.swift
//  ProjectIndigo
//
//  Created by Ed Beecroft on 01/01/2019.
//  Copyright © 2019 Ed Beecroft. All rights reserved.
//

import UIKit

// Hex converter
extension UIColor {
    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? dark : light
            }
        } else {
            return light
        }
    }
}

extension UIColor {
	convenience init(red: Int, green: Int, blue: Int) {
		assert(red >= 0 && red <= 255, "Invalid red component")
		assert(green >= 0 && green <= 255, "Invalid green component")
		assert(blue >= 0 && blue <= 255, "Invalid blue component")
		
		self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
	}
	
	convenience init(rgb: Int) {
		self.init(
			red: (rgb >> 16) & 0xFF,
			green: (rgb >> 8) & 0xFF,
			blue: rgb & 0xFF
		)
	}
}

extension UIColor {
	
	convenience init(hexString: String) {
		
		var cString:String = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
		
		if (cString.hasPrefix("#")) {
			cString.remove(at: cString.startIndex)
		}
		
		if ((cString.count) != 6) {
			self.init(red: 1.0 / 255.0, green: 1.0 / 255.0, blue: 1.0 / 255.0, alpha: 1.0)
		} else {
			var rgbValue:UInt32 = 0
			Scanner(string: cString).scanHexInt32(&rgbValue)
			
			self.init(
				red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
				green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
				blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
				alpha: CGFloat(1.0)
			)
		}
	}
	
	func toHexString() -> String {
		var r:CGFloat = 0
		var g:CGFloat = 0
		var b:CGFloat = 0
		var a:CGFloat = 0
		
		getRed(&r, green: &g, blue: &b, alpha: &a)
		
		let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
		
		return String(format:"#%06x", rgb)
	}
}

extension UIColor {
    static func colourBetween(startColor: UIColor, endColor: UIColor, percentage: CGFloat) -> UIColor {
        let percentage = max(min(percentage, 100), 0) / 100
        switch percentage {
        case 0: return startColor
        case 1: return endColor
        default:
            var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
            var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
            guard startColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1) else { return startColor }
            guard endColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else { return startColor }

            return UIColor(red: CGFloat(r1 + (r2 - r1) * percentage),
                           green: CGFloat(g1 + (g2 - g1) * percentage),
                           blue: CGFloat(b1 + (b2 - b1) * percentage),
                           alpha: CGFloat(a1 + (a2 - a1) * percentage))
        }
    }
}
