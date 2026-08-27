//
//  AppTabBarController.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 26/04/2019.
//  Copyright © 2020 Radically Better Ltd All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices

class AppTabBarController: UITabBarController, UITabBarControllerDelegate {
    private var searchNavController: SwipeNavigationController?
    private var searchViewController: SearchVC?

	override func viewDidLoad() {
		super.viewDidLoad()

        delegate = self

        if #unavailable(iOS 26) {
            tabBar.isTranslucent = false
        }
        let appearance = TabBarStyler.makeAppearance()

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = tabBar.standardAppearance
        tabBar.tintColor = Colours.orangePrimary
        tabBar.unselectedItemTintColor = Colours.textSecondary
        
		setupTabs()
        handleResumeReadingIfNeeded()
		
		// Register to Apple ID credential revoke notification
        NotificationCenter.default.addObserver(self, selector: #selector(appleIDCredentialRevoked(_:)), name: ASAuthorizationAppleIDProvider.credentialRevokedNotification, object: nil)
        
        AppNotifiers.shared.tabBarHasLoaded = true
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        let appearance = TabBarStyler.makeAppearance()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = tabBar.standardAppearance
    }
    
	@objc func appleIDCredentialRevoked(_ notification: Notification) {
		// Make sure user signed in with Apple
		if
			let providerId = Auth.auth().currentUser?.providerData.first?.providerID,
			providerId == "apple.com" {
			DispatchQueue.main.async {
				AccountManager.signOut(tabBarController: self)
			}
		}
	}
	
	func setupTabs() {
        let homepageVC: UIViewController & HomeTabControlling = {
            switch HomeVariant.current {
            case .original:
                return HomeVC()
            case .personalized:
                return PersonalizedHomeVC()
            }
        }()
        let todayVCNav = SwipeNavigationController(rootViewController: homepageVC)
        let todayVCTitle = "Home"
        // This is the tab bar title
        homepageVC.tabBarItem = UITabBarItem(title: todayVCTitle, image: UIImage(named: "homeTabBarIcon"), tag: Tab.discover.rawValue)
        homepageVC.title = todayVCTitle

        let searchVC = SearchVC()
        let searchVCNav = SwipeNavigationController(rootViewController: searchVC)
        let searchVCTitle = "Search"
        searchVC.title = searchVCTitle
        searchVC.tabBarItem = UITabBarItem(title: searchVCTitle, image: UIImage(named: "searchTabBarIcon"), tag: Tab.search.rawValue)
        searchNavController = searchVCNav
        searchViewController = searchVC
        
		let pastConversationsVC = LibraryVC()
		let pastConversationsVCNav = SwipeNavigationController(rootViewController: pastConversationsVC)
        let pastConversationsVCTitle = "Library"
        pastConversationsVC.title = pastConversationsVCTitle
        pastConversationsVC.tabBarItem = UITabBarItem(title: pastConversationsVCTitle, image: UIImage(named: "libraryTabIcon"), tag: Tab.bookshelf.rawValue)
		
		let accountVC = AccountVC()
        let accountVCNav = SwipeNavigationController(rootViewController: accountVC)
        let accountVCTitle = "Account"
		accountVC.title = accountVCTitle
		accountVC.tabBarItem = UITabBarItem(title: accountVCTitle, image: UIImage(named: "accountTabIcon"), tag: Tab.account.rawValue)
		
//		let tabBarList = [chatbotVCNav, homepageNav, pastConversationsVCNav, writeVCNav, accountVCNav]
        let tabBarList = [todayVCNav, searchVCNav, pastConversationsVCNav, accountVCNav]
		viewControllers = tabBarList
	}
	
	var badgeCount: Int = 0

    // MARK: - UITabBarControllerDelegate

    func tabBarController(_ tabBarController: UITabBarController,
                          didSelect viewController: UIViewController) {
        HapticFeedbackHelper.shared.triggerLightImpactFeedback()
    }
}

extension AppTabBarController {
    /// Sets up the Discover tab's nav stack to show ReadingVC immediately if the user
    /// was reading when they last left the app. Must be called after setupTabs() and
    /// before the view is rendered so the user never sees DiscoverVC flash.
    private func handleResumeReadingIfNeeded() {
        guard RCValues.shared.bool(forKey: .shouldResumeOnReadingVC) else { return }
        guard let resumeInfo = ReadingUserDefaults.getResumeReading() else { return }
        // Clear immediately so DiscoverVC.viewDidLoad doesn't double-handle
        ReadingUserDefaults.clearResumeReading()

        guard let discoverNav = viewControllers?.first(where: { ($0 as? UINavigationController)?.viewControllers.first is HomeTabControlling }) as? UINavigationController,
              let discoverVC = discoverNav.viewControllers.first else { return }

        let metadata = CoreDataBookInternalManager.shared.getWithUUID(uuid: resumeInfo.bookUUID)
        guard let metadata = metadata else { return }
        // We did have a bug where, if someone got to end of a book, tapped complete, but did not complete all stages of EnhancedBookCompletionPopupVC such that the ReadingVC was popped, we'd resume them on that book - at which point they'd hit a dead end.
        guard !metadata.isCompleted() else { return }

        let bookDetailVC = BookDetailVC(contentMetadata: metadata)
        bookDetailVC.hidesBottomBarWhenPushed = true

        if ReadingUserDefaults.getLastReadMode(for: resumeInfo.bookUUID) == .audio {
            if let audioData = metadata.cachedAudio {
                if AccountManager.shared.userIsSubscribed, audioData.isTemporaryDownload {
                    CoreDataBookInternalAudioManager.shared.promoteTemporaryDownload(bookUUID: metadata.contentUUID)
                }
                let audiobookPlayerVC = AudiobookPlayerVC(bookInternal: metadata, audioData: audioData)
                audiobookPlayerVC.hidesBottomBarWhenPushed = true
                discoverNav.setViewControllers([discoverVC, bookDetailVC, audiobookPlayerVC], animated: false)
            } else {
                discoverNav.setViewControllers([discoverVC, bookDetailVC], animated: false)
            }
            return
        }

        guard AccountManager.shared.userIsSubscribed else {
            discoverNav.setViewControllers([discoverVC, bookDetailVC], animated: false)
            return
        }

        let content: ReadableContent? = APIBookInternalContentManager.getBookInternalContent(bookUUID: resumeInfo.bookUUID)
        guard let content = content else { return }

        let readingVC = ReadingVC(metadata: metadata, content: content)
        discoverNav.setViewControllers([discoverVC, bookDetailVC, readingVC], animated: false)
    }

    func selectTab(tab: Tab) {
        selectedIndex = tab.rawValue
    }

    func showSearch(initialFilters: CDBookInternalSearchObject?) {
        selectTab(tab: .search)
        searchNavController?.popToRootViewController(animated: false)
        searchViewController?.applyEntryFilters(initialFilters)
    }

    func handleSectionDeeplink(sectionUUID: String) {
        selectTab(tab: .discover)
        if let discoverVC = viewControllers?.first?.children.compactMap({ $0 as? HomeTabControlling }).first {
            discoverVC.scrollToSectionWithUUID(sectionUUID: sectionUUID)
        }
    }
}

enum Tab: Int {
    case discover = 0
    case search = 1
    case bookshelf = 2
    case account = 3
}

protocol HomeTabControlling: AnyObject {
    func scrollToSectionWithUUID(sectionUUID: String)
}
