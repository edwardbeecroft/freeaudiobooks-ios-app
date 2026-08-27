import UIKit
import Firebase
import FirebaseFirestore

class APIBookInternalSectionManager {
    private init() {}
    static let shared = APIBookInternalSectionManager()
}

extension APIBookInternalSectionManager {
    func fetchSectionsForBookUUID(bookUUID: String, completion: @escaping (_ content: CDShortStoryContent?, _ success: Bool) ->()) {
        let bookInternalSectionsRef = Firestore
            .firestore()
            .collection(FirebasePaths.shortStories.rawValue)
            .document(bookUUID)
            .collection(FirebasePaths.sections.rawValue)
        
        bookInternalSectionsRef.getDocuments(source: .default) { snapshot, error in
            guard
                error == nil,
                let snapshot = snapshot else {
                return completion(nil, false)
            }
            
            var bookInternalSections = snapshot.documents.compactMap { APIShortStorySection(data: $0.data()) }
            bookInternalSections.sort(by: { $0.position < $1.position })
            
            // Convert APIShortStorySection array to string array
            let sectionTexts = bookInternalSections.map { $0.content }
            
            // Persist to CoreData as CDShortStoryContent with all sections
            CoreDataBookInternalContentManager.shared.persist(
                bookUUID: bookUUID,
                datePersisted: Date(),
                sections: sectionTexts
            ) { content, success in
                completion(content, success)
            }
        }
    }
    
    /// Save or update sections by first clearing existing ones
    func saveOrUpdateSections(bookUUID: String, sections: [String], completion: @escaping (_ success: Bool) ->()) {
        // First, delete all existing sections
        deleteAllSections(bookUUID: bookUUID) { deleteSuccess in
            guard deleteSuccess else {
                completion(false)
                return
            }
            
            // Then save the new sections
            self.saveSections(bookUUID: bookUUID, sections: sections, completion: completion)
        }
    }
    
    /// Delete all sections for a story
    private func deleteAllSections(storyUUID: String, completion: @escaping (_ success: Bool) ->()) {
        let baseSectionRef = Firestore
            .firestore()
            .collection(FirebasePaths.shortStories.rawValue)
            .document(storyUUID)
            .collection(FirebasePaths.sections.rawValue)
        
        baseSectionRef.getDocuments { snapshot, error in
            guard error == nil, let snapshot = snapshot else {
                completion(false)
                return
            }
            
            let dispatchGroup = DispatchGroup()
            var overallSuccess = true
            
            for document in snapshot.documents {
                dispatchGroup.enter()
                document.reference.delete { error in
                    if error != nil {
                        overallSuccess = false
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(overallSuccess)
            }
        }
    }
    
    /// Save new sections (helper method)
    private func saveSections(storyUUID: String, sections: [String], completion: @escaping (_ success: Bool) ->()) {
        let baseSectionRef = Firestore
            .firestore()
            .collection(FirebasePaths.shortStories.rawValue)
            .document(storyUUID)
            .collection(FirebasePaths.sections.rawValue)
        
        let dispatchGroup = DispatchGroup()
        var overallSuccess: Bool = true
        
        for (index, section) in sections.enumerated() {
            dispatchGroup.enter()
            
            let newUUID = UUID().uuidString
            let section = APIShortStorySection(uuid: newUUID, position: index, content: section)
            let sectionSpecificRef = baseSectionRef.document(newUUID)
            
            sectionSpecificRef.setData(section.toData(), merge: false) { error in
                if error != nil {
                    overallSuccess = false
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(overallSuccess)
        }
    }
}