//
//  DeckDetailView.swift
//  MTGCollectionApp
//
//  Created on 11/23/2025.
//

import SwiftUI
import SwiftData

struct DeckDetailView: View {
    @Environment(\.modelContext) private var modelContext

    @Bindable var deck: DeckList

    @State private var showingAddCard = false
    @State private var showingExport = false
    @State private var exportURL: URL?
    @State private var selectedSection: DeckSection = .main

    // Error handling
    @State private var errorMessage: String?
    @State private var showError = false

    enum DeckSection: String, CaseIterable {
        case main = "Main Deck"
        case sideboard = "Sideboard"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Stats header
            deckStatsView
            
            Divider()
            
            // Section picker (if sideboard is supported)
            if deck.deckType.supportsSideboard {
                Picker("Section", selection: $selectedSection) {
                    ForEach(DeckSection.allCases, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
            }
            
            // Card list
            List {
                let entries = selectedSection == .main ? (deck.mainDeck ?? []) : (deck.sideboard ?? [])
                
                if entries.isEmpty {
                    ContentUnavailableView {
                        Label("No Cards", systemImage: "rectangle.stack.badge.plus")
                    } description: {
                        Text("Add cards to your \(selectedSection.rawValue.lowercased())")
                    } actions: {
                        Button("Add Card") {
                            showingAddCard = true
                        }
                    }
                } else {
                    ForEach(entries, id: \.self) { entry in
                        if let card = entry.collectionEntry?.card {
                            DeckCardRow(card: card, quantity: entry.quantity)
                        }
                    }
                    .onDelete { indexSet in
                        deleteCards(at: indexSet, from: selectedSection)
                    }
                }
            }
        }
        .navigationTitle(deck.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Menu {
                    Button {
                        showingAddCard = true
                    } label: {
                        Label("Add Card", systemImage: "plus")
                    }
                    
                    Divider()
                    
                    if let url = exportURL {
                        ShareLink(item: url) {
                            Label("Share Deck CSV", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Button {
                            exportDeck()
                        } label: {
                            Label("Export to CSV", systemImage: "square.and.arrow.up")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddCard) {
            AddCardToDeckView(deck: deck, section: selectedSection)
        }
        .alert("Export Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "Failed to export deck")
        }
    }
    
    private var deckStatsView: some View {
        VStack(spacing: 12) {
            // Type and validation status
            HStack {
                Label(deck.deckType.rawValue, systemImage: "tag")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if deck.isValid {
                    Label("Valid", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                } else {
                    Menu {
                        ForEach(deck.validationErrors) { error in
                            Text(error.message)
                        }
                    } label: {
                        Label("Invalid (\(deck.validationErrors.count))", systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }
            }

            // Validation errors (if any)
            if !deck.validationErrors.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(deck.validationErrors) { error in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text(error.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
            
            // Card counts
            HStack(spacing: 20) {
                VStack {
                    Text("\(deck.mainDeckCount)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Main Deck")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let limit = deck.deckType.cardLimit {
                        Text("\(limit) max")
                            .font(.caption2)
                            .foregroundStyle(deck.mainDeckCount > limit ? .red : .secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                
                if deck.deckType.supportsSideboard {
                    Divider()
                    
                    VStack {
                        Text("\(deck.sideboardCount)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Sideboard")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if let limit = deck.deckType.sideboardLimit(isSealed: deck.isSealed) {
                            Text("\(limit) max")
                                .font(.caption2)
                                .foregroundStyle(deck.sideboardCount > limit ? .red : .secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            // Progress bar
            if let limit = deck.deckType.cardLimit {
                ProgressView(value: Double(deck.mainDeckCount), total: Double(limit))
                    .tint(deck.mainDeckCount > limit ? .red : .green)
            }
        }
        .padding()
        .background(.secondary.opacity(0.1))
    }
    
    private func deleteCards(at offsets: IndexSet, from section: DeckSection) {
        let entries = section == .main ? (deck.mainDeck ?? []) : (deck.sideboard ?? [])
        
        for index in offsets {
            let entry = entries[index]
            modelContext.delete(entry)
        }
        
        deck.dateModified = Date()
    }
    
    private func exportDeck() {
        let exportService = CSVExportService(modelContext: modelContext)

        do {
            let url = try exportService.exportDeck(deck)
            exportURL = url
        } catch {
            errorMessage = "Failed to export deck: \(error.localizedDescription)"
            showError = true
        }
    }
}

struct DeckCardRow: View {
    let card: Card
    let quantity: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Quantity badge
            Text("\(quantity)×")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.blue)
                .clipShape(Circle())
            
            // Card image
            AsyncImage(url: URL(string: card.imageURISmall ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(width: 50, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            // Card info
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
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct AddCardToDeckView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var collectionEntries: [CollectionEntry]
    
    let deck: DeckList
    let section: DeckDetailView.DeckSection
    
    @State private var searchText = ""
    @State private var selectedEntry: CollectionEntry?
    @State private var quantity = 1
    
    var availableEntries: [CollectionEntry] {
        collectionEntries.filter { entry in
            entry.quantityAvailable > 0 &&
            (searchText.isEmpty || entry.card?.name.localizedCaseInsensitiveContains(searchText) == true)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                List(availableEntries, id: \.self, selection: $selectedEntry) { entry in
                    Button {
                        selectedEntry = entry
                    } label: {
                        HStack {
                            CollectionEntryRow(entry: entry)
                            
                            if selectedEntry == entry {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
                
                if selectedEntry != nil {
                    VStack(spacing: 12) {
                        Stepper("Quantity: \(quantity)", value: $quantity, in: 1...maxQuantity)
                            .padding(.horizontal)
                        
                        Button("Add to \(section.rawValue)") {
                            addCard()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(.bar)
                }
            }
            .navigationTitle("Add Card")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .searchable(text: $searchText, prompt: "Search your collection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var maxQuantity: Int {
        guard let entry = selectedEntry else { return 1 }
        
        let copyLimit = deck.deckType.copyLimit
        let availableInCollection = entry.quantityAvailable
        
        // Check how many copies already in deck
        let existingQuantity = existingCardQuantity(for: entry)
        let remainingAllowed = copyLimit - existingQuantity
        
        return min(availableInCollection, remainingAllowed)
    }
    
    private func existingCardQuantity(for entry: CollectionEntry) -> Int {
        let allEntries = (deck.mainDeck ?? []) + (deck.sideboard ?? [])
        return allEntries
            .filter { $0.collectionEntry == entry }
            .reduce(0) { $0 + $1.quantity }
    }
    
    private func addCard() {
        guard let entry = selectedEntry else { return }
        
        let deckEntry = DeckEntry(
            collectionEntry: entry,
            deckList: section == .main ? deck : nil,
            sideboardDeckList: section == .sideboard ? deck : nil,
            quantity: quantity
        )
        
        modelContext.insert(deckEntry)
        deck.dateModified = Date()
        
        dismiss()
    }
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}

#Preview {
    NavigationStack {
        DeckDetailView(deck: {
            DeckList(name: "My Commander Deck", deckType: .commander)
        }())
    }
    .modelContainer(for: [DeckList.self, DeckEntry.self, CollectionEntry.self, Card.self], inMemory: true)
}
