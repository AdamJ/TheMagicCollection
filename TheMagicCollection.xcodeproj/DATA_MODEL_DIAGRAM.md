# Data Model Relationships Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        MTG Collection App                            │
│                       Data Model Relationships                       │
└─────────────────────────────────────────────────────────────────────┘


┌──────────────────────────┐
│         Card             │  ← From Scryfall Database
├──────────────────────────┤
│ • scryfallId (unique)    │
│ • name                   │
│ • setCode                │
│ • setName                │
│ • collectorNumber        │
│ • manaCost               │
│ • manaValue              │
│ • typeLine               │
│ • oracleText             │
│ • colors []              │
│ • colorIdentity []       │
│ • rarity                 │
│ • imageURI               │
│ • imageURISmall          │
└────────────┬─────────────┘
             │
             │ one-to-many
             │ @Relationship(deleteRule: .cascade)
             ↓
┌──────────────────────────┐
│   CollectionEntry        │  ← User's Owned Cards
├──────────────────────────┤
│ • card → Card            │
│ • quantityOwned          │
│ • dateAdded              │
│ • notes                  │
│                          │
│ Computed Properties:     │
│ • quantityAvailable      │  = owned - inUse
│ • quantityInUse          │  = sum of all deck entries
└────────────┬─────────────┘
             │
             │ one-to-many
             │ @Relationship(deleteRule: .cascade)
             ↓
┌──────────────────────────┐
│      DeckEntry           │  ← Cards in Decks
├──────────────────────────┤
│ • collectionEntry →      │
│   CollectionEntry        │
│ • deckList → DeckList    │  (main deck)
│ • sideboardDeckList →    │  (or sideboard)
│   DeckList               │
│ • quantity               │
│ • dateAdded              │
│ • notes                  │
│                          │
│ Computed Properties:     │
│ • isSideboard            │
│ • parentDeck             │
└────────────┬─────────────┘
             │
             │ many-to-one
             │ @Relationship(inverse: ...)
             ↓
┌──────────────────────────┐
│       DeckList           │  ← User's Decks/Lists
├──────────────────────────┤
│ • name                   │
│ • deckType (enum)        │
│   - commander            │  100 cards, 1x copies
│   - standard             │  60 cards, 4x copies
│   - draft                │  40 cards, 4x copies
│   - wishList             │  unlimited
│ • isSealed               │
│ • dateCreated            │
│ • dateModified           │
│ • notes                  │
│ • mainDeck [] →          │
│   DeckEntry              │
│ • sideboard [] →         │
│   DeckEntry              │
│                          │
│ Computed Properties:     │
│ • mainDeckCount          │
│ • sideboardCount         │
│ • isValid                │  (validates limits)
└──────────────────────────┘


═══════════════════════════════════════════════════════════════════════

USER WORKFLOW EXAMPLES
═══════════════════════════════════════════════════════════════════════

1. ADDING A CARD TO COLLECTION
   ────────────────────────────

   User scans/enters "Lightning Bolt"
            ↓
   Search Scryfall database for Card
            ↓
   User selects set: "Alpha" #161
            ↓
   Create/Update CollectionEntry:
   - card = Alpha Lightning Bolt
   - quantityOwned = 4
            ↓
   Card appears in collection


2. BUILDING A COMMANDER DECK
   ──────────────────────────

   User creates DeckList:
   - name: "My Atraxa Deck"
   - deckType: .commander
            ↓
   User adds Lightning Bolt from collection
            ↓
   Check: quantityAvailable > 0? ✓
   Check: Would exceed copy limit? ✗ (1 allowed, 0 in deck)
            ↓
   Create DeckEntry:
   - collectionEntry = Lightning Bolt entry
   - deckList = Atraxa deck
   - quantity = 1
            ↓
   CollectionEntry now shows:
   - quantityOwned: 4
   - quantityAvailable: 3 (computed)
   - quantityInUse: 1 (computed)
            ↓
   Card appears in deck


3. REMOVING CARD FROM DECK
   ────────────────────────

   User deletes DeckEntry from deck
            ↓
   SwiftData cascade delete
            ↓
   CollectionEntry automatically updates:
   - quantityAvailable: 4 (computed)
   - quantityInUse: 0 (computed)
            ↓
   Card available for other decks again


═══════════════════════════════════════════════════════════════════════

VIEW HIERARCHY
═══════════════════════════════════════════════════════════════════════

ContentView (TabView)
├── Tab 1: Collection
│   │
│   ├─ CollectionView
│   │  ├── List/Grid of CollectionEntries
│   │  ├── ColorFilterView
│   │  ├── Search bar
│   │  └── Add buttons
│   │
│   ├─ CardScannerView (sheet)
│   │  └── Camera + VisionKit
│   │
│   ├─ ManualCardEntryView (sheet)
│   │  └── Search + Select + Add
│   │
│   └─ CollectionEntryDetailView (navigation)
│      ├── Card images
│      ├── Quantity editor
│      ├── Used-in list
│      └── Notes
│
├── Tab 2: Decks & Lists
│   │
│   ├─ DecksListView
│   │  ├── List of DeckLists
│   │  └── Deck stats
│   │
│   ├─ NewDeckView (sheet)
│   │  └── Name + Type + Options
│   │
│   └─ DeckDetailView (navigation)
│      ├── Deck stats header
│      ├── Main/Sideboard picker
│      ├── Card list
│      └── Export option
│      │
│      └─ AddCardToDeckView (sheet)
│         └── Select from available cards
│
└── Tab 3: Settings
    │
    └─ SettingsView
       ├── Collection stats
       ├── Import Scryfall
       ├── Export options
       └── Data management


═══════════════════════════════════════════════════════════════════════

KEY DESIGN PATTERNS
═══════════════════════════════════════════════════════════════════════

1. COMPUTED PROPERTIES FOR VALIDATION
   ───────────────────────────────────
   
   Instead of storing redundant data, we compute it:
   
   CollectionEntry.quantityAvailable:
   → quantityOwned - sum(deckEntries.quantity)
   
   DeckList.isValid:
   → Check card count against limit
   → Check copy counts against format rules
   → Check sideboard limits


2. RELATIONSHIP CASCADE DELETES
   ─────────────────────────────
   
   When you delete something, related data cleans up:
   
   Delete CollectionEntry:
   → All DeckEntries automatically deleted
   → Card removed from all decks
   
   Delete DeckList:
   → All DeckEntries automatically deleted
   → Cards become available in collection again


3. BIDIRECTIONAL RELATIONSHIPS
   ────────────────────────────
   
   SwiftData manages both directions:
   
   CollectionEntry ↔ DeckEntry:
   - CollectionEntry.deckEntries: [DeckEntry]
   - DeckEntry.collectionEntry: CollectionEntry
   
   Changes to one automatically update the other!


4. ENUM-DRIVEN UI
   ───────────────
   
   DeckType enum controls everything:
   
   enum DeckType {
       case commander  // 100 cards, 1x limit
       case standard   // 60 cards, 4x limit
       case draft      // 40 cards, 4x limit
       case wishList   // unlimited
       
       var cardLimit: Int? { ... }
       var copyLimit: Int { ... }
       var supportsSideboard: Bool { ... }
   }
   
   UI automatically adapts based on deck type!


═══════════════════════════════════════════════════════════════════════

COMMON QUERIES
═══════════════════════════════════════════════════════════════════════

// Get all collection entries
@Query(sort: \CollectionEntry.dateAdded, order: .reverse)
var collectionEntries: [CollectionEntry]

// Search cards by name
let predicate = #Predicate<Card> { card in
    card.name.localizedStandardContains("Lightning")
}

// Find available cards (not in any deck)
collectionEntries.filter { $0.quantityAvailable > 0 }

// Get all decks
@Query(sort: \DeckList.dateModified, order: .reverse)
var decks: [DeckList]

// Check if deck is valid
deck.isValid  // computed property


═══════════════════════════════════════════════════════════════════════

VALIDATION RULES
═══════════════════════════════════════════════════════════════════════

COMMANDER DECK (100 cards)
├─ Main Deck: exactly 100 cards (including commander)
├─ Copy Limit: 1 of each card
│  └─ Exception: Basic lands unlimited
└─ Sideboard: Not supported

STANDARD DECK (60 cards)
├─ Main Deck: minimum 60 cards
├─ Copy Limit: 4 of each card
│  └─ Exception: Basic lands unlimited
└─ Sideboard: maximum 15 cards

DRAFT DECK (40 cards)
├─ Main Deck: minimum 40 cards
├─ Copy Limit: 4 of each card
│  └─ Exception: Basic lands unlimited
└─ Sideboard: 
   ├─ Sealed: unlimited
   └─ Draft: none

WISH LIST
└─ Everything unlimited


═══════════════════════════════════════════════════════════════════════
```
