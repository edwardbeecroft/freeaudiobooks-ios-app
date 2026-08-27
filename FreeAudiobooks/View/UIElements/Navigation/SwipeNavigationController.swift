//
//  SwipeNavigationController.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 01/09/2020.
//  Copyright © 2020 Radically Better Ltd. All rights reserved.
//

import UIKit

final class SwipeNavigationController: UINavigationController {
	
	// MARK: - Lifecycle
	
	override init(rootViewController: UIViewController) {
		super.init(rootViewController: rootViewController)
	}
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// This needs to be in here, not in init
		interactivePopGestureRecognizer?.delegate = self
		delegate = self
	}
	
	deinit {
		delegate = nil
		interactivePopGestureRecognizer?.delegate = nil
	}
	
	// MARK: - Status Bar Delegation

	override var childForStatusBarStyle: UIViewController? {
		return topViewController
	}

	override var childForStatusBarHidden: UIViewController? {
		return topViewController
	}

	// MARK: - Overrides

	override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        // Make the incoming VC's view span the full screen (under the opaque nav bar)
        // so the outgoing screen's floating HeaderView can't show through the transient
        // gap created while the nav bar animates hidden -> shown during the push.
        // Without this, iPad's push animator (which keeps the outgoing VC partly on
        // screen) reveals the grey header for a frame and then snaps it away.
        viewController.extendedLayoutIncludesOpaqueBars = true
        super.pushViewController(viewController, animated: animated)
        interactivePopGestureRecognizer?.isEnabled = false
    }
}

// MARK: - UINavigationControllerDelegate

extension SwipeNavigationController: UINavigationControllerDelegate {
	
	func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        interactivePopGestureRecognizer?.isEnabled = true
    }
}

// MARK: - UIGestureRecognizerDelegate

extension SwipeNavigationController: UIGestureRecognizerDelegate {
	
	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		guard gestureRecognizer == interactivePopGestureRecognizer else {
			return true // default value
		}
		
		// Disable pop gesture in two situations:
		// 1) when the pop animation is in progress
		// 2) when user swipes quickly a couple of times and animations don't have time to be performed
		return viewControllers.count > 1
	}
}
