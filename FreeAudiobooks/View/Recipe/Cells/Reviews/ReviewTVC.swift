//
//  ReviewTVCWithComment.swift
//  Kneady
//
//  Created by Ed Beecroft on 09/09/2020.
//  Copyright © 2020 Cause Tech. All rights reserved.
//

import UIKit
import FirebaseAuth
import Cosmos

class ReviewTVCWithComment: UITableViewCell {
	
	var recipeReview: RecipeReview? {
		didSet {
			guard let review = recipeReview else { return }
			
			updateAuthorImageView()
			
			var authorFirstNameString = review.authorFirstName
			if
				let uid = Auth.auth().currentUser?.uid,
				review.authorUUID == uid {
				authorFirstNameString.append(" (You)")
			}
			reviewAuthorNameLabel.text = authorFirstNameString
			
			cosmosView.rating = review.reviewRating
			reviewCommentLabel.text = review.reviewComment
		}
	}
	
	private let authorImageViewHeightWidth: CGFloat = 32
	private let reviewAuthorImageView = UIImageView()
	private let reviewAuthorNameLabel = UILabel()
	private let reviewCommentLabel = UILabel()
	private let cosmosView = CosmosView()
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		contentView.backgroundColor = Colours.surfacePrimary
		setupUI()
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
		contentView.backgroundColor = Colours.surfacePrimary
		updateAuthorImageView()
	}
	
	private func setupUI() {
		setupUserImageView()
		setupCosmosView()
		setupReviewAuthorNameLabel()
		setupReviewCommentLabel()
	}
	
	func setupUserImageView() {
		reviewAuthorImageView.contentMode = .scaleAspectFit
		contentView.addSubviewForConstraints(reviewAuthorImageView)
		NSLayoutConstraint.activate([
			reviewAuthorImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UIConstants.shared.standardMargin),
			reviewAuthorImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UIConstants.shared.standardMargin),
			reviewAuthorImageView.heightAnchor.constraint(equalToConstant: authorImageViewHeightWidth),
			reviewAuthorImageView.widthAnchor.constraint(equalToConstant: authorImageViewHeightWidth)
		])
		reviewAuthorImageView.clipsToBounds = true
	}
	
	func updateAuthorImageView() {
		if
			let imageURLString = recipeReview?.authorImageURL,
			let imageURL = URL(string: imageURLString) {
			reviewAuthorImageView.kf.indicatorType = .activity
			DispatchQueue.main.async {
				self.reviewAuthorImageView.contentMode = .scaleAspectFill
				self.reviewAuthorImageView.layer.cornerRadius = self.authorImageViewHeightWidth / 2
				self.reviewAuthorImageView.layer.masksToBounds = true
				self.reviewAuthorImageView.kf.setImage(with: imageURL, options: [.transition(.fade(0.2))])
			}
		} else {
			DispatchQueue.main.async {
				self.reviewAuthorImageView.image = User.placeholderImage
				self.reviewAuthorImageView.tintColor = Colours.textSecondary.withAlphaComponent(0.5)
				self.reviewAuthorImageView.layer.cornerRadius = 0
				self.reviewAuthorImageView.layer.masksToBounds = false
				self.reviewAuthorImageView.contentMode = .scaleAspectFit
			}
		}
	}
	
	func setupCosmosView() {
		var settings = CosmosHelper.sharedSettings()
		settings.starSize = 15
		cosmosView.settings = settings
		
//		cosmosView.didFinishTouchingCosmos = { [weak self] rating in
//			guard let self = self else { return }
//			DispatchQueue.main.async {
//				self.scrollToReviewsModule()
//			}
//		}
		
		contentView.addSubviewForConstraints(cosmosView)
		NSLayoutConstraint.activate([
			cosmosView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
			cosmosView.centerYAnchor.constraint(equalTo: reviewAuthorImageView.centerYAnchor)
		])
	}
	
	func setupReviewAuthorNameLabel() {
		reviewAuthorNameLabel.textColor = Colours.textPrimary
		reviewAuthorNameLabel.font = Fonts.futuraDemi16
		reviewAuthorNameLabel.lineBreakMode = .byTruncatingTail
		reviewAuthorNameLabel.textAlignment = .left
		reviewAuthorNameLabel.numberOfLines = 1
		
		contentView.addSubviewForConstraints(reviewAuthorNameLabel)
		NSLayoutConstraint.activate([
			reviewAuthorNameLabel.leadingAnchor.constraint(equalTo: reviewAuthorImageView.trailingAnchor, constant: 12),
			reviewAuthorNameLabel.centerYAnchor.constraint(equalTo: reviewAuthorImageView.centerYAnchor),
			reviewAuthorNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -131)
		])
	}
	
	func setupReviewCommentLabel() {
		reviewCommentLabel.textColor = Colours.textPrimary
		reviewCommentLabel.font = Fonts.futuraMedium16
		reviewCommentLabel.numberOfLines = 0
		reviewCommentLabel.lineBreakMode = .byWordWrapping
		
		contentView.addSubviewForConstraints(reviewCommentLabel)
		NSLayoutConstraint.activate([
			reviewCommentLabel.topAnchor.constraint(equalTo: reviewAuthorImageView.bottomAnchor, constant: 2),
			reviewCommentLabel.leadingAnchor.constraint(equalTo: reviewAuthorNameLabel.leadingAnchor),
			reviewCommentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
			reviewCommentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UIConstants.shared.standardMargin)
		])
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}
}
