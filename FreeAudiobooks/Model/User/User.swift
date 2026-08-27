//
//  User.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 09/01/2019.
//  Copyright © 2019 Ed Beecroft. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseFirestore

class User: NSObject {
	
	let uuid: String
	var emailAddress: String
    var username: String?
	var firstName: String
	var lastName: String
	let signInMethod: String
	
	var profileImageURLString: String?
	
	let createdDate: Date
	
    var savedBookInternalUUIDs: [String]
    var completedBookInternalUUIDs: [String]
    var reviewedBookInternalUUIDs: [String]
    
    var savedStoryUUIDs: [String]
    var completedStoryUUIDs: [String]
    
    var savedItemsOrder: [String]
    
	// Marketing
    var marketingPromptAnswered: Bool // This property was only added in Sept 2025 - but we default to true
	var marketingConsentAmendedDate: Date
	var marketingPermission: Bool
	
	// Privacy
	let privacyPolicyConsentMethod: String
	let privacyPolicyAcceptDate: Date

    let fcmTokens: [String]

    // Audiobook quota tracking
    var audiobookQuotaUUIDsThisMonth: [String]
    var lastAudiobookQuotaResetDate: Date

    // Listening quota tracking
    var listeningQuotaBookUUIDsThisWeek: [String]
    var listeningQuotaWeekStartedAt: Date?

    var favoriteGenres: [BookInternalGenre]

    // Gamification & Stats
    var currentStreak: Int
    var longestStreak: Int
    var lastAppOpenDate: Date
    var streakFreezeUsed: Bool
    var totalReadingTimeSeconds: Int
    var weeklyReadingTimeSeconds: Int
    var weekStartDate: Date
    var weeklyBooksReadUUIDs: [String]

    // Computed property - always matches array count
    var weeklyBooksReadCount: Int {
        return weeklyBooksReadUUIDs.count
    }
	
	init?(dict: [String: Any]) {
		guard
			let uuid = dict[FirebaseUserVariables.uuid.rawValue] as? String,
			let emailAddress = dict[FirebaseUserVariables.emailAddress.rawValue] as? String,
			let firstName = dict[FirebaseUserVariables.firstName.rawValue] as? String,
			let lastName = dict[FirebaseUserVariables.lastName.rawValue] as? String,
            let savedStoryUUIDs = dict[FirebaseUserVariables.savedStoryUUIDs.rawValue] as? [String],
            let completedStoryUUIDs = dict[FirebaseUserVariables.completedStoryUUIDs.rawValue] as? [String],
			let signInMethod = dict[FirebaseUserVariables.signInMethod.rawValue] as? String,
			let createdDateTimestamp = dict[FirebaseUserVariables.createdDate.rawValue] as? Timestamp,
			let marketingPermission = dict[FirebaseUserVariables.marketingPermission.rawValue] as? Bool,
			let marketingConsentAmendedDate = dict[FirebaseUserVariables.marketingConsentAmendedDate.rawValue] as? Timestamp,
			let privacyPolicyConsentMethod = dict[FirebaseUserVariables.privacyPolicyConsentMethod.rawValue] as? String,
			let privacyPolicyAcceptDate = dict[FirebaseUserVariables.privacyPolicyAcceptDate.rawValue] as? Timestamp,
            let fcmTokens = dict[FirebaseUserVariables.fcmTokens.rawValue] as? [String] else {
				return nil
		}
		self.uuid = uuid
		self.emailAddress = emailAddress
        self.username = dict[FirebaseUserVariables.username.rawValue] as? String
		self.firstName = firstName
		self.lastName = lastName
		self.profileImageURLString = dict[FirebaseUserVariables.profileImageURLString.rawValue] as? String
		self.signInMethod = signInMethod
		self.createdDate = createdDateTimestamp.dateValue()
        
        if let savedShortStories = dict[FirebaseUserVariables.savedBookInternalUUIDs.rawValue] as? [String] {
            self.savedBookInternalUUIDs = savedShortStories.reversed()
        } else {
            self.savedBookInternalUUIDs = []
        }
        self.completedBookInternalUUIDs = dict[FirebaseUserVariables.completedBookInternalUUIDs.rawValue] as? [String] ?? []
        self.reviewedBookInternalUUIDs = dict[FirebaseUserVariables.reviewedBookInternalUUIDs.rawValue] as? [String] ?? []
        
        self.savedStoryUUIDs = savedStoryUUIDs.reversed()
        self.completedStoryUUIDs = completedStoryUUIDs
        
        // Handle savedItemsOrder with fallback for existing users
        if let savedItemsOrder = dict[FirebaseUserVariables.savedItemsOrder.rawValue] as? [String] {
            self.savedItemsOrder = savedItemsOrder
        } else {
            // Migration will be handled by AccountManager.migrateSavedItemsOrderIfNeeded()
            self.savedItemsOrder = []
        }
        
        self.marketingPromptAnswered = dict[FirebaseUserVariables.marketingPromptAnswered.rawValue] as? Bool ?? true
		self.marketingPermission = marketingPermission
		self.marketingConsentAmendedDate = marketingConsentAmendedDate.dateValue()

		self.privacyPolicyConsentMethod = privacyPolicyConsentMethod
		self.privacyPolicyAcceptDate = privacyPolicyAcceptDate.dateValue()
        self.fcmTokens = fcmTokens

        // Audiobook quota tracking - default to empty array and date in past
        self.audiobookQuotaUUIDsThisMonth = dict[FirebaseUserVariables.audiobookQuotaUUIDsThisMonth.rawValue] as? [String] ?? []
        if let resetDate = dict[FirebaseUserVariables.lastAudiobookQuotaResetDate.rawValue] as? Timestamp {
            self.lastAudiobookQuotaResetDate = resetDate.dateValue()
        } else {
            // For legacy users without this field, set to distant past
            // This ensures shouldResetQuota() will detect an expired window and trigger an immediate reset
            self.lastAudiobookQuotaResetDate = Date.distantPast
        }

        self.listeningQuotaBookUUIDsThisWeek = dict[FirebaseUserVariables.listeningQuotaBookUUIDsThisWeek.rawValue] as? [String] ?? []
        self.listeningQuotaWeekStartedAt = (dict[FirebaseUserVariables.listeningQuotaWeekStartedAt.rawValue] as? Timestamp)?.dateValue()
        
        if let favoriteGenreStrings = dict[FirebaseUserVariables.favoriteGenres.rawValue] as? [String] {
            let genreEnums = favoriteGenreStrings.compactMap({ BookInternalGenre(rawValue: $0) })
            if genreEnums.isEmpty {
                self.favoriteGenres = []
            } else {
                self.favoriteGenres = genreEnums
            }
        } else {
            self.favoriteGenres = []
        }

        // Gamification & Stats - with defaults for existing users
        self.currentStreak = dict[FirebaseUserVariables.currentStreak.rawValue] as? Int ?? 1 // Default to 1 (they're here!)
        self.longestStreak = dict[FirebaseUserVariables.longestStreak.rawValue] as? Int ?? 1

        if let lastOpenTimestamp = dict[FirebaseUserVariables.lastAppOpenDate.rawValue] as? Timestamp {
            self.lastAppOpenDate = lastOpenTimestamp.dateValue()
        } else {
            self.lastAppOpenDate = Date()
        }

        self.streakFreezeUsed = dict[FirebaseUserVariables.streakFreezeUsed.rawValue] as? Bool ?? false
        self.totalReadingTimeSeconds = dict[FirebaseUserVariables.totalReadingTimeSeconds.rawValue] as? Int ?? 0
        self.weeklyReadingTimeSeconds = dict[FirebaseUserVariables.weeklyReadingTimeSeconds.rawValue] as? Int ?? 0

        if let weekStartTimestamp = dict[FirebaseUserVariables.weekStartDate.rawValue] as? Timestamp {
            self.weekStartDate = weekStartTimestamp.dateValue()
        } else {
            // Set to start of current week (Monday)
            self.weekStartDate = Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: Date()).date ?? Date()
        }

        self.weeklyBooksReadUUIDs = dict[FirebaseUserVariables.weeklyBooksReadUUIDs.rawValue] as? [String] ?? []
        // weeklyBooksReadCount is now a computed property (count of weeklyBooksReadUUIDs)
	}
    
	func fullName() -> String {
		return "\(firstName) \(lastName)"
	}

    var displayName: String {
        let resolvedUsername = username?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !resolvedUsername.isEmpty {
            return resolvedUsername
        }

        let resolvedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        return resolvedFirstName.isEmpty ? "FreeAudiobooks Listener" : resolvedFirstName
    }
    
    var memberSinceYear: Int? {
        return Calendar.current.dateComponents([.year], from: createdDate).year
    }
	
	static let privacyAcceptMethod: String = "Registration"
    
    var totalSavedBooksCount: Int {
        return savedStoryUUIDs.count + savedBookInternalUUIDs.count
    }
}

extension User {
	static var placeholderImage: UIImage? {
		return UIImage(named: "user-placeholder.jpg")//?.withRenderingMode(.alwaysTemplate)
	}
}

extension User {
    /// Whether user needs to complete their profile (missing email, first name, or last name)
    var needsProfileCompletion: Bool {
        return emailAddress.isEmpty || firstName.isEmpty || lastName.isEmpty
    }
}

extension User {
    func sortedSavedContent(contentType: ContentType?) -> [ReadableContentMetadata] {
        guard !savedItemsOrder.isEmpty else {
            return CoreDataBookInternalManager.shared.getSavedBookInternals()
                .sorted { $0.title ?? "" < $1.title ?? "" }
        }

        let content: [ReadableContentMetadata] = CoreDataBookInternalManager.shared.getSavedBookInternals()

        // Create a dictionary for fast lookup
        let contentByUUID = Dictionary(uniqueKeysWithValues: content.map { ($0.contentUUID, $0) })

        // Sort according to savedItemsOrder (newest first)
        var sortedContent: [ReadableContentMetadata] = []
        for uuid in savedItemsOrder.reversed() {
            if let item = contentByUUID[uuid] {
                sortedContent.append(item)
            }
        }

        // Add any items not in the order array (fallback for edge cases)
        let orderedUUIDs = Set(savedItemsOrder)
        let missingContent = content.filter { !orderedUUIDs.contains($0.contentUUID) }
        sortedContent.append(contentsOf: missingContent.sorted { $0.title ?? "" < $1.title ?? "" })

        return sortedContent
    }
}
