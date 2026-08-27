//
//  CDBookInternal+Extensions.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 06/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Helper Properties
extension CDBookInternal {
    var genre: BookInternalGenre {
        guard
            let genreString,
            let genreUnwrapped = BookInternalGenre(rawValue: genreString) else {
            return .romance
        }
        return genreUnwrapped
    }
    var shouldShowAdultContentBadgeOnCovers: Bool {
        return containsAdultContent && RCValues.shared.bool(forKey: .showAdultContentOnCovers)
    }
    var tags: [String] {
        tagsData as? [String] ?? []
    }
    // Note: chapters are now stored in CDBookInternalContent, not embedded in CDBookInternal
    var readingTimeInt: Int {
        return Int(readingTimeMinutes)
    }
    var listeningTimeInt: Int {
        return Int(listeningTimeMinutes)
    }
    var listeningTimeMinutesRounded: Int {
        return APIBookInternalAudio.roundListeningTimeMinutes(listeningTimeInt)
    }
    var chapterCountInt: Int {
        return Int(chapterCount)
    }
    var bookType: BookInternalType {
        guard
            let bookTypeString,
            let bookTypeUnwrapped = BookInternalType(rawValue: bookTypeString) else {
            return .shortStory
        }
        return bookTypeUnwrapped
    }

    // Early Access Properties
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

    var isAvailableToUser: Bool {
        // If no early access date is set, it's available to everyone
        guard let dateString = availableForAllDateString else {
            return true
        }

        // Parse date string and compare with today in local timezone
        guard let unlockDate = DateFormatters.earlyAccessDateFormatter.date(from: dateString) else {
            return true // If date parse fails, default to available
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let unlockDay = calendar.startOfDay(for: unlockDate)

        // If unlock day has arrived or passed, it's available to everyone
        if today >= unlockDay {
            return true
        }

        // Otherwise, only available to subscribers
        return AccountManager.shared.userIsSubscribed
    }

    var abbreviatedAuthorName: String? {
        guard let authorName = authorName?.trimmingCharacters(in: .whitespacesAndNewlines),
              !authorName.isEmpty else { return nil }

        let parts = authorName
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        guard let first = parts.first else { return nil }
        guard let last = parts.last, parts.count >= 2 else {
            return authorName
        }

        guard let firstInitial = first.first else { return authorName }
        return "\(firstInitial). \(last)"
    }
}

extension CDBookInternal {
    
    // MARK: - Audio Properties
    var audioURLsEnumDict: [AudiobookLanguage: String] {
        let audioURLsDict = audioURLs as? [String: String] ?? [:]
        return audioURLsDict.compactMapKeys { AudiobookLanguage(rawValue: $0) }
    }

    func hasAudiobook(for language: AudiobookLanguage) -> Bool {
        return audioURLsEnumDict[language] != nil
    }

    func audioURL(for language: AudiobookLanguage) -> String? {
        return audioURLsEnumDict[language]
    }

    var hasAnyAudiobook: Bool {
        return !audioURLsEnumDict.isEmpty
    }

    var availableAudioLanguages: [AudiobookLanguage] {
        return Array(audioURLsEnumDict.keys).sorted { $0.displayString < $1.displayString }
    }

    var availableAudioLanguageStrings: [String] {
        return availableAudioLanguages.map { $0.displayString }
    }

    var cachedAudio: CDBookInternalAudio? {
        return CoreDataBookInternalAudioManager.shared.getWithUUID(bookUUID: contentUUID)
    }

    var downloadedAudio: CDBookInternalAudio? {
        return CoreDataBookInternalAudioManager.shared.getDownloadedWithUUID(bookUUID: contentUUID)
    }

    var downloadedAudioLanguage: String? {
        return downloadedAudio?.language
    }

    var downloadedAudioFileSize: String? {
        return downloadedAudio?.fileSizeString
    }
}

// MARK: - ReadableContentMetadata Protocol Conformance
extension CDBookInternal: ReadableContentMetadata {
    var contentUUID: String {
        return uuid ?? "" // Far from ideal that uuid is optional in cd
    }
    
    var contentType: ContentType {
        return .bookInternal
    }
    
    var coverImageXLURLString: String? {
        return coverImageURLXL
    }
    var coverImageURLString: String? {
        return coverImageURL
    }
    var coverImageThumbnailURLString: String? {
        return coverImageURLThumbnail
    }
    
    var readerCountInt: Int {
        return Int(readerCount)
    }
    
    var subtitleText: String {
        // Display author, genre, and progress for short stories
        if let authorName = authorName, !authorName.isEmpty {
            return "\(authorName) · \(genre.displayString) · \(progressPercentageString)"
        } else {
            // Fallback for books without author
            return "\(genre.displayString) · \(progressPercentageString)"
        }
    }

    var authorsString: String {
        return authorName ?? ""
    }

    var genreDisplayString: String? {
        return genre.displayString
    }
    
    var synopsis: String? {
        return blurb
    }
    
    var needsAISynopsis: Bool {
        return false
    }

    var collectionsText: String? {
        return nil
    }

    var lengthDisplayText: String? {
        return "\(listeningTimeMinutesRounded) min"
    }

    var progressPercentageString: String {
        if AccountManager.shared.userHasCompletedBookInternalWithUUID(contentUUID) {
            return "Completed"
        } else if let progressPercentage = ReadingUserDefaults.progressForBookWithUUID(contentUUID) {
            return "\(progressPercentage)%"
        } else {
            return "Not started"
        }
    }
    
    var isContentStored: Bool {
        return hasDownloadedAudio
    }
    
    var hasDownloadedAudio: Bool {
        return downloadedAudio != nil
    }
    
    var hasDownloadedText: Bool {
        // Only count as downloaded if content exists AND is not temporary
        guard let content = APIBookInternalContentManager.getBookInternalContent(bookUUID: contentUUID) else {
            return false
        }
        return !content.isTemporaryDownload
    }
    
    // MARK: - Reading methods (from ReadableForReading)
    func getReadingOffset() -> ReadingOffset? {
        return ReadingUserDefaults.getOffsetForBookWithUUID(contentUUID)
    }
    
    func setReadingOffset(currentSection: Int, totalSections: Int, yOffset: CGFloat, totalYOffset: CGFloat) {
        ReadingUserDefaults.setOffsetForBookWithUUID(contentUUID,
                                                     currentSection: currentSection,
                                                     totalSections: totalSections,
                                                     currentSectionYOffset: yOffset,
                                                     currentSectionTotalYOffset: totalYOffset)
    }
    
    // Completion tracking
    func markCompleted() {
        AccountManager.shared.handleCompletedBookInternal(self, completed: true, completion: {})
        // Cancel any pending engagement notification for this book
        EngagementEngine.cancelNotificationForBookIfNeeded(bookUUID: contentUUID)
    }
    
    func isCompleted() -> Bool {
        return AccountManager.shared.userHasCompletedBookInternalWithUUID(contentUUID)
    }
    
    var sharingDeeplinkURL: String? {
        return deeplinkURL
    }
}
