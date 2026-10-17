//
//  KokoroVoiceTests.swift
//  stepbuddyTests
//
//  Created by Sai Vikshit Kode on 10/16/26.
//

import Foundation
import Testing
@testable import stepbuddy

struct KokoroVoiceTests {
    @Test func parsesAccentGenderAndName() throws {
        let heart = try #require(KokoroVoice(id: "af_heart"))
        #expect(heart.name == "Heart")
        #expect(!heart.isBritish)
        #expect(heart.isFemale)
        #expect(heart.accentName == "American English")

        let george = try #require(KokoroVoice(id: "bm_george"))
        #expect(george.name == "George")
        #expect(george.isBritish)
        #expect(!george.isFemale)
    }

    @Test func rejectsUnrecognizedIdentifiers() {
        for id in ["", "heart", "af", "af_", "zf_heart", "ax_heart", "abc_heart"] {
            #expect(KokoroVoice(id: id) == nil, "\(id)")
        }
    }

    @Test func sectionsGroupByAccentAndGenderSortedByName() {
        let sections = KokoroVoice.sections(["bm_lewis", "af_sky", "am_adam", "af_bella", "bm_george", "junk"])

        #expect(sections.map(\.title) == ["American · Female", "American · Male", "British · Male"])
        #expect(sections[0].voices.map(\.name) == ["Bella", "Sky"])
        #expect(sections[2].voices.map(\.name) == ["George", "Lewis"])
    }
}
