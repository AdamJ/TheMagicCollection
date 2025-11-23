# MTG Collection App - Quick Start Guide

## What I've Created For You

I've built a complete foundation for your Magic: The Gathering collection management iOS app. Here's what you have:

### ✅ Complete SwiftData Models
- **Card**: Represents MTG cards from Scryfall
- **CollectionEntry**: Your owned cards with quantity tracking
- **DeckList**: Decks and lists with validation
- **DeckEntry**: Cards in decks (marks them as "in use")

### ✅ Core Services
- **ScryfallService**: Import and search Scryfall card database
- **CSVExportService**: Export your data for backup

### ✅ Full UI Implementation
- **Collection View**: Browse your cards in list or grid view
- **Deck Builder**: Create and manage multiple deck types
- **Card Scanner**: Framework for camera-based scanning (needs ML implementation)
- **Manual Entry**: Search and add cards manually
- **Settings**: Import data, export backups, manage app

### ✅ Key Features
- ✓ Track physical card quantities
- ✓ Mark cards as "in-use" when added to decks
- ✓ Automatic deck validation (card limits, copy limits)
- ✓ Support for Commander, Standard, Draft, and Wish Lists
- ✓ Color filtering and name search
- ✓ CSV export for backup
- ✓ iPad and iPhone support

## How to Get Started

### Step 1: Create Xcode Project
```bash
1. Open Xcode
2. File > New > Project
3. Choose: iOS > App
4. Product Name: MTGCollectionApp
5. Interface: SwiftUI
6. Language: Swift
7. Storage: None (we add SwiftData manually)
8. Create
```

### Step 2: Add the Files
Copy all the provided files into your Xcode project:

```
MTGCollectionApp/
├── MTGCollectionApp.swift          ← App entry point
├── Models/
│   ├── Card.swift
│   ├── CollectionEntry.swift
│   ├── DeckList.swift
│   └── DeckEntry.swift
├── Services/
│   ├── ScryfallService.swift
│   └── CSVExportService.swift
└── Views/
    ├── ContentView.swift
    ├── CollectionView.swift
    ├── CollectionEntryDetailView.swift
    ├── DecksListView.swift
    ├── DeckDetailView.swift
    ├── CardScannerView.swift
    ├── ManualCardEntryView.swift
    └── SettingsView.swift
```

### Step 3: Download Scryfall Data
1. Visit: https://scryfall.com/docs/api/bulk-data
2. Find "Default Cards" 
3. Click "Download" (JSON format)
4. Save file (will be ~200MB)

### Step 4: Build and Run
1. Select target device (iPhone or simulator)
2. Click Run (⌘R)
3. App launches with empty collection

### Step 5: Import Scryfall Data
1. In app, go to Settings tab
2. Tap "Import Scryfall Database"
3. Select the Scryfall JSON file you downloaded
4. Wait for import (may take 2-3 minutes)
5. You now have 80,000+ cards to search!

### Step 6: Test the App
1. Go to Collection tab
2. Tap + menu > "Manual Entry"
3. Search for "Lightning Bolt"
4. Select a printing
5. Add quantity
6. Card appears in your collection!

7. Go to Decks tab
8. Tap + to create a deck
9. Choose "Commander" type
10. Open the deck
11. Add cards from your collection
12. Watch as they're marked "in use"!

## What Works Right Now

### ✅ Fully Functional
- Creating and browsing collection
- Adding cards manually
- Searching by name
- Filtering by color
- Creating decks of all types
- Adding cards to decks
- Deck validation
- In-use tracking
- CSV export
- Settings and data management

### ⚠️ Needs Implementation
- **Card Scanner**: Framework is there, needs VisionKit integration
- **ML Recognition**: Need to train/integrate card recognition model
- **Price Tracking**: Need to add price API integration
- **Statistics**: Need to add charts for mana curve, etc.

## Architecture Overview

### Data Flow
```
Scryfall JSON → Card (database)
     ↓
User scans/adds → CollectionEntry (owned cards)
     ↓
User builds deck → DeckEntry (marks card in-use)
     ↓
Belongs to → DeckList (the deck itself)
```

### Key Relationships
- One **Card** can have many **CollectionEntries** (different printings)
- One **CollectionEntry** can have many **DeckEntries** (used in multiple decks)
- One **DeckList** has many **DeckEntries** (main deck + sideboard)

### Automatic Features
- **Computed Quantities**: Available cards = Owned - In Use
- **Cascade Deletes**: Delete deck → cards become available again
- **Validation**: Deck automatically checks card/copy limits
- **Two-way Relationships**: SwiftData keeps everything in sync

## Understanding the Code

### Models (SwiftData)
```swift
@Model
final class CollectionEntry {
    var card: Card?
    var quantityOwned: Int
    
    // Computed automatically!
    var quantityAvailable: Int {
        quantityOwned - quantityInUse
    }
}
```

### Views (SwiftUI)
```swift
struct CollectionView: View {
    // Auto-updates when data changes!
    @Query var entries: [CollectionEntry]
    
    var body: some View {
        List(entries) { entry in
            Text(entry.card?.name ?? "")
        }
    }
}
```

### Services (Business Logic)
```swift
class ScryfallService {
    func searchCards(byName: String) -> [Card] {
        // Search local database
    }
}
```

## Next Steps

### Immediate (Do First)
1. ✅ Set up Xcode project
2. ✅ Copy files
3. ✅ Import Scryfall data
4. ✅ Test basic functionality
5. 🔨 Add app icon
6. 🔨 Test on real device

### Short Term (This Week)
1. Implement card scanner with VisionKit
2. Add more filter options
3. Improve card detail view
4. Add deck statistics
5. Test with larger collection

### Medium Term (This Month)
1. Add price tracking
2. Implement deck analysis
3. Add custom tags/categories
4. Support multiple printings
5. Add deck import/export formats

### Long Term (Future)
1. CloudKit sync for multi-device
2. Widgets for collection stats
3. Apple Watch life counter
4. Community features
5. App Store release

## Common Tasks

### Adding a New Deck Type
```swift
// In DeckList.swift, add to enum:
enum DeckType: String, CaseIterable {
    case brawl = "Brawl (60)"
    
    var cardLimit: Int? {
        case .brawl: return 60
    }
    
    var copyLimit: Int {
        case .brawl: return 1  // Singleton
    }
}
```

### Adding a New Filter
```swift
// In CollectionView.swift:
@State private var selectedRarity = ""

var filteredEntries: [CollectionEntry] {
    entries.filter { entry in
        selectedRarity.isEmpty || 
        entry.card?.rarity == selectedRarity
    }
}
```

### Customizing Export Format
```swift
// In CSVExportService.swift:
func exportToCustomFormat() throws -> URL {
    var text = "Name,Quantity\n"
    // Add your custom logic
    return try saveToTempFile(text, filename: "export.csv")
}
```

## Troubleshooting

### Import Fails
- Check file is valid JSON
- Ensure app has file access permissions
- Try smaller test file first
- Check console for specific error

### Cards Not Appearing
- Verify import completed successfully
- Check search filters aren't too restrictive
- Try clearing filters
- Check database in Settings

### Deck Validation Issues
- Review deck type rules
- Check for basic land exceptions
- Verify copy counts
- Look at validation errors in detail view

### Performance Slow
- Limit search results
- Use pagination for large lists
- Reduce image quality if needed
- Profile with Instruments

## Resources

### Documentation
- README.md: Project overview
- ARCHITECTURE.md: Deep dive into design
- DATA_MODEL_DIAGRAM.md: Visual relationships
- CODE_SNIPPETS.swift: Common patterns
- IMPLEMENTATION_CHECKLIST.md: Feature tracking

### External Resources
- Scryfall API: https://scryfall.com/docs/api
- SwiftData Docs: https://developer.apple.com/documentation/swiftdata
- VisionKit Docs: https://developer.apple.com/documentation/visionkit

## Questions?

Common questions answered:

**Q: Do I need an internet connection?**
A: Only for initial Scryfall import. After that, app works offline.

**Q: Can I use this with multiple devices?**
A: Not yet. CloudKit sync is a future enhancement.

**Q: How do I update card data?**
A: Re-import the latest Scryfall file via Settings.

**Q: Can I track digital cards (Arena/MTGO)?**
A: Not currently. This tracks physical cards only.

**Q: Is card scanning accurate?**
A: Card scanner needs ML implementation. Manual entry is 100% accurate.

**Q: Can I share decks with friends?**
A: Yes, via CSV export. Import feature coming later.

## Contributing Ideas

Want to add features? Great places to start:

1. **Easy**: Add more color theme options
2. **Easy**: Improve empty state graphics
3. **Medium**: Implement mana curve chart
4. **Medium**: Add price tracking integration
5. **Hard**: Build ML card recognition model
6. **Hard**: Add CloudKit sync

## License & Acknowledgments

- Magic: The Gathering © Wizards of the Coast
- Card data provided by Scryfall
- This is a personal project template
- Feel free to customize and extend!

---

**Ready to build?** Start with Step 1 above and you'll have a working app in 15 minutes! 🎉

For questions or issues, refer to the detailed documentation in ARCHITECTURE.md or CODE_SNIPPETS.swift.

Happy deck building! 🃏✨
