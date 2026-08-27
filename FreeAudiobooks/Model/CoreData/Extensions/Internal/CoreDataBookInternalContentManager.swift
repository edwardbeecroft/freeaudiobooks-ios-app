//
//  CoreDataBookInternalContentManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 09/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import CoreData

class CoreDataBookInternalContentManager {
    private init() {}
    static let shared = CoreDataBookInternalContentManager()
    
    private let coreDataManager = CoreDataManager.shared
}

// MARK: - Basic Functions
extension CoreDataBookInternalContentManager {
    func persist(bookUUID: String, datePersisted: Date, sections: [String], isTemporary: Bool = false, completion: @escaping (CDBookInternalContent?, Bool) -> Void) {
        coreDataManager.performBackgroundTask { context in
            do {
                // Check if short story content already exists
                let predicate = NSPredicate(format: "bookID == %@", bookUUID)
                let existingContent = self.coreDataManager.fetchInBackground(CDBookInternalContent.self, context: context, predicate: predicate).first
                
                let bookInternalContent = existingContent ?? self.coreDataManager.createInBackground(CDBookInternalContent.self, context: context)
                
                bookInternalContent.bookID = bookUUID
                bookInternalContent.datePersisted = datePersisted
                bookInternalContent.isTemporaryDownload = isTemporary
                bookInternalContent.sections = sections as NSArray

                // Save the context
                if context.hasChanges {
                    try context.save()
                    print("BookInternalContent: Successfully persisted book \(bookUUID) with \(sections.count) sections")
                } else {
                    print("BookInternalContent: No changes to save for book \(bookUUID)")
                }

                // Get the object in the main context for return
                let objectID = bookInternalContent.objectID
                DispatchQueue.main.async {
                    let mainContextObject = self.coreDataManager.context.object(with: objectID) as? CDBookInternalContent
                    completion(mainContextObject, true)
                }
            } catch {
                print("BookInternalContent: Failed to persist book \(bookUUID): \(error)")
                DispatchQueue.main.async {
                    completion(nil, false)
                }
            }
        }
    }
}

// MARK: - Query Functions
extension CoreDataBookInternalContentManager {
    
    func getWithUUID(bookUUID: String) -> CDBookInternalContent? {
        let predicate = NSPredicate(format: "bookID == %@", bookUUID)
        return coreDataManager.fetchOne(CDBookInternalContent.self, predicate: predicate)
    }
    
    func getAllBooksInternal() -> [CDBookInternalContent] {
        return coreDataManager.fetch(CDBookInternalContent.self)
    }
    
    func deleteBookInternalContent(bookUUID: String) {
        let predicate = NSPredicate(format: "bookID == %@", bookUUID)
        if let bookInternalContent = coreDataManager.fetchOne(CDBookInternalContent.self, predicate: predicate) {
            coreDataManager.delete(bookInternalContent)
            coreDataManager.save()
        }
    }
    
    func clearAllBookInternalContent() {
        coreDataManager.deleteAll(CDBookInternalContent.self)
        coreDataManager.save()
    }

    func clearTemporaryDownloads(excludingBookUUID: String? = nil) {
        let predicate = NSPredicate(format: "isTemporaryDownload == YES")
        let temporaryContent = coreDataManager.fetch(CDBookInternalContent.self, predicate: predicate)
        guard !temporaryContent.isEmpty else { return }

        let activityByBookUUID = ReadingUserDefaults.temporaryTextRetentionActivityByBookUUID()

        var deletedCount = 0
        for content in temporaryContent {
            guard let bookUUID = content.bookID else {
                print("📱 Cleaning up temporary download with no book UUID")
                coreDataManager.delete(content)
                deletedCount += 1
                continue
            }
            let activity = activityByBookUUID[bookUUID]
            let shouldRetain = TemporaryTextRetentionPolicy.shouldRetain(
                contentUUID: bookUUID,
                resumeBookUUID: excludingBookUUID,
                hasStartedReading: activity?.hasStartedReading == true,
                daysSinceLastRead: activity?.daysSinceLastRead
            )
            if shouldRetain {
                continue
            }
            print("📱 Cleaning up expired temporary download: \(bookUUID)")
            coreDataManager.delete(content)
            deletedCount += 1
        }

        if deletedCount > 0 {
            coreDataManager.save()
            print("📱 Cleared \(deletedCount) temporary downloads")
        }
    }
}
