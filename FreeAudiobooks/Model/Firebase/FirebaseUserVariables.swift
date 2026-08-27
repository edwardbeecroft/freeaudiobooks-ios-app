//
//  FirebaseUserVariables.swift
//  LiveCard
//
//  Created by Edward Beecroft on 22/09/2018.
//  Copyright © 2018 SnowDrift Labs. All rights reserved.
//

import Foundation
import FirebaseCore

enum FirebaseUserVariables: String {
	case uuid
	case firstName
	case lastName
    case username
	case emailAddress
	
	case profileImageURLString
	case signInMethod
    case sourceApp
	case createdDate
    
    case savedBookInternalUUIDs
    case completedBookInternalUUIDs
    case reviewedBookInternalUUIDs
    
    case savedStoryUUIDs
    case completedStoryUUIDs
    
    case savedItemsOrder
    
    case marketingPromptAnswered
	case marketingPermission
	case marketingConsentAmendedDate
	case privacyPolicyConsentMethod
	case privacyPolicyAcceptDate
	case appleUserIdentifier
    case fcmTokens

    // Audiobook quota tracking
    case audiobookQuotaUUIDsThisMonth
    case lastAudiobookQuotaResetDate
    case listeningQuotaBookUUIDsThisWeek
    case listeningQuotaWeekStartedAt

    case favoriteGenres

    // Onboarding responses
    case readingFrequency
    case listeningOccasions
    case howDidYouHear
    case previousApps
    case listeningReasons
    case readingBarriers
    case dailyListeningGoal

    // Gamification & Stats
    case currentStreak
    case longestStreak
    case lastAppOpenDate
    case streakFreezeUsed
    case totalReadingTimeSeconds
    case weeklyReadingTimeSeconds
    case weekStartDate
    case weeklyBooksReadCount
    case weeklyBooksReadUUIDs
}

enum FirebasePaths: String {
	case users
    case usernames
    case discoverSections
    case books
    case booksInternal
    case booksInternalTags
    case genreCharts
    case socialPosts
    case reviews
    case sections
    
    case roadmap
    case feedback

    case subscriptionTrials
}

enum SignInMethod: String {
	case manual
	case apple
	case google
}
