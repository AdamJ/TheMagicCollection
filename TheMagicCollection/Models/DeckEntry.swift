//
//  DeckEntry.swift
//  MTGCollectionApp
//
//  Created on 11/23/2025.
//

import Foundation
import SwiftData

/// Represents a card entry within a deck or list
@Model
final class DeckEntry {
    /// Reference to the collection entry (marks card as in-use)
    var collectionEntry: CollectionEntry?
    
    /// The deck this entry belongs to (main deck)
    var deckList: DeckList?
    
    /// The deck this entry belongs to (sideboard)
    var sideboardDeckList: DeckList?
    
    /// Quantity of this card in the deck
    var quantity: Int
    
    /// Date added to deck
    var dateAdded: Date
    
    /// Optional notes specific to this card in this deck
    var notes: String?
    
    /// Computed property: whether this is a sideboard entry
    var isSideboard: Bool {
        sideboardDeckList != nil
    }
    
    /// Computed property: the parent deck list
    var parentDeck: DeckList? {
        deckList ?? sideboardDeckList
    }
    
    init(
        collectionEntry: CollectionEntry,
        deckList: DeckList? = nil,
        sideboardDeckList: DeckList? = nil,
        quantity: Int,
        dateAdded: Date = Date(),
        notes: String? = nil
    ) {
        self.collectionEntry = collectionEntry
        self.deckList = deckList
        self.sideboardDeckList = sideboardDeckList
        self.quantity = quantity
        self.dateAdded = dateAdded
        self.notes = notes
    }
}
