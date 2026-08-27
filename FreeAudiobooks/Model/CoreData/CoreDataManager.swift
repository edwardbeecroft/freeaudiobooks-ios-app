//
//  CoreDataManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 30/08/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    func setupPersistentStore() {
        
        // dumpCoreDataDebugInfo()
        
        let container = persistentContainer
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("⚠️ Core Data failed to load: \(error), \(error.userInfo)")
                
                // Attempt fallback: delete the store if it exists and retry
                if let url = storeDescription.url {
                    do {
                        print("⚠️ Deleting incompatible store at \(url.path)")
                        try FileManager.default.removeItem(at: url)
                        
                        AnalyticsManager.shared.trackCoreDataDeleteRequired()
                        
                        // Retry loading after deletion
                        container.loadPersistentStores { _, retryError in
                            if let retryError = retryError {
                                print("❌ Retry failed: \(retryError)")
                            } else {
                                print("✅ Successfully loaded store after deleting incompatible one")
                            }
                        }
                    } catch {
                        print("❌ Failed to delete store: \(error)")
                    }
                } else {
                    print("❌ Very odd - no store URL")
                }
            } else {
                print("✅ Successfully loaded Core Data store at \(storeDescription.url?.path ?? "unknown")")
            }
        }
    }

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FreeAudiobooks")
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - Save Operations
    
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved Core Data save error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    // MARK: - Generic CRUD Operations
    
    func create<T: NSManagedObject>(_ type: T.Type) -> T {
        let entity = NSEntityDescription.entity(forEntityName: String(describing: type), in: context)!
        return T(entity: entity, insertInto: context)
    }
    
    func createInBackground<T: NSManagedObject>(_ type: T.Type, context: NSManagedObjectContext) -> T {
        let entity = NSEntityDescription.entity(forEntityName: String(describing: type), in: context)!
        return T(entity: entity, insertInto: context)
    }
    
    func fetch<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors

        do {
            return try context.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }

    func fetch<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, limit: Int) -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        request.fetchLimit = limit

        do {
            return try context.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }
    
    func fetchInBackground<T: NSManagedObject>(_ type: T.Type, context: NSManagedObjectContext, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        do {
            return try context.fetch(request)
        } catch {
            print("Background fetch error: \(error)")
            return []
        }
    }
    
    func fetchOne<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate) -> T? {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        request.predicate = predicate
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Fetch one error: \(error)")
            return nil
        }
    }
    
    func delete<T: NSManagedObject>(_ object: T) {
        context.delete(object)
    }
    
    func deleteAll<T: NSManagedObject>(_ type: T.Type) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: type))
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
        } catch {
            print("Delete all error: \(error)")
        }
    }
    
    // MARK: - Batch Operations
    
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask { context in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            block(context)
            // Note: Explicit save responsibility moved to call sites for precise timing control
        }
    }
    
    func performAndWait<T>(_ block: (NSManagedObjectContext) -> T) -> T {
        var result: T!
        context.performAndWait {
            result = block(context)
        }
        return result
    }
    
    // MARK: - Utilities
    
    func clearAllData() {
        let entityNames = persistentContainer.managedObjectModel.entities.compactMap { $0.name }
        
        for entityName in entityNames {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            
            do {
                try context.execute(deleteRequest)
            } catch {
                print("Error clearing \(entityName): \(error)")
            }
        }
        
        save()
    }
    
    func objectExists<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate) -> Bool {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        request.predicate = predicate
        request.fetchLimit = 1
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("Object exists error: \(error)")
            return false
        }
    }
}

extension CoreDataManager {
    // MARK: - Core Data Stack
    
    func dumpCoreDataDebugInfo() {
        // 1️⃣ Print launch arguments and environment
        print("🚀 Launch arguments:")
        for arg in CommandLine.arguments {
            print("  \(arg)")
        }

        print("🌿 Environment variables:")
        for (key, value) in ProcessInfo.processInfo.environment {
            print("  \(key) = \(value)")
        }

        // 2️⃣ Enable Core Data debug logging
        setenv("com.apple.CoreData.SQLDebug", "1", 1)      // Logs SQL queries
        setenv("com.apple.CoreData.MigrationDebug", "1", 1) // Logs migration steps
        setenv("com.apple.CoreData.Logging", "1", 1)       // General Core Data logging
    }
}
