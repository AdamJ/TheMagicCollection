//
//  CollectionEntry.swift
//  MTGCollectionApp
//
//  Created on 11/23/2025.
//

import Foundation
import SwiftData

/// Represents a user's ownership of a specific card with quantity tracking
@Model
final class CollectionEntry {
    /// The card this entry refers to
    var card: Card?
    
    /// Total quantity owned
    var quantityOwned: Int
    
    /// Date added to collection
    var dateAdded: Date
    
    /// Optional notes about this card (e.g., condition, foil status)
    var notes: String?
    
    /// Relationships to deck entries
    @Relationship(deleteRule: .cascade, inverse: \DeckEntry.collectionEntry)
    var deckEntries: [DeckEntry]?
    
    /// Computed property: quantity available (not in use)
    var quantityAvailable: Int {
        let usedQuantity = deckEntries?.reduce(0) { $0 + $1.quantity } ?? 0
        return max(0, quantityOwned - usedQuantity)
    }
    
    /// Computed property: quantity in use across all decks
    var quantityInUse: Int {
        deckEntries?.reduce(0) { $0 + $1.quantity } ?? 0
    }
    
    init(
        card: Card,
        quantityOwned: Int,
        dateAdded: Date = Date(),
        notes: String? = nil
    ) {
        self.card = card
        self.quantityOwned = quantityOwned
        self.dateAdded = dateAdded
        self.notes = notes
    }
}
