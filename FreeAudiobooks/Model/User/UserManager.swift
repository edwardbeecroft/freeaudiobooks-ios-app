//
//  UserManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 06/09/2020.
//  Copyright © 2020 Radically Better Ltd. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseFirestore

class UserManager {
	private init() {}
	static let shared = UserManager()
}

extension UserManager {
	func fetchUserWithUUID(_ uuid: String,
						   source: FirestoreSource = .default,
						   completion: @escaping (User?) -> ()) {
		
		let userRef = Firestore.firestore()
			.collection(FirebasePaths.users.rawValue)
			.document(uuid)
		
		userRef.getDocument(source: source) { (snapshot, error) in
			
			if
				let docSnapshot = snapshot,
				docSnapshot.exists,
				let data = docSnapshot.data() {
				
				let user = User(dict: data)
				completion(user)
			} else {
				completion(nil)
			}
		}
	}
}

extension UserManager {
    func buildInitialData(firstName: String,
                          lastName: String,
                          email: String,
                          uid: String,
                          signInMethod: SignInMethod) -> [String: Any] {

        let date = Date()
        var data: [String: Any] = [
            FirebaseUserVariables.firstName.rawValue: firstName,
            FirebaseUserVariables.lastName.rawValue: lastName,
            FirebaseUserVariables.emailAddress.rawValue: email.lowercased(),
            FirebaseUserVariables.signInMethod.rawValue: signInMethod.rawValue,
            FirebaseUserVariables.sourceApp.rawValue: "freeaudiobooks",
            FirebaseUserVariables.uuid.rawValue: uid,
            FirebaseUserVariables.createdDate.rawValue: date,

            FirebaseUserVariables.savedStoryUUIDs.rawValue: [String](),
            FirebaseUserVariables.completedStoryUUIDs.rawValue: [String](),

            FirebaseUserVariables.savedBookInternalUUIDs.rawValue: [String](),
            FirebaseUserVariables.completedBookInternalUUIDs.rawValue: [String](),
            FirebaseUserVariables.savedItemsOrder.rawValue: [String](),

            FirebaseUserVariables.marketingPromptAnswered.rawValue: false,
            FirebaseUserVariables.marketingPermission.rawValue: false,
            FirebaseUserVariables.marketingConsentAmendedDate.rawValue: date,
            FirebaseUserVariables.privacyPolicyConsentMethod.rawValue: User.privacyAcceptMethod,
            FirebaseUserVariables.privacyPolicyAcceptDate.rawValue: date,
            FirebaseUserVariables.fcmTokens.rawValue: [String](),

            // Audiobook quota defaults
            FirebaseUserVariables.audiobookQuotaUUIDsThisMonth.rawValue: [String](),
            FirebaseUserVariables.lastAudiobookQuotaResetDate.rawValue: date,
            FirebaseUserVariables.listeningQuotaBookUUIDsThisWeek.rawValue: [String](),

            // Gamification & Stats defaults
            FirebaseUserVariables.currentStreak.rawValue: 1, // Start at 1 (they're here now!)
            FirebaseUserVariables.longestStreak.rawValue: 1,
            FirebaseUserVariables.lastAppOpenDate.rawValue: date,
            FirebaseUserVariables.streakFreezeUsed.rawValue: false,
            FirebaseUserVariables.totalReadingTimeSeconds.rawValue: 0,
            FirebaseUserVariables.weeklyReadingTimeSeconds.rawValue: 0,
            FirebaseUserVariables.weekStartDate.rawValue: Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: date).date ?? date,
            FirebaseUserVariables.weeklyBooksReadUUIDs.rawValue: [String]()
            // weeklyBooksReadCount is now a computed property
        ]

        // Always pull onboarding data from UserDefaults
        if let genres = NewOnboardingUserDefaults.getSelectedGenres(), !genres.isEmpty {
            data[FirebaseUserVariables.favoriteGenres.rawValue] = genres.map { $0.rawValue }
        } else if let savedGenres = OnboardingGenreUserDefaults.getSelectedGenres() {
            // Legacy fallback
            let genreStrings = savedGenres.map { $0.rawValue }
            data[FirebaseUserVariables.favoriteGenres.rawValue] = genreStrings
            OnboardingGenreUserDefaults.clearSelectedGenres()
        }
        if let frequency = NewOnboardingUserDefaults.getReadingFrequency() {
            data[FirebaseUserVariables.readingFrequency.rawValue] = frequency
        }
        if let occasions = NewOnboardingUserDefaults.getListeningOccasions(), !occasions.isEmpty {
            data[FirebaseUserVariables.listeningOccasions.rawValue] = occasions
        }
        if let source = NewOnboardingUserDefaults.getHowDidYouHear() {
            data[FirebaseUserVariables.howDidYouHear.rawValue] = source
        }
        if let apps = NewOnboardingUserDefaults.getPreviousApps(), !apps.isEmpty {
            data[FirebaseUserVariables.previousApps.rawValue] = apps
        }
        if let reasons = NewOnboardingUserDefaults.getListeningReasons(), !reasons.isEmpty {
            data[FirebaseUserVariables.listeningReasons.rawValue] = reasons
        }
        if let barriers = NewOnboardingUserDefaults.getReadingBarriers(), !barriers.isEmpty {
            data[FirebaseUserVariables.readingBarriers.rawValue] = barriers
        }
        if let goal = NewOnboardingUserDefaults.getDailyListeningGoal() {
            data[FirebaseUserVariables.dailyListeningGoal.rawValue] = goal
        }

        return data
    }
}
