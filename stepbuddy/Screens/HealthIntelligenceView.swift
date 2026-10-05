//
//  HealthIntelligenceView.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 9/19/26.
//

import SwiftUI
import TipKit
import FoundationModels

struct HealthIntelligenceTip: Tip {
    var title: Text {
        Text("Health Intelligence")
    }

    var message: Text? {
        Text("Use AI to understand your health data.")
    }

    var image: Image? {
        Image(systemName: "apple.intelligence")
    }
}

struct HealthIntelligenceView: View {

    let store: HealthIntelligenceStore

    @Environment(\.dismiss) private var dismiss
    @Environment(HealthKitManager.self) private var hkManager

    var body: some View {
        NavigationStack {
            Group {
                if #available(iOS 26, *) {
                    HealthInsightsScreen(insights: store.insightsManager, steps: hkManager.stepData, weights: hkManager.weightData)
                } else {
                    ContentUnavailableView(
                        "Requires iOS 26",
                        systemImage: "apple.intelligence",
                        description: Text("Update to iOS 26 or later on a device that supports Apple Intelligence to get insights about your health data.")
                    )
                }
            }
            .navigationTitle("Health Intelligence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}


@available(iOS 26, *)
private struct HealthInsightsScreen: View {

    let insights: HealthInsightsManager
    let steps: [HealthMetric]
    let weights: [HealthMetric]

    var body: some View {
        switch insights.model.availability {
        case .available:
            if HealthDataSummary.hasData(steps: steps, weights: weights) {
                InsightsChatView(insights: insights)
                    .task {
                        insights.prepare(steps: steps, weights: weights)
                    }
            } else {
                EmptyStateCard(
                    title: "No Health Data Yet",
                    message: "Health Intelligence needs step or weight data from the last 28 days to give you insights.",
                    color: .pink
                )
                .padding()
                .frame(maxHeight: .infinity, alignment: .top)
            }
        case .unavailable(.deviceNotEligible):
            ContentUnavailableView(
                "Not Supported",
                systemImage: "apple.intelligence",
                description: Text("This device doesn't support Apple Intelligence.")
            )
        case .unavailable(.appleIntelligenceNotEnabled):
            ContentUnavailableView(
                "Apple Intelligence Is Off",
                systemImage: "apple.intelligence",
                description: Text("Turn on Apple Intelligence in Settings to get insights about your health data.")
            )
        case .unavailable(.modelNotReady):
            ContentUnavailableView(
                "Getting Ready",
                systemImage: "arrow.down.circle",
                description: Text("Apple Intelligence is still downloading. Try again in a little while.")
            )
        case .unavailable:
            ContentUnavailableView(
                "Unavailable",
                systemImage: "apple.intelligence",
                description: Text("Apple Intelligence isn't available right now.")
            )
        }
    }
}


@available(iOS 26, *)
private struct InsightsChatView: View {

    let insights: HealthInsightsManager

    @State private var question = ""
    @FocusState private var isInputFocused: Bool

    private let suggestedQuestions = [
        "What was my best day?",
        "How is my weight trending?",
        "Which weekday am I least active?"
    ]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    InsightCard(insight: insights.insight, isGenerating: insights.isGeneratingInsight)

                    if insights.messages.isEmpty {
                        suggestions
                    }

                    ForEach(insights.messages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }

                    if let errorMessage = insights.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }

                    Text("AI-generated on the device. Strictly not a medical advice.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: insights.messages.last?.text) {
                guard let last = insights.messages.last else { return }
                withAnimation {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            inputBar
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    insights.generateInsights()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(insights.isGeneratingInsight)
                .accessibilityLabel("Regenerate insights")
            }
        }
    }

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ask about your data")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(suggestedQuestions, id: \.self) { suggestion in
                Button(suggestion) {
                    ask(suggestion)
                }
                .buttonStyle(.bordered)
                .tint(.pink)
                .disabled(insights.isResponding)
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about your steps or weight", text: $question, axis: .vertical)
                .lineLimit(1...4)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit { ask(question) }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color(.secondarySystemBackground)))
                // The padding sits outside the TextField, so make the whole pill focus it
                .contentShape(Capsule())
                .onTapGesture {
                    isInputFocused = true
                }

            Button {
                ask(question)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
            }
            .tint(.pink)
            .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || insights.isResponding)
            .accessibilityLabel("Send")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func ask(_ text: String) {
        guard !insights.isResponding else { return }
        question = ""
        Task {
            await insights.send(text)
        }
    }
}


@available(iOS 26, *)
private struct InsightCard: View {

    let insight: HealthInsight.PartiallyGenerated?
    let isGenerating: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Your Insights", systemImage: "apple.intelligence")
                .font(.title3.bold())
                .foregroundStyle(LinearGradient.customGradientColor)

            if let summary = insight?.summary {
                Text(summary)
                    .font(.body)
            } else if isGenerating {
                ThinkingIndicator(
                    phrases: ["Looking at your data", "Comparing your weeks", "Spotting trends", "Writing your insights"],
                    label: "Generating your insights"
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let highlights = insight?.highlights, !highlights.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(highlights.enumerated()), id: \.offset) { _, highlight in
                        Label(highlight, systemImage: "sparkle")
                            .font(.subheadline)
                    }
                }
            }

            if let suggestion = insight?.suggestion {
                Label(suggestion, systemImage: "lightbulb")
                    .font(.subheadline)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10).fill(.pink.opacity(0.12)))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
        .animation(.default, value: insight?.highlights?.count)
    }
}


private struct ChatBubble: View {

    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }

            Group {
                if message.text.isEmpty {
                    ThinkingIndicator()
                } else {
                    Text(message.text)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(isUser ? .white : .primary)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isUser ? AnyShapeStyle(.pink) : AnyShapeStyle(Color(.secondarySystemBackground)))
            )

            if !isUser { Spacer(minLength: 40) }
        }
    }
}

/// Animated status shown while the model is generating: in the reply bubble and on the insight card.
private struct ThinkingIndicator: View {

    var phrases = ["Thinking", "Reading your steps", "Checking your weight trend", "Writing a reply"]
    /// What VoiceOver reads instead of the rotating phrases.
    var label = "Generating a reply"

    @State private var phraseIndex = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundStyle(LinearGradient.customGradientColor)
                .symbolEffect(.breathe, isActive: !reduceMotion)

            ZStack(alignment: .leading) {
                shimmeringText(phrases[phraseIndex] + "…")
                    .id(phraseIndex)
                    .transition(.push(from: .bottom))
            }
            .clipped()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .task {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.snappy) {
                    phraseIndex = (phraseIndex + 1) % phrases.count
                }
            }
        }
    }

    /// Secondary text with the app's gradient sweeping across it.
    private func shimmeringText(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
            .overlay {
                TimelineView(.animation(paused: reduceMotion)) { context in
                    let duration = 1.6
                    let phase = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: duration) / duration

                    GeometryReader { proxy in
                        LinearGradient.customGradientColor
                            .frame(width: proxy.size.width * 0.5)
                            .offset(x: (phase * 1.5 - 0.5) * proxy.size.width)
                    }
                }
                .mask {
                    Text(text)
                        .font(.subheadline.weight(.medium))
                }
            }
    }
}

#Preview("Thinking Indicator") {
    ThinkingIndicator()
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemBackground)))
}

#Preview {
    HealthIntelligenceView(store: HealthIntelligenceStore())
        .environment(HealthKitManager())
}
