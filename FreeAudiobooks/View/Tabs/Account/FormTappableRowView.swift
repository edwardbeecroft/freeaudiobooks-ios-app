//
//  FormTappableRowView.swift
//  VaultX
//
//  Created by Ed Beecroft on 01/01/2024.
//  Copyright © 2024 Radically Better. All rights reserved.
//

import UIKit

class FormTappableRowView: BaseFormView {
    
    var tapHandler: (() -> Void)?
    
    private let introLabel = UILabel()
    private let imageBackgroundView = UIView()
    private let imageView = UIImageView()
    private let alertBackgroundView = UIView()
    private let alertCountLabel = UILabel()
    private let chevronImageView = UIImageView()
    
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateAppearanceColors() {
        super.updateAppearanceColors()
        // Rows should remain slightly elevated from the Account tab background in both themes.
        backgroundColor = Colours.surfaceCard
    }
    
    func setupUI() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapRow))
        isUserInteractionEnabled = true
        addGestureRecognizer(tap)
        
        imageBackgroundView.layer.cornerRadius = 5
        imageBackgroundView.layer.masksToBounds = true
        
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        
        introLabel.font = Fonts.medium15
        introLabel.lineBreakMode = .byTruncatingTail
        introLabel.numberOfLines = 0
        introLabel.textColor = Colours.textSecondary
        introLabel.textAlignment = .left
//        introLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        chevronImageView.image = UIImage(named: "chevron-right")?.withRenderingMode(.alwaysTemplate)
        chevronImageView.tintColor = Colours.textTertiary
        
        alertBackgroundView.backgroundColor = .red //Colours.tempPrimary
        let alertHeightWidth: CGFloat = 24
        alertBackgroundView.layer.cornerRadius = alertHeightWidth / 2
        alertBackgroundView.layer.masksToBounds = true
        
        alertCountLabel.textAlignment = .center
        alertCountLabel.textColor = .white
        alertCountLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        
        addSubviewForConstraints(alertBackgroundView)
        alertBackgroundView.addSubviewForConstraints(alertCountLabel)
        alertBackgroundView.isHidden = true
        
        addSubviewForConstraints(imageBackgroundView)
        imageBackgroundView.addSubviewForConstraints(imageView)
        addSubviewForConstraints(introLabel)
        addSubviewForConstraints(chevronImageView)
        
        NSLayoutConstraint.activate([
            
            imageBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            imageBackgroundView.widthAnchor.constraint(equalToConstant: 28),
            imageBackgroundView.heightAnchor.constraint(equalToConstant: 28),
            
            imageView.centerYAnchor.constraint(equalTo: imageBackgroundView.centerYAnchor),
            imageView.centerXAnchor.constraint(equalTo: imageBackgroundView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.heightAnchor.constraint(equalToConstant: 20),
            
            chevronImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            
            introLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            introLabel.leadingAnchor.constraint(lessThanOrEqualTo: imageBackgroundView.trailingAnchor, constant: 12),
            introLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronImageView.leadingAnchor, constant: -12),
            introLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
            
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 12),
            
            chevronImageView.centerYAnchor.constraint(equalTo: introLabel.centerYAnchor),
            imageBackgroundView.centerYAnchor.constraint(equalTo: introLabel.centerYAnchor),
            
            alertBackgroundView.centerYAnchor.constraint(equalTo: introLabel.centerYAnchor),
            alertBackgroundView.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -12),
            alertBackgroundView.heightAnchor.constraint(equalToConstant: alertHeightWidth),
            alertBackgroundView.widthAnchor.constraint(equalToConstant: alertHeightWidth),
            
            alertCountLabel.centerYAnchor.constraint(equalTo: alertBackgroundView.centerYAnchor),
            alertCountLabel.centerXAnchor.constraint(equalTo: alertBackgroundView.centerXAnchor)
        ])

        updateAppearanceColors()
    }
    
    func configure(backgroundColor: UIColor, rowImage: UIImage, rowText: String) {
        imageBackgroundView.backgroundColor = backgroundColor
        imageView.image = rowImage.withRenderingMode(.alwaysTemplate)
        introLabel.text = rowText
    }
    
    func setAlertCount(_ count: Int) {
        if count < 1 {
            alertBackgroundView.isHidden = true
            alertCountLabel.text = nil
        } else {
            alertBackgroundView.isHidden = false
            alertCountLabel.text = "\(count)"
        }
    }

}

extension FormTappableRowView {
    @objc private func didTapRow() {
        tapHandler?()
    }
}
