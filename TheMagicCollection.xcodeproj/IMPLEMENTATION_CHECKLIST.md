# Implementation Checklist

Use this checklist to track progress on implementing the MTG Collection App.

## Phase 1: Basic Setup ✅

- [x] Create SwiftData models (Card, CollectionEntry, DeckList, DeckEntry)
- [x] Set up app structure with tabs
- [x] Create collection view with list/grid toggle
- [x] Create deck list view
- [x] Create settings view
- [x] Implement CSV export service
- [x] Implement Scryfall service for database management

## Phase 2: Core Functionality

### Collection Management
- [ ] Test manual card entry flow end-to-end
- [ ] Add card image caching for better performance
- [ ] Implement edit functionality for collection entries
- [ ] Add bulk operations (delete multiple, update quantities)
- [ ] Test color filtering with real data
- [ ] Add sorting options (name, date added, set, quantity)

### Deck Building
- [ ] Test deck creation flow
- [ ] Test adding cards to deck with validation
- [ ] Verify copy limit enforcement
- [ ] Verify card limit enforcement
- [ ] Test sideboard functionality
- [ ] Add deck statistics view (mana curve, colors, types)
- [ ] Add deck notes/description
- [ ] Test deck deletion and card availability restoration

### Data Import/Export
- [ ] Test Scryfall bulk data import with real file
- [ ] Add progress indicator for import
- [ ] Handle import errors gracefully
- [ ] Test CSV export for collection
- [ ] Test CSV export for individual decks
- [ ] Test CSV export for all decks
- [ ] Add share sheet integration

## Phase 3: Card Scanning

### Vision Framework Integration
- [ ] Set up VisionKit DataScannerViewController
- [ ] Request camera permissions
- [ ] Implement text recognition for card names
- [ ] Match recognized text against Scryfall database
- [ ] Handle multiple matches (let user choose)
- [ ] Add confidence scoring
- [ ] Implement review screen for scanned cards
- [ ] Allow editing scanned results before adding
- [ ] Add batch scanning support
- [ ] Handle low-light conditions gracefully

### ML Model (Optional - Advanced)
- [ ] Train Core ML model for card recognition
- [ ] Integrate model into scanning flow
- [ ] Test accuracy with various card conditions
- [ ] Add fallback to text recognition

## Phase 4: User Experience Enhancements

### Search & Filter
- [ ] Add autocomplete for card search
- [ ] Add filter by set
- [ ] Add filter by rarity
- [ ] Add filter by card type
- [ ] Add filter by mana cost
- [ ] Add combined filters
- [ ] Save recent searches
- [ ] Add search history

### Visual Improvements
- [ ] Design app icon
- [ ] Add launch screen
- [ ] Implement proper loading states
- [ ] Add skeleton views for loading
- [ ] Add pull-to-refresh where appropriate
- [ ] Improve empty states with better graphics
- [ ] Add animations for card additions
- [ ] Polish transitions between views

### iPad Optimization
- [ ] Test on iPad and adjust layouts
- [ ] Use split views for deck building
- [ ] Optimize grid layouts for larger screens
- [ ] Add keyboard shortcuts
- [ ] Support drag and drop between views

## Phase 5: Advanced Features

### Deck Analysis
- [ ] Calculate and display mana curve
- [ ] Show color distribution pie chart
- [ ] Show card type breakdown
- [ ] Calculate average mana value
- [ ] Show rarity distribution
- [ ] Add deck comparison feature

### Card Details
- [ ] Add rulings display
- [ ] Show legality in different formats
- [ ] Display price information (via API)
- [ ] Show card printings/variations
- [ ] Add ability to switch between printings

### Collection Features
- [ ] Track card condition (NM, LP, MP, HP, Damaged)
- [ ] Track foil status
- [ ] Add custom tags/categories
- [ ] Add collection value tracking
- [ ] Show collection statistics
- [ ] Add collection goals/wishlist priority

### Deck Features
- [ ] Import deck from text format
- [ ] Export deck in Arena format
- [ ] Export deck in MTGO format
- [ ] Add deck testing mode (sample hands)
- [ ] Add mulligan simulator
- [ ] Track deck history/changes

## Phase 6: Polish & Testing

### Testing
- [ ] Write unit tests for models
- [ ] Write unit tests for validation logic
- [ ] Write unit tests for export service
- [ ] Write integration tests for data flow
- [ ] Test with large collections (1000+ cards)
- [ ] Test with many decks (20+ decks)
- [ ] Memory profiling
- [ ] Performance testing

### Accessibility
- [ ] Test with VoiceOver
- [ ] Add accessibility labels where needed
- [ ] Test with Dynamic Type (large text)
- [ ] Test with reduced motion
- [ ] Test with high contrast mode
- [ ] Add accessibility hints for complex interactions

### Error Handling
- [ ] Add proper error types
- [ ] Show user-friendly error messages
- [ ] Add retry mechanisms
- [ ] Handle network failures gracefully
- [ ] Handle file system errors
- [ ] Add error logging

### Documentation
- [ ] Add code comments to complex logic
- [ ] Document API endpoints if using online services
- [ ] Create user guide
- [ ] Add tooltips/help for first-time users
- [ ] Create video tutorial (optional)

## Phase 7: App Store Preparation

### Requirements
- [ ] Add Privacy Policy
- [ ] Add Terms of Service (if needed)
- [ ] Create App Store screenshots
- [ ] Write app description
- [ ] Add keywords for SEO
- [ ] Create promotional graphics
- [ ] Test on all supported iOS versions
- [ ] Test on all device sizes

### Compliance
- [ ] Ensure Scryfall attribution is visible
- [ ] Add WotC trademark notices
- [ ] Review Apple's App Store guidelines
- [ ] Test in-app purchase flow (if adding premium features)
- [ ] Add analytics (if desired)

### Release
- [ ] Set up App Store Connect
- [ ] Upload build for TestFlight
- [ ] Run beta test with friends
- [ ] Gather and incorporate feedback
- [ ] Submit for App Store review
- [ ] Prepare launch announcement

## Optional Advanced Features

### Cloud Features
- [ ] Add CloudKit integration for sync
- [ ] Implement conflict resolution
- [ ] Add multi-device support
- [ ] Add backup to iCloud

### Social Features
- [ ] Share decks with friends
- [ ] Compare collections
- [ ] Deck ratings/comments
- [ ] Community deck database

### Widgets
- [ ] Create collection stats widget
- [ ] Create random card widget
- [ ] Create deck summary widget
- [ ] Add Live Activities for drafts

### Apple Watch
- [ ] Life counter app
- [ ] Deck quick view
- [ ] Collection stats at a glance

### Notifications
- [ ] New set releases
- [ ] Price alerts
- [ ] Collection milestones

## Current Status

**Completed**: Phase 1 - Basic architecture and file structure created

**Next Up**: Phase 2 - Test and refine core functionality with real data

**Blockers**: Need to download Scryfall bulk data to test imports

## Notes

- Focus on core features first (Phases 1-2)
- Card scanning (Phase 3) can be deferred if needed
- Advanced features (Phase 5+) are nice-to-have
- Test frequently with real data as you go
- Don't over-engineer early - iterate based on usage

## Getting Started Today

1. Create new Xcode project
2. Copy all provided files into project
3. Download Scryfall bulk data: https://scryfall.com/docs/api/bulk-data
4. Build and run
5. Import Scryfall data via Settings
6. Test manual card entry
7. Create a test deck
8. Verify in-use tracking works

## Questions to Consider

- Do you want to support multiple currencies for prices?
- Should the app work completely offline?
- Do you plan to monetize (ads, premium features)?
- How important is cross-device sync to you?
- Should users be able to share collections publicly?

---

**Remember**: Start simple, test often, and iterate based on what works!
