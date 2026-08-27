//
//  UpvoteUserDefaults.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 06/03/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation

struct UpvoteUserDefaults {
    
    private static let storyUpvotedUUIDsPath = "storyUpvotedUUIDsPath"
    static var storyUpvotedUUIDs: [String] {
        get {
            return UserDefaults.standard.stringArray(forKey: storyUpvotedUUIDsPath) ?? []
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: storyUpvotedUUIDsPath)
        }
    }
    static func handleVoteForStoryWithUUID(_ storyUUID: String) {
        if storyUpvotedUUIDs.contains(storyUUID) {
            // Remove
            var new = storyUpvotedUUIDs
            new.removeAll(where: { $0 == storyUUID })
            storyUpvotedUUIDs = new
        } else {
            // Add
            var new = storyUpvotedUUIDs
            new.append(storyUUID)
            storyUpvotedUUIDs = new
        }
    }
}

struct RoadmapVotingUserDefaults {
    
    private static let roadmapUpvotedUUIDsPath = "roadmapUpvotedUUIDsPath"
    static var roadmapUpvotedUUIDs: [String] {
        get {
            return UserDefaults.standard.stringArray(forKey: roadmapUpvotedUUIDsPath) ?? []
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: roadmapUpvotedUUIDsPath)
        }
    }
    static func handleVoteForRoadmapItem(_ roadmapItem: RoadmapItem) {
        if roadmapUpvotedUUIDs.contains(roadmapItem.uuid) {
            // Remove
            var new = roadmapUpvotedUUIDs
            new.removeAll(where: { $0 == roadmapItem.uuid })
            roadmapUpvotedUUIDs = new
        } else {
            // Add
            var new = roadmapUpvotedUUIDs
            new.append(roadmapItem.uuid)
            roadmapUpvotedUUIDs = new
        }
    }
}
