//
//  StoryDataView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 15/08/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView

class StoryDataView: UIView {
    
    private let introLabel = UILabel() // GENRE
    private let titleLabel = UILabel() // Paranormal
    
    init() {
        super.init(frame: .zero)
        setupLabels()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func set(introText: String,
             titleText: String,
             subtitleText _: String) {
        backgroundColor = Colours.surfacePrimary
        
        introLabel.text = introText
        titleLabel.text = titleText
    }
}

extension StoryDataView {
    func setupLabels() {
        [introLabel, titleLabel].forEach {
            $0.textAlignment = .left
            $0.numberOfLines = 1
            
            addSubviewForConstraints($0)
            
            NSLayoutConstraint.activate([
                $0.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
                $0.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4)
            ])
        }
        introLabel.font = Fonts.medium13
        titleLabel.font = Fonts.semiBold14
        
        introLabel.textColor = Colours.textSecondary
        titleLabel.textColor = Colours.textPrimary
        
        NSLayoutConstraint.activate([
            introLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.topAnchor.constraint(equalTo: introLabel.bottomAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
