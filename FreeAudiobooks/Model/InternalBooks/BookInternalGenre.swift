//
//  BookInternalGenre.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 14/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

enum BookInternalGenre: String, CaseIterable {
    case romance
    case thriller
    case drama
    case mystery
    case fantasy
    case adventure
    case historical
    case scienceFiction
    case horror
    case comedy
    case kids

    var displayString: String {
        switch self {
        case .romance:
            return "Romance"
        case .thriller:
            return "Thriller"
        case .mystery:
            return "Mystery"
        case .horror:
            return "Horror"
        case .fantasy:
            return "Fantasy"
        case .scienceFiction:
            return "Sci-Fi"
        case .historical:
            return "Historical"
        case .drama:
            return "Drama"
        case .adventure:
            return "Adventure"
        case .comedy:
            return "Comedy"
        case .kids:
            return "Kids"
        }
    }

    var searchSymbolName: String {
        switch self {
        case .romance: return "heart.fill"
        case .thriller: return "bolt.fill"
        case .drama: return "theatermasks.fill"
        case .mystery: return "magnifyingglass"
        case .fantasy: return "sparkles"
        case .adventure: return "map.fill"
        case .historical: return "clock.fill"
        case .scienceFiction: return "atom"
        case .horror: return "moon.stars.fill"
        case .comedy: return "face.smiling.fill"
        case .kids: return "star.fill"
        }
    }

    var searchImageName: String {
        "\(rawValue)-search"
    }
}

// Romance

// Enemies to lovers romance
// Slow-burn small-town romance
// Second-chance romance
// Forbidden love romance
// Friends to lovers romance
// Historical regency romance
// Holiday romance

// Thriller

// Dark psychological thriller
// Fast-paced conspiracy thriller
// Domestic thriller in suburbia
// Noir-inspired crime thriller
// Techno-thriller with hacking stakes
// Action-packed international chase thriller
// Harlan Coben–style missing person thriller

// Mystery
// Cozy village mystery with an amateur sleuth
// Hardboiled detective mystery
// Locked-room puzzle mystery
// Police procedural mystery
// Historical whodunnit mystery
// Supernatural mystery with eerie clues
// Noir mystery in a rain-soaked city

// Horror

// Gothic haunted house horror
// Psychological body horror
// Folk horror in an isolated village
// Paranormal ghost horror
// Survival horror in the wilderness
// Cosmic Lovecraftian horror
// Slasher-style horror with rising tension

// Fantasy

// Epic high fantasy with magical kingdoms
// Dark fantasy with moral ambiguity
// Urban fantasy in a modern city
// Fairy-tale–inspired fantasy
// Sword-and-sorcery adventure fantasy
// Myth-inspired fantasy (Greek, Norse, etc.)
// Portal fantasy (characters crossing into another world)

// Science Fiction

// Hard sci-fi with technology focus
// Dystopian sci-fi society
// Space opera with interstellar conflict
// Cyberpunk sci-fi in neon cities
// Post-apocalyptic survival sci-fi
// First-contact alien encounter
// Time-travel paradox sci-fi

// Historical

// World War II drama
// Ancient Rome intrigue
// Medieval courtly intrigue
// 1920s Jazz Age setting
// Victorian London mystery
// American Civil War drama
// Renaissance Florence intrigue

// Drama

// Family saga drama
// Coming-of-age drama
// Domestic relationship drama
// Workplace power struggle drama
// War-torn society drama
// Small-town generational drama
// Character-driven psychological drama

// Adventure

// Swashbuckling pirate adventure
// Jungle exploration adventure
// Arctic survival expedition adventure
// Treasure-hunt quest adventure
// Lost-world discovery adventure
// Post-apocalyptic scavenger adventure
// Road-trip coming-of-age adventure

//Comedy

// Romantic comedy with awkward mishaps
// Satirical workplace comedy
// Witty family drama comedy
// Absurdist surreal comedy
// Parody of a well-known genre
// Dark comedy about everyday struggles
// Travel misadventure comedy

// Author Names //

// Romance

//Isabella Hart
//Julianne Rivers
//Leo Montgomery
//Clara Vale
//Adrian Blake

//Thriller

//Vincent Kane
//Harper Cross
//Sloane Mercer
//Felix Drake
//Marlowe Steele

//Mystery

//Eleanor Quinn
//Jasper Holt
//Margot Pierce
//Desmond Grey
//Lila Winslow

//Horror

//Damian Crowe
//Sylvia Blackwood
//Thorne Marlow
//Raven Leigh
//Lucinda Vale

//Fantasy

//Alaric Storm
//Seraphina Dusk
//Eamon Thorne
//Lyra Wren
//Caelan Frost

//Science Fiction

//Orion Vega
//Nova Sinclair
//Cassian Ryker
//Elara Quill
//Juno Trelaw

//Historical

//Beatrice Hawthorne
//Edmund Fairfax
//Cecilia Montrose
//Thaddeus Langley
//Arabella Crowne

//Drama

//Madeline Avery
//Simon Calder
//Vivienne Clarke
//Theodore Hensley
//Rosalind Keene

//Adventure

//Finn Gallagher
//Isla Quinn
//Dashiell Hunt
//Tessa Drake
//Ronan Wilde

//Comedy

//Poppy Winslet
//Maxie Chandler
//Jasper Lark
//Olive Penrose
//Felix Goodwin
