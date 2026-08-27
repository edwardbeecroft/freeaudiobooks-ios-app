//
//  APIBookSocialPostManager.swift
//  FreeAudiobooks
//
//  Created by Codex on 25/02/2026.
//

import Foundation
import FirebaseFirestore

enum APIBookSocialPostVariables: String {
    case socialPost
    case bookUUID
    case createdAt
    case updatedAt
    case generatorCreatorID
    case source
    case bookTitleSnapshot
}

final class APIBookSocialPostManager {
    private init() {}
    static let shared = APIBookSocialPostManager()
}

extension APIBookSocialPostManager {
    func fetchLatestSocialPost(bookUUID: String, completion: @escaping (_ socialPost: String?, _ success: Bool) -> ()) {
        let docRef = Firestore
            .firestore()
            .collection(FirebasePaths.socialPosts.rawValue)
            .document(bookUUID)

        docRef.getDocument(source: .default) { snapshot, error in
            guard error == nil else {
                completion(nil, false)
                return
            }

            guard
                let snapshot,
                snapshot.exists,
                let socialPost = snapshot.data()?[APIBookSocialPostVariables.socialPost.rawValue] as? String else {
                completion(nil, true)
                return
            }

            let trimmedSocialPost = socialPost.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedSocialPost.isEmpty else {
                completion(nil, true)
                return
            }

            completion(trimmedSocialPost, true)
        }
    }

    func saveLatestSocialPost(
        bookUUID: String,
        socialPost: String,
        generatorCreatorID: String?,
        bookTitleSnapshot: String?,
        completion: @escaping (_ success: Bool) -> ()
    ) {
        let trimmedSocialPost = socialPost.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSocialPost.isEmpty else {
            completion(true)
            return
        }

        let docRef = Firestore
            .firestore()
            .collection(FirebasePaths.socialPosts.rawValue)
            .document(bookUUID)

        docRef.getDocument(source: .default) { snapshot, error in
            guard error == nil else {
                completion(false)
                return
            }

            let titleSnapshot = bookTitleSnapshot?.trimmingCharacters(in: .whitespacesAndNewlines)
            let creatorID = generatorCreatorID?.trimmingCharacters(in: .whitespacesAndNewlines)

            var data: [String: Any] = [
                APIBookSocialPostVariables.socialPost.rawValue: trimmedSocialPost,
                APIBookSocialPostVariables.bookUUID.rawValue: bookUUID,
                APIBookSocialPostVariables.updatedAt.rawValue: FieldValue.serverTimestamp(),
                APIBookSocialPostVariables.source.rawValue: "ai_book_generation"
            ]

            let isNewDocument = snapshot?.exists != true
            let hasCreatedAt = snapshot?.data()?[APIBookSocialPostVariables.createdAt.rawValue] != nil
            if isNewDocument || !hasCreatedAt {
                data[APIBookSocialPostVariables.createdAt.rawValue] = FieldValue.serverTimestamp()
            }

            if let creatorID, !creatorID.isEmpty {
                data[APIBookSocialPostVariables.generatorCreatorID.rawValue] = creatorID
            } else if !isNewDocument {
                data[APIBookSocialPostVariables.generatorCreatorID.rawValue] = FieldValue.delete()
            }

            if let titleSnapshot, !titleSnapshot.isEmpty {
                data[APIBookSocialPostVariables.bookTitleSnapshot.rawValue] = titleSnapshot
            } else if !isNewDocument {
                data[APIBookSocialPostVariables.bookTitleSnapshot.rawValue] = FieldValue.delete()
            }

            docRef.setData(data, merge: true) { error in
                completion(error == nil)
            }
        }
    }
}
