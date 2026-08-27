//
//  HelpUsGrowVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 05/04/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseFirestore
import NVActivityIndicatorView
import FirebaseAuth
import PopupDialog
import Lottie

class HelpUsGrowVC: UIViewController {
    
    private lazy var addReviewButton: UIButton = {
        let buttonTitle = RCValues.shared.string(forKey: .fullscreenReviewVCButtonTitleAB)
        return Buttons.primaryCTA(buttonTitle: buttonTitle)
    }()

    private lazy var helpUsGrowAnimationView: LottieAnimationView = {
        let animationView = LottieAnimationView(name: "reviews-1")
        animationView.loopMode = .loop
        animationView.backgroundColor = nil
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.contentMode = .scaleAspectFit
        return animationView
    }()
    private let introLabel = UILabel()
    private let helpUsGrowLabel = UILabel()
    
    let wasPresented: Bool
    init(wasPresented: Bool) {
        self.wasPresented = wasPresented
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colours.surfacePrimary
        
        setupNavBar()
        setupPrimaryUI()
        setupAddReviewButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        
        AnalyticsManager.shared.trackHelpUsGrowViewed()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard NavigationBarStyler.reapplyIfNeeded(on: self, previousTraitCollection: previousTraitCollection) else { return }
        setupNavBar()
    }
}

private extension HelpUsGrowVC {
    func setupNavBar() {
        guard let navigationBar = self.navigationController?.navigationBar else {return}
        NavigationBarStyler.apply(to: navigationBar)
        navigationController?.view.backgroundColor = Colours.surfacePrimary
        
        let btnLeftMenu: UIButton = UIButton(type: .system)
        let imageName = wasPresented ? "dismissIcon" : "backButtonNavIcon"
        let backImage = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        btnLeftMenu.setImage(backImage, for: .normal)
        btnLeftMenu.tintColor = Colours.textPrimary
        
        btnLeftMenu.addTarget(self, action: #selector(popVCFromNavItem), for: .touchUpInside)
        btnLeftMenu.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        let barButton = UIBarButtonItem(customView: btnLeftMenu)
        self.navigationItem.leftBarButtonItem = barButton
        
        self.title = "Help Us Grow"
    }
    
    @objc func popVCFromNavItem() {
        // We're not in the Account, so we record this as a "not now"
        if wasPresented {
            AnalyticsManager.shared.trackHelpUsGrowNotNowTapped()
            SKReviewManager.incrementFullScreenTappedNotNowCount()
        }
        popVC()
    }
    
    @objc func popVC() {
        if wasPresented {
            self.dismiss(animated: true)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
}

private extension HelpUsGrowVC {
    func setupPrimaryUI() {
        setupHelpUsGrowLabel()
        setupHelpUsGrowAnimationView()
    }
    func setupHelpUsGrowLabel() {
        
        introLabel.numberOfLines = 0
        introLabel.lineBreakMode = .byWordWrapping
//        introLabel.font = Fonts.medium16
//        introLabel.textColor = Colours.charcoal
        
        introLabel.font = Fonts.semiBold16
        introLabel.textColor = Colours.textPrimary
        
        introLabel.textAlignment = .center
        introLabel.text = RCValues.shared.string(forKey: .fullscreenReviewVCIntroText)
        
        view.addSubviewForConstraints(introLabel)
        NSLayoutConstraint.activate([
            introLabel.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: UIConstants.shared.standardMargin),
            introLabel.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -UIConstants.shared.standardMargin),
            introLabel.centerYAnchor.constraint(equalTo: view.safeCenterYAnchor, constant: -20)
        ])
    
        view.addSubviewForConstraints(helpUsGrowLabel)
        helpUsGrowLabel.textColor = Colours.subtext
        helpUsGrowLabel.font = Fonts.medium16
        helpUsGrowLabel.numberOfLines = 0
        helpUsGrowLabel.lineBreakMode = .byWordWrapping
        helpUsGrowLabel.textAlignment = .center
        
        helpUsGrowLabel.text = RCValues.shared.string(forKey: .fullscreenReviewVCDetailTextAB)
        
        NSLayoutConstraint.activate([
            helpUsGrowLabel.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 40),
            helpUsGrowLabel.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -40),
            helpUsGrowLabel.topAnchor.constraint(equalTo: introLabel.bottomAnchor, constant: 12)
        ])
    }
    func setupHelpUsGrowAnimationView() {
        view.addSubviewForConstraints(helpUsGrowAnimationView)
        NSLayoutConstraint.activate([
            helpUsGrowAnimationView.widthAnchor.constraint(equalToConstant: 300),
            helpUsGrowAnimationView.heightAnchor.constraint(equalToConstant: 300),
            helpUsGrowAnimationView.bottomAnchor.constraint(equalTo: helpUsGrowLabel.topAnchor, constant: -20),
            helpUsGrowAnimationView.centerXAnchor.constraint(equalTo: view.safeCenterXAnchor)
        ])
        helpUsGrowAnimationView.play()
    }
}

extension HelpUsGrowVC {
    func setupAddReviewButton() {
        view.addSubviewForConstraints(addReviewButton)
        NSLayoutConstraint.activate([
            addReviewButton.topAnchor.constraint(equalTo: helpUsGrowLabel.bottomAnchor, constant: 30),
            addReviewButton.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 20),
            addReviewButton.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -20),
            addReviewButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight)
        ])
        addReviewButton.addTarget(self, action: #selector(addReviewTapped), for: .touchUpInside)
    }
}

extension HelpUsGrowVC {
    @objc func addReviewTapped() {
        
        AnalyticsManager.shared.trackHelpUsGrowReviewTapped()
        
        // If liked, show full review screen
        SKReviewManager.hasTappedAddReview = true
        
        let appID = AppConstants.shared.appStoreId
        let urlStr = RCValues.shared.string(forKey: .appStoreReviewURLAB).replacingOccurrences(of: "*APPID*", with: appID)
        if let url = URL(string: urlStr), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            
            popVC()
        }
    }
}
