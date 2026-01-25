//
//  ManualCardEntryView.swift
//  MTGCollectionApp
//
//  Created on 11/23/2025.
//

import SwiftUI
import SwiftData

struct ManualCardEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var searchResults: [Card] = []
    @State private var selectedCard: Card?
    @State private var quantity = 1
    @State private var notes = ""
    @State private var isSearching = false
    @State private var showManualEntry = false

    // Manual entry fields
    @State private var manualCardName = ""
    @State private var manualSetName = ""
    @State private var manualCollectorNumber = ""
    @State private var manualManaCost = ""
    @State private var manualTypeLine = ""
    @State private var manualRarity = "common"

    // Error handling
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("💡 Tip: Import the Scryfall database in Settings for the best card-adding experience with auto-complete and card images.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                }
                
                if !showManualEntry {
                    Section("Search for Card") {
                        TextField("Card name", text: $searchText)
                            #if os(iOS)
                            .textInputAutocapitalization(.words)
                            #endif
                            .onChange(of: searchText) { oldValue, newValue in
                                performSearch()
                            }
                        
                        if isSearching {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        }
                    }
                    
                    if !searchResults.isEmpty {
                        Section("Search Results") {
                            ForEach(searchResults.prefix(20), id: \.scryfallId) { card in
                                Button {
                                    selectedCard = card
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(card.name)
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                            
                                            Text("\(card.setName) · #\(card.collectorNumber)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedCard?.scryfallId == card.scryfallId {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    } else if !searchText.isEmpty && !isSearching {
                        Section {
                            Button {
                                manualCardName = searchText
                                showManualEntry = true
                            } label: {
                                Label("No results found. Enter card details manually", systemImage: "pencil")
                            }
                        }
                    }
                    
                    // Quick access to manual entry
                    if searchText.isEmpty && searchResults.isEmpty {
                        Section {
                            Button {
                                showManualEntry = true
                            } label: {
                                Label("Enter Card Details Manually", systemImage: "square.and.pencil")
                            }
                        }
                    }
                }
                
                if showManualEntry {
                    Section("Card Information") {
                        TextField("Card Name", text: $manualCardName)
                        TextField("Set Name", text: $manualSetName)
                        TextField("Collector Number (Optional)", text: $manualCollectorNumber)
                        TextField("Mana Cost (Optional)", text: $manualManaCost)
                        TextField("Type Line (Optional)", text: $manualTypeLine)
                        
                        Picker("Rarity", selection: $manualRarity) {
                            Text("Common").tag("common")
                            Text("Uncommon").tag("uncommon")
                            Text("Rare").tag("rare")
                            Text("Mythic").tag("mythic")
                        }
                    }
                    
                    Section {
                        Button {
                            showManualEntry = false
                            searchText = manualCardName
                            manualCardName = ""
                            manualSetName = ""
                            manualCollectorNumber = ""
                            manualManaCost = ""
                            manualTypeLine = ""
                            manualRarity = "common"
                            performSearch()
                        } label: {
                            Label("Search Database Instead", systemImage: "magnifyingglass")
                        }
                    }
                }
                
                if selectedCard != nil || (showManualEntry && !manualCardName.isEmpty) {
                    if let card = selectedCard {
                        Section("Card Details") {
                            HStack {
                                AsyncImage(url: URL(string: card.imageURISmall ?? "")) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    Rectangle()
                                        .fill(.gray.opacity(0.2))
                                }
                                .frame(width: 80, height: 112)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(card.name)
                                        .font(.headline)
                                    
                                    if let manaCost = card.manaCost {
                                        Text(manaCost)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Text(card.typeLine)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } else if showManualEntry && !manualCardName.isEmpty {
                        Section("Preview") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(manualCardName)
                                    .font(.headline)
                                
                                if !manualSetName.isEmpty {
                                    Text(manualSetName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                if !manualManaCost.isEmpty {
                                    Text(manualManaCost)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                if !manualTypeLine.isEmpty {
                                    Text(manualTypeLine)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Section("Quantity") {
                        Stepper("Quantity: \(quantity)", value: $quantity, in: 1...999)
                    }
                    
                    Section("Notes (Optional)") {
                        TextField("Add notes about this card", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
            }
            .navigationTitle("Add Card")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addCard()
                    }
                    .disabled(selectedCard == nil && (showManualEntry ? manualCardName.isEmpty : true))
                }
            }
            .alert("Error Adding Card", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred while adding the card. Please try again.")
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty, searchText.count >= 2 else {
            searchResults = []
            return
        }

        isSearching = true

        Task {
            let service = ScryfallService(modelContext: modelContext)

            do {
                let results = try service.searchCards(byName: searchText)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                    errorMessage = "Search failed: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func addCard() {
        do {
            if let card = selectedCard {
                // Adding from database search
                try addCardFromDatabase(card)
            } else if showManualEntry && !manualCardName.isEmpty {
                // Adding manual entry
                try addManualCard()
            }

            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to add card: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func addCardFromDatabase(_ card: Card) throws {
        // Check if card already exists in collection
        let cardId = card.scryfallId
        let predicate = #Predicate<CollectionEntry> { entry in
            entry.card?.scryfallId == cardId
        }
        
        let descriptor = FetchDescriptor<CollectionEntry>(predicate: predicate)
        let existingEntries = try modelContext.fetch(descriptor)
        
        if let existingEntry = existingEntries.first {
            // Update existing entry
            existingEntry.quantityOwned += quantity
            if !notes.isEmpty {
                if let existingNotes = existingEntry.notes {
                    existingEntry.notes = existingNotes + "\n" + notes
                } else {
                    existingEntry.notes = notes
                }
            }
        } else {
            // Create new entry
            let entry = CollectionEntry(
                card: card,
                quantityOwned: quantity,
                notes: notes.isEmpty ? nil : notes
            )
            modelContext.insert(entry)
        }
    }
    
    private func addManualCard() throws {
        // Create a new card with manual data
        let card = Card(
            scryfallId: UUID().uuidString,
            name: manualCardName,
            setCode: manualSetName.isEmpty ? "CUSTOM" : String(manualSetName.prefix(3).uppercased()),
            setName: manualSetName.isEmpty ? "Custom" : manualSetName,
            collectorNumber: manualCollectorNumber.isEmpty ? "0" : manualCollectorNumber,
            manaCost: manualManaCost.isEmpty ? nil : manualManaCost,
            manaValue: 0,
            typeLine: manualTypeLine.isEmpty ? "Unknown" : manualTypeLine,
            oracleText: nil,
            colors: [],
            colorIdentity: [],
            rarity: manualRarity
        )
        
        modelContext.insert(card)
        
        // Create collection entry for the manually added card
        let entry = CollectionEntry(
            card: card,
            quantityOwned: quantity,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(entry)
    }
}

#Preview {
    ManualCardEntryView()
        .modelContainer(for: [Card.self, CollectionEntry.self], inMemory: true)
}
