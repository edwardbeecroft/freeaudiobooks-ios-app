//
//  BookReviewsManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 16/10/2025.
//  Copyright © 2025 Kneady Technologies. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class APIBookReviewsManager {
    private init() {}
    static let shared = APIBookReviewsManager()
}

extension APIBookReviewsManager {
    func fetchReviewsForMetadata(contentMetadata: ReadableContentMetadata, completion: @escaping (_ content: [APIBookReview]?, _ success: Bool) ->()) {

        let path = FirebasePaths.booksInternal.rawValue
        let bookReviewsRef = Firestore
            .firestore()
            .collection(path)
            .document(contentMetadata.contentUUID)
            .collection(FirebasePaths.reviews.rawValue)

        let displayedReviewsQuery = bookReviewsRef
            .whereField(APIBookInternalReviewVariables.displayableState.rawValue,
                        isEqualTo: ReviewDisplayableState.displayed.rawValue)

        let currentUserUID = Auth.auth().currentUser?.uid
        let dispatchGroup = DispatchGroup()

        var displayedReviews: [APIBookReview] = []
        var pendingReviewForCurrentUser: APIBookReview?
        var displayedReviewsFetchSucceeded = false

        dispatchGroup.enter()
        displayedReviewsQuery.getDocuments(source: .default) { snapshot, error in
            defer { dispatchGroup.leave() }

            if let error {
                print("Failed to fetch displayed reviews: \(error.localizedDescription)")
            }

            guard
                error == nil,
                let snapshot else {
                return
            }

            displayedReviews = snapshot.documents
                .compactMap { APIBookReview(data: $0.data()) }
                .sorted(by: { $0.createdDate > $1.createdDate })
            displayedReviewsFetchSucceeded = true
        }

        if let currentUserUID {
            dispatchGroup.enter()
            bookReviewsRef
                .whereField(APIBookInternalReviewVariables.userUUID.rawValue, isEqualTo: currentUserUID)
                .getDocuments(source: .default) { snapshot, error in
                    defer { dispatchGroup.leave() }

                    if let error {
                        print("Failed to fetch current user's pending review: \(error.localizedDescription)")
                    }

                    guard
                        error == nil,
                        let snapshot else {
                        return
                    }

                    pendingReviewForCurrentUser = snapshot.documents
                        .compactMap { APIBookReview(data: $0.data()) }
                        .filter { review in
                            review.userUUID == currentUserUID &&
                            review.displayableState == .pendingReview &&
                            review.hasWrittenComment
                        }
                        .sorted(by: { $0.createdDate > $1.createdDate })
                        .first
                }
        }

        dispatchGroup.notify(queue: .main) {
            guard displayedReviewsFetchSucceeded else {
                return completion(nil, false)
            }

            var mergedReviews = displayedReviews

            if
                let pendingReviewForCurrentUser,
                !mergedReviews.contains(where: { $0.uuid == pendingReviewForCurrentUser.uuid }) {
                mergedReviews.insert(pendingReviewForCurrentUser, at: 0)
            }

            completion(mergedReviews, true)
        }
    }

    func fetchRatingForMetadata(contentMetadata: ReadableContentMetadata, completion: @escaping (_ rating: Double?, _ numberOfRatings: Int?, _ success: Bool) ->()) {

        let path = FirebasePaths.booksInternal.rawValue
        let bookDocRef = Firestore
            .firestore()
            .collection(path)
            .document(contentMetadata.contentUUID)

        bookDocRef.getDocument(source: .default) { snapshot, error in
            guard
                error == nil,
                let snapshot = snapshot,
                snapshot.exists else {
                // Document doesn't exist yet (lazy creation), return success with nil values
                return completion(nil, nil, true)
            }

            let data = snapshot.data()
            let rating = data?["rating"] as? Double
            let numberOfRatings = data?["numberOfRatings"] as? Int

            completion(rating, numberOfRatings, true)
        }
    }
}
