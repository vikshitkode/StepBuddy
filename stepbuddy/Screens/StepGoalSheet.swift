//
//  StepGoalSheet.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 10/10/26.
//

import SwiftUI

struct StepGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var goal: Int

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text(goal, format: .number)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(.pink)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: goal)
                    Text("steps a day")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Stepper("Daily step goal", value: $goal, in: StepGoal.range, step: StepGoal.increment)
                    .labelsHidden()

                Text("Your streak counts the days in a row you reach this goal.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxHeight: .infinity)
            .navigationTitle("Daily Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    StepGoalSheet(goal: .constant(10_000))
}
