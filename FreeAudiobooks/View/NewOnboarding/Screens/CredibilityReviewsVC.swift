//
//  CredibilityReviewsVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

/// Credibility/reviews screen (Screen 15)
/// Cal AI-style layout with accolade section, avatars, and testimonials
class CredibilityReviewsVC: BaseNewOnboardingVC {

    override var step: NewOnboardingStep { .credibilityReviews }

    // MARK: - Colors

    private let starColor = UIColor.systemOrange

    // MARK: - UI Elements

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 28
        stack.alignment = .fill
        return stack
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = Colours.textPrimary
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    private var borderedCardViews: [UIView] = []
    private var avatarViews: [UIImageView] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateAppearanceColors()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Only request review once per onboarding session
        if !coordinator.dataStore.didRequestAppReview {
            coordinator.dataStore.didRequestAppReview = true
            SKReviewManager.requestReview(venue: .onboarding)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateAppearanceColors()
    }

    // MARK: - Setup

    private func setupUI() {
        titleLabel.text = RCValues.shared.string(forKey: .onbCredibilityReviewsTitle)

        contentView.addSubviewForConstraints(scrollView)
        scrollView.addSubviewForConstraints(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 10),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])

        // Add title
        stackView.addArrangedSubview(titleLabel)

        // Add accolade card
        let accoladeCard = createAccoladeCard()
        stackView.addArrangedSubview(accoladeCard)

        // Add section title with extra spacing above
        let sectionTitle = createSectionTitle()
        stackView.addArrangedSubview(sectionTitle)
        stackView.setCustomSpacing(48, after: accoladeCard)

        // Add avatar stack
        let avatarContainer = createAvatarStack()
        stackView.addArrangedSubview(avatarContainer)

        // Add user count (closer to avatars)
        let userCountLabel = createUserCountLabel()
        stackView.addArrangedSubview(userCountLabel)
        stackView.setCustomSpacing(8, after: avatarContainer)
        stackView.setCustomSpacing(36, after: userCountLabel)

        // Add testimonial cards
        let testimonial1 = createTestimonialCard(
            imageName: "ob-person-4.jpg",
            name: RCValues.shared.string(forKey: .onbCredibilityReviewsTestimonial1Name),
            reviewText: RCValues.shared.string(forKey: .onbCredibilityReviewsTestimonial1TextAB)
        )
        stackView.addArrangedSubview(testimonial1)

        let testimonial2 = createTestimonialCard(
            imageName: "ob-person-5.jpg",
            name: RCValues.shared.string(forKey: .onbCredibilityReviewsTestimonial2Name),
            reviewText: RCValues.shared.string(forKey: .onbCredibilityReviewsTestimonial2TextAB)
        )
        stackView.addArrangedSubview(testimonial2)

        let testimonial3 = createTestimonialCard(
            imageName: "ob-person-6.jpg",
            name: RCValues.shared.string(forKey: .onbCredibilityReviewsTestimonial3Name),
            reviewText: RCValues.shared.string(forKey: .onbCredibilityReviewsTestimonial3TextAB)
        )
        stackView.addArrangedSubview(testimonial3)
    }

    // MARK: - Accolade Card

    private func createAccoladeCard() -> UIView {
        let card = UIView()
        card.backgroundColor = Colours.surfaceCard
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = Colours.inputBorder.cgColor
        borderedCardViews.append(card)

        // Left wreath
        let leftWreath = UIImageView()
        leftWreath.image = UIImage(named: "wreath-left")?.withRenderingMode(.alwaysTemplate)
        leftWreath.tintColor = starColor
        leftWreath.contentMode = .scaleAspectFit
        leftWreath.translatesAutoresizingMaskIntoConstraints = false

        // Right wreath (flipped)
        let rightWreath = UIImageView()
        rightWreath.image = UIImage(named: "wreath-left")?.withRenderingMode(.alwaysTemplate).withHorizontallyFlippedOrientation()
        rightWreath.tintColor = starColor
        rightWreath.contentMode = .scaleAspectFit
        rightWreath.translatesAutoresizingMaskIntoConstraints = false

        // Center content stack
        let centerStack = UIStackView()
        centerStack.axis = .vertical
        centerStack.spacing = 4
        centerStack.alignment = .center
        centerStack.translatesAutoresizingMaskIntoConstraints = false

        // Rating + Stars row
        let ratingStarsStack = UIStackView()
        ratingStarsStack.axis = .horizontal
        ratingStarsStack.spacing = 3
        ratingStarsStack.alignment = .center

        let ratingLabel = UILabel()
        ratingLabel.text = RCValues.shared.string(forKey: .onbCredibilityReviewsStarRating)
        ratingLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        ratingLabel.textColor = Colours.textPrimary

        ratingStarsStack.addArrangedSubview(ratingLabel)

        // Add 5 stars
        for _ in 0..<5 {
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            let starView = UIImageView(image: UIImage(systemName: "star.fill", withConfiguration: config))
            starView.tintColor = starColor
            ratingStarsStack.addArrangedSubview(starView)
        }

        // Review count
        let reviewCountLabel = UILabel()
        reviewCountLabel.text = "\(RCValues.shared.string(forKey: .onbCredibilityReviewsReviewCount)) App Ratings"
        reviewCountLabel.font = Fonts.medium14
        reviewCountLabel.textColor = Colours.subtext

        centerStack.addArrangedSubview(ratingStarsStack)
        centerStack.addArrangedSubview(reviewCountLabel)

        card.addSubview(leftWreath)
        card.addSubview(rightWreath)
        card.addSubview(centerStack)

        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 95),

            // Position wreaths close to center content
            leftWreath.trailingAnchor.constraint(equalTo: centerStack.leadingAnchor, constant: -8),
            leftWreath.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            leftWreath.widthAnchor.constraint(equalToConstant: 42),
            leftWreath.heightAnchor.constraint(equalToConstant: 52),

            rightWreath.leadingAnchor.constraint(equalTo: centerStack.trailingAnchor, constant: 8),
            rightWreath.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            rightWreath.widthAnchor.constraint(equalToConstant: 42),
            rightWreath.heightAnchor.constraint(equalToConstant: 52),

            centerStack.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            centerStack.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])

        return card
    }

    // MARK: - Section Title

    private func createSectionTitle() -> UILabel {
        let label = UILabel()
        label.text = RCValues.shared.string(forKey: .onbCredibilityReviewsSectionTitleAB)
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = Colours.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    // MARK: - Avatar Stack

    private func createAvatarStack() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let avatarSize: CGFloat = 68
        let overlap: CGFloat = 18
        let totalWidth = (avatarSize * 3) - (overlap * 2)

        let avatarContainer = UIView()
        avatarContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(avatarContainer)

        let imageNames = ["ob-person-1.jpg", "ob-person-2.jpg", "ob-person-3.jpg"]

        for (index, imageName) in imageNames.enumerated() {
            let avatarView = UIImageView()
            avatarView.image = UIImage(named: imageName)
            avatarView.contentMode = .scaleAspectFill
            avatarView.layer.cornerRadius = avatarSize / 2
            avatarView.clipsToBounds = true
            avatarView.layer.borderWidth = 2
            avatarView.layer.borderColor = Colours.surfacePrimary.cgColor
            avatarView.translatesAutoresizingMaskIntoConstraints = false
            avatarViews.append(avatarView)

            avatarContainer.addSubview(avatarView)

            let xOffset = CGFloat(index) * (avatarSize - overlap)

            NSLayoutConstraint.activate([
                avatarView.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor, constant: xOffset),
                avatarView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
                avatarView.widthAnchor.constraint(equalToConstant: avatarSize),
                avatarView.heightAnchor.constraint(equalToConstant: avatarSize)
            ])
        }

        NSLayoutConstraint.activate([
            avatarContainer.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            avatarContainer.topAnchor.constraint(equalTo: container.topAnchor),
            avatarContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            avatarContainer.widthAnchor.constraint(equalToConstant: totalWidth),
            avatarContainer.heightAnchor.constraint(equalToConstant: avatarSize)
        ])

        return container
    }

    // MARK: - User Count

    private func createUserCountLabel() -> UILabel {
        let label = UILabel()
        label.text = RCValues.shared.string(forKey: .onbCredibilityReviewsUserCountAB)
        label.font = Fonts.medium16
        label.textColor = Colours.textPrimary
        label.textAlignment = .center
        return label
    }

    // MARK: - Testimonial Card

    private func createTestimonialCard(imageName: String, name: String, reviewText: String) -> UIView {
        let card = UIView()
        card.backgroundColor = Colours.surfaceCard
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = Colours.inputBorder.cgColor
        borderedCardViews.append(card)

        // Avatar
        let avatar = UIImageView()
        avatar.image = UIImage(named: imageName)
        avatar.contentMode = .scaleAspectFill
        avatar.layer.cornerRadius = 16
        avatar.clipsToBounds = true
        avatar.translatesAutoresizingMaskIntoConstraints = false

        // Name label
        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = Fonts.semiBold16
        nameLabel.textColor = Colours.textPrimary

        // Stars stack
        let starsStack = UIStackView()
        starsStack.axis = .horizontal
        starsStack.spacing = 2
        for _ in 0..<5 {
            let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            let starView = UIImageView(image: UIImage(systemName: "star.fill", withConfiguration: config))
            starView.tintColor = starColor
            starsStack.addArrangedSubview(starView)
        }

        // Header row (name + stars)
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.distribution = .equalSpacing
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        let nameStarsContainer = UIView()
        nameStarsContainer.translatesAutoresizingMaskIntoConstraints = false
        nameStarsContainer.addSubview(nameLabel)
        nameStarsContainer.addSubview(starsStack)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        starsStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: nameStarsContainer.leadingAnchor),
            nameLabel.topAnchor.constraint(equalTo: nameStarsContainer.topAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: nameStarsContainer.bottomAnchor),
            starsStack.trailingAnchor.constraint(equalTo: nameStarsContainer.trailingAnchor),
            starsStack.centerYAnchor.constraint(equalTo: nameStarsContainer.centerYAnchor)
        ])

        // Review text
        let reviewLabel = UILabel()
        reviewLabel.text = reviewText
        reviewLabel.font = Fonts.medium15
        reviewLabel.textColor = Colours.subtext
        reviewLabel.numberOfLines = 0
        reviewLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(avatar)
        card.addSubview(nameStarsContainer)
        card.addSubview(reviewLabel)

        NSLayoutConstraint.activate([
            avatar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            avatar.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            avatar.widthAnchor.constraint(equalToConstant: 32),
            avatar.heightAnchor.constraint(equalToConstant: 32),

            nameStarsContainer.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            nameStarsContainer.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            nameStarsContainer.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),

            reviewLabel.topAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 12),
            reviewLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            reviewLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            reviewLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        return card
    }

    private func updateAppearanceColors() {
        borderedCardViews.forEach { $0.layer.borderColor = Colours.inputBorder.cgColor }
        avatarViews.forEach { $0.layer.borderColor = Colours.surfacePrimary.cgColor }
    }
}
