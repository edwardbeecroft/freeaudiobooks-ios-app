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
    case deeplinkURLFAB
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
    case spiceLevel
}

/// The romance spice level Story Writer sets when it publishes a romance (1–5).
enum RomanceSpiceLevel: Int, CaseIterable, Codable {
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5

    var displayValue: String {
        String(rawValue)
    }

    var containsAdultContent: Bool {
        rawValue >= 3
    }
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
    var deeplinkURLFAB: String
    let storySummary: String?
    let creatorID: String
    let heroBackgroundImageURL: String?
    let heroBackgroundImageURLXL: String?
    let heroLayout: HeroCarouselLayout?
    let heroTitle: String?
    let heroSubtitle: String?
    var chapterCount: Int
    let tags: [String]
    let spiceLevel: RomanceSpiceLevel?

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
            let deeplinkURLFAB = data[APIBookInternalVariables.deeplinkURLFAB.rawValue] as? String,
            let link = URL(string: deeplinkURLFAB), link.scheme == "https",
            link.host == "links.freeaudiobooksapp.com", link.path == "/book-internal/\(uuid)",
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
        // The app shows readers' and listeners' ratings as one score everywhere: lists, sorting,
        // filters and the book page all read these two fields.
        let audio = audioData.compactMap { APIBookInternalAudio(data: $0) }
        let combined = CombinedRating.combine(
            book: (rating: rating, count: numberOfRatings),
            audiobook: audio.first { $0.language == .english }.map { (rating: $0.rating, count: $0.numberOfRatings) }
        )
        self.rating = combined.rating
        self.numberOfRatings = combined.numberOfRatings

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
        if genreEnum == .romance,
           let spiceLevelValue = data[APIBookInternalVariables.spiceLevel.rawValue] as? Int {
            self.spiceLevel = RomanceSpiceLevel(rawValue: spiceLevelValue)
        } else {
            self.spiceLevel = nil
        }

        self.authorName = authorName
        self.creatorID = creatorID
        self.audio = audio
        self.deeplinkURLFAB = deeplinkURLFAB
        
        self.chapterCount = chapterCount
    }
    
}

/// Readers' and listeners' ratings as one score: the book's and its English audiobook's stored totals,
/// weighted by how many ratings each has. The same formula is in freebooks-ios functions/combinedRating.js.
enum CombinedRating {
    static func combine(book: (rating: Double, count: Int),
                        audiobook: (rating: Double, count: Int)?) -> (rating: Double, numberOfRatings: Int) {
        let parts = [book, audiobook].compactMap { $0 }.filter { $0.rating > 0 && $0.rating <= 5 && $0.count > 0 }
        let count = parts.reduce(0) { $0 + $1.count }
        guard count > 0 else { return (0, 0) }
        return (parts.reduce(0) { $0 + $1.rating * Double($1.count) } / Double(count), count)
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
