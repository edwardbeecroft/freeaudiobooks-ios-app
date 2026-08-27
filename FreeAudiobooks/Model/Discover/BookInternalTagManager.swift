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

    var firestoreData: [String: Any] {
        [
            BookInternalTagVariables.id.rawValue: id,
            BookInternalTagVariables.genre.rawValue: genre.rawValue,
            BookInternalTagVariables.tag.rawValue: tag,
            BookInternalTagVariables.title.rawValue: title,
            BookInternalTagVariables.isHomeEligible.rawValue: isHomeEligible
        ]
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

    var firestoreData: [String: Any] {
        [
            GenreChartVariables.genre.rawValue: genre.rawValue,
            GenreChartVariables.bookIDs.rawValue: bookIDs
        ]
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
    func fetchAllTags(source: FirestoreSource,
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

    func fetchAllTags(source: FirestoreSource,
                      completion: @escaping (Result<[BookInternalTag], Error>) -> Void) {
        Firestore.firestore()
            .collection(FirebasePaths.booksInternalTags.rawValue)
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
    private(set) var allAdminTagsByID: [String: BookInternalTag]?

    func eligibleTags(for genre: BookInternalGenre) -> [BookInternalTag]? {
        eligibleTagsByGenre[genre]
    }

    mutating func storeEligibleTags(_ tags: [BookInternalTag], for genre: BookInternalGenre) {
        eligibleTagsByGenre[genre] = tags.filter { $0.isHomeEligible && $0.genre == genre }
    }

    mutating func storeAllAdminTags(_ tags: [BookInternalTag]) {
        allAdminTagsByID = Dictionary(
            tags.map { ($0.id, $0) },
            uniquingKeysWith: { _, latest in latest }
        )

        // A full admin refresh must only refresh customer buckets that were already loaded. It
        // must not make every genre appear cached and prevent its future scoped Firestore query.
        for genre in Array(eligibleTagsByGenre.keys) {
            eligibleTagsByGenre[genre] = tags.filter { $0.isHomeEligible && $0.genre == genre }
        }
    }

    func allAdminTags() -> [BookInternalTag]? {
        allAdminTagsByID.map { Array($0.values) }
    }

    func adminTag(for tag: String, genre: BookInternalGenre) -> BookInternalTag? {
        allAdminTagsByID?.values.first { $0.genre == genre && $0.tag == tag }
    }

    mutating func reconcileSavedTag(_ tag: BookInternalTag) {
        if allAdminTagsByID != nil {
            allAdminTagsByID?[tag.id] = tag
        }

        // The ID may previously have belonged to another genre or may just have become
        // ineligible, so remove it from every bucket that is already resident first.
        for genre in Array(eligibleTagsByGenre.keys) {
            eligibleTagsByGenre[genre]?.removeAll { $0.id == tag.id }
        }

        // Do not create a destination bucket here: an absent key means that genre still needs its
        // proper scoped query. Only keep an already-loaded bucket coherent.
        if tag.isHomeEligible, eligibleTagsByGenre[tag.genre] != nil {
            eligibleTagsByGenre[tag.genre]?.append(tag)
        }
    }
}

final class BookInternalTagManager {
    static let shared = BookInternalTagManager()

    private let loader: BookInternalTagLoading
    private var cache = BookInternalTagCache()
    private var eligibleTagCompletions: [BookInternalGenre: [(Bool, [BookInternalTag]) -> Void]] = [:]
    private var adminTagCompletions: [(Bool, [BookInternalTag]) -> Void] = []
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

    func fetchAllBookInternalTagsForAdmin(source: FirestoreSource = .default,
                                          completion: @escaping (Bool, [BookInternalTag]) -> Void) {
        onMain { [self] in
            if !adminTagCompletions.isEmpty {
                adminTagCompletions.append(completion)
                return
            }

            adminTagCompletions = [completion]
            loader.fetchAllTags(source: source) { [weak self] result in
                self?.onMain { [weak self] in
                    guard let self else { return }
                    let completions = self.adminTagCompletions
                    self.adminTagCompletions.removeAll()
                    switch result {
                    case .success(let tags):
                        self.cache.storeAllAdminTags(tags)
                        completions.forEach { $0(true, tags) }
                    case .failure:
                        completions.forEach { $0(false, []) }
                    }
                }
            }
        }
    }

    func ensureAllBookInternalTagsLoadedForAdmin(completion: @escaping (Bool, [BookInternalTag]) -> Void) {
        onMain { [self] in
            if let tags = cache.allAdminTags() {
                completion(true, tags)
                return
            }
            fetchAllBookInternalTagsForAdmin(completion: completion)
        }
    }

    func adminBookInternalTag(for tag: String, genre: BookInternalGenre) -> BookInternalTag? {
        cache.adminTag(for: tag, genre: genre)
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

    func saveGenreChart(genre: BookInternalGenre,
                        bookIDs: [String],
                        completion: @escaping (Result<GenreChart, Error>) -> Void) {
        let requiredBookCount = GenreChartRules.requiredBookCount
        guard bookIDs.count == requiredBookCount, Set(bookIDs).count == requiredBookCount else {
            let error = NSError(domain: "BookInternalTagManager",
                                code: 2,
                                userInfo: [NSLocalizedDescriptionKey: "Genre charts require exactly \(requiredBookCount) unique books."])
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            return
        }

        let chart = GenreChart(id: genre.rawValue, genre: genre, bookIDs: bookIDs)
        Firestore.firestore()
            .collection(FirebasePaths.genreCharts.rawValue)
            .document(chart.id)
            .setData(chart.firestoreData) { error in
                DispatchQueue.main.async {
                    if let error {
                        completion(.failure(error))
                        return
                    }

                    self.upsertGenreChart(chart)
                    completion(.success(chart))
                }
            }
    }

    func ensureBookInternalTagExists(tag: String,
                                     title: String,
                                     genre: BookInternalGenre,
                                     completion: @escaping (Result<BookInternalTag, Error>) -> Void) {
        let normalizedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedTag.isEmpty, !trimmedTitle.isEmpty else {
            let error = NSError(domain: "BookInternalTagManager",
                                code: 1,
                                userInfo: [NSLocalizedDescriptionKey: "Missing tag or title."])
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            return
        }

        if let existingTag = adminBookInternalTag(for: normalizedTag, genre: genre) {
            DispatchQueue.main.async {
                completion(.success(existingTag))
            }
            return
        }

        let docID = "\(genre.rawValue)_\(normalizedTag)"
        let collection = Firestore.firestore().collection(FirebasePaths.booksInternalTags.rawValue)
        let documentRef = collection.document(docID)

        documentRef.getDocument { snapshot, error in
            if let error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            if
                let snapshot,
                snapshot.exists,
                let data = snapshot.data(),
                let existingTag = BookInternalTag(id: snapshot.documentID, data: data) {
                DispatchQueue.main.async {
                    self.upsertBookInternalTag(existingTag)
                    completion(.success(existingTag))
                }
                return
            }

            let data: [String: Any] = [
                BookInternalTagVariables.id.rawValue: docID,
                BookInternalTagVariables.genre.rawValue: genre.rawValue,
                BookInternalTagVariables.tag.rawValue: normalizedTag,
                BookInternalTagVariables.title.rawValue: trimmedTitle,
                BookInternalTagVariables.isHomeEligible.rawValue: false
            ]

            documentRef.setData(data, merge: true) { error in
                if let error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }

                guard let createdTag = BookInternalTag(id: docID, data: data) else {
                    let tagError = NSError(domain: "BookInternalTagManager",
                                           code: 2,
                                           userInfo: [NSLocalizedDescriptionKey: "Failed to create tag draft."])
                    DispatchQueue.main.async {
                        completion(.failure(tagError))
                    }
                    return
                }

                DispatchQueue.main.async {
                    self.upsertBookInternalTag(createdTag)
                    completion(.success(createdTag))
                }
            }
        }
    }

    func updateBookInternalTag(_ tag: BookInternalTag,
                               title: String,
                               isHomeEligible: Bool,
                               completion: @escaping (Result<BookInternalTag, Error>) -> Void) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            let error = NSError(domain: "BookInternalTagManager",
                                code: 3,
                                userInfo: [NSLocalizedDescriptionKey: "Missing tag title."])
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            return
        }

        let updatedTag = BookInternalTag(id: tag.id,
                                         genre: tag.genre,
                                         tag: tag.tag,
                                         title: trimmedTitle,
                                         isHomeEligible: isHomeEligible)

        Firestore.firestore()
            .collection(FirebasePaths.booksInternalTags.rawValue)
            .document(tag.id)
            .setData(updatedTag.firestoreData, merge: true) { error in
                if let error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }

                DispatchQueue.main.async {
                    self.upsertBookInternalTag(updatedTag)
                    completion(.success(updatedTag))
                }
            }
    }

    private func upsertBookInternalTag(_ tag: BookInternalTag) {
        cache.reconcileSavedTag(tag)
    }

    private func upsertGenreChart(_ chart: GenreChart) {
        if let existingIndex = genreCharts.firstIndex(where: { $0.genre == chart.genre }) {
            genreCharts[existingIndex] = chart
        } else {
            genreCharts.append(chart)
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
