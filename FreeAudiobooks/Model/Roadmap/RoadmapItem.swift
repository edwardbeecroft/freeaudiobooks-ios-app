//
//  RoadmapItem.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 06/03/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

enum RoadmapItemVariables: String {
    case uuid
    case title
    case description
    case itemType
    case upvoteCount
    case createdDate
    case moderationStatus
    case status
    case userUUID
    case releaseVersion
}

enum RoadmapItemType: String, Codable {
    case uncategorized
    case bug
    case booksAndAudio
    case feature

    var displayString: String {
        switch self {
        case .uncategorized: return "Uncategorized"
        case .bug: return "Bug"
        case .booksAndAudio: return "Books & Audio"
        case .feature: return "Feature"
        }
    }
}

// Controls public visibility / eligibility
enum ModerationStatus: String, Codable {
    case pending = "pending"    // submitted, not public
    case approved = "approved"  // public
    case rejected = "rejected"  // not public (spam/abuse/wrong channel/duplicate)

    var isPublic: Bool { self == .approved }
}

// Controls product pipeline (only meaningful when moderationStatus == .approved)
enum RoadmapItemStatus: String, Codable {
    case requested = "requested"    // approved, in backlog (default on approval)
    case planned = "planned"        // committed to do
    case inProgress = "inProgress"  // being built
    case released = "released"      // shipped
    case declined = "declined"      // valid request, but not doing it (optional, public)

    var displayString: String {
        switch self {
        case .requested: return "Requested"
        case .planned: return "Planned"
        case .inProgress: return "In Progress"
        case .released: return "Released"
        case .declined: return "Declined"
        }
    }
}

class RoadmapItem {
    let uuid: String
    let title: String
    let description: String
    let itemType: RoadmapItemType
    var upvoteCount: Int
    let createdDate: Date
    let moderationStatus: ModerationStatus
    let status: RoadmapItemStatus
    let releaseVersion: String?

    init?(data: [String: Any]) {
        guard
            let uuid = data[RoadmapItemVariables.uuid.rawValue] as? String,
            let title = data[RoadmapItemVariables.title.rawValue] as? String,
            let description = data[RoadmapItemVariables.description.rawValue] as? String,
            let upvoteCount = data[RoadmapItemVariables.upvoteCount.rawValue] as? Int,
            let createdDateTimestamp = data[RoadmapItemVariables.createdDate.rawValue] as? Timestamp,
            let moderationStatusString = data[RoadmapItemVariables.moderationStatus.rawValue] as? String,
            let moderationStatusEnum = ModerationStatus(rawValue: moderationStatusString),
            let statusString = data[RoadmapItemVariables.status.rawValue] as? String,
            let statusEnum = RoadmapItemStatus(rawValue: statusString) else {
                return nil
        }

        self.uuid = uuid
        self.title = title
        self.description = description
        self.upvoteCount = upvoteCount
        self.createdDate = createdDateTimestamp.dateValue()
        self.moderationStatus = moderationStatusEnum
        self.status = statusEnum
        self.releaseVersion = data[RoadmapItemVariables.releaseVersion.rawValue] as? String

        // itemType defaults to .uncategorized if not set
        if let typeString = data[RoadmapItemVariables.itemType.rawValue] as? String,
           let typeEnum = RoadmapItemType(rawValue: typeString) {
            self.itemType = typeEnum
        } else {
            self.itemType = .uncategorized
        }
    }

    var postDateTimeString: String {
        return createdDate.dayOrDateSentString
    }
}
