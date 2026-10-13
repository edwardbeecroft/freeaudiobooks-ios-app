import UIKit
import FirebaseCore
import FirebaseFirestore

class APIBookInternalSectionManager {
    private init() {}
    static let shared = APIBookInternalSectionManager()
}

extension APIBookInternalSectionManager {
    func fetchSectionsForBookUUID(bookUUID: String, isTemporary: Bool = false, completion: @escaping (_ content: CDBookInternalContent?, _ success: Bool) ->()) {
        let bookInternalSectionsRef = Firestore
            .firestore()
            .collection(FirebasePaths.booksInternal.rawValue)
            .document(bookUUID)
            .collection(FirebasePaths.sections.rawValue)
        
        bookInternalSectionsRef.getDocuments(source: .default) { snapshot, error in
            guard
                error == nil,
                let snapshot = snapshot else {
                return completion(nil, false)
            }
            
            var bookInternalSections = snapshot.documents.compactMap { APIBookInternalSection(data: $0.data()) }
            bookInternalSections.sort(by: { $0.position < $1.position })
            
            // Convert APIBookInternalSection array to string array
            let sectionTexts = bookInternalSections.map { $0.content }
            
            // Persist to CoreData as CDBookInternalContent with all sections
            CoreDataBookInternalContentManager.shared.persist(
                bookUUID: bookUUID,
                datePersisted: Date(),
                sections: sectionTexts,
                isTemporary: isTemporary
            ) { content, success in
                completion(content, success)
            }
        }
    }
}
