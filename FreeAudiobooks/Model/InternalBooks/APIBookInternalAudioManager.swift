//
//  APIBookInternalAudioManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 26/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import UIKit
import FirebaseCore
import FirebaseStorage
import AVFoundation

enum AudiobookAccessResult {
    case downloaded(CDBookInternalAudio)
    case alreadyDownloaded
    case quotaExceeded
    case noAudio
    case failed(APIBookInternalAudioManager.AudioDownloadError)
}

enum AudiobookDownloadState {
    case idle
    case downloading(progress: Float)
    case downloaded(CDBookInternalAudio)
    case failed(APIBookInternalAudioManager.AudioDownloadError)

    var progress: Float? {
        if case let .downloading(progress) = self {
            return progress
        }
        return nil
    }
}

class APIBookInternalAudioManager {
    static let shared = APIBookInternalAudioManager()

    private final class ActiveDownload {
        var progressHandlers: [(Float) -> Void]
        var completionHandlers: [(AudiobookAccessResult) -> Void]

        init(progressHandler: @escaping (Float) -> Void, completion: @escaping (AudiobookAccessResult) -> Void) {
            self.progressHandlers = [progressHandler]
            self.completionHandlers = [completion]
        }
    }

    private var activeDownloads: [String: ActiveDownload] = [:]
    private var downloadStates: [String: AudiobookDownloadState] = [:]

    private init() {}
}

extension Notification.Name {
    static let audiobookDownloadStateDidChange = Notification.Name("audiobookDownloadStateDidChange")
}

// MARK: - Audio Download (moved from APIBookInternalManager)
extension APIBookInternalAudioManager {
    func downloadState(for bookUUID: String) -> AudiobookDownloadState {
        if let state = downloadStates[bookUUID] {
            return state
        }

        if let audio = CoreDataBookInternalAudioManager.shared.getDownloadedWithUUID(bookUUID: bookUUID) {
            return .downloaded(audio)
        }

        return .idle
    }

    func isDownloading(bookUUID: String) -> Bool {
        if case .downloading = downloadState(for: bookUUID) {
            return true
        }
        return false
    }

    func clearDownloadState(for bookUUID: String) {
        guard activeDownloads[bookUUID] == nil else { return }
        downloadStates[bookUUID] = nil
        NotificationCenter.default.post(
            name: .audiobookDownloadStateDidChange,
            object: self,
            userInfo: [
                "bookUUID": bookUUID,
                "state": AudiobookDownloadState.idle
            ]
        )
    }

    func downloadAudiobook(
        for contentMetadata: ReadableContentMetadata,
        language: AudiobookLanguage = .english,
        isTemporary: Bool = false,
        progressHandler: @escaping (Float) -> Void,
        completion: @escaping (AudiobookAccessResult) -> Void
    ) {
        guard
            let bookInternal = contentMetadata as? CDBookInternal,
            bookInternal.hasAnyAudiobook,
            let audioURL = bookInternal.audioURL(for: language) else {
            print("Audio download unavailable for content: \(contentMetadata.contentUUID), language: \(language.rawValue)")
            completion(.noAudio)
            return
        }

        guard AccountManager.shared.userIsSubscribed || ListeningQuotaManager.shared.canListen(contentUUID: bookInternal.contentUUID) else {
            print("Audio download blocked by listening quota for book: \(bookInternal.contentUUID)")
            completion(.quotaExceeded)
            return
        }

        if bookInternal.hasDownloadedAudio {
            print("Audio download skipped because audio already exists for book: \(bookInternal.contentUUID)")
            if let audio = bookInternal.downloadedAudio {
                setDownloadState(.downloaded(audio), for: bookInternal.contentUUID)
            }
            // Already acquired - the quota only charges for first-time acquisitions.
            completion(.alreadyDownloaded)
            return
        }

        if let activeDownload = activeDownloads[bookInternal.contentUUID],
           case let .downloading(progress) = downloadState(for: bookInternal.contentUUID) {
            print("Audio download already in progress for book: \(bookInternal.contentUUID), attaching listener at progress: \(progress)")
            activeDownload.progressHandlers.append(progressHandler)
            activeDownload.completionHandlers.append(completion)
            progressHandler(progress)
            return
        }

        activeDownloads[bookInternal.contentUUID] = ActiveDownload(
            progressHandler: progressHandler,
            completion: completion
        )
        print("Audio download queued for book: \(bookInternal.contentUUID), language: \(language.rawValue), url: \(audioURL)")
        setDownloadState(.downloading(progress: 0), for: bookInternal.contentUUID)

        downloadAndStoreAudioFile(
            from: audioURL,
            language: language,
            bookInternalUUID: bookInternal.contentUUID,
            isTemporary: isTemporary,
            progressHandler: { [weak self] progress in
                self?.handleDownloadProgress(progress, for: bookInternal.contentUUID)
            }
        ) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let audio):
                if !isTemporary {
                    DownloadTimestampManager.shared.recordAudioDownload(uuid: bookInternal.contentUUID)
                }
                self.recordQuotaAccessIfNeeded(contentUUID: bookInternal.contentUUID) { _ in
                    // Temporary downloads shouldn't surface as "downloaded" in the UI.
                    let finalState: AudiobookDownloadState = isTemporary ? .idle : .downloaded(audio)
                    self.setDownloadState(finalState, for: bookInternal.contentUUID)
                    self.completeActiveDownload(for: bookInternal.contentUUID, result: .downloaded(audio))
                }
            case .failed(let error):
                self.setDownloadState(.failed(error), for: bookInternal.contentUUID)
                self.completeActiveDownload(for: bookInternal.contentUUID, result: .failed(error))
            }
        }
    }

    func recordQuotaAccessIfNeeded(contentUUID: String, completion: @escaping (Bool) -> Void) {
        if AccountManager.shared.userIsSubscribed {
            completion(true)
        } else {
            ListeningQuotaManager.shared.recordSuccessfulListen(contentUUID: contentUUID, completion: completion)
        }
    }

    func downloadAndStoreAudioFile(from url: String, language: AudiobookLanguage, bookInternalUUID: String, isTemporary: Bool = false, progressHandler: @escaping (Float) -> Void, completion: @escaping (AudioDownloadResult) -> Void) {
        guard let audioURL = URL(string: url) else {
            print("Audio download invalid URL for book: \(bookInternalUUID), url: \(url)")
            completion(.failed(.invalidURL))
            return
        }

        print("Audio download started for book: \(bookInternalUUID), language: \(language.rawValue), url: \(audioURL.absoluteString)")

        let downloadTask = URLSession.shared.downloadTask(with: audioURL) { tempURL, response, error in
            func reportProgress(_ progress: Float) {
                DispatchQueue.main.async {
                    progressHandler(progress)
                }
            }

            func finish(_ result: AudioDownloadResult) {
                DispatchQueue.main.async {
                    completion(result)
                }
            }

            let httpResponse = response as? HTTPURLResponse
            if let httpResponse {
                print("Audio download response for book: \(bookInternalUUID), status: \(httpResponse.statusCode), expectedBytes: \(httpResponse.expectedContentLength), mimeType: \(httpResponse.mimeType ?? "nil")")
            } else {
                print("Audio download response for book: \(bookInternalUUID), response: \(String(describing: response))")
            }

            if let error = error {
                let nsError = error as NSError
                print("Audio download failed for book: \(bookInternalUUID), errorDomain: \(nsError.domain), errorCode: \(nsError.code), error: \(error.localizedDescription)")
                finish(.failed(.networkError(error)))
                return
            }

            if let httpResponse, !(200...299).contains(httpResponse.statusCode) {
                let statusError = NSError(
                    domain: "APIBookInternalAudioManager",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "Audio download HTTP \(httpResponse.statusCode)"]
                )
                print("Audio download failed for book: \(bookInternalUUID), bad status: \(httpResponse.statusCode)")
                finish(.failed(.networkError(statusError)))
                return
            }

            guard let tempURL = tempURL else {
                print("Audio download failed for book: \(bookInternalUUID), missing temp file URL")
                finish(.failed(.noData))
                return
            }

            let tempFileExists = FileManager.default.fileExists(atPath: tempURL.path)
            print("Audio download temp file for book: \(bookInternalUUID), path: \(tempURL.path), exists: \(tempFileExists)")

            do {
                // Update progress to 90% for file processing phase.
                reportProgress(0.9)

                let data = try Data(contentsOf: tempURL)
                print("Audio download read temp file for book: \(bookInternalUUID), bytes: \(data.count)")

                // Validate file size.
                if !CDBookInternalAudio.isFileSizeValid(data) {
                    print("Audio download rejected for book: \(bookInternalUUID), file too large, bytes: \(data.count)")
                    finish(.failed(.fileTooLarge))
                    return
                }

                // Get duration from the downloaded audio data.
                var duration: TimeInterval = 0.0
                do {
                    let audioPlayer = try AVAudioPlayer(data: data)
                    audioPlayer.prepareToPlay()
                    duration = audioPlayer.duration.rounded()
                    print("Audio download calculated duration for book: \(bookInternalUUID), duration: \(duration) seconds")
                } catch {
                    let nsError = error as NSError
                    print("Audio download duration calculation failed for book: \(bookInternalUUID), errorDomain: \(nsError.domain), errorCode: \(nsError.code), error: \(error.localizedDescription)")
                    duration = 0.0
                }

                // Update progress to 100% for persistence phase.
                reportProgress(1.0)

                // Store in CoreData.
                CoreDataBookInternalAudioManager.shared.persist(
                    bookUUID: bookInternalUUID,
                    language: language.rawValue,
                    audioData: data,
                    duration: duration,
                    originalURL: url,
                    isTemporary: isTemporary
                ) { savedAudio in
                    if let savedAudio = savedAudio {
                        print("Audio download persisted for book: \(bookInternalUUID), bytes: \(data.count), duration: \(duration)")
                        if duration > 0 {
                            AudioPlaybackProgressManager.shared.saveDuration(duration, for: bookInternalUUID)
                        }
                        completion(.success(savedAudio))
                    } else {
                        print("Audio download persist failed for book: \(bookInternalUUID)")
                        completion(.failed(.invalidAudioData))
                    }
                }
            } catch {
                let nsError = error as NSError
                print("Audio download temp file read failed for book: \(bookInternalUUID), path: \(tempURL.path), errorDomain: \(nsError.domain), errorCode: \(nsError.code), error: \(error.localizedDescription)")
                finish(.failed(.networkError(error)))
            }
        }

        // Observe download progress (cap at 80%)
        let progressObserver = downloadTask.progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async {
                progressHandler(Float(progress.fractionCompleted * 0.8))
            }
        }

        // Store observer to prevent deallocation
        objc_setAssociatedObject(downloadTask, "progressObserver", progressObserver, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        downloadTask.resume()
    }

    private func handleDownloadProgress(_ progress: Float, for bookUUID: String) {
        setDownloadState(.downloading(progress: progress), for: bookUUID)
        activeDownloads[bookUUID]?.progressHandlers.forEach { $0(progress) }
    }

    private func completeActiveDownload(for bookUUID: String, result: AudiobookAccessResult) {
        let completionHandlers = activeDownloads[bookUUID]?.completionHandlers ?? []
        activeDownloads[bookUUID] = nil
        completionHandlers.forEach { $0(result) }
    }

    private func setDownloadState(_ state: AudiobookDownloadState, for bookUUID: String) {
        downloadStates[bookUUID] = state
        NotificationCenter.default.post(
            name: .audiobookDownloadStateDidChange,
            object: self,
            userInfo: [
                "bookUUID": bookUUID,
                "state": state
            ]
        )
    }

    enum AudioDownloadResult {
        case success(CDBookInternalAudio)
        case failed(AudioDownloadError)
    }

    enum AudioDownloadError {
        case invalidURL
        case networkError(Error)
        case noData
        case fileTooLarge
        case invalidAudioData
        case storageError

        var localizedDescription: String {
            switch self {
            case .invalidURL:
                return "Invalid audio URL"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .noData:
                return "No audio data received"
            case .fileTooLarge:
                return "Audio file too large (max 100MB)"
            case .invalidAudioData:
                return " format"
            case .storageError:
                return "Failed to save audio file"
            }
        }
    }
}
