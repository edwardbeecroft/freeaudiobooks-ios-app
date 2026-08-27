//
//  CoreDataBookInternalAudioManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 26/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import CoreData

class CoreDataBookInternalAudioManager {
    private init() {}
    static let shared = CoreDataBookInternalAudioManager()
    static let temporaryDownloadRetentionInterval: TimeInterval = 30 * 24 * 60 * 60

    private let coreDataManager = CoreDataManager.shared

    func getContext() -> NSManagedObjectContext {
        return coreDataManager.context
    }

    func saveContext() {
        coreDataManager.save()
    }
}

// MARK: - Basic Functions
extension CoreDataBookInternalAudioManager {
    func persist(bookUUID: String, language: String, audioData: Data, duration: TimeInterval, originalURL: String? = nil, isTemporary: Bool = false, completion: @escaping (CDBookInternalAudio?) -> Void) {
        coreDataManager.performBackgroundTask { [weak self] context in
            guard let self = self else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            // Check if audio already exists for this book
            let predicate = NSPredicate(format: "bookID == %@", bookUUID)
            let existingAudio = self.coreDataManager.fetchInBackground(CDBookInternalAudio.self, context: context, predicate: predicate).first

            let audio = existingAudio ?? self.coreDataManager.createInBackground(CDBookInternalAudio.self, context: context)

            // Update properties
            audio.bookID = bookUUID
            audio.language = language
            audio.audioData = audioData
            audio.fileSize = Int64(audioData.count)
            audio.duration = duration
            audio.datePersisted = Date()
            audio.originalURL = originalURL
            audio.isTemporaryDownload = isTemporary

            do {
                if context.hasChanges {
                    try context.save()
                }

                let objectID = audio.objectID
                DispatchQueue.main.async {
                    let mainContextAudio = self.coreDataManager.context.object(with: objectID) as? CDBookInternalAudio
                    completion(mainContextAudio)
                }
            } catch {
                print("❌ Failed to save CDBookInternalAudio: \(error)")
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }

    func getWithUUID(bookUUID: String) -> CDBookInternalAudio? {
        let predicate = NSPredicate(format: "bookID == %@", bookUUID)
        return coreDataManager.fetchOne(CDBookInternalAudio.self, predicate: predicate)
    }

    func getDownloadedWithUUID(bookUUID: String) -> CDBookInternalAudio? {
        let predicate = NSPredicate(format: "bookID == %@ AND isTemporaryDownload == NO", bookUUID)
        return coreDataManager.fetchOne(CDBookInternalAudio.self, predicate: predicate)
    }

    func getAllAudioBooks() -> [CDBookInternalAudio] {
        let sortDescriptor = NSSortDescriptor(key: "datePersisted", ascending: false)
        return coreDataManager.fetch(CDBookInternalAudio.self, sortDescriptors: [sortDescriptor])
    }

    func deleteBookInternalAudio(bookUUID: String, completion: @escaping (Bool) -> Void) {
        coreDataManager.performBackgroundTask { context in
            let predicate = NSPredicate(format: "bookID == %@", bookUUID)
            let fetchRequest: NSFetchRequest<CDBookInternalAudio> = CDBookInternalAudio.fetchRequest()
            fetchRequest.predicate = predicate

            do {
                let audioFiles = try context.fetch(fetchRequest)
                audioFiles.forEach { context.delete($0) }

                if context.hasChanges {
                    try context.save()
                }

                DispatchQueue.main.async { completion(true) }
            } catch {
                print("❌ Failed to delete CDBookInternalAudio: \(error)")
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    func clearAllBookInternalAudio(completion: @escaping (Bool) -> Void) {
        coreDataManager.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<CDBookInternalAudio> = CDBookInternalAudio.fetchRequest()

            do {
                let audioFiles = try context.fetch(fetchRequest)
                audioFiles.forEach { context.delete($0) }

                if context.hasChanges {
                    try context.save()
                }

                DispatchQueue.main.async { completion(true) }
            } catch {
                print("❌ Failed to clear all CDBookInternalAudio: \(error)")
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    @discardableResult
    func promoteTemporaryDownload(bookUUID: String) -> Bool {
        guard let audio = getWithUUID(bookUUID: bookUUID) else { return false }
        guard audio.isTemporaryDownload else { return false }

        audio.isTemporaryDownload = false
        audio.datePersisted = Date()
        coreDataManager.save()
        DownloadTimestampManager.shared.recordAudioDownload(uuid: bookUUID)
        return true
    }

    func clearTemporaryDownloads(excludingBookUUID: String? = nil) {
        clearExpiredTemporaryDownloads(excludingBookUUID: excludingBookUUID)
    }

    func clearExpiredTemporaryDownloads(
        excludingBookUUID: String? = nil,
        now: Date = Date(),
        retentionInterval: TimeInterval = CoreDataBookInternalAudioManager.temporaryDownloadRetentionInterval
    ) {
        // Fetch only the metadata needed for the expiry check, so the audio blobs
        // of downloads we keep are never loaded into memory.
        let request = NSFetchRequest<NSDictionary>(entityName: "CDBookInternalAudio")
        request.predicate = NSPredicate(format: "isTemporaryDownload == YES")
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["bookID", "datePersisted"]

        let metadata: [NSDictionary]
        do {
            metadata = try coreDataManager.context.fetch(request)
        } catch {
            print("❌ Failed to fetch temporary audiobook metadata: \(error)")
            return
        }

        let expiredBookIDs: [String] = metadata.compactMap { record in
            guard
                let bookID = record["bookID"] as? String,
                bookID != excludingBookUUID,
                isTemporaryDownloadExpired(
                    bookID: bookID,
                    datePersisted: record["datePersisted"] as? Date,
                    now: now,
                    retentionInterval: retentionInterval
                )
            else { return nil }
            return bookID
        }

        guard !expiredBookIDs.isEmpty else { return }

        expiredBookIDs.forEach { print("📱 Cleaning up stale temporary audiobook download: \($0)") }

        let expiredPredicate = NSPredicate(format: "isTemporaryDownload == YES AND bookID IN %@", expiredBookIDs)
        let expiredAudio = coreDataManager.fetch(CDBookInternalAudio.self, predicate: expiredPredicate)
        expiredAudio.forEach { coreDataManager.delete($0) }
        coreDataManager.save()
        print("📱 Cleared \(expiredAudio.count) stale temporary audiobook downloads")
    }

    private func isTemporaryDownloadExpired(
        bookID: String,
        datePersisted: Date?,
        now: Date,
        retentionInterval: TimeInterval
    ) -> Bool {
        let playbackUpdatedAt = AudioPlaybackProgressManager.shared.getProgress(for: bookID)?.updatedAt
        let lastAccessedAt = [playbackUpdatedAt, datePersisted]
            .compactMap { $0 }
            .max() ?? .distantPast

        return now.timeIntervalSince(lastAccessedAt) > retentionInterval
    }
}

// MARK: - Storage Management
extension CoreDataBookInternalAudioManager {
    func getTotalStorageSize() -> Int64 {
        let allAudio = getAllAudioBooks()
        return allAudio.reduce(0) { $0 + $1.fileSize }
    }

    func getTotalStorageSizeMB() -> Double {
        let bytes = getTotalStorageSize()
        return Double(bytes) / (1024.0 * 1024.0)
    }

    func getAudioBooksOrderedBySize(ascending: Bool = false) -> [CDBookInternalAudio] {
        let sortDescriptor = NSSortDescriptor(key: "fileSize", ascending: ascending)
        return coreDataManager.fetch(CDBookInternalAudio.self, sortDescriptors: [sortDescriptor])
    }
}
