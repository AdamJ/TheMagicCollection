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
    
    var body: some View {
        NavigationStack {
            Form {
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
                }
                
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
                    .disabled(selectedCard == nil)
                }
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
                }
            }
        }
    }
    
    private func addCard() {
        guard let card = selectedCard else { return }
        
        // Check if card already exists in collection
        let cardId = card.scryfallId
        let predicate = #Predicate<CollectionEntry> { entry in
            entry.card?.scryfallId == cardId
        }
        
        let descriptor = FetchDescriptor<CollectionEntry>(predicate: predicate)
        
        do {
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
            
            try modelContext.save()
            dismiss()
        } catch {
            print("Error adding card: \(error)")
        }
    }
}

#Preview {
    ManualCardEntryView()
        .modelContainer(for: [Card.self, CollectionEntry.self], inMemory: true)
}
