//
//  HealthDataSummary.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 10/5/26.
//

import Foundation

/// Turns the dashboard's health data into compact text the on-device model can reason over.
/// Stats are precomputed here because the small on-device model is unreliable at arithmetic.
enum HealthDataSummary {
    static func hasData(steps: [HealthMetric], weights: [HealthMetric]) -> Bool {
        steps.contains { $0.value > 0 } || weights.contains { $0.value > 0 }
    }

    static func promptText(steps: [HealthMetric], weights: [HealthMetric], stepGoal: StepGoalStatus? = nil) -> String {
        // Days without steps come back from HealthKit as 0 (weights already skip missing days)
        let steps = steps.filter { $0.value > 0 }.sorted { $0.date < $1.date }
        let weights = weights.filter { $0.value > 0 }.sorted { $0.date < $1.date }

        var lines: [String] = []

        if let first = (steps + weights).map(\.date).min(), let last = (steps + weights).map(\.date).max() {
            lines.append("Period: \(first.formatted(date: .abbreviated, time: .omitted)) to \(last.formatted(date: .abbreviated, time: .omitted)).")
        }

        lines.append("")
        lines.append("STEPS")
        lines.append(contentsOf: stepStats(for: steps))
        if let stepGoal, !steps.isEmpty {
            lines.append(contentsOf: goalStats(for: steps, stepGoal: stepGoal))
        }

        lines.append("")
        lines.append("WEIGHT (lb)")
        lines.append(contentsOf: weightStats(for: weights))

        lines.append("")
        lines.append("DAILY LOG")
        lines.append(contentsOf: dailyLog(steps: steps, weights: weights))

        return lines.joined(separator: "\n")
    }


    private static func stepStats(for steps: [HealthMetric]) -> [String] {
        guard !steps.isEmpty,
              let best = steps.max(by: { $0.value < $1.value }),
              let worst = steps.min(by: { $0.value < $1.value }) else {
            return ["No step data."]
        }

        let total = steps.reduce(0) { $0 + $1.value }
        var lines = [
            "Days with data: \(steps.count)",
            "Total: \(format(total)) steps",
            "Daily average: \(format(total / Double(steps.count))) steps",
            "Best day: \(dayTitle(best.date)) with \(format(best.value)) steps",
            "Lowest day: \(dayTitle(worst.date)) with \(format(worst.value)) steps"
        ]

        let lastWeek = steps.suffix(7)
        let weekBefore = steps.dropLast(7).suffix(7)
        if !lastWeek.isEmpty, !weekBefore.isEmpty {
            let recentAvg = average(of: lastWeek)
            let previousAvg = average(of: weekBefore)
            let change = (recentAvg - previousAvg) / previousAvg * 100
            let comparison = "\(signed(change, decimals: 0))% vs the 7 days with data before that: \(format(previousAvg))"
            lines.append("Average of the last 7 days with data: \(format(recentAvg)) steps (\(comparison))")
        }

        let weekdayAverages = ChartMath.averageWeekdayCount(for: steps)
            .map { "\($0.date.weekdayTitle) \(format($0.value))" }
            .joined(separator: ", ")
        lines.append("Average by weekday: \(weekdayAverages)")

        return lines
    }

    private static func goalStats(for steps: [HealthMetric], stepGoal: StepGoalStatus) -> [String] {
        let daysMet = StepStreak.daysMet(steps: steps, goal: stepGoal.goal)
        return [
            "Daily step goal: \(format(stepGoal.goal)) steps, reached on \(daysMet) of the \(steps.count) days with data",
            "Goal streak: \(days(stepGoal.currentStreak)) in a row (best in the last year: \(days(stepGoal.bestStreak)))"
        ]
    }

    private static func weightStats(for weights: [HealthMetric]) -> [String] {
        guard let first = weights.first, let latest = weights.last,
              let highest = weights.max(by: { $0.value < $1.value }),
              let lowest = weights.min(by: { $0.value < $1.value }) else {
            return ["No weight data."]
        }

        return [
            "Readings: \(weights.count)",
            "First: \(format(first.value, decimals: 1)) lb on \(dayTitle(first.date))",
            "Latest: \(format(latest.value, decimals: 1)) lb on \(dayTitle(latest.date))",
            "Net change: \(signed(latest.value - first.value, decimals: 1)) lb",
            "Highest: \(format(highest.value, decimals: 1)) lb, lowest: \(format(lowest.value, decimals: 1)) lb"
        ]
    }

    private static func dailyLog(steps: [HealthMetric], weights: [HealthMetric]) -> [String] {
        let calendar = Calendar.current
        let stepsByDay = Dictionary(steps.map { (calendar.startOfDay(for: $0.date), $0.value) }) { _, last in last }
        let weightsByDay = Dictionary(weights.map { (calendar.startOfDay(for: $0.date), $0.value) }) { _, last in last }
        let days = Set(stepsByDay.keys).union(weightsByDay.keys).sorted()

        return days.map { day in
            var parts: [String] = []
            if let steps = stepsByDay[day] { parts.append("\(format(steps)) steps") }
            if let weight = weightsByDay[day] { parts.append("\(format(weight, decimals: 1)) lb") }
            return "\(dayTitle(day)): \(parts.joined(separator: ", "))"
        }
    }


    private static func average(of metrics: some Collection<HealthMetric>) -> Double {
        metrics.reduce(0) { $0 + $1.value } / Double(metrics.count)
    }

    private static func days(_ count: Int) -> String {
        count == 1 ? "1 day" : "\(count) days"
    }

    private static func dayTitle(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    private static func format(_ value: Double, decimals: Int = 0) -> String {
        value.formatted(.number.precision(.fractionLength(decimals)))
    }

    private static func signed(_ value: Double, decimals: Int) -> String {
        value.formatted(.number.precision(.fractionLength(decimals)).sign(strategy: .always()))
    }
}
