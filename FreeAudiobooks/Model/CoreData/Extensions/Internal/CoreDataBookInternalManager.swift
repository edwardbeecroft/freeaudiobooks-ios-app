//
//  CoreDataBookInternalManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 06/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import CoreData

class CoreDataBookInternalManager {
    private init() {}
    static let shared = CoreDataBookInternalManager()
    
    private let coreDataManager = CoreDataManager.shared
    
    func getContext() -> NSManagedObjectContext {
        return coreDataManager.context
    }
    
    func saveContext() {
        coreDataManager.save()
    }
}

// MARK: - Basic Functions
extension CoreDataBookInternalManager {
    func persistSynchronously(_ apiShortStories: [APIBookInternal]) -> [CDBookInternal] {
        guard !apiShortStories.isEmpty else { return [] }

        let context = coreDataManager.context
        var savedStories: [CDBookInternal] = []

        context.performAndWait {
            let uuids = apiShortStories.map(\.uuid)
            let predicate = NSPredicate(format: "uuid IN %@", uuids)
            let existingStories = self.coreDataManager.fetchInBackground(
                CDBookInternal.self,
                context: context,
                predicate: predicate
            )
            var storiesByUUID: [String: CDBookInternal] = [:]
            storiesByUUID.reserveCapacity(max(existingStories.count, apiShortStories.count))
            for story in existingStories {
                storiesByUUID[story.contentUUID] = story
            }

            for apiBookInternal in apiShortStories {
                let existingStory = storiesByUUID[apiBookInternal.uuid]
                let story = existingStory ?? self.coreDataManager.createInBackground(CDBookInternal.self, context: context)
                self.apply(apiBookInternal, to: story, isNew: existingStory == nil)
                storiesByUUID[apiBookInternal.uuid] = story
            }
            do {
                try context.save()
            } catch {
                print("Failed saving context: \(error)")
            }
            // These are the objects just inserted or updated in the view context; fetching each
            // UUID again would issue one Core Data query per story.
            savedStories = apiShortStories.compactMap { storiesByUUID[$0.uuid] }
        }

        return savedStories
    }
    
    func getAll() -> [CDBookInternal] {
        let sortDescriptor = NSSortDescriptor(key: "datePublished", ascending: false)
        let predicate = NSPredicate(format: "isHidden == %@", NSNumber(value: false))
        return coreDataManager.fetch(CDBookInternal.self, predicate: predicate, sortDescriptors: [sortDescriptor])
    }

    func getAll(in genres: [BookInternalGenre]) -> [CDBookInternal] {
        guard !genres.isEmpty else { return [] }

        let sortDescriptor = NSSortDescriptor(key: "datePublished", ascending: false)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isHidden == %@", NSNumber(value: false)),
            NSPredicate(format: "genreString IN %@", genres.map(\.rawValue))
        ])
        return coreDataManager.fetch(CDBookInternal.self,
                                     predicate: predicate,
                                     sortDescriptors: [sortDescriptor])
    }

    func getAllAsync(completion: @escaping ([CDBookInternal]) -> Void) {
        let sortDescriptor = NSSortDescriptor(key: "datePublished", ascending: false)
        let predicate = NSPredicate(format: "isHidden == %@", NSNumber(value: false))

        coreDataManager.performBackgroundTask { [weak self] context in
            guard let self else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            let request = NSFetchRequest<NSManagedObjectID>(entityName: String(describing: CDBookInternal.self))
            request.predicate = predicate
            request.sortDescriptors = [sortDescriptor]
            request.resultType = .managedObjectIDResultType

            do {
                let objectIDs = try context.fetch(request)
                DispatchQueue.main.async {
                    let stories = objectIDs.compactMap { objectID -> CDBookInternal? in
                        guard
                            let object = try? self.coreDataManager.context.existingObject(with: objectID),
                            let story = object as? CDBookInternal else {
                            return nil
                        }
                        return story
                    }
                    completion(stories)
                }
            } catch {
                print("Failed to fetch internal books: \(error)")
                DispatchQueue.main.async { completion([]) }
            }
        }
    }
    
    func getWithUUID(uuid: String) -> CDBookInternal? {
        let predicate = NSPredicate(format: "uuid == %@", uuid)
        return coreDataManager.fetchOne(CDBookInternal.self, predicate: predicate)
    }
    
    func getWithUUIDs(uuids: [String]) -> [CDBookInternal] {
        guard !uuids.isEmpty else { return [] }
        let predicate = NSPredicate(format: "uuid IN %@", uuids)
        let fetched = coreDataManager.fetch(CDBookInternal.self, predicate: predicate)
        
        // Build a lookup from UUID to object
        let fetchedByUUID = Dictionary(uniqueKeysWithValues: fetched.map { ($0.uuid, $0) })
        
        // Map input uuids directly to objects
        return uuids.compactMap { fetchedByUUID[$0] }
    }
    
    func getPopular(limit: Int = 5) -> [CDBookInternal] {
        let sortDescriptor = NSSortDescriptor(key: "readerCount", ascending: false)
        let predicate = NSPredicate(format: "isHidden == %@", NSNumber(value: false))
        return coreDataManager.fetch(CDBookInternal.self, predicate: predicate, sortDescriptors: [sortDescriptor], limit: limit)
    }
    
    func increaseReaderCountForBookInternalWithUUID(_ uuid: String) {
        guard let cdBookInternal = getWithUUID(uuid: uuid) else { return }

        let context = coreDataManager.context
        context.performAndWait {
            cdBookInternal.readerCount += 1
            do {
                try context.save()
            } catch {
                print("Failed to increment reader count for CDBookInternal with UUID \(uuid): \(error)")
            }
        }
    }
    
    func getSavedBookInternals() -> [CDBookInternal] {
        guard let user = AccountManager.shared.user else { return [] }
        let savedUUIDs = user.savedBookInternalUUIDs
        guard !savedUUIDs.isEmpty else { return [] }
        
        return getWithUUIDs(uuids: savedUUIDs)
    }
    
    func getDownloadedBookInternals() -> [CDBookInternal] {
        let allBookInternals = getAll()
        return allBookInternals.filter { $0.hasDownloadedAudio }
    }
}

// MARK: - Private Helper Methods
private extension CoreDataBookInternalManager {
    func apply(_ apiBookInternal: APIBookInternal,
               to story: CDBookInternal,
               isNew: Bool) {
        // Update story properties
        story.uuid = apiBookInternal.uuid
        story.bookTypeString = apiBookInternal.bookType.rawValue
        story.title = apiBookInternal.title
        story.blurb = apiBookInternal.blurb
        story.coverImageURLXL = apiBookInternal.coverImageURLXL
        story.coverImageURL = apiBookInternal.coverImageURL
        story.coverImageURLThumbnail = apiBookInternal.coverImageURLThumbnail
        story.genreString = apiBookInternal.genre.rawValue
        story.readingTimeMinutes = Int32(apiBookInternal.readingTimeMinutes)
        story.chapterCount = Int32(apiBookInternal.chapterCount)
        story.readerCount = Int32(apiBookInternal.readerCount)
        story.datePublished = apiBookInternal.datePublished
        story.dateUpdated = apiBookInternal.dateUpdated
        story.isHidden = apiBookInternal.isHidden
        story.isSubscriptionOnly = apiBookInternal.isSubscriptionOnly
        story.containsAdultContent = apiBookInternal.containsAdultContent
        story.rating = apiBookInternal.rating
        story.numberOfRatings = Int32(apiBookInternal.numberOfRatings)
        story.availableForAllDateString = apiBookInternal.availableForAllDateString
        story.authorName = apiBookInternal.authorName
        story.deeplinkURL = apiBookInternal.deeplinkURL
        story.heroBackgroundImageURL = apiBookInternal.heroBackgroundImageURL
        story.heroBackgroundImageURLXL = apiBookInternal.heroBackgroundImageURLXL
        story.heroLayout = apiBookInternal.heroLayout?.rawValue
        story.heroTitle = apiBookInternal.heroTitle
        story.heroSubtitle = apiBookInternal.heroSubtitle
        story.tagsData = apiBookInternal.tags as NSArray

        let audioURLsDict = apiBookInternal.audio.reduce(into: [String: String]()) { dict, audio in
            dict[audio.language.rawValue] = audio.storageURL
        }
        story.audioURLs = audioURLsDict as NSDictionary

        let preferredAudio = apiBookInternal.audio.first(where: { $0.language == .english }) ?? apiBookInternal.audio.first
        story.listeningTimeSeconds = preferredAudio?.listeningTimeSeconds ?? 0
        story.listeningTimeMinutes = Int32(preferredAudio?.listeningTimeMinutes ?? 0)
        story.remoteAudioFileSize = preferredAudio?.fileSizeBytes ?? 0
        
        // Set datePersisted for new stories or update existing ones that don't have it set
        if isNew || story.datePersisted == nil {
            story.datePersisted = Date()
        }
    }
}
