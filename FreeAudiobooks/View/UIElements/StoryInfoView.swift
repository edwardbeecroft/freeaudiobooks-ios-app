//
//  StoryInfoView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 10/08/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView

class StoryInfoView: UIView {
    let dataImageView = UIImageView()
    let countLabel = UILabel()
    
    var tappedUpvoteHandler: (() -> Void)?

    init(image: UIImage, text: String) {
        super.init(frame: .zero)
        setupUI()
        
        dataImageView.image = image.withRenderingMode(.alwaysTemplate)
        countLabel.text = text
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StoryInfoView {
    private func setupUI() {
        
        let imageSize: CGFloat = 16
        addSubviewForConstraints(dataImageView)
        NSLayoutConstraint.activate([
            dataImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dataImageView.topAnchor.constraint(equalTo: topAnchor),
            dataImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dataImageView.heightAnchor.constraint(equalToConstant: imageSize),
            dataImageView.widthAnchor.constraint(equalToConstant: imageSize)
        ])
        
        dataImageView.tintColor = Colours.lightUI
        dataImageView.contentMode = .scaleAspectFit
        
        addSubviewForConstraints(countLabel)
        NSLayoutConstraint.activate([
            countLabel.leadingAnchor.constraint(equalTo: dataImageView.trailingAnchor, constant: 4),
            countLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            countLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        
        countLabel.numberOfLines = 1
        countLabel.textColor = Colours.lightUI
        countLabel.font = Fonts.regular13
        countLabel.textAlignment = .left
        
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
    }
    
    @objc private func tapped() {
        tappedUpvoteHandler?()
    }
}
