//
//  SettingsView.swift
//  MTGCollectionApp
//
//  Created on 11/23/2025.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allCards: [Card]
    @Query private var collectionEntries: [CollectionEntry]
    @Query private var decks: [DeckList]

    @State private var showingImportPicker = false
    @State private var showingExportSheet = false
    @State private var isImporting = false
    @State private var importProgress = 0.0
    @State private var showingDeleteAlert = false
    @State private var exportURL: URL?
    @State private var exportType: ExportType?

    // Error handling
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSuccess = false
    @State private var successMessage: String?

    enum ExportType {
        case collection
        case allDecks
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Collection Stats") {
                    LabeledContent("Total Cards in Database", value: "\(allCards.count)")
                    LabeledContent("Unique Cards Owned", value: "\(collectionEntries.count)")
                    LabeledContent("Total Cards Owned", value: "\(totalCardsOwned)")
                    LabeledContent("Decks & Lists", value: "\(decks.count)")
                }
                
                Section("Data Management") {
                    Button {
                        showingImportPicker = true
                    } label: {
                        Label("Import Scryfall Database", systemImage: "square.and.arrow.down")
                    }
                    .disabled(isImporting)
                    
                    if isImporting {
                        ProgressView(value: importProgress) {
                            Text("Importing cards...")
                        }
                    }
                    
                    Button {
                        showingExportSheet = true
                    } label: {
                        Label("Export Collection", systemImage: "square.and.arrow.up")
                    }
                    
                    if let url = exportURL {
                        ShareLink(item: url) {
                            Label("Share \(exportType == .collection ? "Collection" : "Decks")", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                
                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Database", value: "Scryfall")
                    
                    Link(destination: URL(string: "https://scryfall.com")!) {
                        Label("Visit Scryfall", systemImage: "link")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete All Data", systemImage: "trash")
                    }
                } footer: {
                    Text("Warning: This will delete all your cards, decks, and lists. This action cannot be undone.")
                }
            }
            .navigationTitle("Settings")
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportOptionsView(
                    onExportCollection: {
                        exportCollection()
                        showingExportSheet = false
                    },
                    onExportAllDecks: {
                        exportAllDecks()
                        showingExportSheet = false
                    }
                )
            }
            .alert("Delete All Data", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("Are you sure you want to delete all your data? This action cannot be undone.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") { }
            } message: {
                Text(successMessage ?? "Operation completed successfully")
            }
        }
    }
    
    private var totalCardsOwned: Int {
        collectionEntries.reduce(0) { $0 + $1.quantityOwned }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            isImporting = true
            importProgress = 0.0

            Task {
                let service = ScryfallService(modelContext: modelContext)

                do {
                    // Ensure we have access to the security-scoped resource
                    guard url.startAccessingSecurityScopedResource() else {
                        await MainActor.run {
                            isImporting = false
                            errorMessage = "Unable to access the selected file. Please try again."
                            showError = true
                        }
                        return
                    }

                    defer {
                        url.stopAccessingSecurityScopedResource()
                    }

                    try await service.loadBulkData(from: url)

                    await MainActor.run {
                        isImporting = false
                        importProgress = 1.0
                        successMessage = "Successfully imported Scryfall database with \(allCards.count) cards."
                        showSuccess = true
                    }
                } catch {
                    await MainActor.run {
                        isImporting = false
                        errorMessage = "Import failed: \(error.localizedDescription)"
                        showError = true
                    }
                }
            }

        case .failure(let error):
            errorMessage = "File selection failed: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func exportCollection() {
        let service = CSVExportService(modelContext: modelContext)

        do {
            let url = try service.exportCollection()
            exportURL = url
            exportType = .collection
            successMessage = "Collection exported successfully. Use the share button to save or send the file."
            showSuccess = true
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
            showError = true
        }
    }

    private func exportAllDecks() {
        let service = CSVExportService(modelContext: modelContext)

        do {
            let url = try service.exportAllDecks()
            exportURL = url
            exportType = .allDecks
            successMessage = "All decks exported successfully. Use the share button to save or send the file."
            showSuccess = true
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func deleteAllData() {
        // Delete all entries
        for entry in collectionEntries {
            modelContext.delete(entry)
        }
        
        // Delete all decks (cascade will handle entries)
        for deck in decks {
            modelContext.delete(deck)
        }
        
        // Optionally delete all cards from database
        // (You might want to keep these for future use)
        // for card in allCards {
        //     modelContext.delete(card)
        // }
        
        try? modelContext.save()
    }
}

struct ExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onExportCollection: () -> Void
    let onExportAllDecks: () -> Void
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        onExportCollection()
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Export Collection", systemImage: "square.stack.3d.up")
                                .font(.headline)
                            
                            Text("Export all cards in your collection to a CSV file")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button {
                        onExportAllDecks()
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Export All Decks", systemImage: "rectangle.stack")
                                .font(.headline)
                            
                            Text("Export all your decks and lists to CSV files")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Choose Export Type")
                } footer: {
                    Text("Exported files will be saved to your device and can be shared.")
                }
            }
            .navigationTitle("Export Options")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 300)
        #endif
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Card.self, CollectionEntry.self, DeckList.self], inMemory: true)
}
