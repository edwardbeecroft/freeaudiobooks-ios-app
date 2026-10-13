//
//  BookInternalTagManager.swift
//  FreeAudiobooks
//
//  Created by OpenAI Codex on 27/03/2026.
//

import Foundation
import FirebaseFirestore

enum BookInternalTagVariables: String {
    case id
    case genre
    case tag
    case title
    case isHomeEligible
}

struct BookInternalTag: Hashable {
    let id: String
    let genre: BookInternalGenre
    let tag: String
    let title: String
    let isHomeEligible: Bool

    var enabled: Bool {
        isHomeEligible
    }

    init?(id: String, data: [String: Any]) {
        let rawID = (data[BookInternalTagVariables.id.rawValue] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedID = rawID?.isEmpty == false ? rawID! : id

        guard
            let genreString = data[BookInternalTagVariables.genre.rawValue] as? String,
            let genre = BookInternalGenre(rawValue: genreString),
            let tag = data[BookInternalTagVariables.tag.rawValue] as? String,
            let title = data[BookInternalTagVariables.title.rawValue] as? String else {
            return nil
        }

        self.id = resolvedID
        self.genre = genre
        self.tag = tag
        self.title = title
        self.isHomeEligible = data[BookInternalTagVariables.isHomeEligible.rawValue] as? Bool
            ?? data["enabled"] as? Bool
            ?? false
    }

}

enum GenreChartVariables: String {
    case genre
    case bookIDs
}

struct GenreChart: Hashable {
    let id: String
    let genre: BookInternalGenre
    let bookIDs: [String]

    init(id: String, genre: BookInternalGenre, bookIDs: [String]) {
        self.id = id
        self.genre = genre
        self.bookIDs = bookIDs
    }

    init?(id: String, data: [String: Any]) {
        guard
            let genreString = data[GenreChartVariables.genre.rawValue] as? String,
            let genre = BookInternalGenre(rawValue: genreString),
            let bookIDs = data[GenreChartVariables.bookIDs.rawValue] as? [String] else {
            return nil
        }

        self.id = id
        self.genre = genre
        self.bookIDs = bookIDs
    }

}

/// The single definition of a usable genre chart, shared by Home and by the admin screens that
/// author and audit charts, so that what admin calls "ready" is exactly what Home will render.
enum GenreChartRules {
    static let requiredBookCount = 10

    /// Unique chart entries that resolve to a book in the chart's own genre.
    ///
    /// - Parameter genreOfEligibleBook: the genre of the book with this ID, or `nil` when the ID
    ///   is unknown or the book cannot appear on Home (hidden, or still in early access).
    static func validBookIDs(in bookIDs: [String],
                             genre: BookInternalGenre,
                             genreOfEligibleBook: (String) -> BookInternalGenre?) -> [String] {
        var seenBookIDs = Set<String>()
        return bookIDs.filter { bookID in
            guard seenBookIDs.insert(bookID).inserted else { return false }
            return genreOfEligibleBook(bookID) == genre
        }
    }

    /// A chart is only rendered when it holds exactly ten unique books that are all eligible and
    /// all in its own genre. Anything less is a content error, and Home shows its popularity row.
    static func isComplete(bookIDs: [String],
                           genre: BookInternalGenre,
                           genreOfEligibleBook: (String) -> BookInternalGenre?) -> Bool {
        guard bookIDs.count == requiredBookCount else { return false }
        return validBookIDs(in: bookIDs,
                            genre: genre,
                            genreOfEligibleBook: genreOfEligibleBook).count == requiredBookCount
    }
}

protocol BookInternalTagLoading {
    func fetchHomeEligibleTags(for genre: BookInternalGenre,
                               source: FirestoreSource,
                               completion: @escaping (Result<[BookInternalTag], Error>) -> Void)
}

final class FirestoreBookInternalTagLoader: BookInternalTagLoading {
    func fetchHomeEligibleTags(for genre: BookInternalGenre,
                               source: FirestoreSource,
                               completion: @escaping (Result<[BookInternalTag], Error>) -> Void) {
        Firestore.firestore()
            .collection(FirebasePaths.booksInternalTags.rawValue)
            .whereField(BookInternalTagVariables.isHomeEligible.rawValue, isEqualTo: true)
            .whereField(BookInternalTagVariables.genre.rawValue, isEqualTo: genre.rawValue)
            .getDocuments(source: source) { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }
                guard let snapshot else {
                    completion(.failure(Self.missingSnapshotError))
                    return
                }

                let tags = snapshot.documents.compactMap {
                    BookInternalTag(id: $0.documentID, data: $0.data())
                }
                completion(.success(tags))
            }
    }

    private static let missingSnapshotError = NSError(
        domain: "BookInternalTagManager",
        code: 4,
        userInfo: [NSLocalizedDescriptionKey: "Firestore returned no tag snapshot."]
    )
}

struct BookInternalTagCache {
    private(set) var eligibleTagsByGenre: [BookInternalGenre: [BookInternalTag]] = [:]

    func eligibleTags(for genre: BookInternalGenre) -> [BookInternalTag]? {
        eligibleTagsByGenre[genre]
    }

    mutating func storeEligibleTags(_ tags: [BookInternalTag], for genre: BookInternalGenre) {
        eligibleTagsByGenre[genre] = tags.filter { $0.isHomeEligible && $0.genre == genre }
    }
}

final class BookInternalTagManager {
    static let shared = BookInternalTagManager()

    private let loader: BookInternalTagLoading
    private var cache = BookInternalTagCache()
    private var eligibleTagCompletions: [BookInternalGenre: [(Bool, [BookInternalTag]) -> Void]] = [:]
    private(set) var genreCharts: [GenreChart] = []

    init(loader: BookInternalTagLoading = FirestoreBookInternalTagLoader()) {
        self.loader = loader
    }

    func ensureHomeEligibleTags(for genre: BookInternalGenre,
                                completion: @escaping (Bool, [BookInternalTag]) -> Void) {
        onMain { [self] in
            if let tags = cache.eligibleTags(for: genre) {
                completion(true, tags)
                return
            }

            if eligibleTagCompletions[genre] != nil {
                eligibleTagCompletions[genre]?.append(completion)
                return
            }

            eligibleTagCompletions[genre] = [completion]
            loader.fetchHomeEligibleTags(for: genre, source: .default) { [weak self] result in
                self?.onMain { [weak self] in
                    guard let self else { return }
                    let completions = self.eligibleTagCompletions.removeValue(forKey: genre) ?? []
                    switch result {
                    case .success(let tags):
                        self.cache.storeEligibleTags(tags, for: genre)
                        let cachedTags = self.cache.eligibleTags(for: genre) ?? []
                        completions.forEach { $0(true, cachedTags) }
                    case .failure:
                        // Failure is deliberately not cached, so a later request can retry.
                        completions.forEach { $0(false, []) }
                    }
                }
            }
        }
    }

    func ensureHomeEligibleTags(for genres: [BookInternalGenre],
                                completion: @escaping (Bool, [BookInternalTag]) -> Void) {
        onMain { [self] in
            var seenGenres = Set<BookInternalGenre>()
            let uniqueGenres = genres.filter { seenGenres.insert($0).inserted }
            guard !uniqueGenres.isEmpty else {
                completion(true, [])
                return
            }

            var results: [BookInternalGenre: [BookInternalTag]] = [:]
            var allSucceeded = true
            var remaining = uniqueGenres.count

            for genre in uniqueGenres {
                ensureHomeEligibleTags(for: genre) { success, tags in
                    allSucceeded = allSucceeded && success
                    results[genre] = tags
                    remaining -= 1

                    if remaining == 0 {
                        completion(allSucceeded, uniqueGenres.flatMap { results[$0] ?? [] })
                    }
                }
            }
        }
    }

    func chart(genre: BookInternalGenre) -> GenreChart? {
        genreCharts.first { $0.genre == genre }
    }

    func fetchGenreCharts(source: FirestoreSource = .default,
                          completion: @escaping (Bool, [GenreChart]?) -> Void) {
        Firestore.firestore()
            .collection(FirebasePaths.genreCharts.rawValue)
            .getDocuments(source: source) { snapshot, error in
                self.onMain {
                    guard error == nil, let snapshot else {
                        completion(false, nil)
                        return
                    }

                    let charts = snapshot.documents.compactMap {
                        GenreChart(id: $0.documentID, data: $0.data())
                    }
                    self.genreCharts = charts
                    completion(true, charts)
                }
            }
    }

    private func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }
}

private extension BookInternalTag {
    init(id: String,
         genre: BookInternalGenre,
         tag: String,
         title: String,
         isHomeEligible: Bool) {
        self.id = id
        self.genre = genre
        self.tag = tag
        self.title = title
        self.isHomeEligible = isHomeEligible
    }
}
