//
//  ChartMathTests.swift
//  stepbuddyTests
//
//  Created by Sai Vikshit Kode on 10/10/26.
//

import Foundation
import Testing
@testable import stepbuddy

struct ChartMathTests {
    private func metric(_ dayOffset: Int, _ value: Double) -> HealthMetric {
        HealthMetric(date: TestDates.day(dayOffset), value: value)
    }

    // MARK: - averageWeekdayCount

    @Test func averageWeekdayCountIsEmptyForNoData() {
        #expect(ChartMath.averageWeekdayCount(for: []).isEmpty)
    }

    @Test func averageWeekdayCountAveragesEachWeekday() {
        let result = ChartMath.averageWeekdayCount(for: [
            metric(0, 1_000),   // Monday
            metric(7, 3_000),   // next Monday
            metric(1, 500)      // Tuesday
        ])

        #expect(result.map(\.value) == [2_000, 500])
        #expect(result.map(\.date.weekdayInt) == [2, 3])
    }

    @Test func averageWeekdayCountIsOrderedSundayFirst() {
        let result = ChartMath.averageWeekdayCount(for: [
            metric(5, 100),   // Saturday
            metric(0, 200),   // Monday
            metric(6, 300)    // Sunday
        ])

        #expect(result.map(\.date.weekdayInt) == [1, 2, 7])
        #expect(result.map(\.value) == [300, 200, 100])
    }

    // MARK: - avgDailyWeightDiff

    @Test func avgDailyWeightDiffNeedsTwoReadings() {
        #expect(ChartMath.avgDailyWeightDiff(for: []).isEmpty)
        #expect(ChartMath.avgDailyWeightDiff(for: [metric(0, 170)]).isEmpty)
    }

    @Test func avgDailyWeightDiffUsesTheChangeFromThePreviousReading() {
        let result = ChartMath.avgDailyWeightDiff(for: [
            metric(0, 170),     // Monday: first reading, no diff
            metric(1, 171),     // Tuesday: +1
            metric(2, 170.5)    // Wednesday: -0.5
        ])

        #expect(result.map(\.date.weekdayInt) == [3, 4])
        #expect(result.map(\.value) == [1, -0.5])
    }

    @Test func avgDailyWeightDiffSortsByDateFirst() {
        let result = ChartMath.avgDailyWeightDiff(for: [
            metric(2, 170.5),
            metric(0, 170),
            metric(1, 171)
        ])

        #expect(result.map(\.value) == [1, -0.5])
    }

    @Test func avgDailyWeightDiffAveragesTheSameWeekday() {
        let result = ChartMath.avgDailyWeightDiff(for: [
            metric(6, 170),    // Sunday
            metric(7, 171),    // Monday: +1
            metric(13, 171),   // Sunday: 0
            metric(14, 168)    // Monday: -3
        ])

        // Sunday: (0) / 1, Monday: (+1 - 3) / 2
        #expect(result.map(\.date.weekdayInt) == [1, 2])
        #expect(result.map(\.value) == [0, -1])
    }

    @Test func avgDailyWeightDiffSkipsNonFiniteValues() {
        let result = ChartMath.avgDailyWeightDiff(for: [
            metric(0, 170),
            metric(1, .nan),
            metric(2, 172)
        ])

        // The NaN day is dropped, so Wednesday diffs against Monday
        #expect(result.map(\.date.weekdayInt) == [4])
        #expect(result.map(\.value) == [2])
    }
}
