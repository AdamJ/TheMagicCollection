//
//  CardScannerView.swift
//  MTGCollectionApp
//
//  Created on 11/23/2025.
//

import SwiftUI
#if canImport(VisionKit)
import VisionKit
#endif

struct CardScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isScanning = false
    @State private var scannedCards: [ScannedCard] = []
    @State private var showingResults = false
    
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
                        // TODO: Implement DataScannerViewController wrapper
                        // This will use VisionKit to scan cards
                        Text("Camera view will go here")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.black)
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
                ScannedCardsReviewView(scannedCards: $scannedCards)
            }
        }
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
}

struct ScannedCardsReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var scannedCards: [ScannedCard]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(scannedCards) { scannedCard in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(scannedCard.cardName)
                            .font(.headline)
                        
                        if let setCode = scannedCard.setCode {
                            Text("Set: \(setCode)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("Confidence: \(Int(scannedCard.confidence * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Scanned Cards")
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
                }
            }
        }
    }
    
    private func addScannedCards() {
        // TODO: Implement adding scanned cards to collection
        // This will need to match against the Scryfall database
        dismiss()
    }
}

#Preview {
    CardScannerView()
        .modelContainer(for: [Card.self, CollectionEntry.self], inMemory: true)
}
