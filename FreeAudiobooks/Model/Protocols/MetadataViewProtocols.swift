//
//  MetadataViewProtocols.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 30/11/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation

/// Protocol for views that support downloading content
protocol DownloadableMetadataView: AnyObject {
    /// Handler called when the download button is tapped. Passes the view itself to the handler.
    var tappedDownloadHandler: ((DownloadableMetadataView) -> Void)? { get set }

    /// The content metadata associated with this view
    var contentMetadata: ReadableContentMetadata? { get }

    /// Updates the download button appearance based on current download state
    func updateDownloadElements()

    /// Starts the download animation (pulsing effect)
    func startDownloadAnimation()

    /// Updates the visible download progress.
    func updateDownloadProgress(_ progress: Float)

    /// Stops the download animation and restores normal appearance
    func stopDownloadAnimation()
}

/// Protocol for views that support saving/bookmarking content
protocol SaveableMetadataView: AnyObject {
    /// Handler called when the save button is tapped. Passes the view itself to the handler.
    var tappedSaveHandler: ((SaveableMetadataView) -> Void)? { get set }

    /// The content metadata associated with this view
    var contentMetadata: ReadableContentMetadata? { get }

    /// Updates the save button appearance based on current saved state
    func updateSaveElements()
}
