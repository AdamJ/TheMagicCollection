//
//  ContentView.swift
//  MTGCollectionApp
//
//  Created on 11/23/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "square.stack.3d.up")
                }
                .tag(0)
            
            DecksListView()
                .tabItem {
                    Label("Decks & Lists", systemImage: "rectangle.stack")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Card.self, CollectionEntry.self, DeckList.self, DeckEntry.self], inMemory: true)
}
