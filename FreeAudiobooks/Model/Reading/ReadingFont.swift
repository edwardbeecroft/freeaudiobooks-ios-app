//
//  ReadingFonts.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 07/08/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

enum ReadingFont: String, CaseIterable {
    
    case bookerly
    case literata
    case avenirNext
    case futura
    case karla
    
    // Other options:
//    case atkinson
//    case georgia
//    case lato
//    case yrsa
//    case bitter
    
    var sizeMultiplier: Double {
        switch self {
        case .bookerly, .avenirNext, .karla, .literata: return 1.0
        case .futura: return 1.1
        }
    }
    
    func withSize(_ size: ReadingTextSize) -> UIFont {
        
        var fontName = ""
        switch self {
        case .bookerly: fontName = "Bookerly-Regular"
        case .avenirNext: fontName = "AvenirNext-Regular"
        case .futura: fontName = "Jost-Light"
        case .karla: fontName = "Karla-Regular"
        case .literata: fontName = "Literata-Regular"
//        case .atkinson: fontName = "AtkinsonHyperlegible-Regular"
        }
        
        let adjustedSize = size.rawValue * sizeMultiplier
        return UIFont(name: fontName, size: adjustedSize)!
    }

    func boldWithSize(_ size: ReadingTextSize) -> UIFont {
        var fontName = ""
        switch self {
        case .bookerly: fontName = "Bookerly-Bold"
        case .avenirNext: fontName = "AvenirNext-Bold"
        case .futura: fontName = "Jost-Bold"
        case .karla: fontName = "Karla-Bold"
        case .literata: fontName = "Literata-Bold"
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
}
