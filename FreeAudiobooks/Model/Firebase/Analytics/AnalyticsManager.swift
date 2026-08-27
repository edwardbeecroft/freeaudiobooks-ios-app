
//
//  AnalyticsManager.swift
//  LiveCard
//
//  Created by Edward Beecroft on 25/09/2018.
//  Copyright © 2018 SnowDrift Labs. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseAnalytics
import SuperwallKit

enum AnalyticsParameter: String {
    case paywallPlacement
    case genre
    case readingTimeMins
    case searchState
    case searchSource
    case filterCount
    case homeVariant
    // Snake-case raw values preserve existing Firebase event keys.
    case paywallName = "paywall_name"
    case paywallIdentifier = "paywall_identifier"
    case experimentId = "experiment_id"
    case variantId = "variant_id"
    case variantType = "variant_type"
    case authMethod = "auth_method"
    case listeningQuotaRemaining
    case listeningQuotaLimit
    case listeningQuotaUsed
}

class AnalyticsManager {
	
	static let shared = AnalyticsManager()
	private init() {}
	
	enum EventTypes: String {
		
		// Explore
		case appLaunched
        case coreDataDeleteRequired
        
        case selectFavoriteGenresViewed
        case selectFavoriteGenresCompleted

        // First launch tracking
        case firstLaunchBookMetadataViewed
        case firstLaunchBookViewed

        case discoverViewed
        case searchViewed
        case searchViewedWithState
        case searchGenreCardImpression
        case searchGenreCardTapped
        case searchFiltersOpened
        case searchFiltersApplied
        case searchBookOpened
        case faqsViewed
        case savedStoriesViewed
        case accountViewed
        case accountUpsellTapped
        
        case tappedDiscoverEarlyAccessCTA
        case earlyAccessSearchUpsellTapped

        case bookMetadataViewed
        case bookViewed
        
        case bookInternalMetadataViewed
        case bookInternalViewed
        case bookInternalAudioViewed
        
        case bookInternalSaved
        case bookInternalUnsaved
        case bookInternalCompleted
        case bookInternalCompletedRomance
        case bookInternalAudioCompleted // Additional to bookInternalCompleted, which is called for both text/audio completions
        case bookInternalUncompleted
        
        case bookRatingSubmitted
        case bookInternalRatingSubmitted // Internal
        case bookInternalAudiobookRatingSubmitted // Internal - audiobook
        case bookRatingSubmittedWithComment // All
        
        
        case showPaywallPrePopupChecked
        
        case bookOffsetOutOfBounds
        
        case bookSaved
        case bookUnsaved
        case bookCompleted
        case bookUncompleted
        
        case storyUpvoted
        case storyUpvoteRemoved
        
        case helpUsGrowViewed
        case helpUsGrowReviewTapped
        case helpUsGrowNotNowTapped
        
        case roadmapViewed
        case roadmapAddItemTapped
        case roadmapItemSubmitted
        case roadmapItemUpvoted
        case roadmapDiscoverHeaderCapsuleSeen
        case roadmapDiscoverHeaderCapsuleTapped

		// User Account & Profile
		case userLoggedIn
		case userLoginError
		case userRegisterError
		case userLoggedOut
		case userSetProfileImage
		case updatedMarketingPreferences
		case viewedAccountDetails
		case changedEmail
		case changedPassword
		case viewedPrivacy
		case viewedTerms
		case tappedContactSupport
		case viewedFAQs
		case tappedSocialPage
		case tappedSocialShare
		case signInWithAppleFailed
		case signInWithAppleFailedNoEmail
        case tappedSubmitFeatureRequest
        case tappedQuickAction
		
		case tappedReviewApp
		case requestedAppReviewAutomatically
		
        // Paywall
		case paywallViewed
		case paywallUserSubscribed
        case postOnboardingPaywallSubscribed
        case listeningQuotaPaywallSubscribed
        case userSubscribedForAccountUpsell
        case listeningQuotaDepletedSheetViewed
        case paywallUserSubscribedForDLPlacement

        // Offline playback upsell
        case listenOfflineUpsellShown
        case listenOfflineUpsellSubTapped
        case listenOfflineUpsellDismissed
        
		case paywallRestorePurchasesSuccess
		
		// Misc
        case allowedNotifications
		case allowedNotificationsInReg
		case rejectedNotificationsInReg

        // Engagement Engine
        case scheduledBookEngagementPushNotification
        case tappedBookEngagementPushNotification

        // Daily Reminder
        case scheduledDailyReminderNotification
        case tappedDailyReminderNotification
        case viewedDailyReminderSettings
        case savedDailyReminderSettings
        case disabledDailyReminders

        // Onboarding Retention Nudges
        case scheduledOnboardingRetentionNudges
        case tappedOnboardingRetentionNudge
        case cancelledOnboardingRetentionNudges

        case explicitImageDetected

        // Push Pre-Permission Prompt
        case pushPrePromptViewed
        case pushPrePromptNotNowTapped
        case pushPrePromptEnableTapped
        case pushPermissionGranted
        case pushPermissionDenied
        
        case subscribePopupCTADisplayed
        case subscribePopupCTATapped

        // Reading Milestones
        case readingStarted
        case readingActivated
        case listeningQuotaBookConsumed
        case readingOnboardingAutoRevealShown
        case readingOnboardingLearned

        // Gamification & Stats
        case streakIncremented
        case streakReset
        case streakFreezeUsed
        case streakMilestoneReached
        case achievedNewLongestStreak
        case viewedStatsPage

        // Feedback
        case userFeedbackFormViewed
        case userFeedbackSubmitted

        case startReadingTapped

        // Enhanced Book Completion
        case enhancedBookCompletionViewed
        case enhancedBookCompletionShareViewed
        case enhancedBookCompletionShareTapped
        case enhancedBookCompletionShareCompleted
        case enhancedBookCompletionShareSkipped

        // New Onboarding Flow (v4.0.0+)
        case newOnboardingStarted
        case newOnboardingCompleted
        case newOnboardingAbandoned

        // New Onboarding - Screen Events
        case onbWelcomeVideoScreenViewed
        case onbWelcomeVideoContinueTapped
        case onbGenreSelectionScreenViewed
        case onbGenreSelectionContinueTapped
        case onbListeningOccasionScreenViewed
        case onbListeningOccasionContinueTapped
        case onbReadingFrequencyScreenViewed
        case onbReadingFrequencyContinueTapped
        case onbHowDidYouHearScreenViewed
        case onbHowDidYouHearContinueTapped
        case onbPreviousAppsScreenViewed
        case onbPreviousAppsContinueTapped
        case onbBuildsHabitsLineChartScreenViewed
        case onbBuildsHabitsLineChartContinueTapped
        case onbWhyDoYouListenScreenViewed
        case onbWhyDoYouListenContinueTapped
        case onbReadingBarriersScreenViewed
        case onbReadingBarriersContinueTapped
        case onbReadingBarrierResolutionScreenViewed
        // Explicit rawValue: the identifier is 41 chars, over Firebase's 40-char event-name limit (over-limit events are silently dropped).
        case onbReadingBarrierResolutionContinueTapped = "onbReadingBarrierResContinueTapped"
        case onbDailyListeningGoalScreenViewed
        case onbDailyListeningGoalContinueTapped
        case onbGenreSelected
        case onbPreviousAppSelected
        case onbListeningReasonSelected
        case onbReadingBarrierSelected
        case onbPushNotificationScreenViewed
        case onbPushNotificationContinueTapped
        case onbPushNotificationGranted
        case onbPushNotificationDenied
        case onbPushNotificationSkipped
        case onbCredibilityReviewsScreenViewed
        case onbCredibilityReviewsContinueTapped
        case onbPersonalizedPicksScreenViewed
        case onbPersonalizedPicksContinueTapped
        case onbPersonalizedPicksRomanceActivatedv2
        case onbSaveProgressAuthScreenViewed
        case onbSaveProgressAuthAppleTapped
        case onbSaveProgressAuthGoogleTapped
        case onbSaveProgressAuthEmailTapped
        case onbSaveProgressAuthComplete
        case onbPaywallScreenViewed
        case onbPaywallSubscribed
        case onbPaywallDeclined

        // Email Opt-In Prompt
        case emailOptInPromptShown
        case emailOptInPromptNotNow
        case emailOptInOptedIn
        case emailOptInPromptSuppressed

        // Book Recap
        case recapViewed
        case recapGenerated
        case recapError
        case recapContinueReadingTapped
        case recapDismissed
        case recapRetryTapped
	}
	
	// Explore
	func trackAppLaunched() {
        handleLogEvent(eventName: EventTypes.appLaunched.rawValue, parameters: nil)
	}
    func trackCoreDataDeleteRequired() {
        handleLogEvent(eventName: EventTypes.coreDataDeleteRequired.rawValue, parameters: nil)
    }
    
    func trackSelectFavoriteGenresViewed() {
        handleLogEvent(eventName: EventTypes.selectFavoriteGenresViewed.rawValue, parameters: nil)
    }
    func trackSelectFavoriteGenresCompleted() {
        handleLogEvent(eventName: EventTypes.selectFavoriteGenresCompleted.rawValue, parameters: nil)
    }
    
    // MARK: - First Launch Tracking

    func trackFirstLaunchBookMetadataViewed() {
        handleLogEvent(eventName: EventTypes.firstLaunchBookMetadataViewed.rawValue, parameters: nil)
    }
    func trackFirstLaunchBookViewed() {
        handleLogEvent(eventName: EventTypes.firstLaunchBookViewed.rawValue, parameters: nil)
    }

    func trackBookInternalMetadataViewed(genre: BookInternalGenre) {
        handleLogEvent(eventName: EventTypes.bookInternalMetadataViewed.rawValue,
                       parameters: [AnalyticsParameter.genre.rawValue: genre.displayString])
    }
    func trackBookMetadataViewed() {
        handleLogEvent(eventName: EventTypes.bookMetadataViewed.rawValue, parameters: nil)
    }
    
    func trackBookViewed() {
        handleLogEvent(eventName: EventTypes.bookViewed.rawValue, parameters: nil)
    }
    func trackBookInternalViewed(genre: BookInternalGenre) {
        handleLogEvent(eventName: EventTypes.bookInternalViewed.rawValue,
                       parameters: [AnalyticsParameter.genre.rawValue: genre.displayString])
    }
    func trackBookInternalAudioViewed(genre: BookInternalGenre) {
        handleLogEvent(eventName: EventTypes.bookInternalAudioViewed.rawValue,
                       parameters: [AnalyticsParameter.genre.rawValue: genre.displayString])
    }
    
    func trackDiscoverViewed(homeVariant: HomeVariant = .original) {
        handleLogEvent(eventName: EventTypes.discoverViewed.rawValue,
                       parameters: [AnalyticsParameter.homeVariant.rawValue: homeVariant.rawValue])
    }
    func trackSearchViewed() {
        handleLogEvent(eventName: EventTypes.searchViewed.rawValue, parameters: nil)
    }
    func trackSearchViewedWithState(state: String) {
        handleLogEvent(eventName: EventTypes.searchViewedWithState.rawValue,
                       parameters: [AnalyticsParameter.searchState.rawValue: state])
    }
    func trackSearchGenreCardImpression(genre: BookInternalGenre, state: String) {
        handleLogEvent(eventName: EventTypes.searchGenreCardImpression.rawValue,
                       parameters: [
                        AnalyticsParameter.genre.rawValue: genre.displayString,
                        AnalyticsParameter.searchState.rawValue: state
                       ])
    }
    func trackSearchGenreCardTapped(genre: BookInternalGenre, state: String) {
        handleLogEvent(eventName: EventTypes.searchGenreCardTapped.rawValue,
                       parameters: [
                        AnalyticsParameter.genre.rawValue: genre.displayString,
                        AnalyticsParameter.searchState.rawValue: state
                       ])
    }
    func trackSearchFiltersOpened(state: String) {
        handleLogEvent(eventName: EventTypes.searchFiltersOpened.rawValue,
                       parameters: [AnalyticsParameter.searchState.rawValue: state])
    }
    func trackSearchFiltersApplied(filterCount: Int, state: String) {
        handleLogEvent(eventName: EventTypes.searchFiltersApplied.rawValue,
                       parameters: [
                        AnalyticsParameter.filterCount.rawValue: filterCount,
                        AnalyticsParameter.searchState.rawValue: state
                       ])
    }
    func trackSearchBookOpened(source: String, state: String, genre: BookInternalGenre) {
        handleLogEvent(eventName: EventTypes.searchBookOpened.rawValue,
                       parameters: [
                        AnalyticsParameter.searchSource.rawValue: source,
                        AnalyticsParameter.searchState.rawValue: state,
                        AnalyticsParameter.genre.rawValue: genre.displayString
                       ])
    }
    func trackFAQsViewed() {
        handleLogEvent(eventName: EventTypes.faqsViewed.rawValue, parameters: nil)
    }
    func trackSavedStoriesViewed() {
        handleLogEvent(eventName: EventTypes.savedStoriesViewed.rawValue, parameters: nil)
    }
    func trackAccountViewed() {
        handleLogEvent(eventName: EventTypes.accountViewed.rawValue, parameters: nil)
    }
    func trackAccountUpsellTapped() {
        handleLogEvent(eventName: EventTypes.accountUpsellTapped.rawValue, parameters: nil)
    }
    
    func trackBookInternalSaved(genre: BookInternalGenre) {
        handleLogEvent(eventName: EventTypes.bookInternalSaved.rawValue,
                       parameters: [AnalyticsParameter.genre.rawValue: genre.displayString])
    }
    func trackBookInternalUnsaved() {
        handleLogEvent(eventName: EventTypes.bookInternalUnsaved.rawValue, parameters: nil)
    }
    func trackBookInternalCompleted(cdBookInternal: CDBookInternal) {
        let parameters: [String: Any] = [
            AnalyticsParameter.genre.rawValue: cdBookInternal.genre.displayString,
            AnalyticsParameter.readingTimeMins.rawValue: cdBookInternal.readingTimeInt
        ]
        
        handleLogEvent(eventName: EventTypes.bookInternalCompleted.rawValue,
                       parameters: parameters)
        
        if cdBookInternal.genre == .romance {
            handleLogEvent(eventName: EventTypes.bookInternalCompletedRomance.rawValue,
                           parameters: parameters)
        }
    }
    func trackBookInternalAudioCompleted(cdBookInternal: CDBookInternal) {
        handleLogEvent(eventName: EventTypes.bookInternalAudioCompleted.rawValue,
                       parameters: [AnalyticsParameter.genre.rawValue: cdBookInternal.genre.displayString])
    }
    func trackBookInternalUncompleted() {
        handleLogEvent(eventName: EventTypes.bookInternalUncompleted.rawValue, parameters: nil)
    }
    
    func trackBookRatingSubmitted(rating: Double) {
        handleLogEvent(eventName: EventTypes.bookRatingSubmitted.rawValue,
                       parameters: ["bookRating": "\(Int(rating))"])
    }
    func trackBookInternalRatingSubmitted(rating: Double,
                                          genre: BookInternalGenre) {
        handleLogEvent(eventName: EventTypes.bookInternalRatingSubmitted.rawValue,
                       parameters: ["bookInternalRating": "\(Int(rating))",
                                    AnalyticsParameter.genre.rawValue: genre.displayString])
    }
    func trackBookInternalAudiobookRatingSubmitted(rating: Double,
                                                   genre: BookInternalGenre) {
        handleLogEvent(eventName: EventTypes.bookInternalAudiobookRatingSubmitted.rawValue,
                       parameters: ["bookInternalAudiobookRating": "\(Int(rating))",
                                    AnalyticsParameter.genre.rawValue: genre.displayString])
    }
    func trackBookRatingSubmittedWithComment(rating: Double,
                                             genre: BookInternalGenre) {
        handleLogEvent(eventName: EventTypes.bookRatingSubmittedWithComment.rawValue,
                       parameters: ["bookInternalRating": "\(Int(rating))",
                                    AnalyticsParameter.genre.rawValue: genre.displayString])
    }
    
    func trackBookOffsetOutOfBounds() {
        handleLogEvent(eventName: EventTypes.bookOffsetOutOfBounds.rawValue, parameters: nil)
    }
    
    func trackBookSaved() {
        handleLogEvent(eventName: EventTypes.bookSaved.rawValue, parameters: nil)
    }
    func trackBookUnsaved() {
        handleLogEvent(eventName: EventTypes.bookUnsaved.rawValue, parameters: nil)
    }
    func trackBookCompleted() {
        handleLogEvent(eventName: EventTypes.bookCompleted.rawValue, parameters: nil)
    }
    func trackBookUncompleted() {
        handleLogEvent(eventName: EventTypes.bookUncompleted.rawValue, parameters: nil)
    }
    
    // Paywall
    func trackShowPaywallPrePopupChecked() {
        handleLogEvent(eventName: EventTypes.showPaywallPrePopupChecked.rawValue, parameters: nil)
    }
    
    func trackStoryUpvoted() {
        handleLogEvent(eventName: EventTypes.storyUpvoted.rawValue, parameters: nil)
    }
    func trackStoryUpvoteRemoved() {
        handleLogEvent(eventName: EventTypes.storyUpvoteRemoved.rawValue, parameters: nil)
    }
    
    func trackHelpUsGrowViewed() {
        handleLogEvent(eventName: EventTypes.helpUsGrowViewed.rawValue, parameters: nil)
    }
    func trackHelpUsGrowReviewTapped() {
        handleLogEvent(eventName: EventTypes.helpUsGrowReviewTapped.rawValue, parameters: nil)
    }
    func trackHelpUsGrowNotNowTapped() {
        handleLogEvent(eventName: EventTypes.helpUsGrowNotNowTapped.rawValue, parameters: nil)
    }
    
    func trackRoadmapViewed() {
        handleLogEvent(eventName: EventTypes.roadmapViewed.rawValue, parameters: nil)
    }
    func trackRoadmapAddItemTapped() {
        handleLogEvent(eventName: EventTypes.roadmapAddItemTapped.rawValue, parameters: nil)
    }
    func trackRoadmapItemSubmitted() {
        handleLogEvent(eventName: EventTypes.roadmapItemSubmitted.rawValue, parameters: nil)
    }
    func trackRoadmapItemUpvoted() {
        handleLogEvent(eventName: EventTypes.roadmapItemUpvoted.rawValue, parameters: nil)
    }
    func trackRoadmapDiscoverHeaderCapsuleSeen() {
        handleLogEvent(eventName: EventTypes.roadmapDiscoverHeaderCapsuleSeen.rawValue, parameters: nil)
    }
    func trackRoadmapDiscoverHeaderCapsuleTapped() {
        handleLogEvent(eventName: EventTypes.roadmapDiscoverHeaderCapsuleTapped.rawValue, parameters: nil)
    }

    func trackPaywallViewedForPlacement(_ placement: PaywallPlacement,
                                        paywallInfo: PaywallInfo? = nil) {
        var parameters: [String: Any] = [
            AnalyticsParameter.paywallPlacement.rawValue: placement.rawValue
        ]
        if let paywallInfo = paywallInfo {
            parameters[AnalyticsParameter.paywallName.rawValue] = paywallInfo.name
            parameters[AnalyticsParameter.paywallIdentifier.rawValue] = paywallInfo.identifier
            if let experiment = paywallInfo.experiment {
                parameters[AnalyticsParameter.experimentId.rawValue] = experiment.id
                parameters[AnalyticsParameter.variantId.rawValue] = experiment.variant.id
                parameters[AnalyticsParameter.variantType.rawValue] = experiment.variant.type == .holdout ? "holdout" : "treatment"
            }
        }
        handleLogEvent(eventName: EventTypes.paywallViewed.rawValue,
                       parameters: parameters)
    }

    func trackListeningQuotaDepletedSheetViewed(cdBookInternal: CDBookInternal?) {
        var parameters: [String: Any] = [
            AnalyticsParameter.paywallPlacement.rawValue: PaywallPlacement.listeningQuota.rawValue,
            AnalyticsParameter.listeningQuotaRemaining.rawValue: ListeningQuotaManager.shared.remaining,
            AnalyticsParameter.listeningQuotaLimit.rawValue: ListeningQuotaManager.shared.weeklyLimit,
            AnalyticsParameter.listeningQuotaUsed.rawValue: ListeningQuotaManager.shared.normalisedBookUUIDs.count
        ]
        if let genre = cdBookInternal?.genre {
            parameters[AnalyticsParameter.genre.rawValue] = genre.displayString
        }
        if let readingTimeMins = cdBookInternal?.readingTimeInt {
            parameters[AnalyticsParameter.readingTimeMins.rawValue] = readingTimeMins
        }
        handleLogEvent(eventName: EventTypes.listeningQuotaDepletedSheetViewed.rawValue,
                       parameters: parameters)
    }

    func trackPaywallUserSubscribed(placement: PaywallPlacement, cdBookInternal: CDBookInternal?) {
        var parameters: [String: Any] = [
            AnalyticsParameter.paywallPlacement.rawValue: placement.rawValue
        ]
        if let genre = cdBookInternal?.genre {
            parameters[AnalyticsParameter.genre.rawValue] = genre.displayString
        }
        if let readingTimeMins = cdBookInternal?.readingTimeInt {
            parameters[AnalyticsParameter.readingTimeMins.rawValue] = readingTimeMins
        }
        handleLogEvent(eventName: EventTypes.paywallUserSubscribed.rawValue,
                       parameters: parameters)

        if placement != .onboarding {
            handleLogEvent(eventName: EventTypes.postOnboardingPaywallSubscribed.rawValue,
                           parameters: parameters)
        }

        if placement == .listeningQuota {
            handleLogEvent(eventName: EventTypes.listeningQuotaPaywallSubscribed.rawValue,
                           parameters: parameters)
        }
    }
    func trackPaywallUserSubscribedForAccountUpsell() {
        handleLogEvent(eventName: EventTypes.userSubscribedForAccountUpsell.rawValue,
                       parameters: nil)
    }
    func trackPaywallUserSubscribedForDLPlacement() {
        handleLogEvent(eventName: EventTypes.paywallUserSubscribedForDLPlacement.rawValue,
                       parameters: nil)
    }

    // Offline playback upsell
    func trackListenOfflineUpsellShown() {
        handleLogEvent(eventName: EventTypes.listenOfflineUpsellShown.rawValue, parameters: nil)
    }
    func trackListenOfflineUpsellSubscribeTapped() {
        handleLogEvent(eventName: EventTypes.listenOfflineUpsellSubTapped.rawValue, parameters: nil)
    }
    func trackListenOfflineUpsellDismissed() {
        handleLogEvent(eventName: EventTypes.listenOfflineUpsellDismissed.rawValue, parameters: nil)
    }
    func trackTappedDiscoverEarlyAccessCTA() {
        handleLogEvent(eventName: EventTypes.tappedDiscoverEarlyAccessCTA.rawValue,
                       parameters: nil)
    }
    func trackEarlyAccessSearchUpsellTapped() {
        handleLogEvent(eventName: EventTypes.earlyAccessSearchUpsellTapped.rawValue,
                       parameters: nil)
    }
    
    func trackSubscribePopupCTADisplayed() {
        handleLogEvent(eventName: EventTypes.subscribePopupCTADisplayed.rawValue,
                       parameters: nil)
    }
    func trackSubscribePopupCTATapped() {
        handleLogEvent(eventName: EventTypes.subscribePopupCTATapped.rawValue,
                       parameters: nil)
    }
    
	// Paywall - Restore
	func trackPaywallRestorePurchasesSuccess() {
        handleLogEvent(eventName: EventTypes.paywallRestorePurchasesSuccess.rawValue, parameters: nil)
	}
	
	// App Reviews
	func trackTappedReviewApp() {
        handleLogEvent(eventName: EventTypes.tappedReviewApp.rawValue, parameters: nil)
	}
	func trackRequestedAppReviewAutomatically(venue: SKReviewVenue) {
        handleLogEvent(eventName: EventTypes.requestedAppReviewAutomatically.rawValue, parameters: ["requestAppReviewVenue": venue.rawValue])
	}
	
	// User Account
	func trackUserLoggedIn() {
        handleLogEvent(eventName: EventTypes.userLoggedIn.rawValue, parameters: nil)
	}
	func trackUserLogInError() {
        handleLogEvent(eventName: EventTypes.userLoginError.rawValue, parameters: nil)
	}
	func trackUserRegisterError() {
        handleLogEvent(eventName: EventTypes.userRegisterError.rawValue, parameters: nil)
	}
	func trackSignInWithAppleFailed(reason: String) {
        handleLogEvent(eventName: EventTypes.signInWithAppleFailed.rawValue, parameters: ["signInWithAppleFailReason": reason])
	}
	func trackSignInWithAppleFailedNoEmail() {
        handleLogEvent(eventName: EventTypes.signInWithAppleFailedNoEmail.rawValue, parameters: nil)
	}
	func trackUserLoggedOut() {
        handleLogEvent(eventName: EventTypes.userLoggedOut.rawValue, parameters: nil)
	}
	func trackUserSetProfileImage() {
        handleLogEvent(eventName: EventTypes.userSetProfileImage.rawValue, parameters: nil)
	}
	func trackUserUpdatedMarketingPreferences(subscribed: Bool) {
        let no = L10n.no
        let yes = L10n.yes
        
        let subscribedText = subscribed ? yes : no
        handleLogEvent(eventName: EventTypes.updatedMarketingPreferences.rawValue, parameters: ["subscribed": subscribedText])
	}
	func trackViewedAccountDetails() {
        handleLogEvent(eventName: EventTypes.viewedAccountDetails.rawValue, parameters: nil)
	}
	func trackChangedEmail() {
		handleLogEvent(eventName: EventTypes.changedEmail.rawValue, parameters: nil)
	}
	func trackChangedPassword() {
		handleLogEvent(eventName: EventTypes.changedPassword.rawValue, parameters: nil)
	}
	func trackViewedPrivacy() {
		handleLogEvent(eventName: EventTypes.viewedPrivacy.rawValue, parameters: nil)
	}
	func trackViewedTerms() {
		handleLogEvent(eventName: EventTypes.viewedTerms.rawValue, parameters: nil)
	}
	func trackTappedContactSupport() {
		handleLogEvent(eventName: EventTypes.tappedContactSupport.rawValue, parameters: nil)
	}
    func trackTappedSubmitFeatureRequest() {
        handleLogEvent(eventName: EventTypes.tappedSubmitFeatureRequest.rawValue, parameters: nil)
    }
    func trackTappedQuickAction(type: String) {
        handleLogEvent(eventName: EventTypes.tappedQuickAction.rawValue, parameters: ["type": type])
    }
	func trackViewedFAQs() {
		handleLogEvent(eventName: EventTypes.viewedFAQs.rawValue, parameters: nil)
	}
	func trackTappedSocialPage(medium: SocialPage) {
        handleLogEvent(eventName: EventTypes.tappedSocialPage.rawValue, parameters: ["medium": medium.rawValue])
	}
	enum SocialPage: String {
		case facebook
		case twitter
		case instagram
        case tiktok
	}
	func trackTappedSocialShare() {
		handleLogEvent(eventName: EventTypes.tappedSocialShare.rawValue, parameters: nil)
	}
	// Notifications - Registration
    func trackAllowedPushNotifications() {
        handleLogEvent(eventName: EventTypes.allowedNotifications.rawValue, parameters: nil)
    }
	func trackAllowedPushNotificationsInReg() {
		handleLogEvent(eventName: EventTypes.allowedNotificationsInReg.rawValue, parameters: nil)
	}
	func trackRejectedPushNotificationsInReg() {
		handleLogEvent(eventName: EventTypes.rejectedNotificationsInReg.rawValue, parameters: nil)
	}

    // Engagement Engine
    func trackScheduledBookEngagementPushNotification() {
        handleLogEvent(eventName: EventTypes.scheduledBookEngagementPushNotification.rawValue, parameters: nil)
    }
    func trackTappedBookEngagementPushNotification() {
        handleLogEvent(eventName: EventTypes.tappedBookEngagementPushNotification.rawValue, parameters: nil)
    }

    // Daily Reminder
    func trackScheduledDailyReminderNotification() {
        handleLogEvent(eventName: EventTypes.scheduledDailyReminderNotification.rawValue, parameters: nil)
    }
    func trackTappedDailyReminderNotification() {
        handleLogEvent(eventName: EventTypes.tappedDailyReminderNotification.rawValue, parameters: nil)
    }
    func trackViewedDailyReminderSettings() {
        handleLogEvent(eventName: EventTypes.viewedDailyReminderSettings.rawValue, parameters: nil)
    }
    func trackSavedDailyReminderSettings() {
        handleLogEvent(eventName: EventTypes.savedDailyReminderSettings.rawValue, parameters: nil)
    }
    func trackDisabledDailyReminders() {
        handleLogEvent(eventName: EventTypes.disabledDailyReminders.rawValue, parameters: nil)
    }

    // Onboarding Retention Nudges
    func trackScheduledOnboardingRetentionNudges() {
        handleLogEvent(eventName: EventTypes.scheduledOnboardingRetentionNudges.rawValue, parameters: nil)
    }
    func trackTappedOnboardingRetentionNudge(slot: Int, segment: String) {
        handleLogEvent(
            eventName: EventTypes.tappedOnboardingRetentionNudge.rawValue,
            parameters: ["slot": slot, "segment": segment]
        )
    }
    func trackCancelledOnboardingRetentionNudges(reason: String) {
        handleLogEvent(
            eventName: EventTypes.cancelledOnboardingRetentionNudges.rawValue,
            parameters: ["reason": reason]
        )
    }

    // Image Moderation
    func trackExplicitImageDetected() {
        handleLogEvent(eventName: EventTypes.explicitImageDetected.rawValue, parameters: nil)
    }

    // Push Pre-Permission Prompt
    func trackPushPrePromptViewed() {
        handleLogEvent(eventName: EventTypes.pushPrePromptViewed.rawValue, parameters: nil)
    }
    func trackPushPrePromptNotNowTapped() {
        handleLogEvent(eventName: EventTypes.pushPrePromptNotNowTapped.rawValue, parameters: nil)
    }
    func trackPushPrePromptEnableTapped() {
        handleLogEvent(eventName: EventTypes.pushPrePromptEnableTapped.rawValue, parameters: nil)
    }
    func trackPushPermissionGranted() {
        handleLogEvent(eventName: EventTypes.pushPermissionGranted.rawValue, parameters: nil)
    }
    func trackPushPermissionDenied() {
        handleLogEvent(eventName: EventTypes.pushPermissionDenied.rawValue, parameters: nil)
    }

    // Reading Milestones
    func trackReadingStarted() {
        handleLogEvent(eventName: EventTypes.readingStarted.rawValue, parameters: nil)
    }
    func trackReadingActivated() {
        handleLogEvent(eventName: EventTypes.readingActivated.rawValue, parameters: nil)
    }
    func trackListeningQuotaBookConsumed() {
        handleLogEvent(
            eventName: EventTypes.listeningQuotaBookConsumed.rawValue,
            parameters: [
                AnalyticsParameter.listeningQuotaRemaining.rawValue: ListeningQuotaManager.shared.remaining,
                AnalyticsParameter.listeningQuotaLimit.rawValue: ListeningQuotaManager.shared.weeklyLimit,
                AnalyticsParameter.listeningQuotaUsed.rawValue: ListeningQuotaManager.shared.normalisedBookUUIDs.count
            ]
        )
    }
    func trackReadingOnboardingAutoRevealShown() {
        handleLogEvent(eventName: EventTypes.readingOnboardingAutoRevealShown.rawValue, parameters: nil)
    }
    func trackReadingOnboardingLearned() {
        handleLogEvent(eventName: EventTypes.readingOnboardingLearned.rawValue, parameters: nil)
    }

    func handleLogEvent(eventName: String, parameters: [String: Any]?) {
        let cleanedParameters = cleanParametersForFirebase(parameters)
        Analytics.logEvent(eventName, parameters: cleanedParameters)
    }

    private func cleanParametersForFirebase(_ parameters: [String: Any]?) -> [String: Any]? {
        guard let params = parameters, !params.isEmpty else { return nil }

        var cleanedParams: [String: Any] = [:]
        let maxParameters = 25
        let maxValueLength = 100

        for (key, value) in params {
            // Stop if we've reached the parameter limit
            if cleanedParams.count >= maxParameters {
                break
            }

            // Convert value to string if needed
            let stringValue: String
            if let strValue = value as? String {
                stringValue = strValue
            } else if let numValue = value as? NSNumber {
                stringValue = numValue.stringValue
            } else {
                stringValue = String(describing: value)
            }

            // Filter out Superwall internal editor URLs - they don't add analytical value
            if stringValue.starts(with: "https://user-content.superwalleditor.com") {
                continue
            }

            // Truncate to max length if needed
            if stringValue.count > maxValueLength {
                let truncated = String(stringValue.prefix(maxValueLength - 3)) + "..."
                cleanedParams[key] = truncated
            } else {
                cleanedParams[key] = stringValue
            }
        }

        return cleanedParams.isEmpty ? nil : cleanedParams
    }

    // MARK: - Gamification & Stats

    func trackStreakIncremented(streak: Int) {
        handleLogEvent(eventName: EventTypes.streakIncremented.rawValue,
                       parameters: ["streak": streak])
    }

    func trackStreakReset(previousStreak: Int) {
        handleLogEvent(eventName: EventTypes.streakReset.rawValue,
                       parameters: ["previous_streak": previousStreak])
    }

    func trackStreakFreezeUsed(streak: Int) {
        handleLogEvent(eventName: EventTypes.streakFreezeUsed.rawValue,
                       parameters: ["streak": streak])
    }

    func trackStreakMilestoneReached(milestone: Int) {
        handleLogEvent(eventName: EventTypes.streakMilestoneReached.rawValue,
                       parameters: ["milestone": milestone])
    }

    func trackAchievedNewLongestStreak(streak: Int) {
        handleLogEvent(eventName: EventTypes.achievedNewLongestStreak.rawValue,
                       parameters: ["streak": streak])
    }

    func trackViewedStatsPage() {
        handleLogEvent(eventName: EventTypes.viewedStatsPage.rawValue, parameters: nil)
    }

    // Feedback
    func trackUserFeedbackFormViewed() {
        handleLogEvent(eventName: EventTypes.userFeedbackFormViewed.rawValue, parameters: nil)
    }
    func trackUserFeedbackSubmitted() {
        handleLogEvent(eventName: EventTypes.userFeedbackSubmitted.rawValue, parameters: nil)
    }
    
    func trackStartReadingTapped() {
        handleLogEvent(eventName: EventTypes.startReadingTapped.rawValue, parameters: nil)
    }

    // MARK: - Enhanced Book Completion

    func trackEnhancedBookCompletionViewed() {
        handleLogEvent(eventName: EventTypes.enhancedBookCompletionViewed.rawValue, parameters: nil)
    }

    func trackEnhancedBookCompletionShareViewed() {
        handleLogEvent(eventName: EventTypes.enhancedBookCompletionShareViewed.rawValue, parameters: nil)
    }

    func trackEnhancedBookCompletionShareTapped() {
        handleLogEvent(eventName: EventTypes.enhancedBookCompletionShareTapped.rawValue, parameters: nil)
    }

    func trackEnhancedBookCompletionShareCompleted() {
        handleLogEvent(eventName: EventTypes.enhancedBookCompletionShareCompleted.rawValue, parameters: nil)
    }

    func trackEnhancedBookCompletionShareSkipped() {
        handleLogEvent(eventName: EventTypes.enhancedBookCompletionShareSkipped.rawValue, parameters: nil)
    }

    // MARK: - New Onboarding Flow (v4.0.0+)

    func trackNewOnboardingStarted(variant: String) {
        handleLogEvent(eventName: EventTypes.newOnboardingStarted.rawValue,
                       parameters: ["variant": variant])
    }

    func trackNewOnboardingCompleted(variant: String,
                                     didSubscribe: Bool,
                                     paywallName: String?,
                                     paywallIdentifier: String?,
                                     experimentId: String?,
                                     variantId: String?,
                                     variantType: String?) {
        var parameters: [String: Any] = [
            "variant": variant,
            "did_subscribe": didSubscribe
        ]
        if let paywallName = paywallName {
            parameters[AnalyticsParameter.paywallName.rawValue] = paywallName
        }
        if let paywallIdentifier = paywallIdentifier {
            parameters[AnalyticsParameter.paywallIdentifier.rawValue] = paywallIdentifier
        }
        if let experimentId = experimentId {
            parameters[AnalyticsParameter.experimentId.rawValue] = experimentId
        }
        if let variantId = variantId {
            parameters[AnalyticsParameter.variantId.rawValue] = variantId
        }
        if let variantType = variantType {
            parameters[AnalyticsParameter.variantType.rawValue] = variantType
        }
        handleLogEvent(eventName: EventTypes.newOnboardingCompleted.rawValue,
                       parameters: parameters)
    }

    func trackNewOnboardingAbandoned(variant: String, lastStep: String) {
        handleLogEvent(eventName: EventTypes.newOnboardingAbandoned.rawValue,
                       parameters: ["variant": variant, "last_step": lastStep])
    }

    // MARK: - New Onboarding Screen Events

    func trackOnbWelcomeVideoScreenViewed() {
        handleLogEvent(eventName: EventTypes.onbWelcomeVideoScreenViewed.rawValue, parameters: nil)
    }
    func trackOnbWelcomeVideoContinueTapped() {
        handleLogEvent(eventName: EventTypes.onbWelcomeVideoContinueTapped.rawValue, parameters: nil)
    }
    func trackOnbGenreSelectionScreenViewed() {
        handleLogEvent(eventName: EventTypes.onbGenreSelectionScreenViewed.rawValue, parameters: nil)
    }
    func trackOnbGenreSelectionContinueTapped(genres: [BookInternalGenre]) {
        handleLogEvent(eventName: EventTypes.onbGenreSelectionContinueTapped.rawValue, parameters: [
            "count": genres.count,
            "count_string": "\(genres.count)"]
        )
        for genre in genres {
            handleLogEvent(eventName: EventTypes.onbGenreSelected.rawValue, parameters: ["genre": genre.rawValue])
        }
    }
    func trackOnbReadingFrequencyScreenViewed() {
        handleLogEvent(eventName: EventTypes.onbReadingFrequencyScreenViewed.rawValue, parameters: nil)
    }
    func trackOnbReadingFrequencyContinueTapped(frequency: String) {
        handleLogEvent(eventName: EventTypes.onbReadingFrequencyContinueTapped.rawValue, parameters: ["frequency": frequency])
    }
    func trackOnbListeningOccasionScreenViewed() {
        handleLogEvent(eventName: EventTypes.onbListeningOccasionScreenViewed.rawValue, parameters: nil)
    }
    func trackOnbListeningOccasionContinueTapped(occasions: [String]) {
        handleLogEvent(eventName: EventTypes.onbListeningOccasionContinueTapped.rawValue, parameters: [
            "count": occasions.count,
            "occasions": occasions.joined(separator: ",")
        ])
    }
    func trackOnbHowDidYouHearScreenViewed() {
        handleLogEvent(eventName: EventTypes.onbHowDidYouHearScreenViewed.rawValue, parameters: nil)
    }
    func trackOnbHowDidYouHearContinueTapped(source: String) {
        handleLogEvent(eventName: EventTypes.onbHowDidYouHearContinueTapped.rawValue, parameters: ["source": source])
    }
    func trackOnbPreviousAppsScreenViewed() {
        handleLogEvent(eventName: EventTypes.onbPreviousAppsScreenViewed.rawValue, parameters: nil)
    }
    func trackOnbPreviousAppsContinueTapped(apps: [String]) {
        handleLogEvent(eventName: EventTypes.onbPreviousAppsContinueTapped.rawValue, parameters: [
            "count": apps.count,
            "count_string": "\(apps.count)"])
        for app in apps {
            handleLogEvent(eventName: EventTypes.onbPreviousAppSelected.rawValue, parameters: ["app": app])
        }
    }
    func trackOnbBuildsHabitsLineChartScreenViewed() {
        handleLogEvent(eventName: EventTypes.onbBuildsHabitsLineChartScreenViewed.rawValue, parameters: nil)
    }
    func trackOnbBuildsHabitsLineChartContinueTapped() {
        handleLogEvent(eventName: EventTypes.onbBuildsHabitsLineChartContinueTapped.rawValue, parameters: nil)
    }
    func trackOnbWhyDoYouListenScreenViewed() {
        handleLogEvent(eventName: EventTypes.onbWhyDoYouListenScreenViewed.rawValue, parameters: nil)
    }
    func trackOnbWhyDoYouListenContinueTapped(listeningReasons: [String]) {
        handleLogEvent(eventName: EventTypes.onbWhyDoYouListenContinueTapped.rawValue, parameters: [
            "count": listeningReasons.count,
            "count_string": "\(listeningReasons.count)"]
        )
        for reason in listeningReasons {
            handleLogEvent(eventName: EventTypes.onbListeningReasonSelected.rawValue, parameters: ["reason": reason])
        }
    }
    func trackOnbReadingBarriersScreenViewed() {
        handleLogEvent(eventName: EventTypes.onbReadingBarriersScreenViewed.rawValue, parameters: nil)
    }
    func trackOnbReadingBarriersContinueTapped(barriers: [String]) {
        handleLogEvent(eventName: EventTypes.onbReadingBarriersContinueTapped.rawValue, parameters: [
            "count": barriers.count,
            "count_string": "\(barriers.count)"]
        )
        for barrier in barriers {
            handleLogEvent(eventName: EventTypes.onbReadingBarrierSelected.rawValue, parameters: ["barrier": barrier])
        }
    }
    func trackOnbReadingBarrierResolutionScreenViewed() {
        handleLogEvent(eventName: EventTypes.onbReadingBarrierResolutionScreenViewed.rawValue, parameters: nil)
    }
    func trackOnbReadingBarrierResolutionContinueTapped() {
        handleLogEvent(eventName: EventTypes.onbReadingBarrierResolutionContinueTapped.rawValue, parameters: nil)
    }
    func trackOnbDailyListeningGoalScreenViewed() {
        handleLogEvent(eventName: EventTypes.onbDailyListeningGoalScreenViewed.rawValue, parameters: nil)
    }
    func trackOnbDailyListeningGoalContinueTapped(goal: Int) {
        handleLogEvent(eventName: EventTypes.onbDailyListeningGoalContinueTapped.rawValue, parameters: ["goal": goal])
    }
    func trackOnbPushNotificationScreenViewed() {
        handleLogEvent(eventName: EventTypes.onbPushNotificationScreenViewed.rawValue, parameters: nil)
    }
    func trackOnbPushNotificationContinueTapped() {
        handleLogEvent(eventName: EventTypes.onbPushNotificationContinueTapped.rawValue, parameters: nil)
    }
    func trackOnbPushNotificationGranted() {
        handleLogEvent(eventName: EventTypes.onbPushNotificationGranted.rawValue, parameters: nil)
    }
    func trackOnbPushNotificationDenied() {
        handleLogEvent(eventName: EventTypes.onbPushNotificationDenied.rawValue, parameters: nil)
    }
    func trackOnbPushNotificationSkipped() {
        handleLogEvent(eventName: EventTypes.onbPushNotificationSkipped.rawValue, parameters: nil)
    }
    func trackOnbCredibilityReviewsScreenViewed() {
        handleLogEvent(eventName: EventTypes.onbCredibilityReviewsScreenViewed.rawValue, parameters: nil)
    }
    func trackOnbCredibilityReviewsContinueTapped() {
        handleLogEvent(eventName: EventTypes.onbCredibilityReviewsContinueTapped.rawValue, parameters: nil)
    }
    func trackOnbPersonalizedPicksScreenViewed() {
        handleLogEvent(eventName: EventTypes.onbPersonalizedPicksScreenViewed.rawValue, parameters: nil)
    }
    func trackOnbPersonalizedPicksContinueTapped() {
        handleLogEvent(eventName: EventTypes.onbPersonalizedPicksContinueTapped.rawValue, parameters: nil)
    }
    func trackOnbPersonalizedPicksRomanceActivated(imageVariant: String) {
        handleLogEvent(eventName: EventTypes.onbPersonalizedPicksRomanceActivatedv2.rawValue,
                       parameters: ["image_variant": imageVariant])
    }
    func trackOnbSaveProgressAuthScreenViewed() {
        handleLogEvent(eventName: EventTypes.onbSaveProgressAuthScreenViewed.rawValue, parameters: nil)
    }
    func trackOnbSaveProgressAuthAppleTapped() {
        handleLogEvent(eventName: EventTypes.onbSaveProgressAuthAppleTapped.rawValue, parameters: nil)
    }
    func trackOnbSaveProgressAuthGoogleTapped() {
        handleLogEvent(eventName: EventTypes.onbSaveProgressAuthGoogleTapped.rawValue, parameters: nil)
    }
    func trackOnbSaveProgressAuthEmailTapped() {
        handleLogEvent(eventName: EventTypes.onbSaveProgressAuthEmailTapped.rawValue, parameters: nil)
    }
    func trackOnbSaveProgressAuthComplete(authMethod: String) {
        handleLogEvent(
            eventName: EventTypes.onbSaveProgressAuthComplete.rawValue,
            parameters: [
                AnalyticsParameter.authMethod.rawValue: authMethod
            ]
        )
    }
    func trackOnbPaywallScreenViewed() {
        handleLogEvent(eventName: EventTypes.onbPaywallScreenViewed.rawValue, parameters: nil)
    }
    func trackOnbPaywallSubscribed() {
        handleLogEvent(eventName: EventTypes.onbPaywallSubscribed.rawValue, parameters: nil)
    }
    func trackOnbPaywallDeclined() {
        handleLogEvent(eventName: EventTypes.onbPaywallDeclined.rawValue, parameters: nil)
    }

    // MARK: - Email Opt-In Prompt

    func trackEmailOptInPromptShown(trigger: EmailOptInTrigger, genre: BookInternalGenre, dismissCount: Int) {
        let params: [String: Any] = [
            "trigger": trigger.rawValue,
            "dismiss_count": dismissCount,
            AnalyticsParameter.genre.rawValue: genre.displayString
        ]
        handleLogEvent(eventName: EventTypes.emailOptInPromptShown.rawValue, parameters: params)
    }

    func trackEmailOptInPromptNotNow(trigger: EmailOptInTrigger, genre: BookInternalGenre, dismissCount: Int) {
        let params: [String: Any] = [
            "trigger": trigger.rawValue,
            "dismiss_count": dismissCount,
            AnalyticsParameter.genre.rawValue: genre.displayString
        ]
        handleLogEvent(eventName: EventTypes.emailOptInPromptNotNow.rawValue, parameters: params)
    }

    func trackEmailOptInOptedIn(trigger: EmailOptInTrigger, genre: BookInternalGenre, dismissCount: Int) {
        let params: [String: Any] = [
            "trigger": trigger.rawValue,
            "dismiss_count": dismissCount,
            AnalyticsParameter.genre.rawValue: genre.displayString
        ]
        handleLogEvent(eventName: EventTypes.emailOptInOptedIn.rawValue, parameters: params)
    }

    func trackEmailOptInPromptSuppressed(reason: EmailOptInSuppressionReason) {
        handleLogEvent(eventName: EventTypes.emailOptInPromptSuppressed.rawValue,
                       parameters: ["reason": reason.rawValue])
    }

    // MARK: - Book Recap

    func trackRecapViewed(genre: BookInternalGenre?) {
        var parameters: [String: Any]? = nil
        if let genre = genre {
            parameters = [AnalyticsParameter.genre.rawValue: genre.displayString]
        }
        handleLogEvent(eventName: EventTypes.recapViewed.rawValue, parameters: parameters)
    }

    func trackRecapGenerated(genre: BookInternalGenre?) {
        var parameters: [String: Any]? = nil
        if let genre = genre {
            parameters = [AnalyticsParameter.genre.rawValue: genre.displayString]
        }
        handleLogEvent(eventName: EventTypes.recapGenerated.rawValue, parameters: parameters)
    }

    func trackRecapError(error: String) {
        handleLogEvent(eventName: EventTypes.recapError.rawValue, parameters: ["error": error])
    }

    func trackRecapContinueReadingTapped() {
        handleLogEvent(eventName: EventTypes.recapContinueReadingTapped.rawValue, parameters: nil)
    }

    func trackRecapDismissed() {
        handleLogEvent(eventName: EventTypes.recapDismissed.rawValue, parameters: nil)
    }

    func trackRecapRetryTapped() {
        handleLogEvent(eventName: EventTypes.recapRetryTapped.rawValue, parameters: nil)
    }
}
