//
//  ShortStorySearchPromptTVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 10/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

class ShortStorySearchPromptTVC: UITableViewCell {
    
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let ctaButton = Buttons.primaryCTA(buttonTitle: "Browse Filters")
    private let topBorderView = UIView()
    private let topBottomSpacing: CGFloat = 28
    
    var ctaTappedHandler: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    private func setupUI() {
        setupTopBorder()
        setupTitleLabel()
        setupSubtitleLabel()
        setupCTAButton()
        
        // Set content for this specific prompt
        titleLabel.text = "Find Your Perfect Listen"
        subtitleLabel.text = "Filter by genre, listening time, or mood to discover your next favorite story"
    }
}

private extension ShortStorySearchPromptTVC {
    func setupTopBorder() {
        topBorderView.backgroundColor = Colours.separator
        
        contentView.addSubviewForConstraints(topBorderView)
        NSLayoutConstraint.activate([
            topBorderView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            topBorderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            topBorderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            topBorderView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    func setupTitleLabel() {
        titleLabel.textColor = Colours.textPrimary
        titleLabel.font = Fonts.semiBold20
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.textAlignment = .center
        
        contentView.addSubviewForConstraints(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topBorderView.bottomAnchor, constant: topBottomSpacing),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin)
        ])
        
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
    }
    
    func setupSubtitleLabel() {
        subtitleLabel.textColor = Colours.subtext
        subtitleLabel.font = Fonts.medium15
        subtitleLabel.numberOfLines = 0
        subtitleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.textAlignment = .center
        
        contentView.addSubviewForConstraints(subtitleLabel)
        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
        ])
    }
    
    func setupCTAButton() {
        contentView.addSubviewForConstraints(ctaButton)
        NSLayoutConstraint.activate([
            ctaButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            ctaButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight),
            ctaButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            ctaButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            ctaButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -topBottomSpacing),
        ])
        ctaButton.addTarget(self, action: #selector(ctaTapped), for: .touchUpInside)
    }
    
    @objc func ctaTapped() {
        ctaTappedHandler?()
    }
}
