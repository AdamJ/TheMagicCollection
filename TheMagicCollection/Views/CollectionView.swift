//
//  CollectionView.swift
//  MTGCollectionApp
//
//  Created on 11/23/2025.
//

import SwiftUI
import SwiftData

enum ViewMode {
    case list
    case grid
}

struct CollectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CollectionEntry.dateAdded, order: .reverse) private var collectionEntries: [CollectionEntry]
    
    @State private var searchText = ""
    @State private var selectedColors: Set<MTGColor> = []
    @State private var viewMode: ViewMode = .list
    @State private var showingScanner = false
    @State private var showingManualEntry = false
    
    var filteredEntries: [CollectionEntry] {
        var filtered = collectionEntries
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { entry in
                entry.card?.name.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        // Filter by colors
        if !selectedColors.isEmpty {
            filtered = filtered.filter { entry in
                guard let card = entry.card else { return false }
                let cardColors = Set(card.colors.compactMap { MTGColor(rawValue: $0) })
                return !cardColors.isDisjoint(with: selectedColors)
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if collectionEntries.isEmpty {
                    emptyStateView
                } else {
                    collectionContentView
                }
            }
            .navigationTitle("My Collection")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        viewMode = viewMode == .list ? .grid : .list
                    } label: {
                        Image(systemName: viewMode == .list ? "square.grid.2x2" : "list.bullet")
                    }
                    
                    Menu {
                        Button {
                            showingScanner = true
                        } label: {
                            Label("Scan Cards", systemImage: "camera")
                        }
                        
                        Button {
                            showingManualEntry = true
                        } label: {
                            Label("Manual Entry", systemImage: "plus")
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search by name")
            .sheet(isPresented: $showingScanner) {
                CardScannerView()
            }
            .sheet(isPresented: $showingManualEntry) {
                ManualCardEntryView()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No Cards in Collection")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start building your collection by scanning cards or adding them manually.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                Button {
                    showingScanner = true
                } label: {
                    Label("Scan Cards", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    showingManualEntry = true
                } label: {
                    Label("Manual Entry", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
    }
    
    private var collectionContentView: some View {
        VStack(spacing: 0) {
            // Color filter
            ColorFilterView(selectedColors: $selectedColors)
            
            Divider()
            
            // Main content
            Group {
                if viewMode == .list {
                    listView
                } else {
                    gridView
                }
            }
        }
    }
    
    private var listView: some View {
        List {
            ForEach(filteredEntries, id: \.self) { entry in
                NavigationLink {
                    CollectionEntryDetailView(entry: entry)
                } label: {
                    CollectionEntryRow(entry: entry)
                }
            }
            .onDelete(perform: deleteEntries)
        }
    }
    
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                ForEach(filteredEntries, id: \.self) { entry in
                    NavigationLink {
                        CollectionEntryDetailView(entry: entry)
                    } label: {
                        CollectionEntryCard(entry: entry)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
    
    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            let entry = filteredEntries[index]
            modelContext.delete(entry)
        }
    }
}

// MARK: - Supporting Views

struct CollectionEntryRow: View {
    let entry: CollectionEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Card image placeholder
            AsyncImage(url: URL(string: entry.card?.imageURISmall ?? "")) { image in
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
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.card?.name ?? "Unknown Card")
                    .font(.headline)
                
                Text("\(entry.card?.setName ?? "Unknown Set") · #\(entry.card?.collectorNumber ?? "?")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    Label("\(entry.quantityOwned)", systemImage: "square.stack.3d.up")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    
                    if entry.quantityInUse > 0 {
                        Label("\(entry.quantityInUse) in use", systemImage: "checkmark.circle")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct CollectionEntryCard: View {
    let entry: CollectionEntry
    
    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: entry.card?.imageURI ?? "")) { image in
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
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(entry.card?.name ?? "Unknown")
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            HStack {
                Label("\(entry.quantityOwned)", systemImage: "square.stack.3d.up")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                
                if entry.quantityInUse > 0 {
                    Label("\(entry.quantityInUse)", systemImage: "checkmark.circle")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(8)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
}

struct ColorFilterView: View {
    @Binding var selectedColors: Set<MTGColor>
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(MTGColor.allCases, id: \.self) { color in
                    ColorFilterButton(
                        color: color,
                        isSelected: selectedColors.contains(color)
                    ) {
                        if selectedColors.contains(color) {
                            selectedColors.remove(color)
                        } else {
                            selectedColors.insert(color)
                        }
                    }
                }
                
                if !selectedColors.isEmpty {
                    Button {
                        selectedColors.removeAll()
                    } label: {
                        Text("Clear")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .padding(.leading, 4)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

struct ColorFilterButton: View {
    let color: MTGColor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: color.symbolName)
                    .font(.caption)
                Text(color.name)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color.color : Color.secondary.opacity(0.2))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

enum MTGColor: String, CaseIterable {
    case white = "W"
    case blue = "U"
    case black = "B"
    case red = "R"
    case green = "G"
    
    var name: String {
        switch self {
        case .white: return "White"
        case .blue: return "Blue"
        case .black: return "Black"
        case .red: return "Red"
        case .green: return "Green"
        }
    }
    
    var color: Color {
        switch self {
        case .white: return .white
        case .blue: return .blue
        case .black: return .black
        case .red: return .red
        case .green: return .green
        }
    }
    
    var symbolName: String {
        switch self {
        case .white: return "sun.max.fill"
        case .blue: return "drop.fill"
        case .black: return "moonphase.full.moon"
        case .red: return "flame.fill"
        case .green: return "leaf.fill"
        }
    }
}

#Preview {
    CollectionView()
        .modelContainer(for: [Card.self, CollectionEntry.self], inMemory: true)
}
