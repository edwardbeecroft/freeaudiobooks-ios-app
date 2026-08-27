//
//  APIBookInternal.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 06/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

enum BookInternalType: String {
    case shortStory
}

enum APIBookInternalVariables: String {
    case uuid
    case bookType
    case title
    case blurb
    case tagline
    case coverImageURLXL
    case coverImageURL
    case coverImageURLThumbnail
    case genre
    case readingTimeMinutes
    case readerCount
    case datePublished
    case dateUpdated
    case isHidden
    case isSubscriptionOnly
    case audio
    case rating
    case numberOfRatings
    case availableForAllDateString
    case deeplinkURL
    case authorName
    case containsAdultContent
    case storySummary
    case creatorID
    case heroBackgroundImageURL
    case heroBackgroundImageURLXL
    case heroLayout
    case heroTitle
    case heroSubtitle
    case chapterCount
    case tags
}

class APIBookInternal {
    let uuid: String
    let bookType: BookInternalType
    let title: String
    let blurb: String
    let tagline: String?
    let coverImageURLXL: String
    let coverImageURL: String
    let coverImageURLThumbnail: String
    let genre: BookInternalGenre
    let readingTimeMinutes: Int
    var readerCount: Int
    let datePublished: Date
    let dateUpdated: Date
    let isHidden: Bool
    let isSubscriptionOnly: Bool
    let containsAdultContent: Bool
    let rating: Double
    let numberOfRatings: Int
    let availableForAllDateString: String?
    let authorName: String
    var audio: [APIBookInternalAudio]
    var deeplinkURL: String
    let storySummary: String?
    let creatorID: String
    let heroBackgroundImageURL: String?
    let heroBackgroundImageURLXL: String?
    let heroLayout: HeroCarouselLayout?
    let heroTitle: String?
    let heroSubtitle: String?
    var chapterCount: Int
    let tags: [String]

    init?(data: [String: Any]) {
        guard
            let uuid = data[APIBookInternalVariables.uuid.rawValue] as? String,
            let bookTypeString = data[APIBookInternalVariables.bookType.rawValue] as? String,
            let bookTypeEnum = BookInternalType(rawValue: bookTypeString),
            let title = data[APIBookInternalVariables.title.rawValue] as? String,
            let blurb = data[APIBookInternalVariables.blurb.rawValue] as? String,
            let coverImageURLXL = data[APIBookInternalVariables.coverImageURLXL.rawValue] as? String,
            let coverImageURL = data[APIBookInternalVariables.coverImageURL.rawValue] as? String,
            let coverImageURLThumbnail = data[APIBookInternalVariables.coverImageURLThumbnail.rawValue] as? String,
            let genreString = data[APIBookInternalVariables.genre.rawValue] as? String,
            let genreEnum = BookInternalGenre(rawValue: genreString),
            let readingTimeMinutes = data[APIBookInternalVariables.readingTimeMinutes.rawValue] as? Int,
            let readerCount = data[APIBookInternalVariables.readerCount.rawValue] as? Int,
            let datePublishedTimestamp = data[APIBookInternalVariables.datePublished.rawValue] as? Timestamp,
            let dateUpdatedTimestamp = data[APIBookInternalVariables.dateUpdated.rawValue] as? Timestamp,
            let isHidden = data[APIBookInternalVariables.isHidden.rawValue] as? Bool,
            let isSubscriptionOnly = data[APIBookInternalVariables.isSubscriptionOnly.rawValue] as? Bool,
            let containsAdultContent = data[APIBookInternalVariables.containsAdultContent.rawValue] as? Bool,
            let rating = data[APIBookInternalVariables.rating.rawValue] as? Double,
            let numberOfRatings = data[APIBookInternalVariables.numberOfRatings.rawValue] as? Int,
            let audioData = data[APIBookInternalVariables.audio.rawValue] as? [[String: Any]],
            let deeplinkURL = data[APIBookInternalVariables.deeplinkURL.rawValue] as? String,
            let authorName = data[APIBookInternalVariables.authorName.rawValue] as? String,
            let creatorID = data[APIBookInternalVariables.creatorID.rawValue] as? String,
            let chapterCount = data[APIBookInternalVariables.chapterCount.rawValue] as? Int else {
                return nil
        }

        self.uuid = uuid
        self.bookType = bookTypeEnum
        self.title = title
        self.blurb = blurb
        self.tagline = data[APIBookInternalVariables.tagline.rawValue] as? String
        self.coverImageURLXL = coverImageURLXL
        self.coverImageURL = coverImageURL
        self.coverImageURLThumbnail = coverImageURLThumbnail
        self.genre = genreEnum
        self.readingTimeMinutes = readingTimeMinutes
        self.readerCount = readerCount
        self.datePublished = datePublishedTimestamp.dateValue()
        self.dateUpdated = dateUpdatedTimestamp.dateValue()
        self.isHidden = isHidden
        self.isSubscriptionOnly = isSubscriptionOnly
        self.containsAdultContent = containsAdultContent
        self.rating = rating
        self.numberOfRatings = numberOfRatings

        // Optional field - parse if present (format: YYYY-MM-DD)
        self.availableForAllDateString = data[APIBookInternalVariables.availableForAllDateString.rawValue] as? String

        // Optional field - story summary
        self.storySummary = data[APIBookInternalVariables.storySummary.rawValue] as? String
        self.heroBackgroundImageURL = data[APIBookInternalVariables.heroBackgroundImageURL.rawValue] as? String
        self.heroBackgroundImageURLXL = data[APIBookInternalVariables.heroBackgroundImageURLXL.rawValue] as? String
        let heroLayoutString = data[APIBookInternalVariables.heroLayout.rawValue] as? String
        self.heroLayout = heroLayoutString.flatMap { HeroCarouselLayout(rawValue: $0) }
        self.heroTitle = data[APIBookInternalVariables.heroTitle.rawValue] as? String
        self.heroSubtitle = data[APIBookInternalVariables.heroSubtitle.rawValue] as? String
        self.tags = data[APIBookInternalVariables.tags.rawValue] as? [String] ?? []

        self.authorName = authorName
        self.creatorID = creatorID
        self.audio = audioData.compactMap { APIBookInternalAudio(data: $0) }
        self.deeplinkURL = deeplinkURL
        
        self.chapterCount = chapterCount
    }
    
    init(uuid: String,
         bookType: BookInternalType,
         title: String,
         blurb: String,
         tagline: String? = nil,
         coverImageURLXL: String,
         coverImageURL: String,
         coverImageURLThumbnail: String,
         genre: BookInternalGenre,
         readingTimeMinutes: Int,
         readerCount: Int,
         datePublished: Date,
         dateUpdated: Date,
         isHidden: Bool,
         isSubscriptionOnly: Bool,
         containsAdultContent: Bool,
         rating: Double,
         numberOfRatings: Int,
         availableForAllDateString: String?,
         authorName: String,
         audio: [APIBookInternalAudio],
         deeplinkURL: String,
         storySummary: String?,
         creatorID: String,
         heroBackgroundImageURL: String?,
         heroBackgroundImageURLXL: String?,
         heroLayout: HeroCarouselLayout?,
         heroTitle: String?,
         heroSubtitle: String?,
         chapterCount: Int,
         tags: [String] = []) {
        self.uuid = uuid
        self.title = title
        self.blurb = blurb
        self.tagline = tagline

        self.coverImageURLXL = coverImageURLXL
        self.coverImageURL = coverImageURL
        self.coverImageURLThumbnail = coverImageURLThumbnail

        self.genre = genre
        self.readingTimeMinutes = readingTimeMinutes
        self.readerCount = readerCount
        self.datePublished = datePublished
        self.dateUpdated = dateUpdated
        self.isHidden = isHidden
        self.isSubscriptionOnly = isSubscriptionOnly
        self.containsAdultContent = containsAdultContent
        self.bookType = bookType
        self.rating = rating
        self.numberOfRatings = numberOfRatings
        self.availableForAllDateString = availableForAllDateString
        self.authorName = authorName
        self.audio = audio
        self.deeplinkURL = deeplinkURL
        self.storySummary = storySummary
        self.creatorID = creatorID
        self.heroBackgroundImageURL = heroBackgroundImageURL
        self.heroBackgroundImageURLXL = heroBackgroundImageURLXL
        self.heroLayout = heroLayout
        self.heroTitle = heroTitle
        self.heroSubtitle = heroSubtitle
        
        self.chapterCount = chapterCount
        self.tags = tags
    }
}

extension APIBookInternal {
    func toData() -> [String: Any] {
        var data: [String: Any] = [
            APIBookInternalVariables.uuid.rawValue: uuid,
            APIBookInternalVariables.bookType.rawValue: bookType.rawValue,
            APIBookInternalVariables.title.rawValue: title,
            APIBookInternalVariables.blurb.rawValue: blurb,
            APIBookInternalVariables.coverImageURLXL.rawValue: coverImageURLXL,
            APIBookInternalVariables.coverImageURL.rawValue: coverImageURL,
            APIBookInternalVariables.coverImageURLThumbnail.rawValue: coverImageURLThumbnail,
            APIBookInternalVariables.genre.rawValue: genre.rawValue,
            APIBookInternalVariables.readingTimeMinutes.rawValue: readingTimeMinutes,
            APIBookInternalVariables.readerCount.rawValue: readerCount,
            APIBookInternalVariables.datePublished.rawValue: datePublished,
            APIBookInternalVariables.dateUpdated.rawValue: dateUpdated,
            APIBookInternalVariables.isHidden.rawValue: isHidden,
            APIBookInternalVariables.isSubscriptionOnly.rawValue: isSubscriptionOnly,
            APIBookInternalVariables.containsAdultContent.rawValue: containsAdultContent,
            APIBookInternalVariables.rating.rawValue: rating,
            APIBookInternalVariables.numberOfRatings.rawValue: numberOfRatings,
            APIBookInternalVariables.audio.rawValue: audio.compactMap { $0.toData() },
            APIBookInternalVariables.deeplinkURL.rawValue: deeplinkURL,
            APIBookInternalVariables.authorName.rawValue: authorName,
            APIBookInternalVariables.creatorID.rawValue: creatorID,
            APIBookInternalVariables.chapterCount.rawValue: chapterCount
        ]

        // Only include availableForAllDateString if it's set (prefer string over timestamp)
        if let availableForAllDateString = availableForAllDateString {
            data[APIBookInternalVariables.availableForAllDateString.rawValue] = availableForAllDateString
        } else {
            data[APIBookInternalVariables.availableForAllDateString.rawValue] = FieldValue.delete()
        }

        // Only include storySummary if it's set
        if let storySummary = storySummary {
            data[APIBookInternalVariables.storySummary.rawValue] = storySummary
        }

        if let tagline = tagline, !tagline.isEmpty {
            data[APIBookInternalVariables.tagline.rawValue] = tagline
        } else {
            data[APIBookInternalVariables.tagline.rawValue] = FieldValue.delete()
        }

        if let backgroundImageURL = heroBackgroundImageURL, !backgroundImageURL.isEmpty {
            data[APIBookInternalVariables.heroBackgroundImageURL.rawValue] = backgroundImageURL
        } else {
            data[APIBookInternalVariables.heroBackgroundImageURL.rawValue] = FieldValue.delete()
        }

        if let backgroundImageURLXL = heroBackgroundImageURLXL, !backgroundImageURLXL.isEmpty {
            data[APIBookInternalVariables.heroBackgroundImageURLXL.rawValue] = backgroundImageURLXL
        } else {
            data[APIBookInternalVariables.heroBackgroundImageURLXL.rawValue] = FieldValue.delete()
        }

        if let heroLayout {
            data[APIBookInternalVariables.heroLayout.rawValue] = heroLayout.rawValue
        } else {
            data[APIBookInternalVariables.heroLayout.rawValue] = FieldValue.delete()
        }

        if let heroTitle = heroTitle, !heroTitle.isEmpty {
            data[APIBookInternalVariables.heroTitle.rawValue] = heroTitle
        } else {
            data[APIBookInternalVariables.heroTitle.rawValue] = FieldValue.delete()
        }

        if let heroSubtitle = heroSubtitle, !heroSubtitle.isEmpty {
            data[APIBookInternalVariables.heroSubtitle.rawValue] = heroSubtitle
        } else {
            data[APIBookInternalVariables.heroSubtitle.rawValue] = FieldValue.delete()
        }

        if !tags.isEmpty {
            data[APIBookInternalVariables.tags.rawValue] = tags
        } else {
            data[APIBookInternalVariables.tags.rawValue] = FieldValue.delete()
        }

        return data
    }
}

extension APIBookInternal {
    var isEarlyAccess: Bool {
        guard let dateString = availableForAllDateString else {
            return false
        }

        // Parse date string and compare with today in local timezone
        guard let unlockDate = DateFormatters.earlyAccessDateFormatter.date(from: dateString) else {
            return false
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let unlockDay = calendar.startOfDay(for: unlockDate)

        return today < unlockDay
    }
}

// MARK: - Dictionary Helper Extension
extension Dictionary {
    func compactMapKeys<T>(_ transform: (Key) -> T?) -> [T: Value] {
        return self.compactMap { key, value in
            transform(key).map { ($0, value) }
        }.reduce(into: [:]) { result, pair in
            result[pair.0] = pair.1
        }
    }
}
