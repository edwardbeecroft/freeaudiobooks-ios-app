//
//  AccountVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 01/01/2019.
//  Copyright © 2019 Ed Beecroft. All rights reserved.
//

import UIKit
import MessageUI
import FirebaseCore
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import SafariServices
import NVActivityIndicatorView
import Kingfisher
import SuperwallKit

protocol ManageProfileVCProtocol: AnyObject {
    func didSuccessfullyUpdateProfile()
}

final class AccountVC: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let accountProfileViewLoggedIn = AccountProfileViewLoggedIn()
    private let dailyRemindersRow = FormTappableRowView()
    private let appearanceRow = FormTappableRowView()
    private let myReadingStatsRow = FormTappableRowView()
    private let accountDetailsRow = FormTappableRowView()
    private let settingsUpgradeView = SettingsUpgradeView()
    private let intruderDetectionRow = FormTappableRowView()
    private var stackView = UIStackView()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        view = UIView()
        view.backgroundColor = Colours.surfacePrimary
        
        setupScrollView()
        createView()
        updateProButtonVisibility()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshForSubscriberStatus),
                                               name: .didUpdateSubscriberStatus,
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
        refreshContent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func refreshContent() {
        accountProfileViewLoggedIn.refreshData()
        updateTopProfileSection()
    }
    
    func setupScrollView() {
        view.addSubviewForConstraints(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        //        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        
        // scrollView.contentInsetAdjustmentBehavior = .never
        //scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 44, right: 0)
        scrollView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    func createView() {
        
        accountProfileViewLoggedIn.roundAllCorners()
        accountProfileViewLoggedIn.hideBottomSplitter()
        accountProfileViewLoggedIn.imageTapHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.showImagePicker()
            }
        }
        
        settingsUpgradeView.roundAllCorners()
        settingsUpgradeView.hideBottomSplitter()
        settingsUpgradeView.upgradeTappedHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                AnalyticsManager.shared.trackAccountUpsellTapped()
                self.displayPaywall(placement: .accountUpsell)
            }
        }
        
        let appPreferencesSectionTitle = FormSectionTitleView(includeInfoButton: false)
        appPreferencesSectionTitle.setIntroText("Account Settings")
        
        accountDetailsRow.configure(backgroundColor: Colours.brandBlack,
                                    rowImage: UIImage(named: "accountTabIconPerson")!,
                                    rowText: "Account Details")
        accountDetailsRow.roundTopCorners()
        accountDetailsRow.tapHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.handleEditProfile()
            }
        }
        dailyRemindersRow.configure(backgroundColor: Colours.brandBlack,
                                    rowImage: UIImage(named: "notifications")!,
                                    rowText: "Listening Reminders")
        dailyRemindersRow.tapHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.showDailyRemindersSettings()
            }
        }
        let appearanceIcon = UIImage(systemName: "circle.lefthalf.filled")
            ?? UIImage(named: "account-info.png")
            ?? UIImage()
        appearanceRow.configure(backgroundColor: Colours.brandBlack,
                                rowImage: appearanceIcon,
                                rowText: "Appearance")
        appearanceRow.tapHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.showAppearanceSettings()
            }
        }

        myReadingStatsRow.configure(backgroundColor: Colours.brandBlack,
                                    rowImage: UIImage(named: "streak")!,
                                    rowText: "My Listening Stats")
        myReadingStatsRow.tapHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.showStatsVC()
            }
        }
        myReadingStatsRow.roundBottomCorners()
        myReadingStatsRow.hideBottomSplitter()
        myReadingStatsRow.isHidden = !RCValues.shared.bool(forKey: .isStatsUIEnabled)
        if myReadingStatsRow.isHidden {
            appearanceRow.roundBottomCorners()
            appearanceRow.hideBottomSplitter()
        }
    
        let supportSectionTitle = FormSectionTitleView(includeInfoButton: false)
        supportSectionTitle.setIntroText("Feedback & Support")
        
        let contactSupportRow = FormTappableRowView()
        contactSupportRow.configure(backgroundColor: Colours.royalNavy,
                                    rowImage: UIImage(named: "email.png")!,
                                    rowText: "Support & Feature Requests")
        contactSupportRow.roundTopCorners()
        contactSupportRow.tapHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.showMailAppForSupport()
            }
        }

        let helpUsGrowRow = FormTappableRowView()
        helpUsGrowRow.configure(backgroundColor: Colours.royalNavy,
                                rowImage: UIImage(named: "heart")!,
                                rowText: "Help Us Grow")
        helpUsGrowRow.tapHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.showFullScreenReviewVC()
            }
        }
        helpUsGrowRow.roundBottomCorners()
        helpUsGrowRow.hideBottomSplitter()
        
        let inviteFriendsRow = FormTappableRowView()
        inviteFriendsRow.configure(backgroundColor: Colours.royalNavy,
                                rowImage: UIImage(named: "gift-box.png")!,
                                rowText: "Invite Friends & Family")
        inviteFriendsRow.tapHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.showShareAppSheet()
            }
        }
        
        let socialSectionTitle = FormSectionTitleView(includeInfoButton: false)
        socialSectionTitle.setIntroText("Follow Us")
        
        let instagramRow = FormTappableRowView()
        let joinDiscordRow = FormTappableRowView()
        
        if RCValues.shared.bool(forKey: .showJoinDiscordInAccountVC) == true {
            joinDiscordRow.roundTopCorners()
            let img = UIImage(named: "discord.png")!
            joinDiscordRow.configure(backgroundColor: Colours.accentLilac,
                                     rowImage: img,
                                     rowText: "Join Our Discord Community")
//            joinDiscordRow.setCustomImage(img)
            joinDiscordRow.tapHandler = { [weak self] in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.goToDiscord()
                }
            }
        } else {
            instagramRow.roundTopCorners()
        }
        
        instagramRow.configure(backgroundColor: Colours.accentLilac,
                               rowImage: UIImage(named: "instagram")!,
                               rowText: "Instagram")
        instagramRow.tapHandler = {
            DispatchQueue.main.async {
                AnalyticsManager.shared.trackTappedSocialPage(medium: .instagram)
                SocialNetwork.Instagram.openPage()
            }
        }
        let tiktokRow = FormTappableRowView()
        tiktokRow.configure(backgroundColor: Colours.accentLilac,
                              rowImage: UIImage(named: "tiktok")!,
                              rowText: "TikTok")
        tiktokRow.tapHandler = {
            DispatchQueue.main.async {
                AnalyticsManager.shared.trackTappedSocialPage(medium: .tiktok)
                SocialNetwork.TikTok.openPage()
            }
        }
        
        let twitterRow = FormTappableRowView()
        twitterRow.configure(backgroundColor: Colours.accentLilac,
                             rowImage: UIImage(named: "twitter")!,
                             rowText: "X / Twitter")
        twitterRow.tapHandler = {
            DispatchQueue.main.async {
                AnalyticsManager.shared.trackTappedSocialPage(medium: .twitter)
                SocialNetwork.Twitter.openPage()
            }
        }
        
        let facebookRow = FormTappableRowView()
        facebookRow.configure(backgroundColor: Colours.accentLilac,
                              rowImage: UIImage(named: "facebook")!,
                              rowText: "Facebook")
        facebookRow.tapHandler = {
            DispatchQueue.main.async {
                AnalyticsManager.shared.trackTappedSocialPage(medium: .facebook)
                SocialNetwork.Facebook.openPage()
            }
        }
        facebookRow.roundBottomCorners()
        facebookRow.hideBottomSplitter()
        
        let moreSectionTitle = FormSectionTitleView(includeInfoButton: false)
        moreSectionTitle.setIntroText("More")
        
        let aboutFreeAudiobooksRow = FormTappableRowView()
        aboutFreeAudiobooksRow.configure(backgroundColor: Colours.brandGrey,
                                 rowImage: UIImage(named: "account-info.png")!,
                                 rowText: "About FreeAudiobooks")
        aboutFreeAudiobooksRow.roundTopCorners()
        aboutFreeAudiobooksRow.tapHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.showAboutFreeAudiobooksVC()
            }
        }
        
        let privacyAndTermsRow = FormTappableRowView()
        privacyAndTermsRow.configure(backgroundColor: Colours.brandGrey,
                                     rowImage: UIImage(named: "legal-docs.png")!,
                                     rowText: "Privacy & Terms")
        privacyAndTermsRow.tapHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.showDialogForPrivacyOrTerms()
            }
        }
        
        var stackArrangedSubviews: [UIView] = [
            appPreferencesSectionTitle,
            dailyRemindersRow,
            appearanceRow,
            myReadingStatsRow,

            socialSectionTitle,
            instagramRow,
            tiktokRow,
            twitterRow,
            facebookRow,
            
            supportSectionTitle,
            contactSupportRow,
            inviteFriendsRow,
            helpUsGrowRow,
            
            moreSectionTitle,
            aboutFreeAudiobooksRow,
            privacyAndTermsRow
        ]
        
        if !AccountManager.shared.userIsSubscribed {
            stackArrangedSubviews.insert(settingsUpgradeView, at: 0)
        }
        if RCValues.shared.bool(forKey: .showJoinDiscordInAccountVC) {
            let instaIndex = stackArrangedSubviews.firstIndex(of: instagramRow)!
            stackArrangedSubviews.insert(joinDiscordRow, at: instaIndex)
        }
        
        let signoutRow = FormTappableRowView()
        signoutRow.configure(backgroundColor: Colours.brandGrey,
                             rowImage: UIImage(named: "logout.png")!,
                             rowText: "Sign Out")
        signoutRow.roundBottomCorners()
        signoutRow.hideBottomSplitter()
        signoutRow.tapHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.logout()
            }
        }
        stackArrangedSubviews.append(signoutRow)
        
        stackArrangedSubviews.forEach({ stackView.addArrangedSubview($0) })
        
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 16
        
        [appPreferencesSectionTitle, supportSectionTitle, socialSectionTitle, moreSectionTitle].forEach {
            stackView.setCustomSpacing(0, after: $0)
        }
        
        [dailyRemindersRow, appearanceRow, inviteFriendsRow, contactSupportRow, joinDiscordRow, instagramRow, tiktokRow, twitterRow,
         aboutFreeAudiobooksRow, privacyAndTermsRow].forEach { stackView.setCustomSpacing(0, after: $0) }
        
        //        borderView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 0).isActive = true
        //        borderView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 0).isActive = true
        
        contentView.addSubviewForConstraints(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    func updateProButtonVisibility() {
        accountProfileViewLoggedIn.refreshData()
    }
}

extension AccountVC {
    func goToDiscord() {
        if
            let discordInviteURL = URL(string: RCValues.shared.string(forKey: .discordInviteURLAB)),
            UIApplication.shared.canOpenURL(discordInviteURL) {
            UIApplication.shared.open(discordInviteURL, options: [:], completionHandler: nil)
        }
    }
}

extension AccountVC {
    func showAppearanceSettings() {
        let vc = AppearanceSettingsVC()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension AccountVC {
    func showDailyRemindersSettings() {
        let vc = DailyRemindersSettingsVC()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension AccountVC {
    func showStatsVC() {
        let statsVC = StatsVC()
        let navController = UINavigationController(rootViewController: statsVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
    }
}

final class AppearanceSettingsVC: UITableViewController {
    private let cellReuseId = "AppearanceSettingsCell"
    private let options = AppAppearancePreference.allCases

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Appearance"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseId)
        tableView.backgroundColor = Colours.surfacePrimary
        tableView.separatorColor = Colours.separator
        NavigationBarStyler.apply(to: navigationController?.navigationBar,
                                  fallbackTraitCollection: view.window?.traitCollection ?? traitCollection)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        tableView.reloadData()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard NavigationBarStyler.reapplyIfNeeded(on: self, previousTraitCollection: previousTraitCollection) else { return }
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        options.count
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        "Choose whether FreeAudiobooks follows your device appearance or always uses Light or Dark mode."
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath)
        let option = options[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = option.title
        content.textProperties.color = Colours.textPrimary
        cell.contentConfiguration = content
        cell.backgroundColor = Colours.surfaceCard
        cell.tintColor = Colours.orangePrimary
        cell.accessoryType = AppearanceManager.shared.currentPreference() == option ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selected = options[indexPath.row]
        let fallbackWindow = (UIApplication.shared.delegate as? AppDelegate)?.window
        AppearanceManager.shared.applyAppearancePreference(selected, window: view.window ?? fallbackWindow)
        navigationController?.popViewController(animated: true)
    }
}

extension AccountVC {
    func showRoadmapVC() {
        let vc = RoadmapVC(wasPresented: false)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension AccountVC {
    func showAboutFreeAudiobooksVC() {
        let subtitle = """
        Welcome to FreeAudiobooks — your gateway to a world of stories. From addictive new listens to timeless classics, FreeAudiobooks brings the stories listeners love together in one simple app.

        Our mission is simple: to make listening more accessible, enjoyable, and inspiring. Whether you’re discovering the latest gripping thriller, diving into a trending romance, or exploring the works of history’s greatest authors, FreeAudiobooks puts an entire audio library in your pocket — completely free.

        Start exploring today and discover your next obsession. With FreeAudiobooks, the next great story is always just a tap away.
        """
        let viewController = ReusableBottomSheetInfoVC(title: "About FreeAudiobooks",
                                                       subtitle: subtitle,
                                                       image: UIImage(named: "notifications")!, // Changed below to logo
                                                       showNegativeCTA: false,
                                                       showDismissButton: false)
        viewController.imageView.image = UIImage(named: "logo-rounded-100")
        viewController.imageView.tintColor = nil
        
        viewController.positiveCTATappedHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.dismiss(animated: true)
            }
        }
        viewController.preferredSheetSizing = .fill
        self.present(viewController, animated: true)
    }
}

extension AccountVC {
    func showDialogForPrivacyOrTerms() {
        let title = "Privacy & Terms"
        let message = RCValues.shared.string(forKey: .privacyTermsDialogBody)

        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)

        let privacyAction = UIAlertAction(title: "Privacy Policy", style: .default) { [weak self] _ in
            AnalyticsManager.shared.trackViewedPrivacy()
            guard let self,
                  let url = URL(string: AppConstants.shared.privacyURL) else { return }
            let svc = SFSafariViewController(url: url)
            self.present(svc, animated: true, completion: nil)
        }

        let termsAction = UIAlertAction(title: "Terms & Conditions", style: .default) { [weak self] _ in
            AnalyticsManager.shared.trackViewedTerms()
            guard let self,
                  let url = URL(string: AppConstants.shared.termsURL) else { return }
            let svc = SFSafariViewController(url: url)
            self.present(svc, animated: true, completion: nil)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alertController.addAction(privacyAction)
        alertController.addAction(termsAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
}

extension AccountVC: AccountDetailsVCDelegate {
    func handleEditProfile() {
        AnalyticsManager.shared.trackViewedAccountDetails()
        let vc = AccountDetailsViewController()
        vc.delegate = self
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    func accountDeleted() {
        EngagementEngine.cancelPendingNotification(includeStores: true)
        self.handleLogout()
    }
}

extension AccountVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func showImagePicker() {
        DispatchQueue.main.async {
            let imagePicker = UIImagePickerController()
            imagePicker.allowsEditing = true
            imagePicker.delegate = self
            imagePicker.modalPresentationStyle = .fullScreen
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var selectedImage: UIImage?
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            selectedImage = editedImage
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            selectedImage = originalImage
        }
        
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
        
        guard let image = selectedImage else {return}
        handleUploadImage(image)
    }
    
    private func handleUploadImage(_ image: UIImage) {
        accountProfileViewLoggedIn.showImageLoadingIndicator(show: true)

        AccountManager.shared.uploadProfileImage(image: image) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .error:
                DispatchQueue.main.async {
                    self.showUploadRetryError(image: image)
                }
            case .explicit:
                DispatchQueue.main.async {
                    self.showPossibleInappropriateContentAlert()
                }
            case .downloadURL:
                DispatchQueue.main.async {
                    self.accountProfileViewLoggedIn.showImageLoadingIndicator(show: false)
                    self.accountProfileViewLoggedIn.refreshData()
                }
            case .progress:
                break
            }
        }
    }
    
    private func showPossibleInappropriateContentAlert() {
        AnalyticsManager.shared.trackExplicitImageDetected()
        accountProfileViewLoggedIn.showImageLoadingIndicator(show: false)
        let alertController = AlertControllers.inappropriateContentAlert(multipleImageUpload: false)
        present(alertController, animated: true, completion: nil)
    }
    
    func showUploadRetryError(image: UIImage) {
        accountProfileViewLoggedIn.showImageLoadingIndicator(show: false)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let retryAction = UIAlertAction(title: "Retry", style: .default) { [weak self] retryTapped in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.handleUploadImage(image)
            }
        }
        let alertController = UIAlertController(title: "Network Error",
                                                message: "Please ensure you have an active internet connection and try again.", preferredStyle: .alert)
        alertController.addAction(cancelAction)
        alertController.addAction(retryAction)
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Support/Dev Request Mail Functionality
extension AccountVC: MFMailComposeViewControllerDelegate {
    
    func showMailAppForSupport() {
        AnalyticsManager.shared.trackTappedContactSupport()
        
        let mailComposeViewController = createMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            DispatchQueue.main.async {
                self.present(mailComposeViewController, animated: true, completion: nil)
            }
        } else {
            let title = "Apple Mail Uninstalled"
            let message = "We were unable to find the Apple Mail app. Please email us at hello@freeaudiobooksapp.com."
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func createMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        let email = RCValues.shared.string(forKey: .freebooksEmailAB)
        mailComposerVC.setToRecipients([email])
        mailComposerVC.setSubject("Support Request")
        
        //        mailComposerVC.navigationBar.backgroundColor = .white
        //        mailComposerVC.navigationBar.tintColor = .white
        //        mailComposerVC.navigationBar.barTintColor = Colours.navBarBackgroundColorInFlow
        //        mailComposerVC.navigationBar.titleTextAttributes = Fonts.navBarTitleTextAttributes
        
        return mailComposerVC
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        
        if result == MFMailComposeResult.sent {
            present(PopupHelper.defaultPopup(title: "Support Request Received 👍", message: "We have received your support request and will respond ASAP."), animated: true, completion: nil)
        }
    }
}

extension AccountVC {
    func showFullScreenReviewVC() {
        let helpUsGrowVC = HelpUsGrowVC(wasPresented: false)
        helpUsGrowVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(helpUsGrowVC, animated: true)
    }
}

extension AccountVC {
    func showShareAppSheet() {
        AnalyticsManager.shared.trackTappedSocialShare()
        DispatchQueue.main.async {
            let text = RCValues.shared.string(forKey: .shareAppMessageBodyAB) + " \(AppConstants.shared.appStoreURL)"
            var shareItems: [Any] = [text]
//            if let image = UIImage(named: "logo-filled-rounded") {
//                shareItems.append(image)
//            }
            let activityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        
            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                popoverController.sourceView = self.view
                popoverController.permittedArrowDirections = UIPopoverArrowDirection.any
            }
            
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
}

// Logout functionality
extension AccountVC {
    @objc func logout() {
        
        let title = "Are you sure?"
        let message = RCValues.shared.string(forKey: .logoutAreYouSureBodyAB)
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let noAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let yesAction = UIAlertAction(title: "Sign out", style: .destructive) { [weak self] tappedYes in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.handleLogout()
            }
        }
        
        controller.addAction(noAction)
        controller.addAction(yesAction)
        
        self.present(controller, animated: true, completion: nil)
    }
    func handleLogout() {
        AccountManager.signOut(tabBarController: self.tabBarController as? AppTabBarController)

        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                  let window = appDelegate.window else { return }
            let loadingVC = LoadingVC()
            let nav = UINavigationController(rootViewController: loadingVC)
            nav.setNavigationBarHidden(true, animated: false)
            window.rootViewController = nav
            window.makeKeyAndVisible()
        }
    }
    func showSignoutSuccessfulPopup() {
        self.present(PopupHelper.defaultPopup(title: "Sign out successful", message: "You can log back in anytime!"), animated: true, completion: nil)
    }
}

extension AccountVC {
    func displayPaywall(placement: PaywallPlacement) {
        let handler = PaywallPresentationHandler()
        handler.onPresent { _ in
            DispatchQueue.main.async {
                AnalyticsManager.shared.trackPaywallViewedForPlacement(placement)
            }
        }
        handler.onDismiss { [weak self] _, result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.updateProButtonVisibility()
                switch result {
                case .declined:
                    print("No purchased occurred.")
                case .purchased(let product):
                    print("Purchased \(product.productIdentifier)")
                    
                    if placement == .accountUpsell {
                        AnalyticsManager.shared.trackPaywallUserSubscribedForAccountUpsell()
                    }
                    
                    AnalyticsManager.shared.trackPaywallUserSubscribed(placement: placement, cdBookInternal: nil)
                    self.showSubscribeSuccessPopup()
                case .restored:
                    print("Restored purchases.")
                    AnalyticsManager.shared.trackPaywallRestorePurchasesSuccess()
                }
            }
        }
        Superwall.shared.register(placement: placement.rawValue, params: nil, handler: handler)
    }
    
    @objc func refreshForSubscriberStatus() {
        if AccountManager.shared.userIsSubscribed {
            self.stackView.removeArrangedSubview(self.settingsUpgradeView)
            self.settingsUpgradeView.removeFromSuperview()
        }
        self.refreshContent()
        self.updateProButtonVisibility()
    }
}

extension AccountVC {
    func updateTopProfileSection() {
        [accountProfileViewLoggedIn, accountDetailsRow].forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        stackView.insertArrangedSubview(accountProfileViewLoggedIn, at: 0)
        let detailsRow = AccountManager.shared.userIsSubscribed ? 2 : 3
        stackView.insertArrangedSubview(accountDetailsRow, at: detailsRow)
        stackView.setCustomSpacing(0, after: accountDetailsRow)
        stackView.layoutIfNeeded()
    }
}
