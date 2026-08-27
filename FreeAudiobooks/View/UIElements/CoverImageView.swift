//
//  CoverImageView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 10/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import Kingfisher

enum ParentVenue {
    case book
    case libraryContinueReading
    case smallMetadataView
    case readingVC
    case home
    
    var size: CGFloat {
        switch self {
        case .readingVC, .smallMetadataView, .home: return 16
        case .book, .libraryContinueReading: return 20
        }
    }
    var inset: CGFloat {
        switch self {
        case .readingVC, .smallMetadataView, .home: return 2
        case .book, .libraryContinueReading: return UIConstants.shared.coverImageBadgeInset
        }
    }
}

class CoverImageView: UIView {

    private let imageView = UIImageView()

    // Completion overlay elements
    private let completionOverlayView = UIView()
    private let completionTickImageView = UIImageView()

    // Progress bar
    private let progressView = UIProgressView(progressViewStyle: .bar)

    // Progress badge (shows percentage in top-right)
    private let progressBadge = UILabel()

    private let imageHeight: CGFloat?
    private let widthMultiplier: CGFloat?
    private let parentVenue: ParentVenue

    // MARK: - Computed Styling Properties

    private var progressBadgeInset: CGFloat {
        switch parentVenue {
        case .libraryContinueReading:
            return 4
        default:
            return UIConstants.shared.coverImageBadgeInset
        }
    }

    /// Shared cover corner radius used across the app, unless explicitly overridden.
    var coverCornerRadiusOverride: CGFloat? {
        didSet {
            guard let r = coverCornerRadiusOverride else { return }
            imageView.layer.cornerRadius = r
            self.layer.cornerRadius = r
        }
    }
    private var coverCornerRadius: CGFloat {
        return coverCornerRadiusOverride ?? UIConstants.shared.bookCoverCornerRadius
    }

    /// Shadow opacity scaled to the view size
    private var scaledShadowOpacity: Float {
        if parentVenue == .home || parentVenue == .libraryContinueReading {
            return 0
        }
        if widthMultiplier != nil {
            return parentVenue == .book ? 0.25 : 0
        }
        guard let height = imageHeight else { return 0 }
        // Only show shadow for larger fixed-height covers (100pt+)
        return height >= 100 ? 0.15 : 0
    }

    /// Shadow radius scaled to the view size
    private var scaledShadowRadius: CGFloat {
        if parentVenue == .home || parentVenue == .libraryContinueReading {
            return 0
        }
        if widthMultiplier != nil {
            return parentVenue == .book ? 4 : 0
        }
        guard let height = imageHeight else { return 0 }
        return height >= 100 ? 3 : 0
    }

    /// Shadow offset scaled to the view size
    private var scaledShadowOffset: CGSize {
        if parentVenue == .home || parentVenue == .libraryContinueReading {
            return .zero
        }
        if widthMultiplier != nil {
            return parentVenue == .book ? CGSize(width: 0, height: 2) : .zero
        }
        guard let height = imageHeight else { return .zero }
        return height >= 100 ? CGSize(width: 0, height: 1) : .zero
    }

    // MARK: - Initialization

    init(height: CGFloat, parentVenue: ParentVenue) {
        self.imageHeight = height
        self.widthMultiplier = nil
        self.parentVenue = parentVenue
        super.init(frame: .zero)
        setupImageView()
        setupProgressView()

        if parentVenue == .book || parentVenue == .libraryContinueReading {
            setupProgressBadge() // Only show this on the content overview
        }
        // Don't setup completion overlay until we have the image
    }

    /// Creates a cover image view that uses a percentage of its superview's width
    /// - Parameters:
    ///   - widthMultiplier: The fraction of the superview's width (e.g., 0.6 for 60%)
    ///   - parentVenue: The venue for context-specific styling
    init(widthMultiplier: CGFloat, parentVenue: ParentVenue) {
        self.imageHeight = nil
        self.widthMultiplier = widthMultiplier
        self.parentVenue = parentVenue
        super.init(frame: .zero)
        setupImageViewForWidthMultiplier()
        setupProgressView()
        if parentVenue == .book || parentVenue == .libraryContinueReading {
            setupProgressBadge()
        }
        // Don't setup completion overlay until we have the image
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    
    func setImage(urlString: String?, isBookCompleted: Bool, progressPercentage: Int?) {
        if
            let imageString = urlString,
            !imageString.isEmpty,
            let imageURL = URL(string: imageString) {
            
            imageView.kf.indicatorType = .activity
            imageView.kf.setImage(with: imageURL, options: [.transition(.fade(0.2))]) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let value):
                    DispatchQueue.main.async {
                        self.setupCompletionOverlayForImage(value.image, isCompleted: isBookCompleted)
                        self.setProgress(progressPercentage)
                    }
                case .failure(_):
                    break
                }
            }
            
        } else {
            // Set placeholder
            imageView.image = User.placeholderImage
            imageView.tintColor = Colours.textSecondary.withAlphaComponent(0.5)
            imageView.layer.cornerRadius = 0
            imageView.layer.masksToBounds = false
            imageView.contentMode = .scaleAspectFit
            imageView.isHidden = false
            
            // Setup overlay for placeholder if needed
            if let placeholderImage = User.placeholderImage {
                setupCompletionOverlayForImage(placeholderImage, isCompleted: isBookCompleted)
                setProgress(progressPercentage)
            }
        }
        
        // Apply shared cover corner radius
        [imageView, completionOverlayView].forEach {
            $0.layer.cornerRadius = coverCornerRadius
            $0.layer.masksToBounds = true
        }
    }
    
    func showCompletionStatus(_ isCompleted: Bool) {
        completionOverlayView.isHidden = !isCompleted

        // Hide progress bar and badge if completed
        if parentVenue != .readingVC {
            progressView.isHidden = isCompleted
            progressBadge.isHidden = isCompleted
        }
    }

    func setProgress(_ progressPercentage: Int?) {
        // Don't show progress if completed (handled in showCompletionStatus)
        if !completionOverlayView.isHidden {
            progressView.isHidden = true
            progressBadge.isHidden = true
            return
        }

        if let percentage = progressPercentage, percentage > 0 {
            let progressValue = Float(percentage) / 100.0
            progressView.progress = progressValue
            progressView.isHidden = false

            // Show progress badge with percentage
            progressBadge.text = "\(percentage)%"
            progressBadge.isHidden = false
        } else {
            progressView.isHidden = true
            progressBadge.isHidden = true
        }
    }

    func setLocalImage(named imageName: String) {
        imageView.image = UIImage(named: imageName)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = coverCornerRadius
        imageView.clipsToBounds = true
    }

    func setContentMode(_ mode: UIView.ContentMode) {
        imageView.contentMode = mode
    }
    
    private func setupCompletionOverlayForImage(_ image: UIImage, isCompleted: Bool) {
        // Remove existing overlay if it exists
        completionTickImageView.removeFromSuperview()
        completionOverlayView.removeFromSuperview()
        
        // Calculate the actual image bounds within the imageView
        let imageViewBounds = imageView.bounds
        let imageSize = image.size
        
        guard imageSize.width > 0 && imageSize.height > 0 && !imageViewBounds.isEmpty else { return }
        
        let imageViewAspectRatio = imageViewBounds.width / imageViewBounds.height
        let imageAspectRatio = imageSize.width / imageSize.height
        
        var imageRect: CGRect
        
        if imageView.contentMode == .scaleAspectFit {
            if imageAspectRatio > imageViewAspectRatio {
                // Image is wider - fit to width, center vertically
                let scaledHeight = imageViewBounds.width / imageAspectRatio
                let yOffset = (imageViewBounds.height - scaledHeight) / 2
                imageRect = CGRect(x: 0, y: yOffset, width: imageViewBounds.width, height: scaledHeight)
            } else {
                // Image is taller - fit to height, center horizontally
                let scaledWidth = imageViewBounds.height * imageAspectRatio
                let xOffset = (imageViewBounds.width - scaledWidth) / 2
                imageRect = CGRect(x: xOffset, y: 0, width: scaledWidth, height: imageViewBounds.height)
            }
        } else {
            // For other content modes, just use the full imageView bounds
            imageRect = imageViewBounds
        }
        
        // Setup completion overlay
        completionOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        completionOverlayView.isHidden = !isCompleted
        
        // Setup checkmark
        completionTickImageView.image = UIImage(systemName: "checkmark.circle.fill")
        completionTickImageView.tintColor = UIColor.white
        completionTickImageView.contentMode = .scaleAspectFit
        
        imageView.addSubviewForConstraints(completionOverlayView)
        completionOverlayView.addSubviewForConstraints(completionTickImageView)
        
        NSLayoutConstraint.activate([
            // Completion overlay (positioned over actual image bounds)
            completionOverlayView.topAnchor.constraint(equalTo: imageView.topAnchor, constant: imageRect.minY),
            completionOverlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: imageRect.minX),
            completionOverlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -(imageViewBounds.width - imageRect.maxX)),
            completionOverlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -(imageViewBounds.height - imageRect.maxY)),
            
            // White checkmark (top-right corner of actual image)
            completionTickImageView.topAnchor.constraint(equalTo: completionOverlayView.topAnchor, constant: parentVenue.inset),
            completionTickImageView.trailingAnchor.constraint(equalTo: completionOverlayView.trailingAnchor, constant: -parentVenue.inset),
            completionTickImageView.widthAnchor.constraint(equalToConstant: parentVenue.size),
            completionTickImageView.heightAnchor.constraint(equalToConstant: parentVenue.size)
        ])
    }
    
    // MARK: - Private Setup Methods
    
    private func setupImageView() {
        addSubviewForConstraints(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.heightAnchor.constraint(equalToConstant: imageHeight ?? 140),
            imageView.widthAnchor.constraint(equalToConstant: (imageHeight ?? 140) * UIConstants.shared.bookInternalCoverImageWidthToHeightRatio)
        ])

        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        // Corner radius and clipping on imageView
        imageView.layer.cornerRadius = coverCornerRadius
        imageView.clipsToBounds = true

        // Shadow on self (container) - shadow values still scale by context
        self.layer.cornerRadius = coverCornerRadius
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = scaledShadowOffset
        self.layer.shadowRadius = scaledShadowRadius
        self.layer.shadowOpacity = scaledShadowOpacity
        self.layer.masksToBounds = false
    }

    private func setupImageViewForWidthMultiplier() {
        addSubviewForConstraints(imageView)

        // Width is set relative to superview, height follows aspect ratio (2:3)
        // The aspect ratio constraint uses height = width / bookInternalCoverImageHeightToWidthRatio
        // Since bookInternalCoverImageHeightToWidthRatio = width/height = 2/3, we need height = width * 1.5
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            // Height is determined by aspect ratio (width:height = 2:3)
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.0 / UIConstants.shared.bookInternalCoverImageWidthToHeightRatio)
        ])

        imageView.contentMode = .scaleAspectFill
        imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        // Corner radius and clipping on imageView
        imageView.layer.cornerRadius = coverCornerRadius
        imageView.clipsToBounds = true

        // Shadow on self (container) - shadow values still scale by context
        self.layer.cornerRadius = coverCornerRadius
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = scaledShadowOffset
        self.layer.shadowRadius = scaledShadowRadius
        self.layer.shadowOpacity = scaledShadowOpacity
        self.layer.masksToBounds = false
    }

    func getWidthMultiplier() -> CGFloat? {
        return widthMultiplier
    }

    private func setupProgressView() {
        progressView.progressTintColor = Colours.orangePrimary
        progressView.trackTintColor = UIColor.systemGray5
        progressView.isHidden = true

        imageView.addSubviewForConstraints(progressView)

        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4)
        ])
    }

    private func setupProgressBadge() {
        progressBadge.font = Fonts.semiBold12
        progressBadge.textColor = UIColor.dynamic(light: Colours.lightUI, dark: Colours.brandBlack.withAlphaComponent(0.78))
        progressBadge.textAlignment = .center
        progressBadge.backgroundColor = .white
        progressBadge.layer.cornerRadius = UIConstants.shared.smallCornerRadius
        progressBadge.layer.masksToBounds = true
        progressBadge.isHidden = true

        imageView.addSubviewForConstraints(progressBadge)

        NSLayoutConstraint.activate([
            progressBadge.topAnchor.constraint(equalTo: imageView.topAnchor, constant: progressBadgeInset),
            progressBadge.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -progressBadgeInset),
            progressBadge.widthAnchor.constraint(equalToConstant: 36),
            progressBadge.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
}
