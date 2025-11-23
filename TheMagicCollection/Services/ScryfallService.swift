//
//  ScryfallService.swift
//  MTGCollectionApp
//
//  Created on 11/23/2025.
//

import Foundation
import SwiftData

/// Service for loading and querying Scryfall card data
@MainActor
class ScryfallService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Load Scryfall bulk data from a local JSON file
    /// Expected format: Array of card objects from Scryfall bulk data
    func loadBulkData(from fileURL: URL) async throws {
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let scryfallCards = try decoder.decode([ScryfallCard].self, from: data)
        
        // Import cards in batches to avoid memory issues
        let batchSize = 100
        for batch in scryfallCards.chunked(into: batchSize) {
            for scryfallCard in batch {
                // Check if card already exists
                let predicate = #Predicate<Card> { card in
                    card.scryfallId == scryfallCard.id
                }
                
                let descriptor = FetchDescriptor<Card>(predicate: predicate)
                let existingCards = try modelContext.fetch(descriptor)
                
                if existingCards.isEmpty {
                    let card = Card(
                        scryfallId: scryfallCard.id,
                        name: scryfallCard.name,
                        setCode: scryfallCard.set,
                        setName: scryfallCard.setName,
                        collectorNumber: scryfallCard.collectorNumber,
                        manaCost: scryfallCard.manaCost,
                        manaValue: scryfallCard.cmc,
                        typeLine: scryfallCard.typeLine,
                        oracleText: scryfallCard.oracleText,
                        colors: scryfallCard.colors ?? [],
                        colorIdentity: scryfallCard.colorIdentity ?? [],
                        rarity: scryfallCard.rarity,
                        imageURI: scryfallCard.imageUris?.normal,
                        imageURISmall: scryfallCard.imageUris?.small
                    )
                    modelContext.insert(card)
                }
            }
            
            try modelContext.save()
        }
    }
    
    /// Search for cards by name
    func searchCards(byName name: String) throws -> [Card] {
        let predicate = #Predicate<Card> { card in
            card.name.localizedStandardContains(name)
        }
        
        let descriptor = FetchDescriptor<Card>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        return try modelContext.fetch(descriptor)
    }
    
    /// Search for cards by color
    func searchCards(byColor colors: [String]) throws -> [Card] {
        let descriptor = FetchDescriptor<Card>(sortBy: [SortDescriptor(\.name)])
        let allCards = try modelContext.fetch(descriptor)
        
        return allCards.filter { card in
            colors.allSatisfy { card.colors.contains($0) }
        }
    }
    
    /// Search for cards by name and color
    func searchCards(byName name: String, colors: [String]) throws -> [Card] {
        let predicate = #Predicate<Card> { card in
            card.name.localizedStandardContains(name)
        }
        
        let descriptor = FetchDescriptor<Card>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        let nameFilteredCards = try modelContext.fetch(descriptor)
        
        if colors.isEmpty {
            return nameFilteredCards
        }
        
        return nameFilteredCards.filter { card in
            colors.allSatisfy { card.colors.contains($0) }
        }
    }
    
    /// Find a card by Scryfall ID
    func findCard(byScryfallId id: String) throws -> Card? {
        let predicate = #Predicate<Card> { card in
            card.scryfallId == id
        }
        
        let descriptor = FetchDescriptor<Card>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }
    
    /// Find cards by set and collector number
    func findCards(set: String, collectorNumber: String) throws -> [Card] {
        let predicate = #Predicate<Card> { card in
            card.setCode == set && card.collectorNumber == collectorNumber
        }
        
        let descriptor = FetchDescriptor<Card>(predicate: predicate)
        return try modelContext.fetch(descriptor)
    }
}

// MARK: - Scryfall Data Models

struct ScryfallCard: Codable {
    let id: String
    let name: String
    let set: String
    let setName: String
    let collectorNumber: String
    let manaCost: String?
    let cmc: Double
    let typeLine: String
    let oracleText: String?
    let colors: [String]?
    let colorIdentity: [String]?
    let rarity: String
    let imageUris: ImageUris?
    
    struct ImageUris: Codable {
        let small: String?
        let normal: String?
        let large: String?
    }
}

// MARK: - Array Extension for Chunking

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
