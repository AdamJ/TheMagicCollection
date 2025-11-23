//
//  DecksListView.swift
//  MTGCollectionApp
//
//  Created on 11/23/2025.
//

import SwiftUI
import SwiftData

struct DecksListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DeckList.dateModified, order: .reverse) private var decks: [DeckList]
    
    @State private var showingNewDeck = false
    @State private var searchText = ""
    
    var filteredDecks: [DeckList] {
        if searchText.isEmpty {
            return decks
        }
        return decks.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if decks.isEmpty {
                    emptyStateView
                } else {
                    deckListView
                }
            }
            .navigationTitle("Decks & Lists")
            .searchable(text: $searchText, prompt: "Search decks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewDeck = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewDeck) {
                NewDeckView()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No Decks or Lists")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first deck or list to start organizing your cards.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                showingNewDeck = true
            } label: {
                Label("Create Deck", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var deckListView: some View {
        List {
            ForEach(filteredDecks, id: \.self) { deck in
                NavigationLink {
                    DeckDetailView(deck: deck)
                } label: {
                    DeckRow(deck: deck)
                }
            }
            .onDelete(perform: deleteDecks)
        }
    }
    
    private func deleteDecks(at offsets: IndexSet) {
        for index in offsets {
            let deck = filteredDecks[index]
            modelContext.delete(deck)
        }
    }
}

struct DeckRow: View {
    let deck: DeckList
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(deck.name)
                    .font(.headline)
                
                Spacer()
                
                if !deck.isValid {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }
            
            HStack(spacing: 12) {
                Label(deck.deckType.rawValue, systemImage: deckTypeIcon(deck.deckType))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Label("\(deck.mainDeckCount) cards", systemImage: "square.stack")
                    .font(.caption)
                    .foregroundStyle(.blue)
                
                if deck.sideboardCount > 0 {
                    Label("\(deck.sideboardCount) SB", systemImage: "square.stack.fill")
                        .font(.caption)
                        .foregroundStyle(.purple)
                }
            }
            
            if let limit = deck.deckType.cardLimit {
                ProgressView(value: Double(deck.mainDeckCount), total: Double(limit))
                    .tint(deck.mainDeckCount > limit ? .red : .green)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func deckTypeIcon(_ type: DeckType) -> String {
        switch type {
        case .commander:
            return "crown"
        case .standard:
            return "rectangle.portrait"
        case .draft:
            return "cube.box"
        case .wishList:
            return "star"
        }
    }
}

struct NewDeckView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var deckName = ""
    @State private var selectedType: DeckType = .standard
    @State private var isSealed = false
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Deck Information") {
                    TextField("Deck Name", text: $deckName)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(DeckType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    if selectedType == .draft {
                        Toggle("Sealed Deck", isOn: $isSealed)
                    }
                }
                
                Section("Details") {
                    if let limit = selectedType.cardLimit {
                        LabeledContent("Card Limit", value: "\(limit)")
                        LabeledContent("Copy Limit", value: "\(selectedType.copyLimit)")
                    } else {
                        Text("Unlimited cards")
                            .foregroundStyle(.secondary)
                    }
                    
                    if selectedType.supportsSideboard {
                        if let sideboardLimit = selectedType.sideboardLimit(isSealed: isSealed) {
                            LabeledContent("Sideboard Limit", value: "\(sideboardLimit)")
                        } else {
                            LabeledContent("Sideboard", value: "Unlimited")
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Deck")
//            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createDeck()
                    }
                    .disabled(deckName.isEmpty)
                }
            }
        }
    }
    
    private func createDeck() {
        let deck = DeckList(
            name: deckName,
            deckType: selectedType,
            isSealed: isSealed,
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(deck)
        dismiss()
    }
}

#Preview("Decks List") {
    DecksListView()
        .modelContainer(for: [DeckList.self], inMemory: true)
}

#Preview("New Deck") {
    NewDeckView()
        .modelContainer(for: [DeckList.self], inMemory: true)
}
