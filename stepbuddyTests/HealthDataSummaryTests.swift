//
//  HealthDataSummaryTests.swift
//  stepbuddyTests
//
//  Created by Sai Vikshit Kode on 10/10/26.
//

import Foundation
import Testing
@testable import stepbuddy

struct HealthDataSummaryTests {
    private func metric(_ dayOffset: Int, _ value: Double) -> HealthMetric {
        HealthMetric(date: TestDates.day(dayOffset), value: value)
    }

    /// Numbers are formatted for the current locale, so build the expected text the same way
    private func number(_ value: Double, decimals: Int = 0) -> String {
        value.formatted(.number.precision(.fractionLength(decimals)))
    }

    private func signed(_ value: Double, decimals: Int) -> String {
        value.formatted(.number.precision(.fractionLength(decimals)).sign(strategy: .always()))
    }

    /// The lines of one section, e.g. "STEPS", up to the next blank line
    private func section(_ title: String, in text: String) -> [String] {
        let lines = text.components(separatedBy: "\n")
        guard let start = lines.firstIndex(of: title) else { return [] }
        return Array(lines[(start + 1)...].prefix { !$0.isEmpty })
    }

    // MARK: - hasData

    @Test func hasDataIsFalseWithoutReadings() {
        #expect(!HealthDataSummary.hasData(steps: [], weights: []))
        #expect(!HealthDataSummary.hasData(steps: [metric(0, 0), metric(1, 0)], weights: [metric(0, 0)]))
    }

    @Test func hasDataIsTrueWithStepsOrWeights() {
        #expect(HealthDataSummary.hasData(steps: [metric(0, 0), metric(1, 5_000)], weights: []))
        #expect(HealthDataSummary.hasData(steps: [], weights: [metric(0, 170)]))
    }

    // MARK: - promptText

    @Test func promptTextSaysWhenThereIsNoData() {
        let text = HealthDataSummary.promptText(steps: [], weights: [])

        #expect(!text.contains("Period:"))
        #expect(section("STEPS", in: text) == ["No step data."])
        #expect(section("WEIGHT (lb)", in: text) == ["No weight data."])
        #expect(section("DAILY LOG", in: text).isEmpty)
    }

    @Test func promptTextSummarizesStepsAndSkipsZeroDays() {
        let text = HealthDataSummary.promptText(
            steps: [metric(0, 4_000), metric(1, 8_000), metric(2, 0), metric(3, 6_000)],
            weights: []
        )
        let steps = section("STEPS", in: text)

        #expect(steps.contains("Days with data: 3"))
        #expect(steps.contains("Total: \(number(18_000)) steps"))
        #expect(steps.contains("Daily average: \(number(6_000)) steps"))
        #expect(steps.contains { $0.hasPrefix("Best day:") && $0.hasSuffix("with \(number(8_000)) steps") })
        #expect(steps.contains { $0.hasPrefix("Lowest day:") && $0.hasSuffix("with \(number(4_000)) steps") })
        #expect(steps.contains { $0.hasPrefix("Average by weekday:") })
        // Fewer than 8 days with data: nothing to compare the last week against
        #expect(!steps.contains { $0.hasPrefix("Average of the last 7 days") })
        #expect(section("DAILY LOG", in: text).count == 3)
    }

    @Test func promptTextComparesTheLastWeekWithTheWeekBefore() {
        let weekBefore = (0..<7).map { metric($0, 5_000) }
        let lastWeek = (7..<14).map { metric($0, 10_000) }
        let text = HealthDataSummary.promptText(steps: weekBefore + lastWeek, weights: [])

        let expected = "Average of the last 7 days with data: \(number(10_000)) steps "
            + "(\(signed(100, decimals: 0))% vs the 7 days with data before that: \(number(5_000)))"
        #expect(section("STEPS", in: text).contains(expected))
    }

    @Test func promptTextSummarizesWeights() {
        let text = HealthDataSummary.promptText(
            steps: [],
            weights: [metric(2, 171), metric(0, 170), metric(1, 172.5)]
        )
        let weights = section("WEIGHT (lb)", in: text)

        #expect(weights.first == "Readings: 3")
        #expect(weights.contains { $0.hasPrefix("First: \(number(170, decimals: 1)) lb on") })
        #expect(weights.contains { $0.hasPrefix("Latest: \(number(171, decimals: 1)) lb on") })
        #expect(weights.contains("Net change: \(signed(1, decimals: 1)) lb"))
        #expect(weights.contains("Highest: \(number(172.5, decimals: 1)) lb, lowest: \(number(170, decimals: 1)) lb"))
    }

    @Test func promptTextLogsEachDayWithStepsAndWeight() {
        let text = HealthDataSummary.promptText(
            steps: [metric(0, 4_000), metric(1, 8_000)],
            weights: [metric(1, 170)]
        )
        let log = section("DAILY LOG", in: text)

        #expect(log.count == 2)
        #expect(log[0].hasSuffix(": \(number(4_000)) steps"))
        #expect(log[1].hasSuffix(": \(number(8_000)) steps, \(number(170, decimals: 1)) lb"))
        #expect(text.hasPrefix("Period: "))
    }
}
