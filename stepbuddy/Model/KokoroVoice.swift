//
//  KokoroVoice.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 10/16/26.
//

import Foundation

/// A Kokoro voice from voices.npz. Identifiers encode the accent and gender, e.g. "af_heart" is
/// American (a) female (f) "Heart" and "bm_george" is British (b) male (m) "George".
struct KokoroVoice: Identifiable, Hashable {
    static let storageKey = "kokoroVoice"
    static let defaultID = "af_heart"

    struct Section: Identifiable, Equatable {
        let title: String
        let voices: [KokoroVoice]

        var id: String { title }
    }

    let id: String
    let name: String
    let isBritish: Bool
    let isFemale: Bool

    /// Nil for identifiers that don't follow the accent-gender_name pattern.
    init?(id: String) {
        let parts = id.split(separator: "_", maxSplits: 1)
        guard parts.count == 2,
              parts[0].count == 2,
              let accent = parts[0].first, "ab".contains(accent),
              let gender = parts[0].last, "fm".contains(gender),
              !parts[1].isEmpty
        else { return nil }

        self.id = id
        self.name = parts[1].capitalized
        self.isBritish = accent == "b"
        self.isFemale = gender == "f"
    }

    var accentName: String {
        isBritish ? "British English" : "American English"
    }

    /// Picker sections: American female, American male, British female, British male. Each sorted by name,
    /// with unrecognized identifiers and empty sections left out.
    static func sections(_ ids: [String]) -> [Section] {
        let voices = ids.compactMap(KokoroVoice.init).sorted { $0.name < $1.name }
        let groups: [(title: String, contains: (KokoroVoice) -> Bool)] = [
            ("American · Female", { !$0.isBritish && $0.isFemale }),
            ("American · Male", { !$0.isBritish && !$0.isFemale }),
            ("British · Female", { $0.isBritish && $0.isFemale }),
            ("British · Male", { $0.isBritish && !$0.isFemale })
        ]

        return groups.compactMap { group in
            let members = voices.filter(group.contains)
            return members.isEmpty ? nil : Section(title: group.title, voices: members)
        }
    }
}
