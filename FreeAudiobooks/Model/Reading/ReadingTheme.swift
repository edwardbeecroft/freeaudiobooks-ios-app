//
//  ReadingBackgroundColors.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 08/08/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

enum ReadingTheme: String, CaseIterable {
    case white
    case cream
    case blue
    case green
    case charcoal
    case extraDark
    
    var backgroundColor: UIColor {
        switch self {
        case .white: return .white
        case .cream: return UIColor(hexString: "FBF0D9")
        case .blue: return UIColor(hexString: "222233")
        case .green: return UIColor(hexString: "1E4147")
        case .charcoal: return Colours.charcoal
        case .extraDark: return UIColor(hexString: "121212")
        }
    }
    var textColor: UIColor {
        switch self {
        case .white: return Colours.charcoal
        case .cream: return Colours.charcoal
        case .blue: return UIColor(hexString: "AACCFF")
        case .green: return .white
        case .charcoal: return UIColor(hexString: "f0f0f0")
        case .extraDark: return UIColor(hexString: "f0f0f0")
        }
    }
    
    var buttonTitleColor: UIColor {
        return backgroundColor
    }
    var buttonBackgroundColor: UIColor {
        if self == .white || self == .cream {
            return Colours.themeAccentDark
        }
        return textColor
    }
    var bottomSplitterColor: UIColor {
        return textColor.withAlphaComponent(0.6)
    }

    var isDark: Bool {
        switch self {
        case .white, .cream: return false
        case .blue, .green, .charcoal, .extraDark: return true
        }
    }

    var preferredStatusBarStyle: UIStatusBarStyle {
        return isDark ? .lightContent : .darkContent
    }

    var chromeBackgroundColor: UIColor {
        return backgroundColor.withAlphaComponent(0.92)
    }

    var chromeBlurStyle: UIBlurEffect.Style {
        return isDark ? .systemThinMaterialDark : .systemMaterial
    }

    var chromeTintColor: UIColor {
        return textColor
    }
}
