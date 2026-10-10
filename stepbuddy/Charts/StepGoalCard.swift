//
//  StepGoalCard.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 10/10/26.
//

import SwiftUI

/// Today's progress toward the daily step goal, plus the goal streak
struct StepGoalCard: View {
    let status: StepGoalStatus
    var onEditGoal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Daily Goal", systemImage: "target")
                    .font(.title3.bold())
                    .foregroundStyle(.pink)
                Spacer()
                Button("Edit Goal", action: onEditGoal)
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.pink)
            }

            HStack(spacing: 16) {
                progressRing
                details
                Spacer(minLength: 0)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.gray.opacity(0.5), lineWidth: 0.5)
                .fill(Color(.secondarySystemBackground).gradient.opacity(0.5))
        )
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(status.todaySteps, format: .number.precision(.fractionLength(0))) / \(status.goal, format: .number.precision(.fractionLength(0))) steps")
                .font(.headline)
                .contentTransition(.numericText())

            Text(progressText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Label(streakText, systemImage: "flame.fill")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(status.currentStreak > 0 ? .orange : .secondary)
                .padding(.top, 2)
        }
        .accessibilityElement(children: .combine)
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.pink.opacity(0.2), lineWidth: 10)
            Circle()
                .trim(from: 0, to: min(status.progress, 1))
                .stroke(Color.pink.gradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: status.progress)
            Image(systemName: status.isTodayMet ? "checkmark" : "figure.walk")
                .font(.title3.bold())
                .foregroundStyle(.pink)
        }
        .frame(width: 64, height: 64)
        .accessibilityHidden(true)
    }

    private var progressText: String {
        if status.isTodayMet {
            return "Goal reached today!"
        }
        return "\(Int(status.progress * 100))% of today's goal"
    }

    private var streakText: String {
        let best = status.bestStreak > status.currentStreak ? " · best \(status.bestStreak)" : ""
        if status.currentStreak == 0 {
            return "Reach your goal to start a streak\(best)"
        }
        return "\(status.currentStreak)-day streak\(best)"
    }
}

#Preview {
    VStack(spacing: 20) {
        StepGoalCard(status: StepGoalStatus(goal: 10_000, history: MockData.steps)) {}
        StepGoalCard(status: StepGoalStatus(goal: 10_000, history: [])) {}
    }
    .padding()
}
