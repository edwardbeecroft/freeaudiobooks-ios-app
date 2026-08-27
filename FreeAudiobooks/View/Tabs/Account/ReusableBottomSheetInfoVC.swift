//
//  ReusableBottomSheetInfoVC.swift
//  VaultX
//
//  Created by Ed Beecroft on 30/12/2023.
//  Copyright © 2023 Radically Better. All rights reserved.
//

import UIKit

final class ReusableBottomSheetInfoVC: BottomSheetController {
    private var stackView = UIStackView()
    let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let negativeCTAButton = Buttons.negativeCTAButton(buttonTitle: "Maybe later")
    private let positiveCTAButton = Buttons.primaryCTA(buttonTitle: "Continue")

    var negativeCTATappedHandler: (() -> Void)?
    var positiveCTATappedHandler: (() -> Void)?
    var dismissHandler: (() -> Void)?
    private let pulseImageView: Bool
    init(title: String,
         subtitle: String,
         image: UIImage,
         positiveCTATitle: String = "Continue",
         showNegativeCTA: Bool,
         negativeCTATitle: String = "Maybe later",
         showDismissButton: Bool,
         pulseImageView: Bool = false) {
        self.pulseImageView = pulseImageView
        super.init(nibName: nil, bundle: nil)
        createView(positiveCTATitle: positiveCTATitle, showNegativeCTA: showNegativeCTA, negativeCTATitle: negativeCTATitle, showDismissButton: showDismissButton)
        
        titleLabel.text = title
        subtitleLabel.text = subtitle
        imageView.image = image.withRenderingMode(.alwaysTemplate)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        if pulseImageView {
//            imageView.addPulseAnimation()
//        }
    }
    
    func createView(positiveCTATitle: String, showNegativeCTA: Bool, negativeCTATitle: String, showDismissButton: Bool) {
        
        //AnalyticsManager.shared.trackStorageInfoViewed()
        
        view = UIView()
        view.backgroundColor = Colours.surfaceCard
        
        tapToDismissEnabled = false
        panToDismissEnabled = false
        
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = Colours.textPrimary
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 40),
            imageView.widthAnchor.constraint(equalToConstant: 40)
        ])
        
        titleLabel.font = Fonts.semiBold18
        titleLabel.textColor = Colours.textPrimary
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        
        subtitleLabel.font = Fonts.medium15
        subtitleLabel.textColor = Colours.subtext
        subtitleLabel.textAlignment = .left
        subtitleLabel.numberOfLines = 0
        subtitleLabel.lineBreakMode = .byWordWrapping
        
        stackView = UIStackView(arrangedSubviews: [
            imageView,
            titleLabel,
            subtitleLabel,
            positiveCTAButton
        ])
        
        if showNegativeCTA {
            stackView.addArrangedSubview(negativeCTAButton)
            NSLayoutConstraint.activate([
                negativeCTAButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
                negativeCTAButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
            ])
        }
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .leading
        stackView.spacing = 12
        
        stackView.setCustomSpacing(20, after: subtitleLabel)
        
        view.addSubviewForConstraints(stackView)

        NSLayoutConstraint.activate([
            
            positiveCTAButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight),
            negativeCTAButton.heightAnchor.constraint(equalToConstant: 32),
            
            positiveCTAButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            positiveCTAButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            
            stackView.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -16)
        ])
        
        negativeCTAButton.addTarget(self, action: #selector(negativeCTATapped), for: .touchUpInside)
        negativeCTAButton.setTitle(negativeCTATitle, for: [])
        
        positiveCTAButton.addTarget(self, action: #selector(positiveCTATapped), for: .touchUpInside)
        positiveCTAButton.setTitle(positiveCTATitle, for: [])
        
        if showDismissButton {
            let dismissButton = UIButton()
            dismissButton.setImage(UIImage(named: "dismissIcon")?.withRenderingMode(.alwaysTemplate), for: [])
            dismissButton.tintColor = Colours.subtext
            dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
            view.addSubviewForConstraints(dismissButton)
            NSLayoutConstraint.activate([
                dismissButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
                dismissButton.heightAnchor.constraint(equalToConstant: 32),
                dismissButton.widthAnchor.constraint(equalToConstant: 32),
                dismissButton.trailingAnchor.constraint(equalTo: positiveCTAButton.trailingAnchor)
            ])
        }
    }
    
    @objc func dismissTapped() {
        dismissHandler?()
    }
    @objc func negativeCTATapped() {
        negativeCTATappedHandler?()
    }
    @objc func positiveCTATapped() {
        positiveCTATappedHandler?()
    }
}

extension ReusableBottomSheetInfoVC {
    func addAnnotationImage(_ image: UIImage, tintColor: UIColor) {
        let annotationImageView = UIImageView()
        imageView.addSubviewForConstraints(annotationImageView)
        NSLayoutConstraint.activate([
            annotationImageView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            annotationImageView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -8),
            annotationImageView.heightAnchor.constraint(equalToConstant: 14),
            annotationImageView.widthAnchor.constraint(equalToConstant: 14)
        ])
        annotationImageView.image = image.withRenderingMode(.alwaysTemplate)
        annotationImageView.tintColor = tintColor
    }
}
