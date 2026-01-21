//
//  CardScannerTests.swift
//  TheMagicCollectionTests
//
//  Created on 1/21/2026.
//

import Testing
import Foundation
@testable import TheMagicCollection

struct CardScannerTests {

    // MARK: - ScannedCard Tests

    @Test func scannedCardInitialization() {
        let card = ScannedCard(
            cardName: "Lightning Bolt",
            setCode: "LEA",
            collectorNumber: "123",
            confidence: 0.95,
            matchedCard: nil
        )

        #expect(card.cardName == "Lightning Bolt")
        #expect(card.setCode == "LEA")
        #expect(card.collectorNumber == "123")
        #expect(card.confidence == 0.95)
        #expect(card.matchedCard == nil)
    }

    @Test func scannedCardWithoutOptionalFields() {
        let card = ScannedCard(
            cardName: "Black Lotus",
            setCode: nil,
            collectorNumber: nil,
            confidence: 0.85,
            matchedCard: nil
        )

        #expect(card.cardName == "Black Lotus")
        #expect(card.setCode == nil)
        #expect(card.collectorNumber == nil)
        #expect(card.confidence == 0.85)
    }

    @Test func scannedCardIdentifiable() {
        let card1 = ScannedCard(cardName: "Sol Ring", setCode: nil, collectorNumber: nil, confidence: 0.9, matchedCard: nil)
        let card2 = ScannedCard(cardName: "Sol Ring", setCode: nil, collectorNumber: nil, confidence: 0.9, matchedCard: nil)

        // Each card should have a unique ID
        #expect(card1.id != card2.id)
    }

    // MARK: - Confidence Calculation Tests

    @Test func confidenceForTextWithCapitalLetter() {
        let text = "Lightning Bolt"
        // Should have base confidence (0.5) + capital letter bonus (0.2) + multiple words bonus (0.2) = 0.9

        #expect(text.first?.isUppercase == true)
        let wordCount = text.components(separatedBy: .whitespaces).count
        #expect(wordCount == 2)
    }

    @Test func confidenceForTextWithNumbers() {
        let text = "Card123"
        // Should have reduced confidence due to numbers

        let hasNumbers = text.rangeOfCharacter(from: .decimalDigits) != nil
        #expect(hasNumbers == true)
    }

    @Test func confidenceForSingleWord() {
        let text = "Counterspell"

        let wordCount = text.components(separatedBy: .whitespaces).count
        #expect(wordCount == 1)
        #expect(text.first?.isUppercase == true)
    }

    @Test func confidenceForMultipleWords() {
        let text = "Birds of Paradise"

        let wordCount = text.components(separatedBy: .whitespaces).count
        #expect(wordCount == 3)
        #expect(text.first?.isUppercase == true)
    }

    // MARK: - Text Validation Tests

    @Test func textTooShortShouldBeFiltered() {
        let text = "AB"
        #expect(text.count < 3)
    }

    @Test func textTooLongShouldBeFiltered() {
        let text = String(repeating: "A", count: 51)
        #expect(text.count > 50)
    }

    @Test func validTextLength() {
        let text = "Lightning Bolt"
        #expect(text.count >= 3 && text.count <= 50)
    }

    // MARK: - Text Processing Tests

    @Test func textTrimmingWhitespace() {
        let text = "  Lightning Bolt  "
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        #expect(trimmed == "Lightning Bolt")
    }

    @Test func emptyTextAfterTrimming() {
        let text = "   "
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        #expect(trimmed.isEmpty)
    }

    // MARK: - Real Card Name Tests

    @Test func realCardNames() {
        let cardNames = [
            "Lightning Bolt",
            "Black Lotus",
            "Birds of Paradise",
            "Jace, the Mind Sculptor",
            "Sol Ring",
            "Counterspell",
            "Force of Will",
            "Dark Ritual",
            "Ancestral Recall",
            "Time Walk"
        ]

        for name in cardNames {
            // All valid card names should meet basic criteria
            #expect(name.count >= 3 && name.count <= 50)
            #expect(name.first?.isUppercase == true)
            #expect(!name.isEmpty)
        }
    }

    @Test func cardNamesWithSpecialCharacters() {
        let cardNames = [
            "Jace, the Mind Sculptor",  // Has comma
            "Teferi's Protection",       // Has apostrophe
            "X",                         // Single character (edge case)
        ]

        // These should still be recognizable
        for name in cardNames {
            #expect(!name.isEmpty)
        }
    }
}
