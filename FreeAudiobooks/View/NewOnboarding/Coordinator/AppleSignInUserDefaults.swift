//
//  AppleSignInUserDefaults.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 16/05/2020.
//  Copyright © 2020 Radically Better Ltd. All rights reserved.
//

import Foundation

struct AppleSignInUserDefaults {

	private static let givenNamePath = "firstNamePath"
	private static let familyNamePath = "firstNamePath"
	private static let emailAddressPath = "emailAddressPath"
	private static let appleUserIdPath = "appleUserIdPath"
	
	static var givenName: String? {
		get {
			return UserDefaults.standard.string(forKey: givenNamePath)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: givenNamePath)
		}
	}
	
	static var familyName: String? {
		get {
			return UserDefaults.standard.string(forKey: familyNamePath)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: familyNamePath)
		}
	}
	
	static var emailAddress: String? {
		get {
			return UserDefaults.standard.string(forKey: emailAddressPath)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: emailAddressPath)
		}
	}
	
	static var appleUserId: String? {
		get {
			return UserDefaults.standard.string(forKey: appleUserIdPath)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: appleUserIdPath)
		}
	}
}
