//
//  CSVExportService.swift
//  MTGCollectionApp
//
//  Created on 11/23/2025.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

/// Service for exporting collection data to CSV format
@MainActor
class CSVExportService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Export entire collection to CSV
    func exportCollection() throws -> URL {
        let descriptor = FetchDescriptor<CollectionEntry>(sortBy: [SortDescriptor(\.dateAdded)])
        let entries = try modelContext.fetch(descriptor)
        
        var csvText = "Card Name,Set Code,Set Name,Collector Number,Quantity Owned,Quantity Available,Quantity In Use,Date Added,Notes\n"
        
        for entry in entries {
            guard let card = entry.card else { continue }
            
            let row = [
                escapeCSV(card.name),
                escapeCSV(card.setCode),
                escapeCSV(card.setName),
                escapeCSV(card.collectorNumber),
                String(entry.quantityOwned),
                String(entry.quantityAvailable),
                String(entry.quantityInUse),
                formatDate(entry.dateAdded),
                escapeCSV(entry.notes ?? "")
            ].joined(separator: ",")
            
            csvText.append(row + "\n")
        }
        
        return try saveToTempFile(csvText, filename: "MTG_Collection_\(Date().formatted(date: .numeric, time: .omitted)).csv")
    }
    
    /// Export a specific deck to CSV
    func exportDeck(_ deck: DeckList) throws -> URL {
        var csvText = "Deck: \(deck.name)\nType: \(deck.deckType.rawValue)\n\n"
        csvText += "Section,Card Name,Set Code,Collector Number,Quantity,Notes\n"
        
        // Export main deck
        if let mainDeck = deck.mainDeck {
            for entry in mainDeck {
                guard let card = entry.collectionEntry?.card else { continue }
                
                let row = [
                    "Main",
                    escapeCSV(card.name),
                    escapeCSV(card.setCode),
                    escapeCSV(card.collectorNumber),
                    String(entry.quantity),
                    escapeCSV(entry.notes ?? "")
                ].joined(separator: ",")
                
                csvText.append(row + "\n")
            }
        }
        
        // Export sideboard
        if let sideboard = deck.sideboard {
            for entry in sideboard {
                guard let card = entry.collectionEntry?.card else { continue }
                
                let row = [
                    "Sideboard",
                    escapeCSV(card.name),
                    escapeCSV(card.setCode),
                    escapeCSV(card.collectorNumber),
                    String(entry.quantity),
                    escapeCSV(entry.notes ?? "")
                ].joined(separator: ",")
                
                csvText.append(row + "\n")
            }
        }
        
        let filename = "\(deck.name.replacingOccurrences(of: " ", with: "_"))_\(Date().formatted(date: .numeric, time: .omitted)).csv"
        return try saveToTempFile(csvText, filename: filename)
    }
    
    /// Export all decks to CSV
    func exportAllDecks() throws -> URL {
        let descriptor = FetchDescriptor<DeckList>(sortBy: [SortDescriptor(\.name)])
        let decks = try modelContext.fetch(descriptor)
        
        var csvText = "Deck Name,Type,Main Deck Count,Sideboard Count,Is Valid,Date Created,Date Modified,Notes\n"
        
        for deck in decks {
            let row = [
                escapeCSV(deck.name),
                escapeCSV(deck.deckType.rawValue),
                String(deck.mainDeckCount),
                String(deck.sideboardCount),
                deck.isValid ? "Yes" : "No",
                formatDate(deck.dateCreated),
                formatDate(deck.dateModified),
                escapeCSV(deck.notes ?? "")
            ].joined(separator: ",")
            
            csvText.append(row + "\n")
        }
        
        return try saveToTempFile(csvText, filename: "MTG_All_Decks_\(Date().formatted(date: .numeric, time: .omitted)).csv")
    }
    
    // MARK: - Private Helpers
    
    private func escapeCSV(_ text: String) -> String {
        if text.contains(",") || text.contains("\"") || text.contains("\n") {
            return "\"\(text.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return text
    }
    
    private func formatDate(_ date: Date) -> String {
        date.formatted(date: .numeric, time: .shortened)
    }
    
    private func saveToTempFile(_ content: String, filename: String) throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(filename)
        
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
}
