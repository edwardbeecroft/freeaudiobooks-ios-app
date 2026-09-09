//
//  DeeplinkManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 08/08/2019.
//  Copyright © 2019 FreeAudiobooks. All rights reserved.
//

import Foundation

class DeeplinkManager {
    static let shared = DeeplinkManager()
    private init() {}

    
    func getLaunchActionFromDeeplinkURL(url: URL) -> LaunchAction? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        
        guard url.scheme == "freeaudiobooks" || (url.scheme == "https" && url.host == "links.freeaudiobooksapp.com") else { return nil }
        let effectivePath = url.scheme == "freeaudiobooks" ? "/" + (url.host ?? "") + components.path : components.path
        var pathComponents = effectivePath.components(separatedBy: "/")
        // the first component is empty, it's just a "", so this removes it
        // the second component is "links", and we care about the next bit, so we remove that too
        pathComponents.removeFirst(1)
        
        if pathComponents.count > 0 {
            switch pathComponents[0] {
            case LaunchAction.bookInternalPath:
                if pathComponents.count > 1 {
                    return LaunchAction.bookInternal(uuid: pathComponents[1])
                }
                return nil
            case LaunchAction.genrePath:
                guard pathComponents.count >= 2,
                      let genre = BookInternalGenre(rawValue: pathComponents[1]) else { return nil }
                if pathComponents.count == 2 { return .genre(genre: genre) }
                guard pathComponents.count == 4, pathComponents[2] == "tag",
                      !pathComponents[3].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
                return .genreTag(genre: genre, tagID: pathComponents[3])
            case "library":
                guard pathComponents.count == 2,
                      let destination = LibraryDestination(rawValue: pathComponents[1]) else { return nil }
                return .library(destination: destination)
            case "discover": return .emailDiscovery
            case "onboardingEmailDiscount": return .onboardingEmailDiscount
            case "paywall":
                return pathComponents.count == 2 && pathComponents[1] == "onboardingEmailDiscount" ? .onboardingEmailDiscount : nil
            case LaunchAction.savedBooksPath: return LaunchAction.savedBooks
            case LaunchAction.roadmapPath: return LaunchAction.roadmap
            case LaunchAction.sectionPath:
                if pathComponents.count > 1 {
                    return LaunchAction.section(sectionUUID: pathComponents[1])
                }
                return nil
            default:
                return nil
            }
        }
        return nil
    }
}

enum LaunchAction: Equatable {
    case bookInternal(uuid: String)
    case savedBooks
    case onboardingEmailDiscount
    case emailDiscovery
    case genre(genre: BookInternalGenre)
    case genreTag(genre: BookInternalGenre, tagID: String)
    case library(destination: LibraryDestination)
    case roadmap
    case section(sectionUUID: String)

    var descriptionString: String {
        switch self {
        case .bookInternal: return LaunchAction.bookInternalPath
        case .emailDiscovery: return "discover"
        case .genre, .genreTag: return LaunchAction.genrePath
        case .library: return "library"
        case .onboardingEmailDiscount: return "onboardingEmailDiscount"
        case .savedBooks: return LaunchAction.savedBooksPath
        case .roadmap: return LaunchAction.roadmapPath
        case .section: return LaunchAction.sectionPath
        }
    }
    
    static let genrePath = "genre"
    static var bookInternalPath: String = "book-internal"
    static var savedBooksPath: String = "saved-books"
    static var roadmapPath: String = "roadmap"
    static var sectionPath: String = "section"
}

/// Explicit Library entry points. Downloads shows Saved with the Downloaded filter.
enum LibraryDestination: String, CaseIterable {
    case inProgress = "in-progress"
    case saved
    case downloads
}
