//
//  Colours.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 01/01/2019.
//  Copyright © 2019 Ed Beecroft. All rights reserved.
//

import UIKit

struct Colours {

    // Apple use #11111 for main titles, #33333 for smaller titles
    
    // Gradient is 227 degrees
    static let freebooksGradientEnd = UIColor(hexString: "#FF3D6E")
    static let freebooksGradientStart = UIColor(hexString: "#FF8500")
    static let ctaBackground = UIColor.dynamic(light: brandBlack, dark: grey245)
    static let ctaForeground = UIColor.dynamic(light: .white, dark: brandBlack)
    
    static let orangePrimary = UIColor(hexString: "#FF6B1A")
    static let themeAccentDark = UIColor(hexString: "002a53") // Did try purple for a bit: 002a53
    
    static let charcoal = UIColor(hexString: "#1e1a24")
    static let negativeButtonTitle = Colours.textTertiary
    static let subtext = Colours.textSecondary
    static let subtextLight = Colours.textSecondary.withAlphaComponent(0.85)
    static let lightUI = UIColor.dynamic(light: charcoal.withAlphaComponent(0.5), dark: UIColor.white.withAlphaComponent(0.45))
    static let veryLightUI = UIColor.dynamic(light: charcoal.withAlphaComponent(0.3), dark: UIColor.white.withAlphaComponent(0.22))
    
    static let downloadedGreen: UIColor = UIColor(hexString: "2FA866") // .systemGreen
    
    static let positiveGreen = UIColor(hexString: "2dc653")
    static let negativeRed = UIColor(hexString: "#DC143C")
    
    // Semantic UI tokens should be preferred in new code. The raw greys below remain for
    // backwards compatibility during migration.
    static let surfacePrimary = UIColor.systemBackground
    static let surfaceSecondary = UIColor.secondarySystemBackground
    static let surfaceCard = UIColor.dynamic(light: Colours.grey247, dark: UIColor(hexString: "1C1C1E"))
    static let textPrimary = UIColor.label
    static let textSecondary = UIColor.secondaryLabel
    static let textTertiary = UIColor.tertiaryLabel
    static let separator = UIColor.separator
    static let inputBackground = UIColor.dynamic(light: .white, dark: UIColor.secondarySystemBackground)
    static let inputBorder = UIColor.dynamic(light: Colours.grey230, dark: UIColor.systemGray4)
    static let chromeBackground = UIColor.dynamic(light: .white, dark: UIColor(hexString: "111214"))
    static let tabBarBackground = UIColor.dynamic(light: .white, dark: UIColor(hexString: "111214"))
    static let shadowBase = UIColor.dynamic(light: .black, dark: .black)
    static let actionIconBackground = Colours.surfaceSecondary
    static let actionIconForeground = Colours.textSecondary.withAlphaComponent(0.8)
    static let actionIconSelectedBackground = Colours.ctaBackground
    static let actionIconSelectedForeground = Colours.ctaForeground
    
    static let pinkCTATitle = UIColor.dynamic(light: .white, dark: grey245)

    static let backgroundGrey: UIColor = UIColor.dynamic(light: Colours.grey243, dark: UIColor.secondarySystemBackground)
    static let royalNavy = UIColor(hexString: "#002A53")
    static let brandGrey = UIColor(hexString: "bebebe")
    static let brandBlack = UIColor(hexString: "#181818")
    static let accentLilac = UIColor(hexString: "#7478f8")
    
	// UIColor.light gray
	// #aaaaaa
	
	// #232323
	static let grey35 = UIColor(red: 35, green: 35, blue: 35)
	
	// #323232
	static let grey50 = UIColor(red: 50, green: 50, blue: 50)
	
	static let grey60 = UIColor(red: 60, green: 60, blue: 60)
	
	static let grey70 = UIColor(red: 70, green: 70, blue: 70)
	
	// #505050
	static let grey80 = UIColor(red: 80, green: 80, blue: 80)
	
	// #5a5a5a
	static let grey90 = UIColor(red: 90, green: 90, blue: 90)
	
	// #646464
	static let grey100 = UIColor(red: 100, green: 100, blue: 100)
	
	// #6e6e6e
	static let grey110 = UIColor(red: 110, green: 110, blue: 110)
	
	// #787878
	static let grey120 = UIColor(red: 120, green: 120, blue: 120)
	
	// #828282
	static let grey130 = UIColor(red: 130, green: 130, blue: 130)
	
	// #8c8c8c
	static let grey140 = UIColor(red: 140, green: 140, blue: 140)
	
	// #969696
	static let grey150 = UIColor(red: 150, green: 150, blue: 150)
	
	// #a0a0a0
	static let grey160 = UIColor(red: 160, green: 160, blue: 160)
	
	// #aaaaaa
	static let grey170 = UIColor(red: 170, green: 170, blue: 170)
	
	// #b4b4b4
	static let grey180 = UIColor(red: 180, green: 180, blue: 180)
	
	// #bebebe
	static let grey190 = UIColor(red: 190, green: 190, blue: 190)
	
	// #c8c8c8
	static let grey200 = UIColor(red: 200, green: 200, blue: 200)
	
	// #d2d2d2
	static let grey210 = UIColor(red: 210, green: 210, blue: 210)
	
	// #dcdcdc
	static let grey220 = UIColor(red: 220, green: 220, blue: 220)
	
	// #e6e6e6
	static let grey230 = UIColor(red: 230, green: 230, blue: 230)
	
	// #ebebeb
	static let grey235 = UIColor(red: 235, green: 235, blue: 235)
	
	// #f0f0f0
	static let grey240 = UIColor(red: 240, green: 240, blue: 240)
	
	// #f3f3f3
	static let grey243 = UIColor(red: 243, green: 243, blue: 243)
	
	// #f5f5f5
	static let grey245 = UIColor(red: 245, green: 245, blue: 245)
	
	// #f7f7f7
	static let grey247 = UIColor(red: 247, green: 247, blue: 247)
	
    static let grey248 = UIColor(red: 248, green: 248, blue: 248)
    
	static let grey250 = UIColor(red: 250, green: 250, blue: 250)
	
	static let grey252 = UIColor(red: 252, green: 252, blue: 252)

	static let grey253 = UIColor(red: 253, green: 253, blue: 253)
}

enum NavigationBarStyler {
    static func apply(to navigationBar: UINavigationBar?,
                      fallbackTraitCollection: UITraitCollection? = nil) {
        guard let navigationBar else { return }

        let effectiveStyle = AppearanceManager.shared.effectiveInterfaceStyle(
            fallbackTraitCollection: fallbackTraitCollection ?? navigationBar.window?.traitCollection ?? navigationBar.traitCollection
        )
        let foregroundColor = Colours.textPrimary.resolvedColor(with: UITraitCollection(userInterfaceStyle: effectiveStyle))
        let backgroundColor: UIColor
        switch effectiveStyle {
        case .dark:
            backgroundColor = UIColor(hexString: "111214")
        default:
            backgroundColor = .white
        }

        navigationBar.tintColor = foregroundColor

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = backgroundColor
        appearance.titleTextAttributes = [
            .foregroundColor: foregroundColor,
            .font: Fonts.semiBold16
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: foregroundColor
        ]
        appearance.shadowColor = Colours.separator

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
    }

    @discardableResult
    static func reapplyIfNeeded(
        on viewController: UIViewController,
        previousTraitCollection: UITraitCollection?,
        refreshNavigationItems: (() -> Void)? = nil
    ) -> Bool {
        guard viewController.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
            return false
        }

        apply(to: viewController.navigationController?.navigationBar,
              fallbackTraitCollection: viewController.view.window?.traitCollection ?? viewController.traitCollection)
        refreshNavigationItems?()
        return true
    }
}

enum TabBarStyler {
    static func makeAppearance() -> UITabBarAppearance {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Colours.tabBarBackground
        appearance.shadowColor = UIColor.clear
        return appearance
    }
}
