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

    let dynalinksRootURL = "https://links.freebooksapp.org"
    
    func getLaunchActionFromDeeplinkURL(url: URL) -> LaunchAction? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        
        var pathComponents = components.path.components(separatedBy: "/")
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
    case roadmap
    case section(sectionUUID: String)

    var descriptionString: String {
        switch self {
        case .bookInternal: return LaunchAction.bookInternalPath
        case .savedBooks: return LaunchAction.savedBooksPath
        case .roadmap: return LaunchAction.roadmapPath
        case .section: return LaunchAction.sectionPath
        }
    }
    
    static var bookInternalPath: String = "book-internal"
    static var savedBooksPath: String = "saved-books"
    static var roadmapPath: String = "roadmap"
    static var sectionPath: String = "section"
}
