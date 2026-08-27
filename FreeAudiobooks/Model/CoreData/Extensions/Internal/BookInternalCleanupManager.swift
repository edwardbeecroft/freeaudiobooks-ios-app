//
//  BookInternalCleanupManager.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 10/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import CoreData

class BookInternalCleanupManager {
    
    private init() {}
    static let shared = BookInternalCleanupManager()
    
    // MARK: - Configuration
    private struct CleanupConfig {
        static let standardRetentionDays: Int = 90
        static let rateLimitKey = "last_cleanup_date"
    }
    
    private let coreDataManager = CoreDataBookInternalManager.shared
    
    // MARK: - Public Interface
    
    /// Performs cleanup of old CDBookInternal records if rate limit allows
    func performCleanupIfNeeded() {
        guard shouldPerformCleanup() else {
            print("BookInternalCleanupManager: Skipping cleanup - rate limited")
            return
        }
        
        performCleanup()
        updateLastCleanupDate()
    }
    
    /// Forces cleanup regardless of rate limiting (for testing)
    func forceCleanup() {
        performCleanup()
        updateLastCleanupDate()
    }
    
    // MARK: - Private Methods
    
    private func shouldPerformCleanup() -> Bool {
        guard let lastCleanup = UserDefaults.standard.object(forKey: CleanupConfig.rateLimitKey) as? Date else {
            // Never performed cleanup before
            return true
        }
        
        let daysSinceLastCleanup = Calendar.current.dateComponents([.day], 
                                                                   from: lastCleanup, 
                                                                   to: Date()).day ?? 0
        return daysSinceLastCleanup >= 1
    }
    
    private func updateLastCleanupDate() {
        UserDefaults.standard.set(Date(), forKey: CleanupConfig.rateLimitKey)
    }
    
    private func performCleanup() {
        let context = coreDataManager.getContext()
        
        context.perform { [weak self] in
            guard let self = self else { return }
            
            let candidatesForDeletion = self.getCandidatesForDeletion(in: context)
            
            if candidatesForDeletion.isEmpty {
                print("BookInternalCleanupManager: No candidates for deletion found")
                return
            }
            
            print("BookInternalCleanupManager: Found \(candidatesForDeletion.count) candidates for deletion")
            
            // Delete the candidates
            var deletedCount = 0
            for candidate in candidatesForDeletion {
                // Also delete associated content and audio if it exists
                self.deleteAssociatedContent(for: candidate.uuid ?? "", in: context)
                self.deleteAssociatedAudio(for: candidate.uuid ?? "", in: context)
                
                context.delete(candidate)
                deletedCount += 1
            }
            
            // Save changes
            do {
                try context.save()
                print("BookInternalCleanupManager: Successfully deleted \(deletedCount) old book internals")
            } catch {
                print("BookInternalCleanupManager: Failed to save after cleanup: \(error)")
            }
        }
    }
    
    private func getCandidatesForDeletion(in context: NSManagedObjectContext) -> [CDBookInternal] {
        let fetchRequest: NSFetchRequest<CDBookInternal> = CDBookInternal.fetchRequest()
        
        do {
            let allBookInternals = try context.fetch(fetchRequest)
            
            return allBookInternals.filter { bookInternal in
                return shouldDelete(bookInternal)
            }
        } catch {
            print("BookInternalCleanupManager: Error fetching book internals: \(error)")
            return []
        }
    }
    
    private func shouldDelete(_ bookInternal: CDBookInternal) -> Bool {
        guard let uuid = bookInternal.uuid,
              let datePersisted = bookInternal.datePersisted else {
            // If no UUID or datePersisted, keep it (shouldn't happen with our new logic)
            return false
        }
        
        let daysSincePersisted = Calendar.current.dateComponents([.day], 
                                                               from: datePersisted, 
                                                               to: Date()).day ?? 0
        
        // Rule 1: Never delete saved books
        if let user = AccountManager.shared.user,
           user.savedBookInternalUUIDs.contains(uuid) {
            return false
        }
        
        // Rule 2: Never delete completed books
        if AccountManager.shared.userHasCompletedBookInternalWithUUID(uuid) {
            return false
        }
        
        // Rule 3: Never delete downloaded audiobooks (user explicitly downloaded them)
        if DownloadTimestampManager.shared.getAudioDownloadTimestamp(uuid: uuid) != nil {
            return false
        }
        
        // Rule 3.5: Never delete downloaded audiobooks (user explicitly downloaded them)
        if DownloadTimestampManager.shared.getAudioDownloadTimestamp(uuid: uuid) != nil {
            return false
        }
        
        // Rule 4: Never delete books with reading progress
        if hasReadingProgress(uuid: uuid) {
            return false
        }
        
        // Rule 4.5: Never delete books with audio listening progress
        if AudioPositionManager.shared.hasPosition(for: uuid) {
            return false
        }

        // Rule 4.6: Never delete books with a recent temporary audiobook cache
        if hasRecentTemporaryAudio(uuid: uuid, in: bookInternal.managedObjectContext) {
            return false
        }

        // Rule 5: Standard retention period
        return daysSincePersisted > CleanupConfig.standardRetentionDays
    }

    private func hasReadingProgress(uuid: String) -> Bool {
        return ReadingUserDefaults.getOffsetForBookWithUUID(uuid)?.hasStartedReading ?? false
    }

    private func hasRecentTemporaryAudio(uuid: String, in context: NSManagedObjectContext?) -> Bool {
        guard let context else { return false }

        // Fetch only datePersisted so the recency check never loads the audio blob.
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "CDBookInternalAudio")
        fetchRequest.predicate = NSPredicate(format: "bookID == %@ AND isTemporaryDownload == YES", uuid)
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.propertiesToFetch = ["datePersisted"]

        do {
            let audioRecords = try context.fetch(fetchRequest)
            let playbackUpdatedAt = AudioPlaybackProgressManager.shared.getProgress(for: uuid)?.updatedAt
            return audioRecords.contains { record in
                let lastAccessedAt = [playbackUpdatedAt, record["datePersisted"] as? Date]
                    .compactMap { $0 }
                    .max() ?? .distantPast

                return Date().timeIntervalSince(lastAccessedAt) <= CoreDataBookInternalAudioManager.temporaryDownloadRetentionInterval
            }
        } catch {
            print("BookInternalCleanupManager: Error fetching temporary audio: \(error)")
            return false
        }
    }
    
    private func deleteAssociatedContent(for uuid: String, in context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<CDBookInternalContent> = CDBookInternalContent.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "bookID == %@", uuid)

        do {
            let contentRecords = try context.fetch(fetchRequest)
            for content in contentRecords {
                context.delete(content)
            }
        } catch {
            print("BookInternalCleanupManager: Error fetching associated content: \(error)")
        }
    }

    private func deleteAssociatedAudio(for uuid: String, in context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<CDBookInternalAudio> = CDBookInternalAudio.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "bookID == %@", uuid)

        do {
            let audioRecords = try context.fetch(fetchRequest)
            for audio in audioRecords {
                context.delete(audio)
            }
        } catch {
            print("BookInternalCleanupManager: Error fetching associated audio: \(error)")
        }
    }
}
