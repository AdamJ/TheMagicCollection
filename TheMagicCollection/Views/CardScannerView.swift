//
//  CardScannerView.swift
//  MTGCollectionApp
//
//  Created on 11/23/2025.
//

import SwiftUI
import SwiftData
#if canImport(VisionKit)
import VisionKit
#endif

struct CardScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isScanning = false
    @State private var scannedCards: [ScannedCard] = []
    @State private var showingResults = false
    @State private var recognizedItems: [RecognizedItem] = []

    // Check if scanning is available on this platform
    private var isScanningAvailable: Bool {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            return DataScannerViewController.isSupported && DataScannerViewController.isAvailable
        }
        #endif
        return false
    }

    var body: some View {
        NavigationStack {
            VStack {
                if isScanningAvailable {
                    if !isScanning {
                        scannerInstructionsView
                    } else {
                        #if os(iOS)
                        if #available(iOS 16.0, *) {
                            DataScannerRepresentable(
                                recognizedItems: $recognizedItems,
                                recognizedDataType: .text(),
                                onScannedCard: { card in
                                    addScannedCard(card)
                                }
                            )
                            .overlay(alignment: .bottom) {
                                scannerOverlayView
                            }
                        } else {
                            Text("Scanning requires iOS 16.0 or later")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(.black)
                        }
                        #else
                        Text("Camera view will go here")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.black)
                        #endif
                    }
                } else {
                    unsupportedDeviceView
                }
            }
            .navigationTitle("Scan Cards")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if isScanning {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showingResults = true
                        }
                        .disabled(scannedCards.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $showingResults) {
                ScannedCardsReviewView(
                    scannedCards: $scannedCards,
                    modelContext: modelContext
                )
            }
        }
    }

    private var scannerOverlayView: some View {
        VStack(spacing: 12) {
            if !scannedCards.isEmpty {
                Text("\(scannedCards.count) card\(scannedCards.count == 1 ? "" : "s") scanned")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.blue.opacity(0.8))
                    .cornerRadius(20)
            }

            Text("Point camera at card name")
                .font(.caption)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.black.opacity(0.6))
                .cornerRadius(12)
        }
        .padding(.bottom, 40)
    }

    private func addScannedCard(_ card: ScannedCard) {
        // Avoid duplicates in the same session
        guard !scannedCards.contains(where: { $0.cardName == card.cardName }) else {
            return
        }
        scannedCards.append(card)
    }
    
    private var scannerInstructionsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            
            Text("Ready to Scan")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                InstructionRow(icon: "light.max", text: "Ensure good lighting")
                InstructionRow(icon: "rectangle.center.inset.filled", text: "Center the card in frame")
                InstructionRow(icon: "camera.metering.spot", text: "Focus on the card name")
            }
            .padding()
            
            Button {
                isScanning = true
            } label: {
                Text("Start Scanning")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
    }
    
    private var unsupportedDeviceView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.slash")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("Camera Not Available")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Card scanning is not available on this device. You can still add cards manually.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

struct InstructionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.blue)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct ScannedCard: Identifiable {
    let id = UUID()
    var cardName: String
    var setCode: String?
    var collectorNumber: String?
    var confidence: Double
    var matchedCard: Card?
}

struct ScannedCardsReviewView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var scannedCards: [ScannedCard]
    let modelContext: ModelContext

    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Group {
                if scannedCards.isEmpty {
                    ContentUnavailableView(
                        "No Cards Scanned",
                        systemImage: "camera.slash",
                        description: Text("Scan some cards to add them to your collection")
                    )
                } else {
                    List {
                        ForEach(scannedCards) { scannedCard in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(scannedCard.cardName)
                                            .font(.headline)

                                        if let setCode = scannedCard.setCode {
                                            Text("Set: \(setCode)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        HStack {
                                            Text("Confidence: \(Int(scannedCard.confidence * 100))%")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)

                                            if scannedCard.matchedCard != nil {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.green)
                                                    .font(.caption)
                                            }
                                        }
                                    }

                                    Spacer()

                                    if let card = scannedCard.matchedCard,
                                       let imageURL = card.imageURISmall,
                                       let url = URL(string: imageURL) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 50, height: 70)
                                        .cornerRadius(4)
                                    }
                                }
                            }
                        }
                        .onDelete { indexSet in
                            scannedCards.remove(atOffsets: indexSet)
                        }
                    }
                }
            }
            .navigationTitle("Review Scanned Cards")
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
                    Button("Add All") {
                        addScannedCards()
                    }
                    .disabled(scannedCards.isEmpty || isProcessing)
                }
            }
            .alert("Error Adding Cards", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .overlay {
                if isProcessing {
                    ProgressView("Adding cards...")
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                }
            }
        }
    }

    private func addScannedCards() {
        isProcessing = true

        Task {
            do {
                let service = ScryfallService(modelContext: modelContext)
                var addedCount = 0

                for scannedCard in scannedCards {
                    // Try to find the card in the database
                    let cards = try service.searchCards(byName: scannedCard.cardName)

                    guard let card = cards.first else {
                        continue
                    }

                    let targetScryfallId = card.scryfallId
                    // Check if this card already exists in the collection
                    let predicate = #Predicate<CollectionEntry> { entry in
                        entry.card?.scryfallId == targetScryfallId
                    }

                    let descriptor = FetchDescriptor<CollectionEntry>(predicate: predicate)
                    let existingEntries = try modelContext.fetch(descriptor)

                    if let existingEntry = existingEntries.first {
                        // Card already in collection, increment quantity
                        existingEntry.quantityOwned += 1
                    } else {
                        // Add new entry to collection
                        let entry = CollectionEntry(
                            card: card,
                            quantityOwned: 1,
                            dateAdded: Date()
                        )
                        modelContext.insert(entry)
                    }

                    addedCount += 1
                }

                try modelContext.save()

                await MainActor.run {
                    isProcessing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Failed to add cards: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - DataScanner UIKit Wrapper

#if os(iOS)
@available(iOS 16.0, *)
struct DataScannerRepresentable: UIViewControllerRepresentable {
    @Binding var recognizedItems: [RecognizedItem]
    let recognizedDataType: DataScannerViewController.RecognizedDataType
    let onScannedCard: (ScannedCard) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [recognizedDataType],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )

        scanner.delegate = context.coordinator

        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // Start scanning if not already started
        if !uiViewController.isScanning {
            try? uiViewController.startScanning()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            recognizedItems: $recognizedItems,
            onScannedCard: onScannedCard
        )
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        @Binding var recognizedItems: [RecognizedItem]
        let onScannedCard: (ScannedCard) -> Void
        private var processedTexts: Set<String> = []
        private var lastProcessTime: Date = .distantPast

        init(recognizedItems: Binding<[RecognizedItem]>, onScannedCard: @escaping (ScannedCard) -> Void) {
            self._recognizedItems = recognizedItems
            self.onScannedCard = onScannedCard
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            processRecognizedItem(item)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            recognizedItems = allItems

            // Process newly added items
            for item in addedItems {
                // Throttle processing to avoid duplicates
                let now = Date()
                guard now.timeIntervalSince(lastProcessTime) > 1.0 else { continue }

                processRecognizedItem(item)
                lastProcessTime = now
            }
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            recognizedItems = allItems
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            recognizedItems = allItems
        }

        private func processRecognizedItem(_ item: RecognizedItem) {
            switch item {
            case .text(let text):
                let recognizedText = text.transcript
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                // Avoid processing the same text multiple times
                guard !processedTexts.contains(recognizedText) else { return }
                guard !recognizedText.isEmpty else { return }

                // Basic filtering - likely card names are 3-50 characters
                guard recognizedText.count >= 3 && recognizedText.count <= 50 else { return }

                processedTexts.insert(recognizedText)

                // Create scanned card with confidence based on text characteristics
                let confidence = calculateConfidence(for: recognizedText)

                let scannedCard = ScannedCard(
                    cardName: recognizedText,
                    setCode: nil,
                    collectorNumber: nil,
                    confidence: confidence,
                    matchedCard: nil
                )

                onScannedCard(scannedCard)

            case .barcode:
                break
            @unknown default:
                break
            }
        }

        private func calculateConfidence(for text: String) -> Double {
            var confidence = 0.5

            // Boost confidence for text with capital letters (card names are title case)
            if text.first?.isUppercase == true {
                confidence += 0.2
            }

            // Boost confidence for text with multiple words (many cards have 2-3 words)
            let wordCount = text.components(separatedBy: .whitespaces).count
            if wordCount >= 2 && wordCount <= 4 {
                confidence += 0.2
            }

            // Reduce confidence for text with numbers (less common in card names)
            if text.rangeOfCharacter(from: .decimalDigits) != nil {
                confidence -= 0.1
            }

            return min(max(confidence, 0.0), 1.0)
        }
    }
}
#endif

// MARK: - Preview

#Preview {
    CardScannerView()
        .modelContainer(for: [Card.self, CollectionEntry.self], inMemory: true)
}

// Wrapper to allow using URLs in ForEach/SwiftUI contexts that require Identifiable.
struct IdentifiableURL: Identifiable, Equatable {
    let url: URL
    var id: String { url.absoluteString }
}

