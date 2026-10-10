//
//  StepStreakTests.swift
//  stepbuddyTests
//
//  Created by Sai Vikshit Kode on 10/10/26.
//

import Foundation
import Testing
@testable import stepbuddy

struct StepStreakTests {
    private let goal = 10_000.0

    /// One metric per value, on consecutive days starting at `firstDay`
    private func days(from firstDay: Int, _ values: [Double]) -> [HealthMetric] {
        values.enumerated().map { HealthMetric(date: TestDates.day(firstDay + $0.offset), value: $0.element) }
    }

    // MARK: - current

    @Test func currentIsZeroWithoutData() {
        #expect(StepStreak.current(steps: [], goal: goal, today: TestDates.day(0)) == 0)
    }

    @Test func currentCountsBackFromToday() {
        let steps = days(from: 0, [12_000, 3_000, 10_000, 15_000, 11_000])

        #expect(StepStreak.current(steps: steps, goal: goal, today: TestDates.day(4)) == 3)
    }

    @Test func currentKeepsYesterdaysStreakUntilTodayIsMet() {
        // Today (day 3) is still below the goal, so the streak runs through yesterday
        let steps = days(from: 0, [10_000, 12_000, 11_000, 2_000])

        #expect(StepStreak.current(steps: steps, goal: goal, today: TestDates.day(3)) == 3)
    }

    @Test func currentKeepsYesterdaysStreakWhenTodayHasNoDataYet() {
        let steps = days(from: 0, [10_000, 12_000])

        #expect(StepStreak.current(steps: steps, goal: goal, today: TestDates.day(2)) == 2)
    }

    @Test func currentIsZeroWhenYesterdayWasMissed() {
        let steps = days(from: 0, [10_000, 12_000, 4_000, 2_000])

        #expect(StepStreak.current(steps: steps, goal: goal, today: TestDates.day(3)) == 0)
    }

    @Test func currentStopsAtADayWithNoData() {
        // Day 2 is missing entirely
        let steps = days(from: 0, [10_000, 12_000]) + days(from: 3, [11_000, 13_000])

        #expect(StepStreak.current(steps: steps, goal: goal, today: TestDates.day(4)) == 2)
    }

    @Test func currentCountsTheGoalExactly() {
        let steps = days(from: 0, [10_000, 9_999, 10_000])

        #expect(StepStreak.current(steps: steps, goal: goal, today: TestDates.day(2)) == 1)
    }

    @Test func currentIgnoresInputOrder() {
        let steps = days(from: 0, [12_000, 11_000, 10_500]).reversed()

        #expect(StepStreak.current(steps: Array(steps), goal: goal, today: TestDates.day(2)) == 3)
    }

    // MARK: - best

    @Test func bestIsZeroWhenTheGoalIsNeverMet() {
        #expect(StepStreak.best(steps: [], goal: goal) == 0)
        #expect(StepStreak.best(steps: days(from: 0, [5_000, 9_000, 0]), goal: goal) == 0)
    }

    @Test func bestFindsTheLongestRun() {
        let steps = days(from: 0, [10_000, 11_000, 2_000, 12_000, 13_000, 14_000, 0, 10_000])

        #expect(StepStreak.best(steps: steps, goal: goal) == 3)
    }

    @Test func bestTreatsMissingDaysAsBreaks() {
        let steps = days(from: 0, [10_000, 11_000]) + days(from: 3, [12_000])

        #expect(StepStreak.best(steps: steps, goal: goal) == 2)
    }

    // MARK: - StepGoalStatus

    @Test func goalStatusReadsTodaysStepsAndStreaks() {
        let history = days(from: 0, [10_000, 11_000, 2_000, 12_000, 13_000, 6_000])
        let status = StepGoalStatus(goal: 10_000, history: history, today: TestDates.day(5))

        #expect(status.todaySteps == 6_000)
        #expect(status.progress == 0.6)
        #expect(!status.isTodayMet)
        #expect(status.currentStreak == 2)
        #expect(status.bestStreak == 2)
    }

    @Test func goalStatusHasNoStepsWhenTodayIsMissing() {
        let status = StepGoalStatus(goal: 10_000, history: days(from: 0, [12_000]), today: TestDates.day(1))

        #expect(status.todaySteps == 0)
        #expect(status.currentStreak == 1)
    }

    // MARK: - daysMet

    @Test func daysMetCountsDaysAtOrAboveTheGoal() {
        let steps = days(from: 0, [10_000, 9_999, 0, 25_000])

        #expect(StepStreak.daysMet(steps: steps, goal: goal) == 2)
    }
}
