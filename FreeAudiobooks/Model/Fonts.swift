//
//  Fonts.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 01/01/2019.
//  Copyright © 2019 Ed Beecroft. All rights reserved.
//

import UIKit

struct Fonts {

    // Canonical system font tokens
    static let medium11: UIFont = systemFont(ofSize: 11, weight: .medium)
    static let semiBold11: UIFont = systemFont(ofSize: 11, weight: .semibold)

    static let regular12: UIFont = systemFont(ofSize: 12, weight: .regular)
    static let light12: UIFont = systemFont(ofSize: 12, weight: .light)
    static let medium12: UIFont = systemFont(ofSize: 12, weight: .medium)
    static let semiBold12: UIFont = systemFont(ofSize: 12, weight: .semibold)

    static let regular13: UIFont = systemFont(ofSize: 13, weight: .regular)
    static let medium13: UIFont = systemFont(ofSize: 13, weight: .medium)
    static let semiBold13: UIFont = systemFont(ofSize: 13, weight: .semibold)
    static let bold13: UIFont = systemFont(ofSize: 13, weight: .bold)

    static let regular14: UIFont = systemFont(ofSize: 14, weight: .regular)
    static let medium14: UIFont = systemFont(ofSize: 14, weight: .medium)
    static let semiBold14: UIFont = systemFont(ofSize: 14, weight: .semibold)

    static let regular15: UIFont = systemFont(ofSize: 15, weight: .regular)
    static let medium15: UIFont = systemFont(ofSize: 15, weight: .medium)
    static let semiBold15: UIFont = systemFont(ofSize: 15, weight: .semibold)

    static let regular16: UIFont = systemFont(ofSize: 16, weight: .regular)
    static let medium16: UIFont = systemFont(ofSize: 16, weight: .medium)
    static let mediumItalic16: UIFont = systemItalicFont(ofSize: 16, weight: .medium)
    static let semiBold16: UIFont = systemFont(ofSize: 16, weight: .semibold)

    static let regular17: UIFont = systemFont(ofSize: 17, weight: .regular)
    static let medium17: UIFont = systemFont(ofSize: 17, weight: .medium)
    static let semiBold17: UIFont = systemFont(ofSize: 17, weight: .semibold)

    static let medium18: UIFont = systemFont(ofSize: 18, weight: .medium)
    static let semiBold18: UIFont = systemFont(ofSize: 18, weight: .semibold)

    static let medium19: UIFont = systemFont(ofSize: 19, weight: .medium)
    static let semiBold19: UIFont = systemFont(ofSize: 19, weight: .semibold)
    static let bold19: UIFont = systemFont(ofSize: 19, weight: .bold)
    
    static let semiBold20: UIFont = systemFont(ofSize: 20, weight: .semibold)

    static let semiBold21: UIFont = systemFont(ofSize: 21, weight: .semibold)
    static let bold21: UIFont = systemFont(ofSize: 21, weight: .bold)
    
    static let medium22: UIFont = systemFont(ofSize: 22, weight: .medium)
    static let semiBold22: UIFont = systemFont(ofSize: 22, weight: .semibold)

    static let medium23: UIFont = systemFont(ofSize: 23, weight: .medium)
    static let semiBold23: UIFont = systemFont(ofSize: 23, weight: .semibold)

    static let semiBold24: UIFont = systemFont(ofSize: 24, weight: .semibold)
    static let bold24: UIFont = systemFont(ofSize: 24, weight: .bold)

    static let semiBold25: UIFont = systemFont(ofSize: 25, weight: .semibold)

    static let semiBold28: UIFont = systemFont(ofSize: 28, weight: .semibold)
    
    static func mediumWithSize(_ size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: .medium)
    }

    static func semiBoldWithSize(_ size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: .semibold)
    }

    static func boldWithSize(_ size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: .bold)
    }

    static let navBarTitleTextAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: Colours.textPrimary,
        .font: Fonts.semiBold16
    ]

    private static func systemFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: weight)
    }

    private static func systemItalicFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let baseFont = UIFont.systemFont(ofSize: size, weight: weight)
        if let italicDescriptor = baseFont.fontDescriptor.withSymbolicTraits(.traitItalic) {
            return UIFont(descriptor: italicDescriptor, size: size)
        }
        return UIFont.italicSystemFont(ofSize: size)
    }
}
