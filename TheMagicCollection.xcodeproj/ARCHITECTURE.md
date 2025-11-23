//
//  ARCHITECTURE.md
//  MTGCollectionApp Architecture Overview
//

# Architecture Overview

## App Architecture Pattern

This app follows the **Model-View pattern** as recommended by Apple for SwiftUI + SwiftData apps:
- **Models**: SwiftData models that are both the data layer and business logic
- **Views**: SwiftUI views that observe and display data
- **Services**: Utility classes for operations like importing, exporting, searching

No separate ViewModels are needed because SwiftData models are observable by default.

## Data Models & Relationships

```
Card (Scryfall Database)
  ↓ one-to-many
CollectionEntry (User's Cards)
  ↓ one-to-many
DeckEntry (Cards in Decks)
  ↓ many-to-one
DeckList (Decks/Lists)
```

### Model Details

**Card**
- Source: Scryfall bulk data
- Represents: A unique printing of a Magic card
- Key fields: scryfallId (unique), name, set, colors, images
- Relationship: Has many CollectionEntries (one card can be owned multiple times)

**CollectionEntry**
- Source: User input (scanning or manual)
- Represents: User's ownership of a specific card printing
- Key fields: quantityOwned, quantityAvailable (computed), quantityInUse (computed)
- Relationships:
  - Belongs to one Card
  - Has many DeckEntries (this card in multiple decks)
- Business Logic: Calculates available quantity based on what's in use

**DeckList**
- Source: User creation
- Represents: A deck or list (Commander, Standard, Draft, Wish List)
- Key fields: name, deckType, isValid (computed)
- Relationships:
  - Has many DeckEntries (main deck)
  - Has many DeckEntries (sideboard)
- Business Logic: Validates card counts and copy limits

**DeckEntry**
- Source: User adding cards to decks
- Represents: A specific card in a specific deck
- Key fields: quantity, isSideboard
- Relationships:
  - Belongs to one CollectionEntry (marks it as "in use")
  - Belongs to one DeckList (main or sideboard)

## View Hierarchy

```
ContentView (TabView)
├── CollectionView
│   ├── CollectionEntryRow/Card (List/Grid items)
│   ├── ColorFilterView
│   ├── CardScannerView
│   ├── ManualCardEntryView
│   └── CollectionEntryDetailView
│
├── DecksListView
│   ├── DeckRow (List items)
│   ├── NewDeckView
│   └── DeckDetailView
│       └── AddCardToDeckView
│
└── SettingsView
```

### View Responsibilities

**ContentView**
- Root view with tab navigation
- Provides modelContainer to all child views

**CollectionView**
- Displays all owned cards
- Supports list/grid toggle
- Filters by name and color
- Entry points: scanning, manual add

**CollectionEntryDetailView**
- Shows detailed card information
- Allows quantity editing
- Shows which decks use this card
- Supports notes

**DecksListView**
- Displays all decks and lists
- Shows deck stats and validity
- Entry point: create new deck

**DeckDetailView**
- Shows deck contents (main/sideboard)
- Displays validation status
- Allows adding/removing cards
- Supports CSV export

**SettingsView**
- Import Scryfall database
- Export collection/decks
- View statistics
- Data management

## Services

### ScryfallService
**Purpose**: Manage the local Scryfall card database

**Key Methods**:
- `loadBulkData(from:)`: Import Scryfall JSON file
- `searchCards(byName:)`: Find cards by name
- `searchCards(byColor:)`: Filter by color
- `findCard(byScryfallId:)`: Look up specific card

**Usage Pattern**:
```swift
let service = ScryfallService(modelContext: modelContext)
let results = try service.searchCards(byName: "Lightning Bolt")
```

### CSVExportService
**Purpose**: Export data to CSV format for backup

**Key Methods**:
- `exportCollection()`: Export all owned cards
- `exportDeck(_:)`: Export specific deck
- `exportAllDecks()`: Export deck list

**Usage Pattern**:
```swift
let service = CSVExportService(modelContext: modelContext)
let url = try service.exportCollection()
// Share via UIActivityViewController
```

## Key Design Decisions

### 1. In-Use Tracking
**Problem**: Users need to know which cards are available for deck building

**Solution**: 
- CollectionEntry tracks total owned quantity
- DeckEntry "reserves" cards by linking to CollectionEntry
- Computed properties calculate available vs. in-use

**Benefits**:
- Users can't accidentally over-allocate cards
- Easy to see where cards are used
- Prevents building multiple decks with same physical cards

### 2. Flexible Deck Types
**Problem**: Different formats have different rules

**Solution**:
- DeckType enum encodes format-specific rules
- Computed properties on DeckList enforce validation
- UI adapts based on deck type (sideboard visibility, limits)

**Benefits**:
- Single model supports all deck types
- Easy to add new formats
- Validation is automatic

### 3. Local Scryfall Database
**Problem**: Need card data without internet dependency

**Solution**:
- One-time import of Scryfall bulk data
- Cards stored in SwiftData
- Local searching via predicates

**Benefits**:
- App works offline
- Fast searches
- No API rate limits
- Full Scryfall data available

### 4. Hybrid Scanning
**Problem**: Card recognition is imperfect

**Solution**:
- Camera scanning with VisionKit (to implement)
- Manual entry fallback
- User can edit scanned results before adding

**Benefits**:
- Faster for bulk scanning
- Accurate for complex cases
- User always has control

## Data Flow Examples

### Example 1: Adding a Card to Collection

```
User Action: Scan card or search manually
     ↓
ScryfallService: Find matching Card in database
     ↓
Check: Does CollectionEntry already exist?
     ├─ Yes: Update quantity
     └─ No: Create new CollectionEntry
     ↓
Save to SwiftData
     ↓
UI: Card appears in collection
```

### Example 2: Building a Deck

```
User Action: Create new DeckList
     ↓
User Action: Add card from collection
     ↓
Check: Is card available? (quantityAvailable > 0)
     ├─ No: Show error
     └─ Yes: Continue
     ↓
Check: Would this exceed copy limit?
     ├─ Yes: Show error
     └─ No: Continue
     ↓
Create DeckEntry linking CollectionEntry to DeckList
     ↓
Save to SwiftData
     ↓
UI: Card appears in deck
UI: CollectionEntry shows "in use"
UI: DeckList updates card count
```

### Example 3: Removing a Card from Deck

```
User Action: Delete DeckEntry
     ↓
SwiftData: Delete cascade relationships
     ↓
CollectionEntry: quantityInUse decreases
CollectionEntry: quantityAvailable increases
     ↓
DeckList: mainDeckCount/sideboardCount updates
     ↓
UI: Card removed from deck
UI: Card shows as available in collection
```

## SwiftData Relationships

### Cascade Delete Rules

1. **Card → CollectionEntry**: `.cascade`
   - If Card is deleted, all CollectionEntries are deleted
   - (Rarely happens - only when clearing database)

2. **CollectionEntry → DeckEntry**: `.cascade`
   - If CollectionEntry is deleted, all DeckEntries are deleted
   - Removes card from all decks when removed from collection

3. **DeckList → DeckEntry**: `.cascade`
   - If DeckList is deleted, all DeckEntries are deleted
   - Cleans up deck contents when deck is deleted
   - CollectionEntry becomes available again

### Query Examples

**All collection entries sorted by date**:
```swift
@Query(sort: \CollectionEntry.dateAdded, order: .reverse) 
var collectionEntries: [CollectionEntry]
```

**Search cards by name**:
```swift
let predicate = #Predicate<Card> { card in
    card.name.localizedStandardContains(searchText)
}
let descriptor = FetchDescriptor<Card>(predicate: predicate)
let results = try modelContext.fetch(descriptor)
```

**Find card in collection**:
```swift
let predicate = #Predicate<CollectionEntry> { entry in
    entry.card?.scryfallId == cardId
}
```

## Performance Considerations

### Large Database Handling
- Scryfall has 80,000+ cards
- Import in batches of 100 to avoid memory issues
- Save after each batch to persist progress

### Image Loading
- Use AsyncImage for lazy loading
- Scryfall provides multiple image sizes
- Use small images for lists, full images for details

### Search Optimization
- Index on card names (SwiftData handles automatically)
- Limit search results to reasonable number (e.g., 20)
- Debounce search input to reduce queries

## Testing Strategy

### Unit Tests (Recommended)
- Model validation logic (DeckList.isValid)
- Computed properties (quantityAvailable)
- Business rules (copy limits, card limits)

### Integration Tests (Recommended)
- Scryfall import process
- CSV export correctness
- Relationship integrity

### UI Tests (Optional)
- Critical user flows:
  - Add card to collection
  - Create deck
  - Add card to deck
  - Export data

## Future Enhancements

### Potential Architecture Changes

1. **Add Caching Layer**
   - Cache frequent searches
   - Cache rendered card images
   - Improve scroll performance

2. **Background Processing**
   - Import Scryfall data in background
   - Pre-process images
   - Calculate statistics asynchronously

3. **Sync Support**
   - Add CloudKit for multi-device sync
   - Conflict resolution strategy
   - Offline-first with sync

4. **Advanced Analytics**
   - Deck statistics calculations
   - Collection value tracking
   - Play history tracking

## Common Patterns

### Adding New Deck Type

1. Add case to `DeckType` enum
2. Implement `cardLimit` and `copyLimit`
3. Update `supportsSideboard` if needed
4. UI will automatically adapt

### Adding New Filter

1. Add UI controls (buttons, pickers)
2. Add state variable for filter
3. Update `filteredEntries` computed property
4. Consider adding to ScryfallService for reuse

### Adding New Export Format

1. Add method to CSVExportService
2. Implement formatting logic
3. Add UI button in SettingsView or DeckDetailView
4. Wire up share sheet

## Error Handling

Current strategy:
- Try/catch in async operations
- Print errors to console (development)
- Graceful degradation (show empty state)

Production recommendations:
- Add proper error types
- Show user-facing error messages
- Add analytics/logging
- Retry mechanisms for imports

## Accessibility

Built-in support:
- SwiftUI provides automatic VoiceOver
- Dynamic Type support
- High contrast support

Recommendations:
- Test with VoiceOver enabled
- Add accessibility labels where needed
- Support larger text sizes

## Localization

Currently: English only

To add localization:
- Use `LocalizedStringKey` for all user-facing text
- Create `Localizable.strings` files
- Test with different locales

---

This architecture provides a solid foundation for a production-ready MTG collection app. The modular design makes it easy to add features, and SwiftData handles the complexity of relationships and persistence.
