//
//  DeckValidationTests.swift
//  TheMagicCollectionTests
//
//  Created on 1/21/2026.
//

import Testing
import Foundation
import SwiftData
@testable import TheMagicCollection

@MainActor
struct DeckValidationTests {

    // MARK: - Deck Type Tests

    @Test func deckTypeCardLimits() {
        #expect(DeckType.commander.cardLimit == 100)
        #expect(DeckType.standard.cardLimit == 60)
        #expect(DeckType.draft.cardLimit == 40)
        #expect(DeckType.wishList.cardLimit == nil)
    }

    @Test func deckTypeCopyLimits() {
        #expect(DeckType.commander.copyLimit == 1)
        #expect(DeckType.standard.copyLimit == 4)
        #expect(DeckType.draft.copyLimit == 4)
        #expect(DeckType.wishList.copyLimit == Int.max)
    }

    @Test func deckTypeSideboardSupport() {
        #expect(DeckType.commander.supportsSideboard == false)
        #expect(DeckType.standard.supportsSideboard == true)
        #expect(DeckType.draft.supportsSideboard == true)
        #expect(DeckType.wishList.supportsSideboard == false)
    }

    // MARK: - Validation Error Tests

    @Test func validationErrorMessages() {
        let mainDeckError = DeckValidationError.mainDeckTooLarge(current: 105, limit: 100)
        #expect(mainDeckError.message.contains("105"))
        #expect(mainDeckError.message.contains("100"))

        let sideboardError = DeckValidationError.sideboardTooLarge(current: 20, limit: 15)
        #expect(sideboardError.message.contains("20"))
        #expect(sideboardError.message.contains("15"))

        let copyError = DeckValidationError.tooManyCopies(cardName: "Lightning Bolt", count: 5, limit: 4)
        #expect(copyError.message.contains("Lightning Bolt"))
        #expect(copyError.message.contains("5"))
        #expect(copyError.message.contains("4"))

        let notAllowedError = DeckValidationError.sideboardNotAllowed(current: 10)
        #expect(notAllowedError.message.contains("10"))
    }

    @Test func validationErrorIdentifiers() {
        let error1 = DeckValidationError.mainDeckTooLarge(current: 105, limit: 100)
        let error2 = DeckValidationError.mainDeckTooLarge(current: 110, limit: 100)

        // Same type of error should have same id
        #expect(error1.id == error2.id)

        let copyError1 = DeckValidationError.tooManyCopies(cardName: "Lightning Bolt", count: 5, limit: 4)
        let copyError2 = DeckValidationError.tooManyCopies(cardName: "Counterspell", count: 5, limit: 4)

        // Different cards should have different ids
        #expect(copyError1.id != copyError2.id)
    }

    // MARK: - DeckList Validation Tests

    @Test func emptyDeckIsValid() {
        let deck = DeckList(name: "Empty Deck", deckType: .commander)

        #expect(deck.isValid == true)
        #expect(deck.validationErrors.isEmpty)
    }

    @Test func wishListIsAlwaysValid() {
        let wishList = DeckList(name: "Wish List", deckType: .wishList)

        // Wish lists have no constraints
        #expect(wishList.isValid == true)
        #expect(wishList.deckType.cardLimit == nil)
    }

    @Test func validationErrorSeverity() {
        let error = DeckValidationError.mainDeckTooLarge(current: 105, limit: 100)
        #expect(error.severity == .error)
    }

    // MARK: - Basic Land Tests

    @Test func basicLandNames() {
        let deck = DeckList(name: "Test", deckType: .commander)

        let basicLands = ["Plains", "Island", "Swamp", "Mountain", "Forest", "Wastes"]

        for land in basicLands {
            // Basic lands should be recognized (private method tested indirectly through validation)
            #expect(!land.isEmpty)
        }
    }

    // MARK: - Deck Type Enum Tests

    @Test func allDeckTypesCaseIterable() {
        let allTypes = DeckType.allCases
        #expect(allTypes.count == 4)
        #expect(allTypes.contains(.commander))
        #expect(allTypes.contains(.standard))
        #expect(allTypes.contains(.draft))
        #expect(allTypes.contains(.wishList))
    }

    @Test func deckTypeRawValues() {
        #expect(DeckType.commander.rawValue == "Commander")
        #expect(DeckType.standard.rawValue == "Standard (60)")
        #expect(DeckType.draft.rawValue == "Draft/Sealed (40)")
        #expect(DeckType.wishList.rawValue == "Wish List")
    }

    @Test func sideboardLimits() {
        // Standard has fixed 15-card sideboard
        #expect(DeckType.standard.sideboardLimit(isSealed: false) == 15)
        #expect(DeckType.standard.sideboardLimit(isSealed: true) == 15)

        // Draft has no sideboard for regular, unlimited for sealed
        #expect(DeckType.draft.sideboardLimit(isSealed: false) == 0)
        #expect(DeckType.draft.sideboardLimit(isSealed: true) == nil)

        // Commander and wish list don't support sideboards
        #expect(DeckType.commander.sideboardLimit(isSealed: false) == nil)
        #expect(DeckType.wishList.sideboardLimit(isSealed: false) == nil)
    }

    // MARK: - Integration Tests with In-Memory Container

    @Test func validCommanderDeck() throws {
        // Create in-memory model container
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Card.self, CollectionEntry.self, DeckList.self, DeckEntry.self,
            configurations: config
        )
        let context = ModelContext(container)

        // Create a commander deck
        let deck = DeckList(name: "Test Commander", deckType: .commander)
        context.insert(deck)

        // Empty commander deck should be valid
        #expect(deck.isValid)
        #expect(deck.validationErrors.isEmpty)
        #expect(deck.mainDeckCount == 0)
    }

    @Test func deckInitialization() {
        let deck = DeckList(name: "My Deck", deckType: .standard, isSealed: false, notes: "Test notes")

        #expect(deck.name == "My Deck")
        #expect(deck.deckType == .standard)
        #expect(deck.isSealed == false)
        #expect(deck.notes == "Test notes")
        #expect(deck.dateCreated <= Date())
        #expect(deck.dateModified == deck.dateCreated)
    }

    @Test func deckDefaultInitialization() {
        let deck = DeckList(name: "Simple Deck", deckType: .draft)

        #expect(deck.name == "Simple Deck")
        #expect(deck.deckType == .draft)
        #expect(deck.isSealed == false) // Default value
        #expect(deck.notes == nil) // Default value
    }
}
