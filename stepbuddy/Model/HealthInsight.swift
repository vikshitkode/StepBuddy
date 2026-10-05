//
//  HealthInsight.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 10/5/26.
//

import Foundation
import FoundationModels

@available(iOS 26, *)
@Generable
struct HealthInsight {

    @Guide(description: "A one or two sentence overview of the user's steps and weight over the period")
    var summary: String

    @Guide(description: "Short, specific observations from the data, each citing a number", .count(3))
    var highlights: [String]

    @Guide(description: "One small, encouraging, actionable suggestion based on the data")
    var suggestion: String
}

struct ChatMessage: Identifiable, Equatable {

    enum Role {
        case user, assistant
    }

    let id = UUID()
    let role: Role
    var text: String
}
