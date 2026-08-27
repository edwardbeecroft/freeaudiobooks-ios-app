//
//  AppConstants.swift
//  FreeAudiobooks
//
//  Created by Edward Beecroft on 24/10/2018.
//  Copyright © 2018 SnowDrift Labs. All rights reserved.
//

import UIKit
import Foundation

enum DevelopmentMode {
    case screenshots
    case production
}

enum AdMode {
    case testing
    case live
}

class AppConstants {
	static let shared = AppConstants()
	private init() {}
	
	let bundleId = Bundle.main.bundleIdentifier
    
	let appStoreId = "6773306508"
    let facebookPageId = "1165577053300693"
    let googleAPIKey = "AIzaSyCgqcYuTSF6Dev9KjFc-8-9cco3P2fztTg"
    
    let developmentMode: DevelopmentMode = .production
    let adMode: AdMode = .live
	
	let appStoreURL = RCValues.shared.string(forKey: .appStoreURLAB)
	let termsURL = RCValues.shared.string(forKey: .termsOfUseURLAB)
	let privacyURL = RCValues.shared.string(forKey: .privacyPolicyURLAB)
    
    let v2FunctionsTimeout: TimeInterval = 3600
    
    // Testing
    static let isDebugAuthRegistrationEnabled = false
}

class UIConstants {
	static let shared = UIConstants()
	private init() {}
	
	let cornerRadius: CGFloat = 8
	let standardMargin: CGFloat = 20
    
	let midButtonHeight: CGFloat = 40
    let midButtonCornerRadius: CGFloat = 20
    
	let fullButtonHeight: CGFloat = 50
    let fullButtonCornerRadius: CGFloat = 25

    let onboardingButtonHeight: CGFloat = 60
    let onboardingButtonCornerRadius: CGFloat = 30

    let cardCornerRadius: CGFloat = 12
	
	// Cell sizes/rations
	let collectionCVCHeightToWidthRatio: CGFloat = 0.7
	
    let smallCornerRadius: CGFloat = 4
    let coverImageBadgeInset: CGFloat = 6
    
	// Sizes
	let fetchingIndicatorWidthHeight: CGFloat = 24 //RCValues.shared.cgFloat(forKey: .inAppVCFetchSpinnerSize)

    let bookInternalCoverImageWidthToHeightRatio: CGFloat = 1024/1536 // All images have this aspect ratio. It's about 0.6666666667
	
	static let subOnlyViewInset: CGFloat = 12
	static let subOnlyViewHeight: CGFloat = 22
	static let subOnlyViewWidth: CGFloat = 58
    
    let spacerHeight: CGFloat = 16
    
    let carouselTitleFont = Fonts.semiBold18
    let carouselTitleTextColour = Colours.textPrimary
    let carouselSubtitleKickerFont = Fonts.medium15
    let carouselSubtitleKickerTextColour = Colours.textSecondary
    let carouselReaderCountLabelFont = Fonts.medium13
    let carouselReaderCountLabelTextColour = Colours.textSecondary

    let filterChipFont = Fonts.medium14

    let coverImageHeight: CGFloat = 173

    // Discover-specific card tuning constants
    let discoverCardCoverHeight: CGFloat = 146
    let bookCoverCornerRadiusSmall: CGFloat = 4
    let bookCoverCornerRadius: CGFloat = 6
    let discoverCarouselMinimumLineSpacing: CGFloat = 8
    let discoverGridMinimumInteritemSpacing: CGFloat = 10
    let discoverContinueReadingCoverHeight: CGFloat = 122
}
