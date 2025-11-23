//
//  Card.swift
//  MTGCollectionApp
//
//  Created on 11/23/2025.
//

import Foundation
import SwiftData

/// Represents a Magic: The Gathering card from the Scryfall database
@Model
final class Card {
    /// Unique Scryfall ID
    var scryfallId: String
    
    /// Card name
    var name: String
    
    /// Card set code (e.g., "MH3", "BRO")
    var setCode: String
    
    /// Card set name
    var setName: String
    
    /// Collector number within the set
    var collectorNumber: String
    
    /// Mana cost (e.g., "{2}{U}{U}")
    var manaCost: String?
    
    /// Converted mana cost / mana value
    var manaValue: Double
    
    /// Card type line (e.g., "Creature — Human Wizard")
    var typeLine: String
    
    /// Oracle text (rules text)
    var oracleText: String?
    
    /// Colors (W, U, B, R, G)
    var colors: [String]
    
    /// Color identity for Commander format
    var colorIdentity: [String]
    
    /// Rarity (common, uncommon, rare, mythic)
    var rarity: String
    
    /// Image URI for card display
    var imageURI: String?
    
    /// Small image URI for list views
    var imageURISmall: String?
    
    /// Relationships
    @Relationship(deleteRule: .cascade, inverse: \CollectionEntry.card)
    var collectionEntries: [CollectionEntry]?
    
    init(
        scryfallId: String,
        name: String,
        setCode: String,
        setName: String,
        collectorNumber: String,
        manaCost: String? = nil,
        manaValue: Double = 0,
        typeLine: String,
        oracleText: String? = nil,
        colors: [String] = [],
        colorIdentity: [String] = [],
        rarity: String,
        imageURI: String? = nil,
        imageURISmall: String? = nil
    ) {
        self.scryfallId = scryfallId
        self.name = name
        self.setCode = setCode
        self.setName = setName
        self.collectorNumber = collectorNumber
        self.manaCost = manaCost
        self.manaValue = manaValue
        self.typeLine = typeLine
        self.oracleText = oracleText
        self.colors = colors
        self.colorIdentity = colorIdentity
        self.rarity = rarity
        self.imageURI = imageURI
        self.imageURISmall = imageURISmall
    }
}
