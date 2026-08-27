//
//  Cause.swift
//  Cause
//
//  Created by Ed Beecroft on 19/05/2020.
//  Copyright © 2020 Cause Tech. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore

enum FirebaseOpportunityVariables: String {
	case uuid
	case name
	case description
	case shortDescription
	case type
	case createdDate
	case isVerified
	case totalRaised
	case contactEmailAddress
	case imageURLStrings
	case isActive
	case websiteURL
	case keyFacts
	case numberOfCheers
	case logoURL
	case patronCount
}

class Cause {
	let uuid: String
	let name: String
	let description: String
	let shortDescription: String
	let type: String
	let totalRaised: Double
	let imageURLStrings: [String]
	let contactEmailAddress: String
	let createdDate: Date
	let isActive: Bool
	let websiteURL: String
	let patronCount: Int
	let keyFacts: [String]
	var numberOfCheers: Int
	var logoURL: String?
	
	init?(data: [String: Any]) {
		guard
			let uuid = data[FirebaseOpportunityVariables.uuid.rawValue] as? String,
			let name = data[FirebaseOpportunityVariables.name.rawValue] as? String,
			let description = data[FirebaseOpportunityVariables.description.rawValue] as? String,
			let shortDescription = data[FirebaseOpportunityVariables.shortDescription.rawValue] as? String,
			let type = data[FirebaseOpportunityVariables.type.rawValue] as? String,
			let totalRaised = data[FirebaseOpportunityVariables.totalRaised.rawValue] as? Double,
			let createdDateTimestamp = data[FirebaseOpportunityVariables.createdDate.rawValue] as? Timestamp,
			let contactEmailAddress = data[FirebaseOpportunityVariables.contactEmailAddress.rawValue] as? String,
			let imageURLStrings = data[FirebaseOpportunityVariables.imageURLStrings.rawValue] as? [String],
			let isActive = data[FirebaseOpportunityVariables.isActive.rawValue] as? Bool,
			let websiteURL = data[FirebaseOpportunityVariables.websiteURL.rawValue] as? String,
			let keyFacts = data[FirebaseOpportunityVariables.keyFacts.rawValue] as? [String],
			let numberOfCheers = data[FirebaseOpportunityVariables.numberOfCheers.rawValue] as? Int,
			let patronCount = data[FirebaseOpportunityVariables.patronCount.rawValue] as? Int else {
				return nil
		}
		
		self.uuid = uuid
		self.name = name
		self.description = description
		self.shortDescription = shortDescription
		self.type = type
		self.totalRaised = totalRaised
		self.imageURLStrings = imageURLStrings
		self.createdDate = createdDateTimestamp.dateValue()
		self.contactEmailAddress = contactEmailAddress
		self.isActive = isActive
		self.websiteURL = websiteURL
		self.patronCount = patronCount
		self.keyFacts = keyFacts
		self.numberOfCheers = numberOfCheers
		self.logoURL = data[FirebaseOpportunityVariables.logoURL.rawValue] as? String
	}
	
	// Always set
	let isVerified: Bool = true
}

enum OpportunityType: String {
	case water
	case trees
	case naturalDisaster
	case disease
}
