//
//  ReadingUserDefaults.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 07/08/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import StoreKit
import FirebaseCore

struct ReadingUserDefaults {
    static func getFont() -> UIFont {
        return font.withSize(textSize)
    }
}

extension ReadingUserDefaults {
    private static let themePath = "themePath"

    private static func readingTheme(for key: RCKeys) -> ReadingTheme? {
        let rawValue = RCValues.shared.string(forKey: key)
        guard !rawValue.isEmpty else { return nil }
        return ReadingTheme(rawValue: rawValue)
    }

    private static func resolvedFallbackInterfaceStyle() -> UIUserInterfaceStyle {
        let appearancePreference = AppAppearanceUserDefaults.appearancePreference
        switch appearancePreference {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            let activeWindows = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .filter { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }
                .flatMap { $0.windows }

            if let keyWindowStyle = activeWindows.first(where: { $0.isKeyWindow })?.traitCollection.userInterfaceStyle,
               keyWindowStyle != .unspecified {
                return keyWindowStyle
            }

            if let windowStyle = activeWindows.first?.traitCollection.userInterfaceStyle,
               windowStyle != .unspecified {
                return windowStyle
            }

            let screenStyle = UIScreen.main.traitCollection.userInterfaceStyle
            return screenStyle == .unspecified ? .light : screenStyle
        }
    }

    private static func defaultThemeForCurrentAppearance() -> ReadingTheme {
        let interfaceStyle = resolvedFallbackInterfaceStyle()
        let modeSpecificKey: RCKeys = interfaceStyle == .dark ? .defaultReaderThemeDark : .defaultReaderThemeLight

        if let modeTheme = readingTheme(for: modeSpecificKey) {
            return modeTheme
        }

        if let legacyTheme = readingTheme(for: .defaultReaderTheme) {
            return legacyTheme
        }

        return interfaceStyle == .dark ? .extraDark : .cream
    }

    static var theme: ReadingTheme {
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: themePath)
        }
        get {
            guard
                let value = UserDefaults.standard.string(forKey: themePath),
                let unwrapped = ReadingTheme(rawValue: value) else {
                return defaultThemeForCurrentAppearance()
            }
            return unwrapped
        }
    }
}

extension ReadingUserDefaults {
    private static let fontPath = "fontPath"
    static var font: ReadingFont {
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: fontPath)
        }
        get {
            guard
                let value = UserDefaults.standard.string(forKey: fontPath),
                let unwrapped = ReadingFont(rawValue: value) else {
                return .bookerly
            }
            return unwrapped
        }
    }
    
    private static let textSizePath = "textSizePath"
    static var textSize: ReadingTextSize {
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: textSizePath)
        }
        get {
            guard
                let value = UserDefaults.standard.value(forKey: textSizePath) as? CGFloat,
                let unwrapped = ReadingTextSize(rawValue: value) else {
                return .sixteen
            }
            return unwrapped
        }
    }
}

extension ReadingUserDefaults {
    private static let paragraphStylePath = "paragraphStylePath"
    static var paragraphStyle: ReadingParagraphStyle {
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: paragraphStylePath)
        }
        get {
            guard
                let value = UserDefaults.standard.string(forKey: paragraphStylePath),
                let unwrapped = ReadingParagraphStyle(rawValue: value) else {
                let rcString = RCValues.shared.string(forKey: .defaultReadingParagraphStyle)
                return ReadingParagraphStyle(rawValue: rcString) ?? .spaced
            }
            return unwrapped
        }
    }
}

extension ReadingUserDefaults {
    static func resetReadingPreferencesToDefaults() {
        UserDefaults.standard.removeObject(forKey: themePath)
        UserDefaults.standard.removeObject(forKey: fontPath)
        UserDefaults.standard.removeObject(forKey: textSizePath)
        UserDefaults.standard.removeObject(forKey: paragraphStylePath)
    }
}

extension ReadingUserDefaults {
    private static let offsetsStore = ReadingOffsetsStore()
    
    private static func getOffsets() -> [ReadingOffset] {
        offsetsStore.offsets()
    }
    
    static func getOffsetForBookWithUUID(_ uuid: String) -> ReadingOffset? {
        let existing = getOffsets()
        return existing.first(where: { $0.bookUUID == uuid })
    }

    static func bookUUIDsWithProgress() -> Set<String> {
        let textProgressUUIDs = Set(
            getOffsets()
                .filter(\.hasStartedReading)
                .map(\.bookUUID)
        )
        let audioProgressUUIDs = Set(AudioPositionManager.shared.getBookUUIDsWithSavedPositions())
        return textProgressUUIDs.union(audioProgressUUIDs)
    }
    
    static func setOffsetForBookWithUUID(
        _ uuid: String,
        currentSection: Int,
        totalSections: Int,
        currentSectionYOffset: CGFloat,
        currentSectionTotalYOffset: CGFloat
    ) {
        offsetsStore.setOffset(
            bookUUID: uuid,
            currentSection: currentSection,
            totalSections: totalSections,
            currentSectionYOffset: currentSectionYOffset,
            currentSectionTotalYOffset: currentSectionTotalYOffset
        )
    }
    
    static func progressForBookWithUUID(_ uuid: String) -> Int? {
        let offset = getOffsetForBookWithUUID(uuid)
        return progressForBookWithUUID(
            uuid,
            offset: offset,
            preferredAudioDuration: preferredAudioDuration(for: uuid)
        )
    }

    /// Calculates progress for a group of already-loaded books without decoding the full text
    /// offset history or fetching the same Core Data book once per item.
    static func progressByBookUUID(for books: [CDBookInternal]) -> [String: Int] {
        var offsetsByBookUUID: [String: ReadingOffset] = [:]
        for offset in getOffsets() {
            if offsetsByBookUUID[offset.bookUUID] == nil {
                offsetsByBookUUID[offset.bookUUID] = offset
            }
        }

        var progressByBookUUID: [String: Int] = [:]
        progressByBookUUID.reserveCapacity(books.count)

        for book in books {
            let uuid = book.contentUUID
            let preferredAudioDuration = book.listeningTimeSeconds > 0
                ? book.listeningTimeSeconds
                : nil
            if let progress = progressForBookWithUUID(
                uuid,
                offset: offsetsByBookUUID[uuid],
                preferredAudioDuration: preferredAudioDuration
            ) {
                progressByBookUUID[uuid] = progress
            }
        }

        return progressByBookUUID
    }

    private static func preferredAudioDuration(for uuid: String) -> TimeInterval? {
        guard let book = CoreDataBookInternalManager.shared.getWithUUID(uuid: uuid),
              book.listeningTimeSeconds > 0 else {
            return nil
        }
        return book.listeningTimeSeconds
    }

    private static func progressForBookWithUUID(
        _ uuid: String,
        offset: ReadingOffset?,
        preferredAudioDuration: @autoclosure () -> TimeInterval?
    ) -> Int? {
        var audioProgress: Int?
        var textProgress: Int?

        // Calculate audio progress if available
        let playbackProgress = AudioPlaybackProgressManager.shared.getProgress(for: uuid)
        let audioPosition = playbackProgress?.position ?? 0
        if audioPosition > 0 {
            var duration = preferredAudioDuration() ?? 0

            if duration <= 0 {
                duration = playbackProgress?.duration ?? 0
            }

            if duration > 0 {
                let progressPercentage = Int((audioPosition / duration * 100).rounded(.up))
                audioProgress = progressPercentage > 98 ? 100 : progressPercentage
            }
        }

        // Calculate text reading progress if available
        if let offset, offset.hasStartedReading {
            // Ensure no division by zero
            let sectionProgress: Double
            if offset.totalSections > 0 {
                sectionProgress = Double(offset.currentSection) / Double(offset.totalSections)
            } else {
                sectionProgress = 0
            }

            let chapterProgress: Double
            if offset.currentSectionTotalYOffset > 0 && offset.totalSections > 0 {
                chapterProgress = (Double(offset.currentSectionYOffset) / Double(offset.currentSectionTotalYOffset)) / Double(offset.totalSections)
            } else {
                chapterProgress = 0
            }

            let combined = ((sectionProgress + chapterProgress) * 100).rounded(.up)
            let combinedInt = Int(combined)
            textProgress = combinedInt > 98 ? 100 : combinedInt
        }

        // Return the higher of the two progress values
        switch (audioProgress, textProgress) {
        case (let audio?, let text?):
            return max(audio, text)
        case (let audio?, nil):
            return audio
        case (nil, let text?):
            return text
        case (nil, nil):
            return nil
        }
    }
    static func clearOffsets() {
        offsetsStore.clearOffsets()
    }

    static func clearOffsetForBookWithUUID(_ uuid: String) {
        offsetsStore.clearOffset(bookUUID: uuid)
    }
}

/// Thread-safe, write-through storage for reading offsets. Reads still compare the persisted data
/// with the cached data so a future out-of-band UserDefaults change cannot leave stale UI state.
final class ReadingOffsetsStore {
    private let userDefaults: UserDefaults
    private let key: String
    private let lock = NSLock()
    private var cachedData: Data?
    private var cachedOffsets: [ReadingOffset]?

    init(userDefaults: UserDefaults = .standard, key: String = "readingOffsetsPath") {
        self.userDefaults = userDefaults
        self.key = key
    }

    func offsets() -> [ReadingOffset] {
        lock.lock()
        defer { lock.unlock() }

        return offsetsLocked(persistedData: userDefaults.data(forKey: key))
    }

    func offset(for bookUUID: String) -> ReadingOffset? {
        offsets().first(where: { $0.bookUUID == bookUUID })
    }

    func setOffset(
        bookUUID: String,
        currentSection: Int,
        totalSections: Int,
        currentSectionYOffset: CGFloat,
        currentSectionTotalYOffset: CGFloat
    ) {
        lock.lock()
        defer { lock.unlock() }

        var updated = offsetsLocked(persistedData: userDefaults.data(forKey: key))
        updated.removeAll(where: { $0.bookUUID == bookUUID })
        updated.append(
            ReadingOffset(
                bookUUID: bookUUID,
                currentSection: currentSection,
                totalSections: totalSections,
                currentSectionYOffset: currentSectionYOffset,
                currentSectionTotalYOffset: currentSectionTotalYOffset
            )
        )

        persistLocked(updated)
    }

    func clearOffsets() {
        lock.lock()
        defer { lock.unlock() }

        userDefaults.removeObject(forKey: key)
        cachedData = nil
        cachedOffsets = []
    }

    func clearOffset(bookUUID: String) {
        lock.lock()
        defer { lock.unlock() }

        var updated = offsetsLocked(persistedData: userDefaults.data(forKey: key))
        updated.removeAll(where: { $0.bookUUID == bookUUID })
        persistLocked(updated)
    }

    private func offsetsLocked(persistedData: Data?) -> [ReadingOffset] {
        if let cachedOffsets, cachedData == persistedData {
            return cachedOffsets
        }

        let decodedOffsets = persistedData
            .flatMap { try? JSONDecoder().decode([ReadingOffset].self, from: $0) } ?? []
        cachedData = persistedData
        cachedOffsets = decodedOffsets
        return decodedOffsets
    }

    private func persistLocked(_ offsets: [ReadingOffset]) {
        guard let encodedData = try? JSONEncoder().encode(offsets) else { return }

        userDefaults.set(encodedData, forKey: key)
        cachedData = encodedData
        cachedOffsets = offsets
    }
}

struct ReadingOffset: Codable {
    let bookUUID: String
    let currentSection: Int
    let totalSections: Int
    let currentSectionYOffset: CGFloat
    let currentSectionTotalYOffset: CGFloat
    
    var hasStartedReading: Bool {
        if currentSection == 0 {
            // 150 is a reasonable amount to consider they've done more than open it
            return currentSectionYOffset > 150
        }
        return true
    }
}

struct TemporaryTextRetentionPolicy {
    static let retentionDays = 30

    static func shouldRetain(
        contentUUID: String,
        resumeBookUUID: String?,
        hasStartedReading: Bool,
        daysSinceLastRead: Int?
    ) -> Bool {
        if contentUUID == resumeBookUUID {
            return true
        }

        guard hasStartedReading, let daysSinceLastRead else {
            return false
        }

        return daysSinceLastRead < retentionDays
    }
}

struct TemporaryTextRetentionActivity {
    var hasStartedReading = false
    var daysSinceLastRead: Int?
}

struct ViewedContentRecord: Codable {
    let contentUUID: String
    let contentType: ContentType
    let viewedAt: Date
}

// MARK: - Last Read Date Tracking

enum LastReadMode: String, Codable {
    case text
    case audio
}

struct LastReadRecord: Codable {
    let bookUUID: String
    let lastReadAt: Date
    let mode: LastReadMode

    init(bookUUID: String, lastReadAt: Date, mode: LastReadMode) {
        self.bookUUID = bookUUID
        self.lastReadAt = lastReadAt
        self.mode = mode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bookUUID = try container.decode(String.self, forKey: .bookUUID)
        lastReadAt = try container.decode(Date.self, forKey: .lastReadAt)
        mode = try container.decodeIfPresent(LastReadMode.self, forKey: .mode) ?? .text
    }
}

extension ReadingUserDefaults {
    private static let lastReadDatesPath = "lastReadDatesPath"

    private static func getLastReadRecords() -> [LastReadRecord] {
        if let data = UserDefaults.standard.data(forKey: lastReadDatesPath),
           let records = try? JSONDecoder().decode([LastReadRecord].self, from: data) {
            return records
        }
        return []
    }

    static func setLastReadDate(for bookUUID: String, mode: LastReadMode = .text) {
        var records = getLastReadRecords()
        records.removeAll { $0.bookUUID == bookUUID }
        records.append(LastReadRecord(bookUUID: bookUUID, lastReadAt: Date(), mode: mode))

        // Keep only recent 200 records
        if records.count > 200 {
            records = Array(records.suffix(200))
        }

        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: lastReadDatesPath)
        }
    }

    static func getLastReadDate(for bookUUID: String) -> Date? {
        return getLastReadRecords().first { $0.bookUUID == bookUUID }?.lastReadAt
    }

    static func getLastReadMode(for bookUUID: String) -> LastReadMode? {
        return getLastReadRecords().first { $0.bookUUID == bookUUID }?.mode
    }

    static func daysSinceLastRead(for bookUUID: String) -> Int? {
        guard let lastReadDate = getLastReadDate(for: bookUUID) else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: lastReadDate, to: Date())
        return components.day
    }

    static func temporaryTextRetentionActivityByBookUUID(
        now: Date = Date()
    ) -> [String: TemporaryTextRetentionActivity] {
        var activityByBookUUID: [String: TemporaryTextRetentionActivity] = [:]

        for offset in getOffsets() where offset.hasStartedReading {
            activityByBookUUID[offset.bookUUID, default: TemporaryTextRetentionActivity()].hasStartedReading = true
        }

        let calendar = Calendar.current
        for record in getLastReadRecords() {
            activityByBookUUID[record.bookUUID, default: TemporaryTextRetentionActivity()].daysSinceLastRead =
                calendar.dateComponents([.day], from: record.lastReadAt, to: now).day
        }

        return activityByBookUUID
    }
}

extension ReadingUserDefaults {
    private static let recentlyViewedContentPath = "recentlyViewedContentPath"

    private static func getViewedContentRecords() -> [ViewedContentRecord] {
        if let data = UserDefaults.standard.data(forKey: recentlyViewedContentPath),
           let records = try? JSONDecoder().decode([ViewedContentRecord].self, from: data) {
            return records
        }
        return []
    }

    static func markContentViewed(contentUUID: String, contentType: ContentType) {
        var updated = getViewedContentRecords()
        updated.removeAll { $0.contentUUID == contentUUID }

        let newRecord = ViewedContentRecord(
            contentUUID: contentUUID,
            contentType: contentType,
            viewedAt: Date()
        )
        updated.insert(newRecord, at: 0)
        updated = Array(updated.prefix(500))

        if let data = try? JSONEncoder().encode(updated) {
            UserDefaults.standard.set(data, forKey: recentlyViewedContentPath)
        }
    }

    static func markBookInternalViewed(bookInternal: CDBookInternal) {
        markContentViewed(contentUUID: bookInternal.contentUUID, contentType: .bookInternal)
    }

    static func getRecentlyViewedContent(limit: Int? = nil) -> [ReadableContentMetadata] {
        let records = getViewedContentRecords()
        var result: [ReadableContentMetadata] = []

        for record in records {
            // Stop if we've reached the limit
            if let limit = limit, result.count >= limit {
                break
            }

            if let bookInternal = CoreDataBookInternalManager.shared.getWithUUID(uuid: record.contentUUID) {
                result.append(bookInternal)
            }
        }

        return result
    }

    static func getRecentlyViewedBookInternals(limit: Int? = nil) -> [CDBookInternal] {
        let records = getViewedContentRecords()
        var result: [CDBookInternal] = []

        for record in records {
            if let limit = limit, result.count >= limit {
                break
            }
            guard record.contentType == .bookInternal else { continue }
            guard let story = CoreDataBookInternalManager.shared.getWithUUID(uuid: record.contentUUID) else { continue }
            result.append(story)
        }

        return result
    }
    
    static func getReadingInProgressContent() -> [ReadableContentMetadata] {
        let textOffsetUUIDs = getOffsets()
            .filter { $0.hasStartedReading }
            .map(\.bookUUID)

        let audioProgressUUIDs = AudioPositionManager.shared.getBookUUIDsWithSavedPositions()
        let recencyOrderedUUIDs = getLastReadRecords().reversed().map(\.bookUUID)

        var orderedUUIDs: [String] = []
        var seenUUIDs = Set<String>()

        for uuid in recencyOrderedUUIDs + Array(textOffsetUUIDs.reversed()) + audioProgressUUIDs {
            guard seenUUIDs.insert(uuid).inserted else { continue }
            orderedUUIDs.append(uuid)
        }

        var inProgressItems: [ReadableContentMetadata] = []

        for uuid in orderedUUIDs {
            let metadata: ReadableContentMetadata? =
                CoreDataBookInternalManager.shared.getWithUUID(uuid: uuid)

            guard let metadata else { continue }

            let isMarkedComplete = AccountManager.shared.userHasCompletedBookInternalWithUUID(uuid)
            if isMarkedComplete { continue }

            let hasTextProgress = getOffsetForBookWithUUID(uuid)?.hasStartedReading == true
            let hasAudioProgress = AudioPositionManager.shared.hasPosition(for: uuid)
            guard hasTextProgress || hasAudioProgress else { continue }

            if let progress = progressForBookWithUUID(uuid), progress >= 100 {
                continue
            }

            inProgressItems.append(metadata)
        }

        return inProgressItems
    }

    static func getLastViewedBookInternalUUIDs() -> [String] {
        return getViewedContentRecords()
            .filter { $0.contentType == .bookInternal }
            .map { $0.contentUUID }
    }
}

// MARK: - Resume Reading on Relaunch
extension ReadingUserDefaults {
    private static let resumeReadingBookUUIDPath = "resumeReadingBookUUIDPath"
    private static let resumeReadingContentTypePath = "resumeReadingContentTypePath"

    static func setResumeReading(bookUUID: String, contentType: ContentType) {
        UserDefaults.standard.set(bookUUID, forKey: resumeReadingBookUUIDPath)
        UserDefaults.standard.set(contentType.rawValue, forKey: resumeReadingContentTypePath)
    }

    static func getResumeReading() -> (bookUUID: String, contentType: ContentType)? {
        guard
            let bookUUID = UserDefaults.standard.string(forKey: resumeReadingBookUUIDPath),
            let contentTypeString = UserDefaults.standard.string(forKey: resumeReadingContentTypePath),
            let contentType = ContentType(rawValue: contentTypeString)
        else {
            return nil
        }
        return (bookUUID, contentType)
    }

    static func clearResumeReading() {
        UserDefaults.standard.removeObject(forKey: resumeReadingBookUUIDPath)
        UserDefaults.standard.removeObject(forKey: resumeReadingContentTypePath)
    }
}
