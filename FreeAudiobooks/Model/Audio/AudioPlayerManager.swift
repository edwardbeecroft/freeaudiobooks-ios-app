//
//  AudioPlayerManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 26/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer
import Kingfisher

protocol AudioPlayerManagerDelegate: AnyObject {
    func audioPlayerDidUpdateTime(_ currentTime: TimeInterval, duration: TimeInterval)
    func audioPlayerDidChangePlaybackState(_ isPlaying: Bool)
    func audioPlayerSleepTimerDidChange(_ selectedDuration: TimeInterval?)
    func audioPlayerDidFinishPlaying()
    func audioPlayerDidFail(with error: Error)
}

class AudioPlayerManager: NSObject {

    static let shared = AudioPlayerManager()

    weak var delegate: AudioPlayerManagerDelegate?

    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    private var sleepTimer: Timer?
    private var audioData: Data?
    private var bookMetadata: (title: String, coverImageURL: String)?
    private var currentBookUUID: String?

    // Playback state
    private(set) var isPlaying: Bool = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var playbackRate: Float = 1.0

    // Sleep timer state
    private(set) var activeSleepTimerDuration: TimeInterval?
    private(set) var sleepTimerEndDate: Date?

    var sleepTimerRemainingTime: TimeInterval? {
        guard let sleepTimerEndDate else { return nil }
        return max(0, sleepTimerEndDate.timeIntervalSinceNow)
    }

    // Position saving
    private var savedPosition: TimeInterval = 0

    override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommandCenter()
        setupBackgroundNotifications()
    }

    deinit {
        stopPlayback()
        saveCurrentPosition()
        NotificationCenter.default.removeObserver(self)
        UIApplication.shared.endReceivingRemoteControlEvents()
    }
}

// MARK: - Public Interface
extension AudioPlayerManager {

    func loadAudio(data: Data, bookTitle: String, coverImageURL: String, bookUUID: String, savedPosition: TimeInterval = 0) throws {
        cancelSleepTimer()

        self.audioData = data
        self.bookMetadata = (title: bookTitle, coverImageURL: coverImageURL)
        self.currentBookUUID = bookUUID
        self.savedPosition = savedPosition

        // Create audio player
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()
        audioPlayer?.enableRate = true
        audioPlayer?.rate = playbackRate

        // Get duration from AVAudioPlayer
        let audioPlayerDuration = audioPlayer?.duration ?? 0

        // Get more precise duration from AVAsset
        //let preciseDuration = getPreciseDuration(from: data)

        // Log both durations for comparison
//        print("🎵 Duration comparison:")
//        print("   AVAudioPlayer duration: \(formatTime(audioPlayerDuration))")
//        print("   AVAsset precise duration: \(formatTime(preciseDuration))")
//        print("   Difference: \(formatTime(abs(audioPlayerDuration - preciseDuration)))")

        // Use AVAudioPlayer duration (appears more accurate for actual playback content)
        // AVAsset sometimes includes padding/metadata that extends beyond actual audio
        duration = audioPlayerDuration //> 0 ? audioPlayerDuration : preciseDuration
        if duration > 0 {
            AudioPlaybackProgressManager.shared.saveDuration(duration, for: bookUUID)
        }

        // Restore saved position
        if savedPosition > 0 && savedPosition < duration {
            audioPlayer?.currentTime = savedPosition
            currentTime = savedPosition
        }

        updateNowPlayingInfo()
        delegate?.audioPlayerDidUpdateTime(currentTime, duration: duration)
    }

    func play() {
        guard let player = audioPlayer else { return }

        do {
            try AVAudioSession.sharedInstance().setActive(true)
            guard player.play() else {
                cancelSleepTimer()
                isPlaying = false
                stopProgressTimer()
                updateNowPlayingInfo()
                delegate?.audioPlayerDidChangePlaybackState(isPlaying)
                delegate?.audioPlayerDidFail(with: playbackError(message: "Failed to start audio playback."))
                return
            }

            isPlaying = true
            startProgressTimer()
            updateNowPlayingInfo()
            delegate?.audioPlayerDidChangePlaybackState(isPlaying)
        } catch {
            cancelSleepTimer()
            delegate?.audioPlayerDidFail(with: error)
        }
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopProgressTimer()
        updateNowPlayingInfo()
        delegate?.audioPlayerDidChangePlaybackState(isPlaying)
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func seekTo(_ time: TimeInterval) {
        guard let player = audioPlayer else { return }
        let clampedTime = max(0, min(time, duration))
        // Pause the audio queue before mutating currentTime. Setting AVAudioPlayer.currentTime
        // while the queue is actively decoding can crash on the converter thread
        // (libAudioToolboxUtility `CrashIfClientProvidedBogusAudioBufferList`), especially with
        // VBR MP3/AAC files. Pausing first stops the converter, then play() resumes from the new time.
        let wasPlaying = player.isPlaying
        player.pause()
        player.currentTime = clampedTime
        if wasPlaying { player.play() }
        currentTime = clampedTime
        updateNowPlayingInfo()
        delegate?.audioPlayerDidUpdateTime(currentTime, duration: duration)
    }

    func skipForward(_ seconds: TimeInterval = 15) {
        seekTo(currentTime + seconds)
    }

    func skipBackward(_ seconds: TimeInterval = 15) {
        seekTo(currentTime - seconds)
    }

    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        audioPlayer?.rate = rate
        updateNowPlayingInfo()
    }

    func setSleepTimer(duration: TimeInterval) {
        guard duration > 0 else {
            cancelSleepTimer()
            return
        }

        sleepTimer?.invalidate()

        activeSleepTimerDuration = duration
        sleepTimerEndDate = Date().addingTimeInterval(duration)

        let timer = Timer(timeInterval: duration, repeats: false) { [weak self] _ in
            self?.sleepTimerDidExpire()
        }
        sleepTimer = timer
        RunLoop.main.add(timer, forMode: .common)

        delegate?.audioPlayerSleepTimerDidChange(duration)
    }

    func cancelSleepTimer() {
        guard sleepTimer != nil || activeSleepTimerDuration != nil || sleepTimerEndDate != nil else { return }

        clearSleepTimerState()
        delegate?.audioPlayerSleepTimerDidChange(nil)
    }

    func stopPlayback() {
        cancelSleepTimer()
        audioPlayer?.stop()
        isPlaying = false
        stopProgressTimer()
        currentTime = 0

        // Clear now playing info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil

        delegate?.audioPlayerDidChangePlaybackState(isPlaying)
    }

    func getCurrentPosition() -> TimeInterval {
        return audioPlayer?.currentTime ?? currentTime
    }
}

// MARK: - Private Methods
private extension AudioPlayerManager {

    func sleepTimerDidExpire() {
        clearSleepTimerState()
        delegate?.audioPlayerSleepTimerDidChange(nil)

        guard isPlaying else { return }

        currentTime = audioPlayer?.currentTime ?? currentTime
        if let currentBookUUID, currentTime > 0 {
            AudioPositionManager.shared.savePosition(currentTime, for: currentBookUUID)
        }
        pause()
    }

    func clearSleepTimerState() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        activeSleepTimerDuration = nil
        sleepTimerEndDate = nil
    }

    func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.allowAirPlay, .allowBluetoothHFP])
            UIApplication.shared.beginReceivingRemoteControlEvents()
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Play command
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }

        // Pause command
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        // Toggle play/pause command
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }

        // Skip forward command
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            let interval = (event as? MPSkipIntervalCommandEvent)?.interval ?? 15
            self?.skipForward(interval)
            return .success
        }
        commandCenter.skipForwardCommand.preferredIntervals = [15]

        // Skip backward command
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            let interval = (event as? MPSkipIntervalCommandEvent)?.interval ?? 15
            self?.skipBackward(interval)
            return .success
        }
        commandCenter.skipBackwardCommand.preferredIntervals = [15]

        // Seek command
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seekTo(event.positionTime)
            return .success
        }
    }

    func setupBackgroundNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioSessionInterrupted),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioRouteChanged),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func appWillResignActive() {
        saveCurrentPosition()
    }

    @objc private func appWillTerminate() {
        saveCurrentPosition()
    }

    @objc private func audioSessionInterrupted(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue),
            type == .began,
            isPlaying
        else { return }

        pause()
    }

    @objc private func audioRouteChanged(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue),
            reason == .oldDeviceUnavailable,
            isPlaying
        else { return }

        pause()
    }

    private func saveCurrentPosition() {
        if let bookUUID = currentBookUUID, currentTime > 0 {
            AudioPositionManager.shared.savePosition(currentTime, for: bookUUID)
        }
    }

    func updateNowPlayingInfo() {
        guard let metadata = bookMetadata else { return }

        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: metadata.title,
            MPMediaItemPropertyArtist: "FreeAudiobooks",
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? playbackRate : 0.0
        ]

        // Set artwork - try to load actual cover image or use placeholder
        setNowPlayingArtwork(from: metadata.coverImageURL) { artwork in
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }

        // Set initial now playing info without artwork first for immediate display
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func setNowPlayingArtwork(from imageURLString: String, completion: @escaping (MPMediaItemArtwork?) -> Void) {
        // Try to load image from URL
        guard let imageURL = URL(string: imageURLString) else {
            completion(createFallbackArtwork())
            return
        }
        
        let resource = KF.ImageResource(downloadURL: imageURL)
        KingfisherManager.shared.retrieveImage(with: resource) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let value):
                    print("Image: \(value.image). Got from: \(value.cacheType)")
                    let image = value.image
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    completion(artwork)
                case .failure(let error):
                    print("Error: \(error)")
                    completion(self?.createFallbackArtwork())
                }
            }
        }
    }

    private func createFallbackArtwork() -> MPMediaItemArtwork? {
        guard let bookIcon = UIImage(systemName: "book.fill") else { return nil }

        // Create a larger, better quality fallback image
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        let fallbackImage = renderer.image { context in
            // Fill background
            UIColor.systemGray6.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Draw book icon in center
            let iconSize: CGFloat = 150
            let iconRect = CGRect(
                x: (size.width - iconSize) / 2,
                y: (size.height - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )

            UIColor.systemGray3.setFill()
            bookIcon.draw(in: iconRect)
        }

        return MPMediaItemArtwork(boundsSize: fallbackImage.size) { _ in fallbackImage }
    }

    func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime

            // Auto-save position every few seconds during playback
            if let bookUUID = self.currentBookUUID, self.currentTime > 0 {
                AudioPositionManager.shared.savePosition(self.currentTime, for: bookUUID)
            }

            self.delegate?.audioPlayerDidUpdateTime(self.currentTime, duration: self.duration)
        }
    }

    func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    func playbackError(message: String) -> NSError {
        NSError(
            domain: "AudioPlayerManager",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioPlayerManager: AVAudioPlayerDelegate {

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        cancelSleepTimer()
        isPlaying = false
        stopProgressTimer()
        currentTime = 0
        updateNowPlayingInfo()
        delegate?.audioPlayerDidChangePlaybackState(isPlaying)
        delegate?.audioPlayerDidFinishPlaying()
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        cancelSleepTimer()
        isPlaying = false
        stopProgressTimer()
        updateNowPlayingInfo()
        delegate?.audioPlayerDidChangePlaybackState(isPlaying)
        delegate?.audioPlayerDidFail(with: error ?? playbackError(message: "Audio playback failed."))
    }
}

// MARK: - Duration Calculation
extension AudioPlayerManager {
    private func getPreciseDuration(from audioData: Data) -> TimeInterval {
        // Create temporary file for AVAsset
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent("temp_audio_\(UUID().uuidString).m4a")

        do {
            // Write audio data to temporary file
            try audioData.write(to: tempFileURL)

            // Create AVURLAsset with precise timing
            let asset = AVURLAsset(url: tempFileURL, options: [
                AVURLAssetPreferPreciseDurationAndTimingKey: true
            ])

            // Get precise duration
            let duration = CMTimeGetSeconds(asset.duration)

            // Clean up temporary file
            try? FileManager.default.removeItem(at: tempFileURL)

            return duration.isFinite ? duration : 0

        } catch {
            print("❌ Failed to get precise duration: \(error)")
            // Clean up on error
            try? FileManager.default.removeItem(at: tempFileURL)
            return 0
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
