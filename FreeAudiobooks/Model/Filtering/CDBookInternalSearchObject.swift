//
//  CDBookInternalSearchObject.swift
//  FreeAudiobooks
//
//  Created by Claude on 09/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

enum CDBookInternalSearchSortOption: String, CaseIterable {
    case relevance
    case popularity
    case newest
    case highestRated

    var displayTitle: String {
        switch self {
        case .relevance: return "Relevance"
        case .popularity: return "Popularity"
        case .newest: return "Newest"
        case .highestRated: return "Highest Rated"
        }
    }
}

enum CDBookInternalFormatFilter: String, CaseIterable {
    case any
    case ebook
    case audiobook

    static let filterDisplayOrder: [CDBookInternalFormatFilter] = [.audiobook, .ebook, .any]

    var displayTitle: String {
        switch self {
        case .any: return "Any"
        case .ebook: return "Ebook"
        case .audiobook: return "Audiobook"
        }
    }
}

enum CDBookInternalLengthBucket: String, CaseIterable {
    case short
    case medium
    case long

    var displayTitle: String {
        switch self {
        case .short: return "Short"
        case .medium: return "Medium"
        case .long: return "Long"
        }
    }

    var range: (min: Int?, max: Int?) {
        switch self {
        case .short: return (nil, 30)
        case .medium: return (30, 90)
        case .long: return (90, nil)
        }
    }

    static func from(min: Int?, max: Int?) -> CDBookInternalLengthBucket? {
        return allCases.first { $0.range.min == min && $0.range.max == max }
    }
}

enum CDBookInternalMinimumRating: String, CaseIterable {
    case any
    case threePlus
    case fourPlus
    case fourPointFivePlus

    var displayTitle: String {
        switch self {
        case .any: return "Any"
        case .threePlus: return "3★+"
        case .fourPlus: return "4★+"
        case .fourPointFivePlus: return "4.5★+"
        }
    }

    var threshold: Double? {
        switch self {
        case .any: return nil
        case .threePlus: return 3.0
        case .fourPlus: return 4.0
        case .fourPointFivePlus: return 4.5
        }
    }
}

/// Search object for filtering short stories (CDBookInternal)
class CDBookInternalSearchObject {
    
    // MARK: - Search Parameters
    var query: String?
    var genre: BookInternalGenre?
    var tag: BookInternalTag?
    var minReadingTime: Int?
    var maxReadingTime: Int?
    var sortOption: CDBookInternalSearchSortOption = .relevance
    var format: CDBookInternalFormatFilter = .any
    var minimumRating: CDBookInternalMinimumRating = .any
    var includeAdultContentForRomance: Bool = false
    
    // MARK: - Pagination
    var page: Int = 1
    var pageSize: Int = 32
    
    // MARK: - Computed Properties
    
    var hasFilters: Bool {
        return activeFilterCount > 0
    }
    
    var activeFilterCount: Int {
        var count = 0
        
        if query != nil { count += 1 }
        if genre != nil { count += 1 }
        if tag != nil { count += 1 }
        if minReadingTime != nil || maxReadingTime != nil { count += 1 }
        if format != .any { count += 1 }
        if minimumRating != .any { count += 1 }
        if genre == .romance && includeAdultContentForRomance { count += 1 }

        return count
    }
    
    // MARK: - Methods
    
    /// Clear all filters
    func clearAll() {
        query = nil
        genre = nil
        tag = nil
        minReadingTime = nil
        maxReadingTime = nil
        sortOption = .relevance
        format = .any
        minimumRating = .any
        includeAdultContentForRomance = false
        page = 1
    }
    
    /// Reset pagination
    func resetPagination() {
        page = 1
    }
    
    /// Remove a specific filter by ID
    func removeFilter(byId id: String) {
        switch id {
        case "query": query = nil
        case "genre":
            genre = nil
            tag = nil
        case "tag": tag = nil
        case "readingTime":
            minReadingTime = nil
            maxReadingTime = nil
        case "format":
            format = .any
        case "rating":
            minimumRating = .any
        case "adult":
            includeAdultContentForRomance = false
        case "sort":
            sortOption = .relevance
        default: break
        }
    }
    
    /// Copy current state
    func copy() -> CDBookInternalSearchObject {
        let copy = CDBookInternalSearchObject()
        copy.query = query
        copy.genre = genre
        copy.tag = tag
        copy.minReadingTime = minReadingTime
        copy.maxReadingTime = maxReadingTime
        copy.sortOption = sortOption
        copy.format = format
        copy.minimumRating = minimumRating
        copy.includeAdultContentForRomance = includeAdultContentForRomance
        copy.page = page
        copy.pageSize = pageSize
        return copy
    }
    
    /// Apply filters to a list of CDBookInternal objects
    func applyFiltersToStories(_ stories: [CDBookInternal]) -> [CDBookInternal] {
        var filteredStories = stories
        
        // Apply query filter
        if let query = query, !query.isEmpty {
            filteredStories = filteredStories.filter { story in
                guard let title = story.title,
                      let blurb = story.blurb,
                      let genreString = story.genreString else {
                    return false
                }
                return title.localizedCaseInsensitiveContains(query) ||
                       (story.authorName?.localizedCaseInsensitiveContains(query) ?? false) ||
                       blurb.localizedCaseInsensitiveContains(query) ||
                       genreString.localizedCaseInsensitiveContains(query)
            }
        }
        
        // Apply genre filter
        if let genre = genre {
            filteredStories = filteredStories.filter { story in
                return story.genreString == genre.rawValue
            }
        }

        // Tags are genre-scoped in the catalogue. Keep this as an exact identifier match so
        // similarly titled tags cannot bleed into one another.
        if let tag = tag {
            filteredStories = filteredStories.filter { story in
                story.tags.contains(tag.tag)
            }
        }
        
        // Apply listening time filter. Lower bound is exclusive, upper bound inclusive,
        // so each length bucket is disjoint (a 30-min book is Short only, a 90-min book Medium only).
        if let minTime = minReadingTime {
            filteredStories = filteredStories.filter { story in
                return story.listeningTimeMinutesRounded > minTime
            }
        }
        
        if let maxTime = maxReadingTime {
            filteredStories = filteredStories.filter { story in
                return story.listeningTimeMinutesRounded <= maxTime
            }
        }

        // Apply format filter
        switch format {
        case .any, .ebook:
            break
        case .audiobook:
            filteredStories = filteredStories.filter { $0.hasAnyAudiobook }
        }

        // Apply minimum rating
        if let ratingThreshold = minimumRating.threshold {
            filteredStories = filteredStories.filter { $0.rating >= ratingThreshold }
        }

        // Romance-only adult toggle. Default behavior excludes adult Romance unless explicitly included.
        if genre == .romance && !includeAdultContentForRomance {
            filteredStories = filteredStories.filter { !$0.containsAdultContent }
        }
        
        return filteredStories
    }

    var selectedLengthBucket: CDBookInternalLengthBucket? {
        CDBookInternalLengthBucket.from(min: minReadingTime, max: maxReadingTime)
    }

    func setLengthBucket(_ bucket: CDBookInternalLengthBucket?) {
        let range = bucket?.range
        minReadingTime = range?.min
        maxReadingTime = range?.max
    }
}
