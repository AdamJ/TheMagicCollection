//
//  DeckList.swift
//  MTGCollectionApp
//
//  Created on 11/23/2025.
//

import Foundation
import SwiftData

enum DeckType: String, Codable, CaseIterable {
    case commander = "Commander"
    case standard = "Standard (60)"
    case draft = "Draft/Sealed (40)"
    case wishList = "Wish List"
    
    var cardLimit: Int? {
        switch self {
        case .commander:
            return 100
        case .standard:
            return 60
        case .draft:
            return 40
        case .wishList:
            return nil // unlimited
        }
    }
    
    var copyLimit: Int {
        switch self {
        case .commander:
            return 1 // Singleton format
        case .standard, .draft:
            return 4
        case .wishList:
            return Int.max // No practical limit
        }
    }
    
    var supportsSideboard: Bool {
        switch self {
        case .standard, .draft:
            return true
        case .commander, .wishList:
            return false
        }
    }
    
    func sideboardLimit(isSealed: Bool) -> Int? {
        switch self {
        case .standard:
            return 15
        case .draft:
            return isSealed ? nil : 0 // Unlimited for sealed, none for regular draft
        case .commander, .wishList:
            return nil
        }
    }
}

/// Represents a deck or list created by the user
@Model
final class DeckList {
    /// Name of the deck/list
    var name: String
    
    /// Type of deck
    var deckType: DeckType
    
    /// Whether this is a sealed deck (for draft format)
    var isSealed: Bool
    
    /// Date created
    var dateCreated: Date
    
    /// Date last modified
    var dateModified: Date
    
    /// Optional notes about this deck
    var notes: String?
    
    /// Main deck entries
    @Relationship(deleteRule: .cascade, inverse: \DeckEntry.deckList)
    var mainDeck: [DeckEntry]?
    
    /// Sideboard entries
    @Relationship(deleteRule: .cascade, inverse: \DeckEntry.sideboardDeckList)
    var sideboard: [DeckEntry]?
    
    /// Computed property: total card count in main deck
    var mainDeckCount: Int {
        mainDeck?.reduce(0) { $0 + $1.quantity } ?? 0
    }
    
    /// Computed property: total card count in sideboard
    var sideboardCount: Int {
        sideboard?.reduce(0) { $0 + $1.quantity } ?? 0
    }
    
    /// Computed property: whether the deck is valid
    var isValid: Bool {
        // Check main deck limit
        if let limit = deckType.cardLimit, mainDeckCount > limit {
            return false
        }
        
        // Check sideboard limit
        if deckType.supportsSideboard {
            if let sideboardLimit = deckType.sideboardLimit(isSealed: isSealed) {
                if sideboardCount > sideboardLimit {
                    return false
                }
            }
        } else if sideboardCount > 0 {
            return false
        }
        
        // Check copy limits in main deck
        if let mainDeck = mainDeck {
            let copyLimit = deckType.copyLimit
            let cardCounts = Dictionary(grouping: mainDeck, by: { $0.collectionEntry?.card?.name ?? "" })
                .mapValues { entries in entries.reduce(0) { $0 + $1.quantity } }
            
            // Allow unlimited basic lands
            for (cardName, count) in cardCounts {
                if !isBasicLand(cardName) && count > copyLimit {
                    return false
                }
            }
        }
        
        return true
    }
    
    private func isBasicLand(_ cardName: String) -> Bool {
        let basicLands = ["Plains", "Island", "Swamp", "Mountain", "Forest", "Wastes"]
        return basicLands.contains(cardName)
    }
    
    init(
        name: String,
        deckType: DeckType,
        isSealed: Bool = false,
        dateCreated: Date = Date(),
        notes: String? = nil
    ) {
        self.name = name
        self.deckType = deckType
        self.isSealed = isSealed
        self.dateCreated = dateCreated
        self.dateModified = dateCreated
        self.notes = notes
    }
}
