//
//  RCValues.swift
//  LiveCard
//
//  Created by Edward Beecroft on 23/09/2018.
//  Copyright © 2018 SnowDrift Labs. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseRemoteConfig

enum RCKeys: String {

	// General
	case privacyPolicyURLAB
	case termsOfUseURLAB
	case minimumAppVersionAB
	case freebooksEmailAB
    case isarAB
    case isarAB2
    case isarAB3
    
    case shareStoryMessageBodyAB
    
    case isReadingVCInterstitialAdEnabled
    case readingVCInterstitialAdSectionGap
  
    case requiredLaunchCountForSKReview
    
    case showRoadmapBetaTag
    case isRoadmapEnabled
    case addRoadmapItemButtonTitle
    case isRoadmapDiscoverHeaderEnabled
    case roadmapDiscoverHeaderImage
    case roadmapInputVariant

	case appStoreReviewURLAB
	case appStoreURLAB

	case monthsBetweenAskingForReview

    // New Onboarding Flow (v4.0.0+)
    case onboardingVariant
    case onboardingVariantv2
    case welcomeVideoVariantAB

    // New Onboarding - Common
    case onbContinueButtonTitle

    // New Onboarding - Welcome Video (Screen 1)
    case onbWelcomeTitleAB
    case onbWelcomeSubtitleAB
    case onbWelcomeButtonTitle

    // New Onboarding - Genre Selection (Screen 2)
    case onbGenreSelectionTitle
    case onbGenreSelectionSubtitle
    case onbGenreSelectionUseSFSymbols

    // New Onboarding - Reading Frequency (Screen 3)
    case onbReadingFrequencyTitleAB
    case onbReadingFrequencySubtitleAB
    case onbListeningOccasionTitleAB
    case onbListeningOccasionSubtitleAB

    // New Onboarding - How Did You Hear (Screen 4)
    case onbHowDidYouHearTitle
    case onbHowDidYouHearSubtitle

    // New Onboarding - Previous Apps (Screen 5)
    case onbPreviousAppsTitleAB
    case onbPreviousAppsSubtitle

    // New Onboarding - Builds Habits Line Chart (Screen 6)
    case onbBuildsHabitsTitleAB
    case onbBuildsHabitsChartLabelAB
    case onbBuildsHabitsMetricAB
    case onbBuildsHabitsFootnoteAB
    case onbBuildsHabitsFreeAudiobooksAB
    case onbBuildsHabitsTryingAlone

    // New Onboarding - Why Do You Listen
    case onbWhyDoYouListenTitleAB
    case onbWhyDoYouListenSubtitleAB

    // New Onboarding - Reading Barriers (Screen 9)
    case onbReadingBarriersTitleAB
    case onbReadingBarriersSubtitle

    // New Onboarding - Make Time Stat (Screen 10) - Personalized Variants
    // Variant 1: lack_of_time
    case onbMakeTimeHeadlineLackOfTimeAB
    case onbMakeTimeStatLackOfTimeAB

    // Variant 2: too_many_choices
    case onbMakeTimeHeadlineTooManyChoicesAB
    case onbMakeTimeStatTooManyChoicesAB

    // Variant 3: hard_to_stay_motivated
    case onbMakeTimeHeadlineHardToStay
    case onbMakeTimeStatHardToStayAB

    // New Onboarding - Daily Listening Goal
    case onbDailyListeningGoalTitleAB
    case onbDailyListeningGoalSubtitleAB

    // New Onboarding - Push Notification (Screen 12)
    case onboardingNotificationsVariantAB
    case onbPushNotificationTitle
    case onbPushNotificationSubtitleAB
    case onbPushNotificationEnableButtonTitle
    case onbPushNotificationConsistencyStat

    // New Onboarding - Credibility Reviews (Screen 15)
    case onbCredibilityReviewsStarRating
    case onbCredibilityReviewsReviewCount
    case onbCredibilityReviewsTitle
    case onbCredibilityReviewsSectionTitleAB
    case onbCredibilityReviewsUserCountAB
    case onbCredibilityReviewsTestimonial1Name
    case onbCredibilityReviewsTestimonial1TextAB
    case onbCredibilityReviewsTestimonial2Name
    case onbCredibilityReviewsTestimonial2TextAB
    case onbCredibilityReviewsTestimonial3Name
    case onbCredibilityReviewsTestimonial3TextAB

    // New Onboarding - Personalized Picks (Screen 18)
    case personalizedPicksVariant
    case onbPersonalizedPicksTitleOriginal
    case onbPersonalizedPicksTitleNoBadge
    case onbPersonalizedPicksSubtitleAB
    case onbPersonalizedPicksRomanceImagev2

    // New Onboarding - Save Progress Auth (Screen 19)
    case onbSaveProgressAuthTitle
    case onbSaveProgressAuthSubtitleAB

    // Part of experiments to get more reviews
    case fullscreenReviewVCButtonTitleAB
    case fullscreenReviewVCIntroText
    case fullscreenReviewVCDetailTextAB
    
    case subscribeSuccessBodyAB
    
	// Social
	case facebookPageURLAB
	case twitterSchemeAB
	case twitterPageURLAB
	case instagramSchemeAB
	case instagramPageURLAB
    case tiktokSchemeAB
    case tiktokPageURLAB
	
    // Engagement Engine
    case shouldSendEngagementEngineNotifications
    case engagementNotificationsDaysDelay
    case engagementNotificationsFollowUpDaysDelay

    // Daily Reminder
    case dailyReminderNotificationTitleAB
    case dailyReminderNotificationBody

    // Onboarding Retention Nudges (first 4-48h activation pushes)
    case shouldSendOnboardingRetentionNudges
    case retentionNudgeEarlyNoBookTitle
    case retentionNudgeEarlyNoBookBodyAB
    case retentionNudgeEarlyBookChosenTitle
    case retentionNudgeEarlyBookChosenBody
    case retentionNudgeEarlyStartedTitle
    case retentionNudgeEarlyStartedBodyAB
    case retentionNudgeEveningNoBookTitle
    case retentionNudgeEveningNoBookBodyAB
    case retentionNudgeEveningBookChosenTitle
    case retentionNudgeEveningBookChosenBodyAB
    case retentionNudgeEveningStartedTitle
    case retentionNudgeEveningStartedBody
    case retentionNudgeFinalNoBookTitleAB
    case retentionNudgeFinalNoBookBodyAB
    case retentionNudgeFinalBookChosenTitle
    case retentionNudgeFinalBookChosenBodyAB
    case retentionNudgeFinalStartedTitle
    case retentionNudgeFinalStartedBody

    case subscribePopupCTA
    
    case weeklyListeningQuotaLimitAB
    case checkConnectivityOnAudioPlaybackAB

    case readingCustomisationPopupTitle
    case readingCustomisationPopupSubtitle
    
    case marketingPermissionsTitle
    case marketingPermissionsSubtitleAB
    case marketingPermissionsUIVariant
    case marketingPermissionsImageNumber
	case marketingPermissionsYesButtonTitle
    case marketingPermissionsNoButtonTitle
    
    case showJoinDiscordInAccountVC
    case discordInviteURLAB
    
	case accountShareWithFriendsCellText
	case shareAppMessageBodyAB
	case logoutAreYouSureBodyAB
	case privacyTermsDialogBody
    
    case pushPrePromptTitleAB
    case pushPrePromptSubtitleAB
    case pushPrePromptEnableCTA
    case pushPrePromptNotNowCTA
	
	// Permissions
	case currentlySubscribedAB
	case notCurrentlySubscribedAB
	
	// Image Moderation
	case inappropriateContentImageTitle
	case singleImageInappropriateContentMessage
	case multipleImagesInappropriateContentMessage
	
    case shouldShowWrittenReviews
    
    case shouldShowEarlyAccessSection
    case showDiscoverEASearchUpsellWidget
    
    case isStatsUIEnabled
    
    case upsellTitleAB
    
    case discoverEarlyAccessUnlockCTATitle
    
    case startReadingCTAVariant
    case homeVariantAB

    // Recap Feature
    case isRecapFeatureEnabled

    // Book completion popup
    case bookCompletionShareButtonTitle
    case bookCompletionTitleLabel
    case bookCompletionRatingPromptLabelAB
    case bookCompletionRatingPromptLabelBookAB
    case bookCompletionReviewPlaceholderTextAB
    case bookCompletionReviewIntroTextAB
    case bookReviewVariantAB

    // Email Opt-In Prompt - Book Saved Trigger
    case emailOptInBookSavedTitle
    case emailOptInBookSavedSubtitle
    case emailOptInBookSavedCTAAB
    case emailOptInBookSavedTitlePaid
    case emailOptInBookSavedSubtitlePaid
    case emailOptInBookSavedCTAPaidAB

    // Email Opt-In Prompt - Book Completed Trigger
    case emailOptInBookCompletedTitle
    case emailOptInBookCompletedSubtitleAB
    case emailOptInBookCompletedCTA
    case emailOptInBookCompletedTitlePaidAB
    case emailOptInBookCompletedSubtitlePaid
    case emailOptInBookCompletedCTAPaid

    // Email Opt-In Prompt - 5th Detail View Trigger
    case emailOptInDetailViewTitleAB
    case emailOptInDetailViewSubtitle
    case emailOptInDetailViewCTA
    case emailOptInDetailViewTitlePaid
    case emailOptInDetailViewSubtitlePaid
    case emailOptInDetailViewCTAPaid

    // Email Opt-In Prompt - New Onboarding Trigger
    case emailOptInOnboardingTitleAB
    case emailOptInOnboardingSubtitle
    case emailOptInOnboardingCTAAB

    // Reading
    case defaultReaderTheme
    case defaultReaderThemeLight
    case defaultReaderThemeDark
    case defaultReadingParagraphStyle
    case shouldResumeOnReadingVC
    case showAdultContentOnCovers
}

class RCValues {
	static let shared = RCValues()
	
	private let remoteConfig: RemoteConfig
	
	private init() {
		remoteConfig = RemoteConfig.remoteConfig()
		loadDefaultValues()
	}
	
	func loadDefaultValues() {
		remoteConfig.setDefaults(fromPlist: "RemoteConfigDefaults")
	}
	
    func fetchCloudValues(expirationDuration: TimeInterval, completion: @escaping () -> Void) {
		remoteConfig.fetch(withExpirationDuration: expirationDuration) { [weak self] status, error in
			guard let self = self else {
				return completion()
			}
			if status == .success {
				self.remoteConfig.activate { success, error in
					completion()
				}
			} else {
				completion()
				print ("Uh-oh. Got an error fetching remote values \(error.debugDescription)")
			}
		}
	}
    
    func rcNeedsRefreshForIncident() -> Bool {
        guard
            let lastFetchTime = remoteConfig.lastFetchTime,
            let time2MinsAgo = Calendar.current.date(byAdding: .minute, value: -2, to: Date()) else { return false }
        
        print("RC: Last fetch time: \(lastFetchTime)")
        print("RC: Time 2 mins ago: \(time2MinsAgo)")
        
        // If we're showing the incident banner, we want to refresh to RC cache every 2 mins
        return lastFetchTime < time2MinsAgo
    }
	
	// Converts our cloud hex to a UIColor
	func color(forKey key: RCKeys) -> UIColor {
		let colorAsHexString = remoteConfig.configValue(forKey: key.rawValue).stringValue ?? "#FFFFFF"
		let convertedColor = UIColor(hexString: colorAsHexString)
		return convertedColor
	}
	
	func bool(forKey key: RCKeys) -> Bool {
		return remoteConfig.configValue(forKey: key.rawValue).boolValue
	}
	
	func string(forKey key: RCKeys) -> String {
		var returnedString = remoteConfig.configValue(forKey: key.rawValue).stringValue ?? ""
		returnedString = returnedString.replacingOccurrences(of: "||", with: "\n")
		return returnedString
	}
	
	func string(forStringKey string: String) -> String? {
		return remoteConfig.configValue(forKey: string).stringValue ?? nil
	}
	
	func double(forKey key: RCKeys, defaultValue: Double = 0.0) -> Double {
		return remoteConfig.configValue(forKey: key.rawValue).numberValue.doubleValue
	}
	
	func int(forKey key: RCKeys) -> Int? {
		return remoteConfig.configValue(forKey: key.rawValue).numberValue.intValue
	}
}

// MARK: - Roadmap Input Variant

/// Defines different roadmap input variants for A/B testing
/// The variant is controlled via RemoteConfig's `roadmapInputVariant` key
enum RoadmapInputVariant: String {
    case typewriter
    case `static`

    /// Gets the current variant from RemoteConfig
    static var current: RoadmapInputVariant {
        let variantString = RCValues.shared.string(forKey: .roadmapInputVariant)
        return RoadmapInputVariant(rawValue: variantString) ?? .typewriter
    }
}

// MARK: - Book Review Variant

enum BookReviewVariant: String {
    case original
    case originalRatingRequired
    case reviewStyle

    static var current: BookReviewVariant {
        let raw = RCValues.shared.string(forKey: .bookReviewVariantAB)
        return BookReviewVariant(rawValue: raw) ?? .original
    }
}

// MARK: - Home Variant

enum HomeVariant: String {
    case original
    case personalized

    static var current: HomeVariant {
        let variantString = RCValues.shared.string(forKey: .homeVariantAB)
        return HomeVariant(rawValue: variantString) ?? .original
    }
}

// MARK: - Onboarding Notifications Variant

enum OnboardingNotificationsVariant: String {
    case original
    case tiles

    static var current: OnboardingNotificationsVariant {
        let variantString = RCValues.shared.string(forKey: .onboardingNotificationsVariantAB)
        return OnboardingNotificationsVariant(rawValue: variantString) ?? .original
    }
}
