//
//  KokoroTextTests.swift
//  stepbuddyTests
//
//  Created by Sai Vikshit Kode on 10/16/26.
//

import Foundation
import Testing
@testable import stepbuddy

struct KokoroTextTests {
    // MARK: - chunks

    @Test func chunksSplitIntoSentences() {
        let chunks = KokoroText.chunks("You walked 9,200 steps. That's up 12%! Keep going?")

        #expect(chunks == ["You walked 9,200 steps.", "That's up 12%!", "Keep going?"])
    }

    @Test func chunksCollapseWhitespaceAndDropBlanks() {
        #expect(KokoroText.chunks("  First   one.\n\n  Second\tone.  ") == ["First one.", "Second one."])
        #expect(KokoroText.chunks(" \n ").isEmpty)
    }

    @Test func chunksSplitLongSentencesBetweenWords() {
        let chunks = KokoroText.chunks("one two three four five six", maxLength: 10)

        #expect(chunks == ["one two", "three four", "five six"])
        #expect(chunks.allSatisfy { $0.count <= 10 })
    }

    @Test func chunksKeepAWordLongerThanTheLimitWhole() {
        #expect(KokoroText.chunks("supercalifragilistic word", maxLength: 10) == ["supercalifragilistic", "word"])
    }

    // MARK: - passage

    @Test func passageEndsEachPartWithAFullStop() {
        let text = KokoroText.passage(["You walked more this month.", "Best day: 14,200 steps", "Nice work!", "Try a walk after lunch"])

        #expect(text == "You walked more this month. Best day: 14,200 steps. Nice work! Try a walk after lunch.")
    }

    @Test func passageSkipsMissingAndBlankParts() {
        #expect(KokoroText.passage([nil, " ", "Steady weight"]) == "Steady weight.")
        #expect(KokoroText.passage([nil]).isEmpty)
    }
}
