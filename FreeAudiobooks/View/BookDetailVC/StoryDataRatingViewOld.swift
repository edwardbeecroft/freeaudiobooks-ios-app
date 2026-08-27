//
//  StoryDataRatingViewOld.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 16/10/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import UIKit
import Cosmos

class StoryDataRatingViewOld: UIView {

    private let introLabel = UILabel() // 15 Ratings
    private let titleLabel = UILabel() // 4.7
    private let starRatingView = CosmosView()

    init() {
        super.init(frame: .zero)
        setupLabels()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func set(introText: String,
             titleText: String,
             rating: Double) {
        backgroundColor = Colours.surfacePrimary

        introLabel.text = introText
        titleLabel.text = titleText
        starRatingView.rating = rating
    }
}

extension StoryDataRatingViewOld {
    func setupLabels() {
        [introLabel, titleLabel].forEach {
            $0.textAlignment = .center
            $0.numberOfLines = 0

            addSubviewForConstraints($0)

            NSLayoutConstraint.activate([
                $0.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
                $0.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4)
            ])
        }
        introLabel.font = Fonts.medium13
        titleLabel.font = Fonts.semiBold16

        introLabel.textColor = Colours.textSecondary
        titleLabel.textColor = Colours.textPrimary

        starRatingView.settings.updateOnTouch = false
        starRatingView.settings.fillMode = .precise
        starRatingView.settings.starSize = 18
        starRatingView.settings.starMargin = 0
        starRatingView.settings.emptyBorderWidth = 1

        starRatingView.settings.filledColor = Colours.textPrimary
        starRatingView.settings.emptyBorderColor = Colours.veryLightUI
        starRatingView.settings.filledBorderColor = Colours.textPrimary
        addSubviewForConstraints(starRatingView)

        NSLayoutConstraint.activate([
            introLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.topAnchor.constraint(equalTo: introLabel.bottomAnchor, constant: 8),
            starRatingView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 9),
            starRatingView.bottomAnchor.constraint(equalTo: bottomAnchor),
            starRatingView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
}
