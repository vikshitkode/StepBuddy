//
//  KokoroText.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 10/16/26.
//

import Foundation

/// Prepares Health Intelligence text for Kokoro, which synthesizes at most 510 phoneme tokens per call.
enum KokoroText {
    /// Splits text into sentences, generated and played one after another so audio starts after the first.
    /// A sentence longer than `maxLength` characters is split between words to stay under the token limit.
    static func chunks(_ text: String, maxLength: Int = 250) -> [String] {
        var sentences: [String] = []
        text.enumerateSubstrings(in: text.startIndex..., options: .bySentences) { sentence, _, _, _ in
            if let sentence {
                sentences.append(sentence)
            }
        }

        return sentences
            .map { $0.split(whereSeparator: \.isWhitespace).joined(separator: " ") }
            .filter { !$0.isEmpty }
            .flatMap { splitByWords($0, maxLength: maxLength) }
    }

    /// Joins parts like the insight card's summary, highlights and suggestion into one passage,
    /// ending each with a full stop so the voice pauses between them.
    static func passage(_ parts: [String?]) -> String {
        parts
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { part in
                guard let last = part.last, !".!?".contains(last) else { return part }
                return part + "."
            }
            .joined(separator: " ")
    }

    private static func splitByWords(_ sentence: String, maxLength: Int) -> [String] {
        guard sentence.count > maxLength else { return [sentence] }

        var pieces: [String] = []
        var current = ""
        for word in sentence.split(separator: " ") {
            if !current.isEmpty, current.count + 1 + word.count > maxLength {
                pieces.append(current)
                current = ""
            }
            current += current.isEmpty ? String(word) : " " + word
        }
        if !current.isEmpty {
            pieces.append(current)
        }
        return pieces
    }
}
