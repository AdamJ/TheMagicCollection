//
//  CODE_SNIPPETS.swift
//  Common code patterns for MTG Collection App
//
//  These are reference snippets - copy and adapt as needed
//

import SwiftUI
import SwiftData

// MARK: - SwiftData Query Examples

// ═══════════════════════════════════════════════════════════════════════
// BASIC QUERIES
// ═══════════════════════════════════════════════════════════════════════

struct QueryExamples: View {
    // Simple query with sorting
    @Query(sort: \CollectionEntry.dateAdded, order: .reverse)
    private var entries: [CollectionEntry]
    
    // Query with predicate
    @Query(filter: #Predicate<DeckList> { deck in
        deck.deckType == .commander
    }, sort: \DeckList.name)
    private var commanderDecks: [DeckList]
    
    // Multiple sort descriptors
    @Query(sort: [
        SortDescriptor(\Card.name),
        SortDescriptor(\Card.setCode)
    ])
    private var cards: [Card]
    
    var body: some View {
        List(entries) { entry in
            Text(entry.card?.name ?? "Unknown")
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════
// MANUAL FETCHING
// ═══════════════════════════════════════════════════════════════════════

extension View {
    func fetchCardsExample(modelContext: ModelContext) throws {
        // Fetch with predicate
        let predicate = #Predicate<Card> { card in
            card.colors.contains("R") && card.manaValue <= 3
        }
        
        let descriptor = FetchDescriptor<Card>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.name)]
        )
        
        let redCards = try modelContext.fetch(descriptor)
        print("Found \(redCards.count) red cards with CMC <= 3")
        
        // Fetch with limit
        var limitedDescriptor = FetchDescriptor<Card>(
            sortBy: [SortDescriptor(\.dateAdded)]
        )
        limitedDescriptor.fetchLimit = 10
        
        let recentCards = try modelContext.fetch(limitedDescriptor)
        print("Most recent 10 cards: \(recentCards.map { $0.name })")
    }
}

// ═══════════════════════════════════════════════════════════════════════
// COMPLEX PREDICATES
// ═══════════════════════════════════════════════════════════════════════

func complexPredicateExamples(modelContext: ModelContext) throws {
    // Multiple conditions with AND
    let predicate1 = #Predicate<Card> { card in
        card.colors.contains("U") &&
        card.typeLine.contains("Creature") &&
        card.rarity == "rare"
    }
    
    // String operations
    let predicate2 = #Predicate<Card> { card in
        card.name.localizedStandardContains("Dragon") ||
        card.typeLine.localizedStandardContains("Dragon")
    }
    
    // Numeric comparisons
    let predicate3 = #Predicate<Card> { card in
        card.manaValue >= 4 && card.manaValue <= 6
    }
    
    // Array operations
    let searchColors = ["U", "B"]
    let predicate4 = #Predicate<Card> { card in
        searchColors.allSatisfy { card.colors.contains($0) }
    }
    
    let descriptor = FetchDescriptor<Card>(predicate: predicate1)
    let results = try modelContext.fetch(descriptor)
}

// ═══════════════════════════════════════════════════════════════════════
// CRUD OPERATIONS
// ═══════════════════════════════════════════════════════════════════════

extension View {
    // CREATE
    func createCard(modelContext: ModelContext) {
        let card = Card(
            scryfallId: UUID().uuidString,
            name: "Test Card",
            setCode: "TST",
            setName: "Test Set",
            collectorNumber: "1",
            typeLine: "Creature",
            rarity: "common"
        )
        
        modelContext.insert(card)
        
        // Save is automatic, but can be forced
        try? modelContext.save()
    }
    
    // READ
    func readCard(modelContext: ModelContext, id: String) throws -> Card? {
        let predicate = #Predicate<Card> { card in
            card.scryfallId == id
        }
        
        let descriptor = FetchDescriptor<Card>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }
    
    // UPDATE
    func updateCard(card: Card) {
        card.name = "Updated Name"
        // SwiftData automatically tracks changes
        // Save happens automatically
    }
    
    // DELETE
    func deleteCard(modelContext: ModelContext, card: Card) {
        modelContext.delete(card)
        // Cascade rules will delete related CollectionEntries
    }
}

// ═══════════════════════════════════════════════════════════════════════
// RELATIONSHIP OPERATIONS
// ═══════════════════════════════════════════════════════════════════════

func relationshipExamples(modelContext: ModelContext) {
    // Create related objects
    let card = Card(
        scryfallId: "123",
        name: "Lightning Bolt",
        setCode: "LEA",
        setName: "Alpha",
        collectorNumber: "161",
        typeLine: "Instant",
        rarity: "common"
    )
    
    let entry = CollectionEntry(
        card: card,
        quantityOwned: 4
    )
    
    // Insert both
    modelContext.insert(card)
    modelContext.insert(entry)
    
    // Access relationship
    if let cardFromEntry = entry.card {
        print("Card name: \(cardFromEntry.name)")
    }
    
    // Access inverse relationship
    if let entries = card.collectionEntries {
        print("This card is in \(entries.count) collection entries")
    }
}

// ═══════════════════════════════════════════════════════════════════════
// COMPUTED PROPERTIES FOR BUSINESS LOGIC
// ═══════════════════════════════════════════════════════════════════════

extension CollectionEntry {
    // Example: Get decks using this card
    var decksUsingThisCard: [DeckList] {
        guard let deckEntries = deckEntries else { return [] }
        return deckEntries.compactMap { $0.parentDeck }
    }
    
    // Example: Check if card is available
    var isAvailable: Bool {
        quantityAvailable > 0
    }
    
    // Example: Get color identity
    var colorIdentity: [String] {
        card?.colorIdentity ?? []
    }
}

extension DeckList {
    // Example: Get all cards in deck
    var allCards: [Card] {
        let mainCards = mainDeck?.compactMap { $0.collectionEntry?.card } ?? []
        let sideboardCards = sideboard?.compactMap { $0.collectionEntry?.card } ?? []
        return mainCards + sideboardCards
    }
    
    // Example: Get color identity of deck
    var deckColorIdentity: Set<String> {
        let allColors = allCards.flatMap { $0.colorIdentity }
        return Set(allColors)
    }
    
    // Example: Get deck value (if you add prices)
    var totalValue: Double {
        let mainValue = mainDeck?.reduce(0.0) { sum, entry in
            let price = entry.collectionEntry?.card?.price ?? 0.0
            return sum + (price * Double(entry.quantity))
        } ?? 0.0
        
        let sideboardValue = sideboard?.reduce(0.0) { sum, entry in
            let price = entry.collectionEntry?.card?.price ?? 0.0
            return sum + (price * Double(entry.quantity))
        } ?? 0.0
        
        return mainValue + sideboardValue
    }
}

// ═══════════════════════════════════════════════════════════════════════
// VALIDATION HELPERS
// ═══════════════════════════════════════════════════════════════════════

extension DeckList {
    // Check if adding a card would be valid
    func canAddCard(_ card: Card, quantity: Int, toSection section: String) -> (Bool, String?) {
        // Check if would exceed card limit
        if let limit = deckType.cardLimit {
            let currentCount = section == "main" ? mainDeckCount : sideboardCount
            if currentCount + quantity > limit {
                return (false, "Would exceed \(section) deck limit of \(limit)")
            }
        }
        
        // Check copy limit
        let copyLimit = deckType.copyLimit
        let currentCopies = countCopies(of: card, in: section)
        
        if !isBasicLand(card.name) && (currentCopies + quantity) > copyLimit {
            return (false, "Would exceed copy limit of \(copyLimit)")
        }
        
        return (true, nil)
    }
    
    private func countCopies(of card: Card, in section: String) -> Int {
        let entries = section == "main" ? (mainDeck ?? []) : (sideboard ?? [])
        return entries
            .filter { $0.collectionEntry?.card?.name == card.name }
            .reduce(0) { $0 + $1.quantity }
    }
    
    private func isBasicLand(_ name: String) -> Bool {
        ["Plains", "Island", "Swamp", "Mountain", "Forest", "Wastes"].contains(name)
    }
}

// ═══════════════════════════════════════════════════════════════════════
// UI HELPERS
// ═══════════════════════════════════════════════════════════════════════

// Mana symbol rendering
struct ManaSymbol: View {
    let symbol: String  // e.g., "W", "U", "B", "R", "G", "1", "2", etc.
    
    var body: some View {
        Text(symbol)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .frame(width: 20, height: 20)
            .background(symbolColor)
            .clipShape(Circle())
    }
    
    var symbolColor: Color {
        switch symbol {
        case "W": return .white
        case "U": return .blue
        case "B": return .black
        case "R": return .red
        case "G": return .green
        default: return .gray
        }
    }
}

// Parse mana cost string
extension String {
    func parseManaSymbols() -> [String] {
        // Parse "{2}{U}{U}" into ["2", "U", "U"]
        let pattern = "\\{([^}]+)\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        
        let matches = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
        
        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: self) else { return nil }
            return String(self[range])
        }
    }
}

// Display mana cost
struct ManaSymbolsView: View {
    let manaCost: String
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(manaCost.parseManaSymbols(), id: \.self) { symbol in
                ManaSymbol(symbol: symbol)
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════
// ASYNC/AWAIT PATTERNS
// ═══════════════════════════════════════════════════════════════════════

// Async data loading
class DataLoader: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    
    @MainActor
    func loadData(modelContext: ModelContext) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Simulate long-running task
            try await Task.sleep(for: .seconds(1))
            
            // Do work on main actor
            // modelContext operations are main-actor isolated
            
        } catch {
            self.error = error
        }
    }
}

// Background processing
func processInBackground(modelContext: ModelContext) async {
    await Task.detached {
        // Heavy computation here
        let results = await expensiveOperation()
        
        // Update UI on main actor
        await MainActor.run {
            // Update SwiftData here
        }
    }.value
}

func expensiveOperation() async -> [String] {
    // Simulate work
    return []
}

// ═══════════════════════════════════════════════════════════════════════
// ERROR HANDLING
// ═══════════════════════════════════════════════════════════════════════

enum AppError: LocalizedError {
    case cardNotFound
    case insufficientQuantity
    case deckLimitExceeded
    case invalidDeckConfiguration
    case importFailed(String)
    case exportFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .cardNotFound:
            return "Card not found in database"
        case .insufficientQuantity:
            return "Not enough cards available"
        case .deckLimitExceeded:
            return "Deck exceeds card limit"
        case .invalidDeckConfiguration:
            return "Invalid deck configuration"
        case .importFailed(let reason):
            return "Import failed: \(reason)"
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        }
    }
}

// Error handling in views
struct ErrorHandlingExample: View {
    @State private var error: Error?
    @State private var showError = false
    
    var body: some View {
        VStack {
            Button("Do Something") {
                doSomething()
            }
        }
        .alert("Error", isPresented: $showError, presenting: error) { _ in
            Button("OK") { }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
    
    func doSomething() {
        do {
            // try something
            throw AppError.cardNotFound
        } catch {
            self.error = error
            self.showError = true
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════
// DEBOUNCED SEARCH
// ═══════════════════════════════════════════════════════════════════════

class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var results: [Card] = []
    
    private var searchTask: Task<Void, Never>?
    
    init() {
        // Watch for search text changes
        Task {
            for await searchText in $searchText.values {
                await performSearch(searchText)
            }
        }
    }
    
    @MainActor
    private func performSearch(_ text: String) async {
        // Cancel previous search
        searchTask?.cancel()
        
        // Debounce
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            
            guard !Task.isCancelled else { return }
            
            // Perform actual search
            // results = ...
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════
// FORMATTING HELPERS
// ═══════════════════════════════════════════════════════════════════════

extension Date {
    func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func relativeFormatted() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

extension Int {
    func formatted() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Double {
    func asCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: self)) ?? "$\(self)"
    }
}

// ═══════════════════════════════════════════════════════════════════════
// TESTING HELPERS
// ═══════════════════════════════════════════════════════════════════════

#if DEBUG
extension ModelContainer {
    // Create in-memory container for previews
    static var preview: ModelContainer {
        let schema = Schema([
            Card.self,
            CollectionEntry.self,
            DeckList.self,
            DeckEntry.self
        ])
        
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        
        // Add sample data
        let context = container.mainContext
        
        let card = Card(
            scryfallId: "preview-1",
            name: "Sample Card",
            setCode: "TST",
            setName: "Test Set",
            collectorNumber: "1",
            typeLine: "Creature — Human",
            rarity: "rare"
        )
        
        context.insert(card)
        
        return container
    }
}
#endif

// Usage in previews:
#Preview {
    CollectionView()
        .modelContainer(.preview)
}

// ═══════════════════════════════════════════════════════════════════════
// PERFORMANCE TIPS
// ═══════════════════════════════════════════════════════════════════════

/*
 1. Use @Query for automatic updates, but be mindful of large datasets
 2. Use fetchLimit when you only need a subset
 3. Implement pagination for large lists
 4. Use AsyncImage with proper placeholders
 5. Cache expensive computations
 6. Batch operations when possible
 7. Use background contexts for heavy imports
 8. Profile with Instruments to find bottlenecks
 
 Example pagination:
 */

struct PaginatedList: View {
    @Query private var allItems: [CollectionEntry]
    @State private var displayCount = 20
    
    var body: some View {
        List {
            ForEach(allItems.prefix(displayCount), id: \.self) { item in
                Text(item.card?.name ?? "")
            }
            
            if displayCount < allItems.count {
                Button("Load More") {
                    displayCount += 20
                }
            }
        }
    }
}
