# MTG Collection App

A comprehensive iOS/iPadOS application for managing your Magic: The Gathering card collection, with support for deck building, scanning, and list management.

## Features

### Core Functionality
- **Card Collection Management**: Track physical MTG cards with quantity management
- **Deck Building**: Create and manage different types of decks
  - Commander (100 cards, singleton format)
  - Standard (60 cards, 4-copy limit)
  - Draft/Sealed (40 cards, with optional sideboard)
  - Wish Lists (unlimited)
- **Card Scanning**: Hybrid approach with camera scanning + manual entry
- **Scryfall Integration**: Local database of card information
- **List/Grid Views**: Toggle between viewing modes
- **Color Filtering**: Filter cards by MTG color
- **In-Use Tracking**: See which cards are currently in decks
- **CSV Export**: Export your collection and decks for backup

### Deck Features
- Card count validation
- Copy limit enforcement (with basic land exceptions)
- Sideboard support for applicable formats
- Visual deck statistics
- Deck validity checking

## Project Structure

```
MTGCollectionApp/
├── MTGCollectionApp.swift          # Main app entry point
├── Models/
│   ├── Card.swift                  # Card model (from Scryfall)
│   ├── CollectionEntry.swift       # User's owned cards
│   ├── DeckList.swift              # Deck/List model
│   └── DeckEntry.swift             # Cards in decks
├── Services/
│   ├── ScryfallService.swift       # Card database management
│   └── CSVExportService.swift      # Export functionality
└── Views/
    ├── ContentView.swift            # Main tab view
    ├── CollectionView.swift         # Collection browser
    ├── CollectionEntryDetailView.swift
    ├── DecksListView.swift          # Deck browser
    ├── DeckDetailView.swift         # Individual deck view
    ├── CardScannerView.swift        # Camera scanning
    ├── ManualCardEntryView.swift    # Manual card addition
    └── SettingsView.swift           # App settings & data management
```

## Technical Details

### Technologies Used
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Persistent storage with model relationships
- **VisionKit**: Card scanning (placeholder for implementation)
- **AsyncImage**: Async image loading from Scryfall
- **Swift Concurrency**: async/await for data operations

### Data Models

**Card**
- Represents a Magic card from Scryfall
- Contains: name, set info, mana cost, type, colors, images, etc.

**CollectionEntry**
- User's ownership of a specific card
- Tracks: quantity owned, quantity available, quantity in use
- Relationships: linked to Card and DeckEntries

**DeckList**
- A deck or list created by the user
- Types: Commander, Standard, Draft, Wish List
- Validation: card limits, copy limits, sideboard rules
- Relationships: has mainDeck and sideboard entries

**DeckEntry**
- Represents a card in a specific deck
- Marks cards as "in use" in collection
- Tracks: quantity, notes, whether it's in sideboard

## Getting Started

### Prerequisites
1. Xcode 15.0 or later
2. iOS 17.0+ / iPadOS 17.0+
3. Scryfall bulk data JSON file (download from https://scryfall.com/docs/api/bulk-data)

### Setup Instructions

1. **Create a new Xcode project**:
   - iOS App template
   - Name: MTGCollectionApp
   - Interface: SwiftUI
   - Storage: None (we'll add SwiftData manually)

2. **Add the provided files** to your project in the appropriate folders

3. **Download Scryfall Data**:
   - Visit https://scryfall.com/docs/api/bulk-data
   - Download "Default Cards" JSON file
   - The app will let you import this via Settings

4. **Configure App Permissions** (Info.plist):
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>We need camera access to scan your Magic cards</string>
   ```

5. **Build and Run** the app on your device or simulator

## Next Steps / TODOs

### High Priority
1. **Implement Card Scanning**:
   - Complete the `CardScannerView` with VisionKit
   - Add ML model for card recognition (OCR for card names)
   - Match scanned text against Scryfall database
   
2. **Enhanced Search**:
   - Add more filter options (set, rarity, type, mana cost)
   - Implement advanced search combinations
   
3. **Deck Statistics**:
   - Mana curve visualization
   - Color distribution charts
   - Card type breakdown

### Medium Priority
4. **Set/Collector Number Editing**:
   - Allow users to change which printing they own
   - Support for multiple printings of same card
   
5. **Card Conditions**:
   - Track card condition (NM, LP, MP, HP, etc.)
   - Track foil/non-foil status
   
6. **Deck Testing**:
   - Sample hand drawer
   - Mulligan simulator
   - Basic goldfish testing

### Low Priority
7. **Price Tracking**:
   - Integration with price APIs
   - Collection value tracking
   - Price history graphs
   
8. **Deck Sharing**:
   - Export decks in standard formats (TXT, Arena, MTGO)
   - Import deck lists from text
   
9. **Themes**:
   - Dark mode optimizations
   - Custom color schemes
   
10. **Widgets**:
    - Collection statistics widget
    - Random card widget
    - Deck summary widget

## Data Flow

### Adding a Card to Collection
1. User scans card or enters manually
2. Card is matched against local Scryfall database
3. `CollectionEntry` is created/updated with quantity
4. Card becomes available for deck building

### Adding a Card to a Deck
1. User browses their collection
2. Selects available card (quantity > 0)
3. Chooses quantity and deck section
4. `DeckEntry` is created, linking CollectionEntry to DeckList
5. Card quantity is marked as "in use"

### Validation Rules
- **Commander**: Max 100 cards, max 1 copy (except basic lands)
- **Standard/Draft**: Max 60/40 cards, max 4 copies (except basic lands)
- **Wish List**: No limits
- **Sideboards**: Only for 60/40 card decks, with format-specific limits

## Scryfall API

This app uses Scryfall's bulk data. To get the latest card data:

1. Visit: https://scryfall.com/docs/api/bulk-data
2. Download "Default Cards" (JSON format)
3. Import via Settings > Import Scryfall Database
4. First import will take a few minutes depending on file size

Scryfall updates their database daily. You can re-import to get the latest cards.

## License

This is a personal project. Magic: The Gathering is © Wizards of the Coast. Card data is provided by Scryfall.

## Contributing

This is currently a solo project template. Feel free to fork and customize for your own needs!

## Acknowledgments

- **Scryfall** for providing comprehensive MTG card data
- **Wizards of the Coast** for Magic: The Gathering
- Apple's SwiftUI and SwiftData frameworks
