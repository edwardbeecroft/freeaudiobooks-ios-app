//
//  StoryDataViewOld.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 15/08/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import UIKit

class StoryDataViewOld: UIView {

    private let introLabel = UILabel() // GENRE
    private let titleLabel = UILabel() // Paranormal
    private let subtitleLabel = UILabel() // Paranormal

    init() {
        super.init(frame: .zero)
        setupLabels()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func set(introText: String,
             titleText: String,
             subtitleText: String) {
        backgroundColor = Colours.surfacePrimary

        introLabel.text = introText
        titleLabel.text = titleText
        subtitleLabel.text = subtitleText
    }
}

extension StoryDataViewOld {
    func setupLabels() {
        [introLabel, titleLabel, subtitleLabel].forEach {
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
        subtitleLabel.font = Fonts.medium14

        introLabel.textColor = Colours.textSecondary
        titleLabel.textColor = Colours.textPrimary
        subtitleLabel.textColor = Colours.textSecondary

        NSLayoutConstraint.activate([
            introLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.topAnchor.constraint(equalTo: introLabel.bottomAnchor, constant: 8),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
