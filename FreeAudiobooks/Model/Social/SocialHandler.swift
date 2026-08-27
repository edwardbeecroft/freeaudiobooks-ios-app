//
//  SocialHandler.swift
//  LiveCard
//
//  Created by Edward Beecroft on 07/10/2018.
//  Copyright © 2018 SnowDrift Labs. All rights reserved.
//

import UIKit

struct SocialNetworkUrl {
	let scheme: String
	let page: String
	
	func openPage() {
		if let schemeUrl = URL(string: scheme), UIApplication.shared.canOpenURL(schemeUrl) {
			UIApplication.shared.open(schemeUrl, options: [:], completionHandler: nil)
		} else if let pageURL = URL(string: page) {
			UIApplication.shared.open(pageURL, options: [:], completionHandler: nil)
		}
	}
}

enum SocialNetwork {
	case Facebook/*, GooglePlus*/, Twitter, Instagram, TikTok
	func url() -> SocialNetworkUrl {
		switch self {
		case .Facebook: return SocialNetworkUrl(scheme: "fb://profile/\(AppConstants.shared.facebookPageId)", page: RCValues.shared.string(forKey: .facebookPageURLAB))
		case .Twitter: return SocialNetworkUrl(scheme: RCValues.shared.string(forKey: .twitterSchemeAB), page: RCValues.shared.string(forKey: .twitterPageURLAB))
		case .Instagram: return SocialNetworkUrl(scheme: RCValues.shared.string(forKey: .instagramSchemeAB), page: RCValues.shared.string(forKey: .instagramPageURLAB))
        case .TikTok: return SocialNetworkUrl(scheme: RCValues.shared.string(forKey: .tiktokSchemeAB), page: RCValues.shared.string(forKey: .tiktokPageURLAB))
		}
	}
	func openPage() {
		self.url().openPage()
	}
}
