//
//  AppDelegate.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 12/06/2019.
//  Copyright © 2020 Radically Better Ltd All rights reserved.
//

import UIKit
import FirebaseAnalytics
import FirebaseAuth
import FirebaseCore
import FirebaseCore
import FirebaseFirestore
import FBSDKCoreKit
import FirebaseMessaging
import AuthenticationServices
import SuperwallKit
import Kingfisher
import GoogleMobileAds
import GoogleSignIn
import MessageUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var tabBarController: AppTabBarController?
    private var appleTransferAuthorizationController: ASAuthorizationController?
    
    var window: UIWindow?
    
    let gcmMessageIDKey = "gcm.message_id"
    static var pnToken: String? = nil {
        didSet {
            if let token = pnToken, token != oldValue {
                print("Saving token to Firebase")
                let data: [String: Any] = [FirebaseUserVariables.fcmTokens.rawValue: FieldValue.arrayUnion([token])]
                AccountManager.shared.updateUserWithData(data, completion: nil)
            }
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        AppearanceManager.shared.applyAppearance(to: window)
        let loadingVC = LoadingVC()
        let nav = UINavigationController(rootViewController: loadingVC)
        nav.setNavigationBarHidden(true, animated: false)
        self.window?.rootViewController = nav
        self.window?.makeKeyAndVisible()
        
        FirebaseApp.configure()
        
        // Preload Core Data early
        CoreDataManager.shared.setupPersistentStore()
        
        // Clean up temporary text downloads from previous sessions and stale temporary audio.
        let resumeBookUUID = ReadingUserDefaults.getResumeReading()?.bookUUID
        CoreDataBookInternalContentManager.shared.clearTemporaryDownloads(excludingBookUUID: resumeBookUUID)
        CoreDataBookInternalAudioManager.shared.clearExpiredTemporaryDownloads(excludingBookUUID: resumeBookUUID)
        
        AnalyticsManager.shared.trackAppLaunched()
        
        AccountManager.shared.pushNotificationsStatus { status in
            if status == .authorized {
                let current = UNUserNotificationCenter.current()
                let options: UNAuthorizationOptions = [.sound, .badge, .alert]
                
                current.requestAuthorization(options: options) { [weak self] (granted, error) in
                    guard let self = self else { return }
                    if error == nil {
                        self.registerForFreeAudiobooksRemoteNotifications()
                    }
                }
            } else {
                // Not requested because not yet authorised
            }
        }
        
        checkAppleCredentialState()
        
        SKReviewManager.incrementLaunchCount()

        //AccountManager.signOut(tabBarController: nil)
        
        configureSuperwall()
        configureFBSDK()
        configureKingfisher()
        configureGoogleAds()
        configureShortcutItems()

        // Start network monitoring
        NetworkMonitor.shared.startMonitoring()
        
        ApplicationDelegate.shared.application (
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        return true
    }
    
    func configureKingfisher() {
        ImageDownloader.default.downloadTimeout = 120
    }
    
    func configureGoogleAds() {
        MobileAds.shared.start(completionHandler: nil)
    }
}

extension AppDelegate: SuperwallDelegate {
    func configureSuperwall() {
        Superwall.configure(apiKey: "pk_kgyZTd--5sz8KjsQFsv3O")
        Superwall.shared.delegate = self
        
        Auth.auth().addStateDidChangeListener { auth, user in
            if let uid = user?.uid {
                Superwall.shared.identify(userId: uid)
            }
        }
    }
    func subscriptionStatusDidChange(from oldValue: SuperwallKit.SubscriptionStatus, to newValue: SuperwallKit.SubscriptionStatus) {
        let isSubscribed = newValue.isActive
        Analytics.setUserProperty(isSubscribed ? "true" : "false", forName: "is_subscribed")
        AccountManager.shared.updateSuperwallUserAttributes()
        NotificationCenter.default.post(name: .didUpdateSubscriberStatus, object: nil)
    }
    func handleSuperwallEvent(withInfo eventInfo: SuperwallEventInfo) {
        AnalyticsManager.shared.handleLogEvent(
            eventName: eventInfo.event.description,
            parameters: eventInfo.params
        )
    }
}
 
extension AppDelegate {
    func configureFBSDK() {
        //                Settings.shared.enableLoggingBehavior(.appEvents)
        Settings.shared.enableLoggingBehavior(.developerErrors)
        Settings.shared.enableLoggingBehavior(.cacheErrors)
        Settings.shared.enableLoggingBehavior(.uiControlErrors)
        
        DispatchQueue.main.async {
            AppEvents.shared.activateApp()
        }
    }
    
	func registerForFreeAudiobooksRemoteNotifications() {
		let current = UNUserNotificationCenter.current()
		Messaging.messaging().delegate = self
		current.delegate = self
		
		DispatchQueue.main.async {
			UIApplication.shared.registerForRemoteNotifications()
		}
        
        if
            let user = AccountManager.shared.user,
            user.fcmTokens.isEmpty {
            fetchAndAssignCurrentPNToken()
        }
	}
    
    func fetchAndAssignCurrentPNToken() {
        Messaging.messaging().token { token, error in
           // Check for error. Otherwise do what you will with token here
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
            } else if let token = token {
                print("Remote instance ID token: \(token)")
                AppDelegate.pnToken = token
            }
        }
    }
	
	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

        // Handle Google Sign-In
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }

        // Handle Superwall deep links
        return Superwall.handleDeepLink(url)
        
//        let bundleId = AppConstants.shared.bundleId
//        
//        guard let urlScheme = url.scheme else { return false }
//        
//        if
//            let fbAppId = Settings.shared.appID,
//            urlScheme.hasPrefix("fb\(fbAppId)") && url.host ==  "authorize" {
//            return ApplicationDelegate.shared.application(
//                app,
//                open: url,
//                sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
//                annotation: options[UIApplication.OpenURLOptionsKey.annotation]
//            )
//        }
//        
//        return false
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

		// Doesn't work
		if let tabBarController = tabBarController {
			UIApplication.shared.applicationIconBadgeNumber = tabBarController.badgeCount
		}
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

		UIApplication.shared.applicationIconBadgeNumber = 0

		if NotificationCenterUserDefaults.didExitForNotifications {
			NotificationCenterUserDefaults.setDidExitForNotifications(didExit: false)
			NotificationCenter.default.post(name: .didEnterAfterExitingForNotifications, object: nil)
		}

        // Re-evaluate onboarding retention nudges so any remaining slots get
        // re-copied for the user's current segment (e.g. they've browsed a book).
        if OnboardingRetentionScheduler.isInRetentionWindow {
            OnboardingRetentionScheduler.refreshRemainingNudges()
        }

        // Perform cleanup of old book internals
        BookInternalCleanupManager.shared.performCleanupIfNeeded()

    }
    
	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		
		// Doesn't work
		if let tabBarController = tabBarController {
			UIApplication.shared.applicationIconBadgeNumber = tabBarController.badgeCount
		}
	}
}

extension AppDelegate: UNUserNotificationCenterDelegate, MessagingDelegate {
	
	// Background
	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
		if let messageId = userInfo[gcmMessageIDKey] {
			print("messageId: \(messageId)")
		}
		print(userInfo)
	}
	
	// Called when user taps on the notification received by the above
	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		if let messageID = userInfo[gcmMessageIDKey] {
			print("messageID: \(messageID)")
		}
        processNotificationUserInfo(userInfo)
		completionHandler(UIBackgroundFetchResult.newData)
	}
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		let userInfo = notification.request.content.userInfo
		if let message = userInfo[gcmMessageIDKey] {
			print("Message: \(message)")
		}
        // Dont think this is the right place for it - the one above suffices.
        //processNotificationUserInfo(userInfo)
		print(userInfo)

        completionHandler([.badge, .sound, .banner, .list])
	}

    // Called when user taps on a local notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        processNotificationUserInfo(userInfo)
        completionHandler()
    }
    
    func processNotificationUserInfo(_ userInfo: [AnyHashable: Any]) {
        // Handle "continue reading" action (daily reminder + onboarding retention nudges).
        if let action = userInfo[DailyReminderScheduler.UserInfoKey.action.rawValue] as? String,
           action == DailyReminderScheduler.NotificationAction.continueReading.rawValue {

            // Distinguish onboarding retention nudges from the daily reminder via `source`.
            let source = userInfo[DailyReminderScheduler.UserInfoKey.source.rawValue] as? String ?? ""
            if source.hasPrefix(OnboardingRetentionScheduler.sourcePrefix) {
                let slot = userInfo[OnboardingRetentionScheduler.UserInfoKey.slot.rawValue] as? Int ?? 0
                let segment = userInfo[OnboardingRetentionScheduler.UserInfoKey.segment.rawValue] as? String ?? ""
                AnalyticsManager.shared.trackTappedOnboardingRetentionNudge(slot: slot, segment: segment)
            } else {
                AnalyticsManager.shared.trackTappedDailyReminderNotification()
            }

            // Fetch current in-progress book, fall back to recently viewed
            let lastRead = ReadingUserDefaults.getReadingInProgressContent().first
                ?? ReadingUserDefaults.getRecentlyViewedContent(limit: 1).first
            if let lastRead = lastRead {
                handleBookEngagementNotification(
                    bookUUID: lastRead.contentUUID,
                    contentTypeString: lastRead.contentType.rawValue
                )
            } else {
                // No reading content found - open bookshelf so user can pick something
                handleSavedBooksDeeplink()
            }
            return
        }

        // Handle engagement engine book notifications
        if
            let bookUUID = userInfo["bookUUID"] as? String,
            let contentTypeString = userInfo["contentType"] as? String {
            AnalyticsManager.shared.trackTappedBookEngagementPushNotification()
            handleBookEngagementNotification(bookUUID: bookUUID, contentTypeString: contentTypeString)
            return
        }

        // Handle section deeplink from push notifications
        if let linkToSectionString = userInfo["linkToSection"] as? String {
            handleSectionDeeplink(sectionUUID: linkToSectionString)
            return
        }

        // Handle launch action deeplinks from push notifications
        if let launchActionPath = userInfo["launchAction"] as? String {
            switch launchActionPath {
            case LaunchAction.roadmapPath:
                handleLaunchAction(.roadmap)
            case LaunchAction.savedBooksPath:
                handleLaunchAction(.savedBooks)
            default:
                break
            }
            return
        }
    }
}

extension AppDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        guard AppDelegate.pnToken != nil else {
            fetchAndAssignCurrentPNToken()
            return
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error.localizedDescription)
    }
    
	func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
		AppDelegate.pnToken = fcmToken
		
//		guard let token = AppDelegate.pnToken else {
//			AppDelegate.pnToken = fcmToken
//			return
//		}
		print("Token: \(fcmToken ?? "Not available")")
	}
}

// MARK: - Deeplinks
extension AppDelegate {
	
	func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
		
        // This will allow us to check if we are coming from a universal link
        // and get the url with its components
       
        // The activity type (NSUserActivityTypeBrowsingWeb) is used
        // when continuing from a web browsing session to either
        // a web browser or a native app. Only activities of this
        // type can be continued from a web browser to a native app.
        
        guard
            userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let incomingURL = userActivity.webpageURL,
            let launchAction = DeeplinkManager.shared.getLaunchActionFromDeeplinkURL(url: incomingURL) else {
            return false
        }
        self.handleLaunchAction(launchAction)
        return true
	}
	
    func handleLaunchAction(_ launchAction: LaunchAction) {
        switch launchAction {
        case .bookInternal(let bookUUID): handleBookInternalLaunchAction(bookUUID: bookUUID)
        case .savedBooks: handleSavedBooksDeeplink()
        case .roadmap: handleRoadmapDeeplink()
        case .section(let sectionUUID): handleSectionDeeplink(sectionUUID: sectionUUID)
        }
    }
}

// MARK: - Dynamic Links
extension AppDelegate {
	func handleBookInternalLaunchAction(bookUUID: String) {
		if AppNotifiers.shared.tabBarHasLoaded {
            if let bookMetadata = CoreDataBookInternalManager.shared.getWithUUID(uuid: bookUUID) {
                showBook(bookMetadata)
            } else {
                APIBookInternalManager.shared.fetchStoriesWithIDs(uuids: [bookUUID]) { success in
                    guard
                        success,
                        let bookMetadata = CoreDataBookInternalManager.shared.getWithUUID(uuid: bookUUID) else {
                            return
                    }
                    DispatchQueue.main.async {
                        self.showBook(bookMetadata)
                    }
                }
            }
		} else {
			AppNotifiers.shared.launchActionNeedsHandling = .bookInternal(uuid: bookUUID)
		}
	}
    func showBook(_ contentMetadata: ReadableContentMetadata) {
        let contentOverviewVC = BookDetailVC(contentMetadata: contentMetadata)
        contentOverviewVC.hidesBottomBarWhenPushed = true
        
        guard let currentVC = UIApplication.topViewController() else { return }
        currentVC.navigationController?.pushViewController(contentOverviewVC, animated: true)
    }
}

extension AppDelegate {
    func handleSavedBooksDeeplink() {
        if
            AppNotifiers.shared.tabBarHasLoaded,
            let tabBarController = tabBarController {
            tabBarController.selectTab(tab: .bookshelf)
        } else {
            AppNotifiers.shared.launchActionNeedsHandling = .savedBooks
        }
    }

    func handleRoadmapDeeplink() {
        if AppNotifiers.shared.tabBarHasLoaded {
            let vc = RoadmapVC(wasPresented: false)
            vc.hidesBottomBarWhenPushed = true
            guard let currentVC = UIApplication.topViewController() else { return }
            currentVC.navigationController?.pushViewController(vc, animated: true)
        } else {
            AppNotifiers.shared.launchActionNeedsHandling = .roadmap
        }
    }

    func handleSectionDeeplink(sectionUUID: String) {
        if
            AppNotifiers.shared.tabBarHasLoaded,
            let tabBarController = tabBarController {
            tabBarController.handleSectionDeeplink(sectionUUID: sectionUUID)
        } else {
            AppNotifiers.shared.launchActionNeedsHandling = .section(sectionUUID: sectionUUID)
        }
    }
}

// MARK: - Engagement Engine Notifications
extension AppDelegate {
    func handleBookEngagementNotification(bookUUID: String, contentTypeString: String) {
        guard ContentType(rawValue: contentTypeString) == .bookInternal else {
            return
        }
        handleBookInternalLaunchAction(bookUUID: bookUUID)
    }
}

// MARK: - UIApplicationShortcutItems
extension AppDelegate {
    func configureShortcutItems() {
        let feedbackIcon = UIApplicationShortcutIcon(type: .compose)
        let feedbackItem = UIApplicationShortcutItem(
            type: "com.freeaudiobooks.ios.feedback",
            localizedTitle: "Report a Bug",
            localizedSubtitle: "Help us improve your experience",
            icon: feedbackIcon,
            userInfo: nil
        )

        let retentionIcon = UIApplicationShortcutIcon(type: .message)
        let retentionItem = UIApplicationShortcutItem(
            type: "com.freeaudiobooks.ios.contactSupport",
            localizedTitle: "Leaving? Let’s Chat",
            localizedSubtitle: "We can fix issues before you go",
            icon: retentionIcon,
            userInfo: nil
        )

        UIApplication.shared.shortcutItems = [retentionItem, feedbackItem]
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        handleShortcutItem(shortcutItem)
        completionHandler(true)
    }

    private func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
        switch shortcutItem.type {
        case "com.freeaudiobooks.ios.feedback":
            AnalyticsManager.shared.trackTappedQuickAction(type: "Bug Report")
            presentEmailComposer(subject: "Bug Report / Issue")
        case "com.freeaudiobooks.ios.contactSupport":
            AnalyticsManager.shared.trackTappedQuickAction(type: "Contact Support")
            presentEmailComposer(subject: "Support Request")
        default:
            break
        }
    }

    private func presentEmailComposer(subject: String) {
        // Wait for tab bar to load if needed
        if !AppNotifiers.shared.tabBarHasLoaded {
            // Store the action to be performed once tab bar loads
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.presentEmailComposer(subject: subject)
            }
            return
        }

        guard let topVC = UIApplication.topViewController() else { return }

        // Check if device can send email
        guard MFMailComposeViewController.canSendMail() else {
            let email = RCValues.shared.string(forKey: .freebooksEmailAB)
            let title = "Apple Mail Uninstalled"
            let message = "We were unable to find the Apple Mail app. Please email us at \(email)."
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(okAction)
            DispatchQueue.main.async {
                topVC.present(alertController, animated: true)
            }
            return
        }

        // Create and configure mail composer
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = topVC as? MFMailComposeViewControllerDelegate

        let email = RCValues.shared.string(forKey: .freebooksEmailAB)
        mailComposerVC.setToRecipients([email])
        mailComposerVC.setSubject(subject)

        DispatchQueue.main.async {
            topVC.present(mailComposerVC, animated: true)
        }
    }
}

// Check if an apple user has revoked access in their settings etc
extension AppDelegate {
	func checkAppleCredentialState() {
		if
			let userID = AppleSignInUserDefaults.appleUserId,
			let providerId = Auth.auth().currentUser?.providerData.first?.providerID,
			providerId == "apple.com" {
			
			// Check Apple ID credential state
			ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID, completion: { credentialState, error in
				switch credentialState {
				case .authorized:
					break
				case .transferred:
					// A transferred credential remains approved. Refresh it silently so
					// this installation starts using the recipient team's user identifier.
					DispatchQueue.main.async {
						self.refreshTransferredAppleCredential(for: userID)
					}
				case .notFound,
					 .revoked:
					// Perform sign out
					DispatchQueue.main.async {
						AccountManager.signOut(tabBarController: nil)
					}
					break
				@unknown default:
					break
				}
			})
		}
	}

	private func refreshTransferredAppleCredential(for userID: String) {
		let request = ASAuthorizationAppleIDProvider().createRequest()
		request.user = userID

		let controller = ASAuthorizationController(authorizationRequests: [request])
		controller.delegate = self
		controller.presentationContextProvider = self
		appleTransferAuthorizationController = controller
		controller.performRequests()
	}
}

extension AppDelegate: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
	func authorizationController(controller: ASAuthorizationController,
								 didCompleteWithAuthorization authorization: ASAuthorization) {
		defer { appleTransferAuthorizationController = nil }

		guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
			return
		}

		AppleSignInUserDefaults.appleUserId = credential.user
		AccountManager.shared.updateUserWithData([
			FirebaseUserVariables.appleUserIdentifier.rawValue: credential.user
		], completion: nil)
	}

	func authorizationController(controller: ASAuthorizationController,
								 didCompleteWithError error: Error) {
		appleTransferAuthorizationController = nil
		// The existing Firebase session remains valid. Server-side migration can
		// still update this user's Apple identifier if the silent refresh fails.
		print("Unable to refresh transferred Sign in with Apple credential: \(error.localizedDescription)")
	}

	func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
		return window!
	}
}

//extension AppDelegate: PurchasesDelegate {
//    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
//        // handle any changes to purchaserInfo
//        AccountManager.shared.handleNewPurchaserInfo(purchaserInfo: customerInfo)
//    }
//}
