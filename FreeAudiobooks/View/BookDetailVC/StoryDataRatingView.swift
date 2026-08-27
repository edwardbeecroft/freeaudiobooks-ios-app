//
//  StoryDataRatingView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 16/10/2025.
//  Copyright © 2025 Kneady Technologies. All rights reserved.
//

import Foundation
import UIKit
import Cosmos

class StoryDataRatingView: UIView {
    
    private let introLabel = UILabel() // 15 Ratings
    private let primaryValueLabel = UILabel() // 4.7
    private let secondaryValueLabel = UILabel() // (15)
    private let starRatingView = CosmosView()
    private let valueStackView = UIStackView()
    
    init() {
        super.init(frame: .zero)
        setupLabels()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func set(introText: String,
             primaryValueText: String,
             secondaryValueText: String?,
             rating: Double) {
        backgroundColor = Colours.surfacePrimary
        
        introLabel.text = introText
        primaryValueLabel.text = primaryValueText
        secondaryValueLabel.text = secondaryValueText
        secondaryValueLabel.isHidden = secondaryValueText == nil
        starRatingView.isHidden = rating <= 0
        starRatingView.rating = rating > 0 ? 1 : 0
    }
}

extension StoryDataRatingView {
    func setupLabels() {
        [introLabel, primaryValueLabel, secondaryValueLabel].forEach {
            $0.textAlignment = .left
            $0.numberOfLines = 1
        }
        addSubviewForConstraints(introLabel)
        addSubviewForConstraints(valueStackView)
        valueStackView.addArrangedSubview(starRatingView)
        valueStackView.addArrangedSubview(primaryValueLabel)
        valueStackView.addArrangedSubview(secondaryValueLabel)

        NSLayoutConstraint.activate([
            introLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            introLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            primaryValueLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
            primaryValueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4)
        ])

        introLabel.font = Fonts.medium13
        primaryValueLabel.font = Fonts.semiBold14
        secondaryValueLabel.font = Fonts.semiBold12
        
        introLabel.textColor = Colours.textSecondary
        primaryValueLabel.textColor = Colours.textPrimary
        secondaryValueLabel.textColor = Colours.textSecondary

        valueStackView.axis = .horizontal
        valueStackView.alignment = .center
        valueStackView.distribution = .fill
        valueStackView.spacing = 4
        valueStackView.setCustomSpacing(2, after: starRatingView)

        starRatingView.settings.updateOnTouch = false
        starRatingView.settings.fillMode = .full
        starRatingView.settings.totalStars = 1
        starRatingView.settings.starSize = 13
        starRatingView.settings.starMargin = 0
        starRatingView.settings.emptyBorderWidth = 1
        starRatingView.settings.filledColor = Colours.textPrimary
        starRatingView.settings.emptyBorderColor = Colours.veryLightUI
        starRatingView.settings.filledBorderColor = Colours.textPrimary
        
        NSLayoutConstraint.activate([
            introLabel.topAnchor.constraint(equalTo: topAnchor),
            valueStackView.topAnchor.constraint(equalTo: introLabel.bottomAnchor, constant: 8),
            valueStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            valueStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
            valueStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
