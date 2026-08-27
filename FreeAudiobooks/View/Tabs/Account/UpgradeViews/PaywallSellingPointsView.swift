//
//  PaywallSellingPointsView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 13/08/2025.
//  Copyright © 2025 Radically Better. All rights reserved.
//

import UIKit

enum PaywallBulletType {
    case simple
    case detailed
}

protocol Bullet {
    var title: String { get }
    var subtitle: String? { get }
    var image: UIImage { get }
}

struct PaywallBullet: Bullet {
    var title: String
    let subtitle: String?
    
    var image: UIImage {
        return UIImage(named: "paywall-tick-green")!
    }
    var type: PaywallBulletType {
        return subtitle != nil && subtitle != "" ? .detailed : .simple
    }
}

struct PaywallBullets {
    static func bulletOffline() -> PaywallBullet {
        let title = "Unlock unlimited audiobooks"
        return PaywallBullet(title: title, subtitle: nil)
    }
    static func bulletEarlyReleases() -> PaywallBullet {
        let title = "Get new releases 90 days early"
        return PaywallBullet(title: title, subtitle: nil)
    }
    static func bulletAdFreeExperience() -> PaywallBullet {
        let title = "Listen ad-free, no interruptions"
        return PaywallBullet(title: title, subtitle: nil)
    }
}

enum PaywallSellingPointsViewVenue {
    case settings
    
    var bullets: [PaywallBullet] {
        return [
            PaywallBullets.bulletOffline(),
            PaywallBullets.bulletEarlyReleases(),
            PaywallBullets.bulletAdFreeExperience()
        ]
    }
    var bulletSpacing: CGFloat {
        switch self {
        case .settings: return 12
        }
    }
}

class PaywallSellingPointsView: UIView {
    private let sellingPointStackView = UIStackView()
     
    private let venue: PaywallSellingPointsViewVenue
    init(venue: PaywallSellingPointsViewVenue) {
        self.venue = venue
        super.init(frame: .zero)
        setupSellingPointStackView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PaywallSellingPointsView {
    func setupSellingPointStackView() {
        sellingPointStackView.alignment = .leading
        sellingPointStackView.axis = .vertical
        sellingPointStackView.distribution = .fill
        
        sellingPointStackView.spacing = venue.bulletSpacing
    
        addSubviewForConstraints(sellingPointStackView)
        NSLayoutConstraint.activate([
            sellingPointStackView.topAnchor.constraint(equalTo: topAnchor),
            sellingPointStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        NSLayoutConstraint.activate([
            sellingPointStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            sellingPointStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            sellingPointStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24)
        ])
        
        for bullet in venue.bullets {
            if bullet.type == .detailed {
                let view = PaywallDetailedBulletView(bullet: bullet)
                sellingPointStackView.addArrangedSubview(view)
            } else {
                let view = PaywallSimpleBulletView(bullet: bullet)
                sellingPointStackView.addArrangedSubview(view)
            }
        }
    }
}
