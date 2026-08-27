//
//  APIBookInternalAudio.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 13/10/2025.
//  Copyright © 2025 Kneady Technologies. All rights reserved.
//

import Foundation
import FirebaseFirestore

enum AudiobookLanguage: String, CaseIterable {
    case english
    
    var displayString: String {
        switch self {
        case .english:
            return "English"
        }
    }
}

enum APIBookInternalAudioVariables: String {
    case uuid
    case createdDate
    case language
    case voice
    case voiceProvider
    case aiTTSModel
    case storageURL
    case rating
    case numberOfRatings
    case listeningTimeSeconds
    case listeningTimeMinutes
    case fileSizeBytes
}

class APIBookInternalAudio {
    let uuid: String
    let createdDate: Date
    let language: AudiobookLanguage
    let voice: String
    let voiceProvider: String
    let aiTTSModel: String
    let storageURL: String
    let rating: Double
    let numberOfRatings: Int
    let listeningTimeSeconds: TimeInterval
    let listeningTimeMinutes: Int
    let fileSizeBytes: Int64

    var listeningTimeMinutesRounded: Int {
        return Self.roundListeningTimeMinutes(listeningTimeMinutes)
    }
    
    init?(data: [String: Any]) {
        guard
            let uuid = data[APIBookInternalAudioVariables.uuid.rawValue] as? String,
            let createdDateTimestamp = data[APIBookInternalAudioVariables.createdDate.rawValue] as? Timestamp,
            let languageString = data[APIBookInternalAudioVariables.language.rawValue] as? String,
            let languageEnum = AudiobookLanguage(rawValue: languageString),
            let voice = data[APIBookInternalAudioVariables.voice.rawValue] as? String,
            let voiceProvider = data[APIBookInternalAudioVariables.voiceProvider.rawValue] as? String,
            let aiTTSModel = data[APIBookInternalAudioVariables.aiTTSModel.rawValue] as? String,
            let storageURL = data[APIBookInternalAudioVariables.storageURL.rawValue] as? String,
            let rating = data[APIBookInternalAudioVariables.rating.rawValue] as? Double,
            let numberOfRatings = data[APIBookInternalAudioVariables.numberOfRatings.rawValue] as? Int,
            let listeningTimeSeconds = APIBookInternalAudio.doubleValue(from: data[APIBookInternalAudioVariables.listeningTimeSeconds.rawValue]),
            let listeningTimeMinutes = APIBookInternalAudio.intValue(from: data[APIBookInternalAudioVariables.listeningTimeMinutes.rawValue]),
            let fileSizeBytes = APIBookInternalAudio.int64Value(from: data[APIBookInternalAudioVariables.fileSizeBytes.rawValue]) else {
            return nil
        }
        self.uuid = uuid
        self.createdDate = createdDateTimestamp.dateValue()
        self.language = languageEnum
        self.voice = voice
        self.voiceProvider = voiceProvider
        self.aiTTSModel = aiTTSModel
        self.storageURL = storageURL
        self.rating = rating
        self.numberOfRatings = numberOfRatings
        self.listeningTimeSeconds = listeningTimeSeconds
        self.listeningTimeMinutes = listeningTimeMinutes
        self.fileSizeBytes = fileSizeBytes
    }
    
    init (
        uuid: String,
        createdDate: Date,
        language: AudiobookLanguage,
        voice: String,
        voiceProvider: String,
        aiTTSModel: String,
        storageURL: String,
        rating: Double,
        numberOfRatings: Int,
        listeningTimeSeconds: TimeInterval,
        listeningTimeMinutes: Int,
        fileSizeBytes: Int64
    ) {
        self.uuid = uuid
        self.createdDate = createdDate
        self.language = language
        self.voice = voice
        self.voiceProvider = voiceProvider
        self.aiTTSModel = aiTTSModel
        self.storageURL = storageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        self.rating = rating
        self.numberOfRatings = numberOfRatings
        self.listeningTimeSeconds = listeningTimeSeconds
        self.listeningTimeMinutes = listeningTimeMinutes
        self.fileSizeBytes = fileSizeBytes
    }
    
    func toData() -> [String: Any] {
        return [
            APIBookInternalAudioVariables.uuid.rawValue: uuid,
            APIBookInternalAudioVariables.createdDate.rawValue: createdDate,
            APIBookInternalAudioVariables.language.rawValue: language.rawValue,
            APIBookInternalAudioVariables.voice.rawValue: voice,
            APIBookInternalAudioVariables.voiceProvider.rawValue: voiceProvider,
            APIBookInternalAudioVariables.aiTTSModel.rawValue: aiTTSModel,
            APIBookInternalAudioVariables.storageURL.rawValue: storageURL,
            APIBookInternalAudioVariables.rating.rawValue: rating,
            APIBookInternalAudioVariables.numberOfRatings.rawValue: numberOfRatings,
            APIBookInternalAudioVariables.listeningTimeSeconds.rawValue: listeningTimeSeconds,
            APIBookInternalAudioVariables.listeningTimeMinutes.rawValue: listeningTimeMinutes,
            APIBookInternalAudioVariables.fileSizeBytes.rawValue: fileSizeBytes
        ]
    }

    private static func doubleValue(from value: Any?) -> Double? {
        if let value = value as? Double {
            return value
        }
        if let value = value as? Int {
            return Double(value)
        }
        if let value = value as? Int64 {
            return Double(value)
        }
        if let value = value as? NSNumber {
            return value.doubleValue
        }
        return nil
    }

    private static func intValue(from value: Any?) -> Int? {
        if let value = value as? Int {
            return value
        }
        if let value = value as? Int64 {
            return Int(value)
        }
        if let value = value as? NSNumber {
            return value.intValue
        }
        return nil
    }

    private static func int64Value(from value: Any?) -> Int64? {
        if let value = value as? Int64 {
            return value
        }
        if let value = value as? Int {
            return Int64(value)
        }
        if let value = value as? NSNumber {
            return value.int64Value
        }
        return nil
    }

    static func roundListeningTimeMinutes(_ minutes: Int) -> Int {
        guard minutes > 0 else { return 0 }
        let rounded = Int((Double(minutes) / 5.0).rounded()) * 5
        return max(5, rounded)
    }
}
