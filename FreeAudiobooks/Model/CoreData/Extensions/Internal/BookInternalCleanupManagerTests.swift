//
//  BookInternalCleanupManagerTests.swift
//  FreeBooks
//
//  Created by Claude Code on 10/09/2025.
//  Copyright © 2025 Kneady Technologies. All rights reserved.
//

import Foundation
import CoreData

// Simple test to validate cleanup manager functionality
extension BookInternalCleanupManager {
    
    /// Test method to validate cleanup logic without actually deleting records
    func testCleanupLogic() -> String {
        var results: [String] = []
        
        // Get all book internals
        let allBookInternals = coreDataManager.getAll()
        results.append("Total CDBookInternal records: \(allBookInternals.count)")
        
        // Count records by age
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        var veryOldRecords = 0
        var oldRecords = 0
        var recentRecords = 0
        var recordsWithoutDates = 0
        
        for bookInternal in allBookInternals {
            if let datePersisted = bookInternal.datePersisted {
                if datePersisted < ninetyDaysAgo {
                    veryOldRecords += 1
                } else if datePersisted < thirtyDaysAgo {
                    oldRecords += 1
                } else {
                    recentRecords += 1
                }
            } else {
                recordsWithoutDates += 1
            }
        }
        
        results.append("Records older than 90 days: \(veryOldRecords)")
        results.append("Records 30-90 days old: \(oldRecords)")
        results.append("Recent records (< 30 days): \(recentRecords)")
        results.append("Records without datePersisted: \(recordsWithoutDates)")
        
        // Test deletion criteria
        var savedBookCount = 0
        var completedBookCount = 0
        var downloadedBookCount = 0
        var booksWithProgressCount = 0
        var candidatesForDeletion = 0
        
        if let user = AccountManager.shared.user {
            savedBookCount = user.savedBookInternalUUIDs.count
        }
        
        for bookInternal in allBookInternals {
            guard let uuid = bookInternal.uuid,
                  let datePersisted = bookInternal.datePersisted else {
                continue
            }
            
            let daysSincePersisted = Calendar.current.dateComponents([.day], 
                                                                   from: datePersisted, 
                                                                   to: Date()).day ?? 0
            
            // Apply cleanup logic (without actually deleting)
            let shouldDelete = shouldDeleteForTesting(bookInternal)
            if shouldDelete {
                candidatesForDeletion += 1
            }
            
            if AccountManager.shared.userHasCompletedBookInternalWithUUID(uuid) {
                completedBookCount += 1
            }
            
            if DownloadTimestampManager.shared.getAudioDownloadTimestamp(uuid: uuid) != nil {
                downloadedBookCount += 1
            }
            
            if hasReadingProgress(uuid: uuid) {
                booksWithProgressCount += 1
            }
        }
        
        results.append("User has \(savedBookCount) saved books")
        results.append("User has completed \(completedBookCount) books")
        results.append("User has downloaded \(downloadedBookCount) books")
        results.append("User has started reading \(booksWithProgressCount) books")
        results.append("Candidates for deletion: \(candidatesForDeletion)")
        
        return results.joined(separator: "\n")
    }
    
    private func shouldDeleteForTesting(_ bookInternal: CDBookInternal) -> Bool {
        guard let uuid = bookInternal.uuid,
              let datePersisted = bookInternal.datePersisted else {
            return false
        }
        
        let daysSincePersisted = Calendar.current.dateComponents([.day], 
                                                               from: datePersisted, 
                                                               to: Date()).day ?? 0
        
        // Never delete saved books
        if let user = AccountManager.shared.user,
           user.savedBookInternalUUIDs.contains(uuid) {
            return false
        }
        
        // Never delete completed books
        if AccountManager.shared.userHasCompletedBookInternalWithUUID(uuid) {
            return false
        }
        
        // Never delete downloaded audiobooks
        if DownloadTimestampManager.shared.getAudioDownloadTimestamp(uuid: uuid) != nil {
            return false
        }
        
        // Never delete books with reading progress
        if hasReadingProgress(uuid: uuid) {
            return false
        }
        
        // Standard retention period
        return daysSincePersisted > CleanupConfig.standardRetentionDays
    }
    
    /// Force run cleanup for testing (use with caution!)
    func testCleanupRun() {
        print("BookInternalCleanupManager: Test run initiated")
        print(testCleanupLogic())
        
        // Uncomment the line below to actually perform cleanup
        // performCleanup()
    }
}
