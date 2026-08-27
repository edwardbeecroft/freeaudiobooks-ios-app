//
//  AppAppearanceManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 01/03/2026.
//  Copyright © 2026 Kneady Technologies. All rights reserved.
//

import Foundation
import UIKit

enum AppAppearancePreference: String, CaseIterable {
    case system
    case light
    case dark

    var resolvedInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

struct AppAppearanceUserDefaults {
    private static let key = "appAppearancePreference"

    static var appearancePreference: AppAppearancePreference {
        get {
            guard
                let rawValue = UserDefaults.standard.string(forKey: key),
                let preference = AppAppearancePreference(rawValue: rawValue)
            else {
                return .system
            }
            return preference
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
        }
    }
}

final class AppearanceManager {
    static let shared = AppearanceManager()

    private init() {}

    func currentPreference() -> AppAppearancePreference {
        AppAppearanceUserDefaults.appearancePreference
    }

    func applyAppearance(to window: UIWindow?) {
        applyAppearancePreference(currentPreference(), window: window)
    }

    func applyAppearancePreference(_ preference: AppAppearancePreference, window: UIWindow?) {
        AppAppearanceUserDefaults.appearancePreference = preference
        window?.overrideUserInterfaceStyle = preference.resolvedInterfaceStyle
    }

    func effectiveInterfaceStyle(fallbackTraitCollection: UITraitCollection?) -> UIUserInterfaceStyle {
        switch currentPreference() {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            if let style = fallbackTraitCollection?.userInterfaceStyle, style == .light || style == .dark {
                return style
            }

            let screenStyle = UIScreen.main.traitCollection.userInterfaceStyle
            if screenStyle == .light || screenStyle == .dark {
                return screenStyle
            }

            return .light
        }
    }
}
