//
//  HealthInsightsManager.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 10/5/26.
//

import Foundation
import FoundationModels
import Observation

/// Owns all Foundation Models (on-device Apple Intelligence) work: the insight summary and the follow-up chat.
@available(iOS 26, *)
@MainActor
@Observable
final class HealthInsightsManager {
    let model = SystemLanguageModel.default

    var insight: HealthInsight.PartiallyGenerated?
    var messages: [ChatMessage] = []
    var isGeneratingInsight = false
    var isResponding = false
    var errorMessage: String?

    private var dataSummary: String?
    private var instructions = ""
    private var chatSession: LanguageModelSession?
    private var insightTask: Task<Void, Never>?


    /// Sets up the model for this data and generates the insight card.
    /// If the data hasn't changed since the last call, the existing insight and chat are kept,
    /// so reopening the sheet picks up where the user left off.
    func prepare(steps: [HealthMetric], weights: [HealthMetric]) {
        let summary = HealthDataSummary.promptText(steps: steps, weights: weights)

        guard summary != dataSummary else {
            if insight == nil && !isGeneratingInsight {
                generateInsights()
            }
            return
        }

        dataSummary = summary
        instructions = """
        You are StepBuddy's friendly fitness assistant. You help the user understand their \
        daily step count and body weight from Apple Health.

        Rules:
        - Answer only from the data below. If the data can't answer a question, say so.
        - Use the precomputed numbers as given; don't recalculate them.
        - Weight is in pounds (lb).
        - You are not a doctor. Never diagnose; for medical concerns, suggest talking to a healthcare professional.
        - Keep answers short: two to four sentences.

        The user's data:
        \(summary)
        """

        resetChat()
        chatSession?.prewarm()
        generateInsights()
    }

    /// Streams a fresh insight card, replacing any existing one.
    func generateInsights() {
        insightTask?.cancel()
        insightTask = Task {
            isGeneratingInsight = true
            errorMessage = nil
            insight = nil
            defer { isGeneratingInsight = false }

            let session = LanguageModelSession(instructions: instructions)
            do {
                let stream = session.streamResponse(
                    to: "Summarize how my steps and weight are trending over this period.",
                    generating: HealthInsight.self
                )
                for try await snapshot in stream {
                    insight = snapshot.content
                }
            } catch is CancellationError {
                return
            } catch {
                errorMessage = Self.message(for: error).text
            }
        }
    }

    /// Asks a follow-up question, streaming the answer into the chat.
    func send(_ question: String) async {
        let question = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isResponding, let chatSession else { return }

        isResponding = true
        errorMessage = nil
        defer { isResponding = false }

        messages.append(ChatMessage(role: .user, text: question))
        messages.append(ChatMessage(role: .assistant, text: ""))
        let replyIndex = messages.count - 1

        do {
            for try await snapshot in chatSession.streamResponse(to: question) {
                messages[replyIndex].text = snapshot.content
            }
        } catch {
            messages.remove(at: replyIndex)
            let (text, shouldReset) = Self.message(for: error)
            errorMessage = text
            if shouldReset {
                resetChat()
            }
        }
    }

    func resetChat() {
        messages = []
        chatSession = LanguageModelSession(instructions: instructions)
    }


    /// Maps model errors to a user-facing message, and whether the chat must start over.
    private static func message(for error: Error) -> (text: String, shouldReset: Bool) {
        // LanguageModelError only exists in the iOS 27 SDK (Xcode 27 / Swift 6.4).
        // CI builds with Xcode 26, so the runtime #available check alone doesn't compile there.
        #if compiler(>=6.4)
        if #available(iOS 27, *), let error = error as? LanguageModelError {
            switch error {
            case .contextSizeExceeded:
                return ("The conversation got too long, so it has been reset. Ask again to continue.", true)
            case .guardrailViolation, .refusal:
                return ("Health Intelligence can't answer that. Try asking about your steps or weight.", false)
            case .unsupportedLanguageOrLocale:
                return ("Apple Intelligence doesn't support your device's language yet.", false)
            default:
                return ("Something went wrong. Please try again.", false)
            }
        }
        #endif

        if let error = error as? LanguageModelSession.GenerationError {
            switch error {
            case .exceededContextWindowSize:
                return ("The conversation got too long, so it has been reset. Ask again to continue.", true)
            case .guardrailViolation, .refusal:
                return ("Health Intelligence can't answer that. Try asking about your steps or weight.", false)
            case .unsupportedLanguageOrLocale:
                return ("Apple Intelligence doesn't support your device's language yet.", false)
            default:
                return ("Something went wrong. Please try again.", false)
            }
        }

        return ("Something went wrong. Please try again.", false)
    }
}


/// Keeps the Health Intelligence insight and chat alive while the sheet is closed.
/// The app targets iOS 18, so the iOS 26-only manager is stored type-erased.
@MainActor
final class HealthIntelligenceStore {
    private var storage: AnyObject?

    @available(iOS 26, *)
    var insightsManager: HealthInsightsManager {
        if let manager = storage as? HealthInsightsManager {
            return manager
        }
        let manager = HealthInsightsManager()
        storage = manager
        return manager
    }
}
