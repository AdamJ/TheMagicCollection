//
//  CollectionEntryDetailView.swift
//  MTGCollectionApp
//
//  Created on 11/23/2025.
//

import SwiftUI
import SwiftData

struct CollectionEntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var entry: CollectionEntry
    
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Card image
                AsyncImage(url: URL(string: entry.card?.imageURI ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                }
                .frame(maxHeight: 400)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 4)
                .padding(.horizontal)
                
                // Card details
                VStack(alignment: .leading, spacing: 16) {
                    Group {
                        DetailRow(label: "Card Name", value: entry.card?.name ?? "Unknown")
                        DetailRow(label: "Set", value: entry.card?.setName ?? "Unknown")
                        DetailRow(label: "Collector Number", value: entry.card?.collectorNumber ?? "?")
                        DetailRow(label: "Rarity", value: entry.card?.rarity.capitalized ?? "Unknown")
                    }
                    
                    Divider()
                    
                    if let manaCost = entry.card?.manaCost {
                        DetailRow(label: "Mana Cost", value: manaCost)
                    }
                    
                    if let typeLine = entry.card?.typeLine {
                        DetailRow(label: "Type", value: typeLine)
                    }
                    
                    if let oracleText = entry.card?.oracleText {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Oracle Text")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(oracleText)
                                .font(.subheadline)
                        }
                    }
                    
                    Divider()
                    
                    // Quantity information
                    VStack(spacing: 12) {
                        HStack {
                            Text("Quantity Owned")
                                .font(.headline)
                            Spacer()
                            if isEditing {
                                Stepper("\(entry.quantityOwned)", value: $entry.quantityOwned, in: 0...999)
                            } else {
                                Text("\(entry.quantityOwned)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                        }
                        
                        HStack {
                            Text("Available")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(entry.quantityAvailable)")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        }
                        
                        HStack {
                            Text("In Use")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(entry.quantityInUse)")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding()
                    .background(.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Show which decks use this card
                    if let deckEntries = entry.deckEntries, !deckEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Used In Decks")
                                .font(.headline)
                            
                            ForEach(deckEntries, id: \.self) { deckEntry in
                                if let deck = deckEntry.parentDeck {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(deck.name)
                                                .font(.subheadline)
                                            Text(deckEntry.isSideboard ? "Sideboard" : "Main Deck")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text("×\(deckEntry.quantity)")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding()
                        .background(.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        
                        if isEditing {
                            TextField("Add notes about this card", text: Binding(
                                get: { entry.notes ?? "" },
                                set: { entry.notes = $0.isEmpty ? nil : $0 }
                            ), axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                        } else {
                            Text(entry.notes ?? "No notes")
                                .font(.subheadline)
                                .foregroundStyle(entry.notes == nil ? .secondary : .primary)
                        }
                    }
                    .padding()
                    .background(.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Date added
                    DetailRow(label: "Date Added", value: entry.dateAdded.formatted(date: .abbreviated, time: .shortened))
                }
                .padding(.horizontal)
                
                // Delete button
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Text("Remove from Collection")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationTitle("Card Details")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Done" : "Edit") {
                    isEditing.toggle()
                    if !isEditing {
                        try? modelContext.save()
                    }
                }
            }
        }
        .alert("Remove Card", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                modelContext.delete(entry)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to remove this card from your collection? This action cannot be undone.")
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
    }
}

#Preview {
    NavigationStack {
        CollectionEntryDetailView(
            entry: {
                let card = Card(
                    scryfallId: "test",
                    name: "Lightning Bolt",
                    setCode: "LEA",
                    setName: "Limited Edition Alpha",
                    collectorNumber: "161",
                    manaCost: "{R}",
                    manaValue: 1,
                    typeLine: "Instant",
                    oracleText: "Lightning Bolt deals 3 damage to any target.",
                    colors: ["R"],
                    colorIdentity: ["R"],
                    rarity: "common"
                )
                
                return CollectionEntry(card: card, quantityOwned: 4)
            }()
        )
    }
    .modelContainer(for: [Card.self, CollectionEntry.self], inMemory: true)
}
