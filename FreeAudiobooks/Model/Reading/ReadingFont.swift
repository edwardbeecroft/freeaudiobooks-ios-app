//
//  ReadingFonts.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 07/08/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

enum ReadingFont: String, CaseIterable {

    // All open-licence (SIL OFL) fonts with bundled regular, bold and italic faces. Order is the
    // order shown in reading settings; Libron is the default.
    case libron
    case literata
    case mulish
    case futura
    case karla

    /// Saved choices for fonts the app no longer ships, mapped to their replacements.
    static func fromStoredValue(_ value: String) -> ReadingFont? {
        switch value {
        case "bookerly": return .libron
        case "avenirNext": return .mulish
        default: return ReadingFont(rawValue: value)
        }
    }

    var sizeMultiplier: Double {
        switch self {
        case .libron, .literata, .mulish, .karla: return 1.0
        case .futura: return 1.1
        }
    }

    func withSize(_ size: ReadingTextSize) -> UIFont {
        let fontName: String
        switch self {
        case .libron: fontName = "Libron-Regular"
        case .literata: fontName = "Literata-Regular"
        case .mulish: fontName = "Mulish-Regular"
        case .futura: fontName = "Jost-Light"
        case .karla: fontName = "Karla-Regular"
        }

        let adjustedSize = size.rawValue * sizeMultiplier
        return UIFont(name: fontName, size: adjustedSize)!
    }

    func boldWithSize(_ size: ReadingTextSize) -> UIFont {
        let fontName: String
        switch self {
        case .libron: fontName = "Libron-Bold"
        case .literata: fontName = "Literata-Bold"
        case .mulish: fontName = "Mulish-Bold"
        case .futura: fontName = "Jost-Bold"
        case .karla: fontName = "Karla-Bold"
        }

        let adjustedSize = size.rawValue * sizeMultiplier

        // Try custom font, fall back to font descriptor bold trait
        if let customFont = UIFont(name: fontName, size: adjustedSize) {
            return customFont
        }

        let regularFont = self.withSize(size)
        if let boldDescriptor = regularFont.fontDescriptor.withSymbolicTraits(.traitBold) {
            return UIFont(descriptor: boldDescriptor, size: adjustedSize)
        }
        return regularFont
    }

    /// The font's italic face. Nil only if the file failed to load, in which case the reader slants the regular.
    func italicWithSize(_ size: ReadingTextSize) -> UIFont? {
        let fontName: String
        switch self {
        case .libron: fontName = "Libron-Italic"
        case .literata: fontName = "Literata-Italic"
        case .mulish: fontName = "Mulish-Italic"
        case .futura: fontName = "Jost-LightItalic"
        case .karla: fontName = "Karla-Italic"
        }
        return UIFont(name: fontName, size: size.rawValue * sizeMultiplier)
    }
}
