//
//  RecapManager.swift
//  FreeAudiobooks
//
//  Created by Claude on 28/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import Network

final class RecapManager {

    static let shared = RecapManager()
    private init() {
        setupNetworkMonitoring()
    }

    private let networkMonitor = NWPathMonitor()
    private var isConnected = true

    // MARK: - Eligibility

    /// Returns true if the recap section should be shown for this book
    func shouldShowRecapSection(for metadata: ReadableContentMetadata) -> Bool {
        // Check remote config flag first
        guard RCValues.shared.bool(forKey: .isRecapFeatureEnabled) else {
            return false
        }

        // Must have started reading
        guard let offset = ReadingUserDefaults.getOffsetForBookWithUUID(metadata.contentUUID),
              offset.hasStartedReading else {
            return false
        }

        // Must have read at least 1 section
        guard offset.currentSection >= 1 || offset.currentSectionYOffset > 300 else {
            return false
        }

        // Must not be completed
        return !AccountManager.shared.userHasCompletedBookInternalWithUUID(metadata.contentUUID)
    }

    // MARK: - Generate Recap

    func generateRecap(
        for metadata: ReadableContentMetadata,
        content: ReadableContent,
        recapLength: String = "medium",
        completion: @escaping (Result<RecapResponse, RecapError>) -> Void
    ) {
        // Check network connectivity
        guard isConnected else {
            // Try to return cached version if available
            if let cached = RecapCacheManager.shared.getCachedRecap(for: metadata.contentUUID) {
                let response = RecapResponse(
                    recap: cached.recap,
                    bookUUID: cached.bookUUID,
                    sectionsCovered: cached.sectionsCovered,
                    cacheKey: cached.cacheKey
                )
                completion(.success(response))
            } else {
                completion(.failure(.offline))
            }
            return
        }

        // Get reading offset
        guard let offset = ReadingUserDefaults.getOffsetForBookWithUUID(metadata.contentUUID) else {
            completion(.failure(.needsMoreReading))
            return
        }

        // Get sections read
        let sectionsArray = content.sectionsArray
        let currentIndex = min(offset.currentSection, sectionsArray.count - 1)

        // Build sections array with partial current section based on scroll position
        var sectionsRead: [String] = []

        // Add all fully completed sections
        if currentIndex > 0 {
            sectionsRead = Array(sectionsArray.prefix(currentIndex))
        }

        // Add partial current section based on how far user has scrolled
        if offset.currentSectionTotalYOffset > 0 {
            let readPercentage = min(1.0, max(0.0, offset.currentSectionYOffset / offset.currentSectionTotalYOffset))

            // Only include if they've read at least 10% of the section
            if readPercentage >= 0.1 {
                let currentSectionText = sectionsArray[currentIndex]
                let charsToInclude = Int(Double(currentSectionText.count) * readPercentage)

                if charsToInclude > 100 { // At least 100 chars to be meaningful
                    let partialSection = String(currentSectionText.prefix(charsToInclude))
                    sectionsRead.append(partialSection)
                }
            }
        }

        guard !sectionsRead.isEmpty else {
            completion(.failure(.needsMoreReading))
            return
        }

        // Calculate progress
        let progress = ReadingUserDefaults.progressForBookWithUUID(metadata.contentUUID) ?? 0

        // Check cache first
        let cacheKey = "\(metadata.contentUUID)_\(currentIndex)_\(sectionsRead.count)_\(recapLength)"
        if let cached = RecapCacheManager.shared.getCachedRecap(for: metadata.contentUUID, cacheKey: cacheKey) {
            let response = RecapResponse(
                recap: cached.recap,
                bookUUID: cached.bookUUID,
                sectionsCovered: cached.sectionsCovered,
                cacheKey: cached.cacheKey
            )
            completion(.success(response))
            return
        }

        // Clean sections to remove problematic control characters
        let cleanedSections = sectionsRead.map { section in
            // Replace problematic characters while preserving readability
            section
                .replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")
                .replacingOccurrences(of: "\t", with: " ")
        }

        // Calculate total words read
        let wordsRead = cleanedSections.reduce(0) { total, section in
            total + section.split(whereSeparator: { $0.isWhitespace }).count
        }

        // Build request
        let request = RecapRequest(
            bookUUID: metadata.contentUUID,
            bookTitle: metadata.title ?? "Unknown Book",
            sectionsRead: cleanedSections,
            currentSectionIndex: currentIndex,
            totalSections: sectionsArray.count,
            readingProgressPercent: progress,
            wordsRead: wordsRead,
            recapLength: recapLength
        )

        // Make API call
        makeAPIRequest(request: request, completion: completion)
    }

    // MARK: - Private Methods

    private func makeAPIRequest(
        request: RecapRequest,
        completion: @escaping (Result<RecapResponse, RecapError>) -> Void
    ) {
        guard let url = GenerateEndpoint.generateBookRecap.url else {
            completion(.failure(.invalidResponse))
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 30  // 30 second timeout for fast response

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            completion(.failure(.networkError(error)))
            return
        }

        print("[RecapManager] Making API request to: \(url)")

        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[RecapManager] Network error: \(error.localizedDescription)")
                    completion(.failure(.networkError(error)))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("[RecapManager] Invalid response - not HTTP")
                    completion(.failure(.invalidResponse))
                    return
                }

                print("[RecapManager] HTTP status: \(httpResponse.statusCode)")

                guard let data = data else {
                    print("[RecapManager] No data in response")
                    completion(.failure(.invalidResponse))
                    return
                }

                // Handle error responses
                if httpResponse.statusCode != 200 {
                    let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
                    print("[RecapManager] Error response: \(responseString)")
                    if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                       let errorMessage = errorResponse["error"] {
                        completion(.failure(.serverError(errorMessage)))
                    } else {
                        completion(.failure(.serverError("Server error: \(httpResponse.statusCode)")))
                    }
                    return
                }

                // Parse success response
                do {
                    let recapResponse = try JSONDecoder().decode(RecapResponse.self, from: data)
                    print("[RecapManager] Success! Recap length: \(recapResponse.recap.count) chars")

                    // Cache the response
                    RecapCacheManager.shared.cacheRecap(recapResponse)

                    completion(.success(recapResponse))
                } catch {
                    let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
                    print("[RecapManager] JSON decode error: \(error). Response: \(responseString)")
                    completion(.failure(.invalidResponse))
                }
            }
        }

        task.resume()
    }

    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
        }
        let queue = DispatchQueue(label: "RecapNetworkMonitor")
        networkMonitor.start(queue: queue)
    }
}
