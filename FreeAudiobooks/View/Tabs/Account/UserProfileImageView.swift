//
//  UserProfileImageView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 13/08/2025.
//  Copyright © 2025 Radically Better. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import Kingfisher

enum UserProfileImageViewVenue {
    case featuredVC
    case profileVC
    case recipeTipVC
    case dashboardHeader
    
    var userImageHeight: CGFloat {
        switch self {
        case .recipeTipVC: return 30
        case .featuredVC: return 40
        case .profileVC: return 54
        case .dashboardHeader: return 28
        }
    }

    var initialsFontSize: CGFloat {
        switch self {
        case .recipeTipVC: return 13
        case .featuredVC: return 17
        case .profileVC: return 22
        case .dashboardHeader: return 12
        }
    }

    var addBadgeSize: CGFloat {
        switch self {
        case .recipeTipVC: return 0
        case .featuredVC: return 16
        case .profileVC: return 18
        case .dashboardHeader: return 12
        }
    }

    var addBadgeCenterInset: CGFloat {
        switch self {
        case .recipeTipVC: return 0
        case .featuredVC: return 5
        case .profileVC: return 6
        case .dashboardHeader: return 4
        }
    }

    var addBadgeFontSize: CGFloat {
        switch self {
        case .recipeTipVC: return 0
        case .featuredVC: return 11
        case .profileVC: return 13
        case .dashboardHeader: return 9
        }
    }

    var addBadgeBaselineOffset: CGFloat {
        switch self {
        case .recipeTipVC: return 0
        case .featuredVC, .profileVC: return 1
        case .dashboardHeader: return 1.5
        }
    }

    var loadingIndicatorSize: CGFloat {
        switch self {
        case .dashboardHeader: return 16
        default: return UIConstants.shared.fetchingIndicatorWidthHeight
        }
    }
}

enum AvatarInitials {
    static let fallback = "FA"

    static func from(firstName: String?, lastName: String?) -> String {
        let characters = [firstName, lastName].compactMap { name in
            name?.trimmingCharacters(in: .whitespacesAndNewlines).first
        }
        return characters.isEmpty ? fallback : String(characters).uppercased()
    }

    static func from(displayName: String?) -> String {
        let words = displayName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline }) ?? []

        guard let first = words.first?.first else { return fallback }
        if let last = words.dropFirst().last?.first {
            return String([first, last]).uppercased()
        }
        return String(first).uppercased()
    }
}

class UserProfileImageView: UIView {
    private let containerView = UIView()
    private let userImageView = UIImageView()
    private let initialsLabel = UILabel()
    private let userAddImageLabel = UILabel()
    
    private var isUploadingProfileImage: Bool = false
    private var loadingIndicatorView: NVActivityIndicatorView?
    var tapHandler: (() -> Void)?
    
    private let venue: UserProfileImageViewVenue
    init(venue: UserProfileImageViewVenue) {
        self.venue = venue
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        applyAppearanceColors()
    }
}

private extension UserProfileImageView {
    @objc func tappedView() {
        tapHandler?()
    }
}

extension UserProfileImageView {
    func update() {
        if let user = AccountManager.shared.user,
           let imageURLString = user.profileImageURLString,
           let imageURL = URL(string: imageURLString) {

            initialsLabel.isHidden = true
            initialsLabel.alpha = 0
            userAddImageLabel.isHidden = true
            userAddImageLabel.alpha = 0
            userImageView.isHidden = false
            userImageView.alpha = isUploadingProfileImage ? 0 : 1

            userImageView.kf.indicatorType = .activity
            DispatchQueue.main.async {
                self.userImageView.kf.setImage(with: imageURL, options: [.transition(.fade(0.2))])
            }
            userImageView.contentMode = .scaleAspectFill
            userImageView.layer.cornerRadius = venue.userImageHeight / 2
            userImageView.layer.masksToBounds = true
            containerView.backgroundColor = .clear
        } else {
            setupWithPlaceholder()
        }

        updateAccessibilityState()
    }

    func setupWithPlaceholder() {
        userImageView.kf.cancelDownloadTask()
        userImageView.isHidden = true
        userImageView.image = nil
        initialsLabel.isHidden = false
        initialsLabel.alpha = isUploadingProfileImage ? 0 : 1
        initialsLabel.text = AvatarInitials.from(
            firstName: AccountManager.shared.user?.firstName,
            lastName: AccountManager.shared.user?.lastName
        )
        userAddImageLabel.isHidden = venue == .recipeTipVC || isUploadingProfileImage
        userAddImageLabel.alpha = isUploadingProfileImage ? 0 : 1
        containerView.backgroundColor = .clear
    }
}

private extension UserProfileImageView {
    func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: venue.userImageHeight),
            widthAnchor.constraint(equalToConstant: venue.userImageHeight)
        ])
        
//        isUserInteractionEnabled = true
//        let tap = UITapGestureRecognizer(target: self, action: #selector(tappedView))
//        addGestureRecognizer(tap)
        
        addSubviewForConstraints(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        containerView.layer.masksToBounds = true
        containerView.layer.cornerRadius = venue.userImageHeight / 2

        userImageView.layer.masksToBounds = true
        containerView.addSubviewForConstraints(userImageView)
        NSLayoutConstraint.activate([
            userImageView.heightAnchor.constraint(equalToConstant: venue.userImageHeight),
            userImageView.widthAnchor.constraint(equalToConstant: venue.userImageHeight),
            userImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            userImageView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        userImageView.contentMode = .scaleAspectFill
        userImageView.layer.cornerRadius = venue.userImageHeight / 2

        containerView.addSubviewForConstraints(initialsLabel)
        NSLayoutConstraint.activate([
            initialsLabel.heightAnchor.constraint(equalToConstant: venue.userImageHeight),
            initialsLabel.widthAnchor.constraint(equalToConstant: venue.userImageHeight),
            initialsLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            initialsLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        initialsLabel.layer.cornerRadius = venue.userImageHeight / 2
        initialsLabel.layer.masksToBounds = true
        initialsLabel.font = Fonts.semiBoldWithSize(venue.initialsFontSize)
        initialsLabel.textAlignment = .center
        initialsLabel.adjustsFontSizeToFitWidth = true
        initialsLabel.minimumScaleFactor = 0.6
        initialsLabel.isHidden = true

        addSubviewForConstraints(userAddImageLabel)
        NSLayoutConstraint.activate([
            userAddImageLabel.heightAnchor.constraint(equalToConstant: venue.addBadgeSize),
            userAddImageLabel.widthAnchor.constraint(equalToConstant: venue.addBadgeSize),
            userAddImageLabel.centerXAnchor.constraint(
                equalTo: userImageView.trailingAnchor,
                constant: -venue.addBadgeCenterInset
            ),
            userAddImageLabel.centerYAnchor.constraint(
                equalTo: userImageView.topAnchor,
                constant: venue.addBadgeCenterInset
            )
        ])
        userAddImageLabel.layer.cornerRadius = venue.addBadgeSize / 2
        userAddImageLabel.layer.masksToBounds = true
        userAddImageLabel.layer.borderWidth = 1
        userAddImageLabel.baselineAdjustment = .alignCenters
        userAddImageLabel.attributedText = NSAttributedString(
            string: "+",
            attributes: [
                .font: UIFont.systemFont(ofSize: venue.addBadgeFontSize, weight: .bold),
                .baselineOffset: venue.addBadgeBaselineOffset
            ]
        )
        userAddImageLabel.textAlignment = .center
        userAddImageLabel.isUserInteractionEnabled = true
        userAddImageLabel.isHidden = true

        isAccessibilityElement = true
        accessibilityTraits = [.button, .image]
        applyAppearanceColors()
        updateAccessibilityState()

//        let labelTap = UITapGestureRecognizer(target: self, action: #selector(userImageViewTapped))
//        userAddImageLabel.addGestureRecognizer(labelTap)
    }

    func applyAppearanceColors() {
        initialsLabel.backgroundColor = UIColor.dynamic(
            light: Colours.orangePrimary.withAlphaComponent(0.10),
            dark: Colours.orangePrimary.withAlphaComponent(0.18)
        )
        initialsLabel.textColor = Colours.orangePrimary
        userAddImageLabel.textColor = Colours.orangePrimary
        userAddImageLabel.backgroundColor = Colours.surfacePrimary
        userAddImageLabel.layer.borderColor = Colours.orangePrimary.withAlphaComponent(0.4).cgColor
    }

    func updateAccessibilityState() {
        let hasProfileImage = AccountManager.shared.user?.profileImageURLString.flatMap(URL.init(string:)) != nil
        accessibilityLabel = hasProfileImage ? "Change profile photo" : "Add profile photo"
    }
}

extension UserProfileImageView {
    func showImageLoadingIndicator(show: Bool) {
        guard show != isUploadingProfileImage ||
                (show && loadingIndicatorView == nil) ||
                (!show && loadingIndicatorView != nil) else { return }

        isUploadingProfileImage = show
        update()

        if show {
            if loadingIndicatorView != nil { return }

            let indicatorView = NVActivityIndicatorView(
                frame: .zero,
                type: .circleStrokeSpin,
                color: Colours.textPrimary,
                padding: 0
            )
            loadingIndicatorView = indicatorView
            addSubviewForConstraints(indicatorView)
            NSLayoutConstraint.activate([
                indicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
                indicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),
                indicatorView.widthAnchor.constraint(equalToConstant: venue.loadingIndicatorSize),
                indicatorView.heightAnchor.constraint(equalToConstant: venue.loadingIndicatorSize)
            ])
            indicatorView.startAnimating()
        } else {
            loadingIndicatorView?.stopAnimating()
            loadingIndicatorView?.removeFromSuperview()
            loadingIndicatorView = nil
            userImageView.alpha = 1
        }
    }
}

enum ReviewerAvatarPlaceholder {
    static func image(
        for displayName: String?,
        diameter: CGFloat,
        traitCollection: UITraitCollection
    ) -> UIImage {
        let initials = AvatarInitials.from(displayName: displayName)
        let backgroundColor = UIColor.dynamic(
            light: Colours.orangePrimary.withAlphaComponent(0.10),
            dark: Colours.orangePrimary.withAlphaComponent(0.18)
        ).resolvedColor(with: traitCollection)
        let textColor = Colours.orangePrimary.resolvedColor(with: traitCollection)
        let font = Fonts.semiBoldWithSize(max(11, diameter * 0.42))

        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false

        let size = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            backgroundColor.setFill()
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))

            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor
            ]
            let textSize = initials.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (diameter - textSize.width) / 2,
                y: (diameter - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            initials.draw(in: textRect, withAttributes: attributes)
        }
    }
}
