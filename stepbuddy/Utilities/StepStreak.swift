//
//  StepStreak.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 10/10/26.
//

import Foundation

/// Streaks of consecutive days that reached the daily step goal. Works on calendar days, so a
/// day with no data at all breaks a streak just like a day below the goal.
enum StepStreak {
    /// Consecutive goal days ending today. Until today's goal is reached the streak runs through
    /// yesterday, so it doesn't look broken first thing in the morning.
    static func current(steps: [HealthMetric], goal: Double, today: Date = .now, calendar: Calendar = .current) -> Int {
        let goalDays = goalDays(in: steps, goal: goal, calendar: calendar)
        var day = calendar.startOfDay(for: today)
        if !goalDays.contains(day), let yesterday = calendar.date(byAdding: .day, value: -1, to: day) {
            day = yesterday
        }

        var streak = 0
        while goalDays.contains(day), let previousDay = calendar.date(byAdding: .day, value: -1, to: day) {
            streak += 1
            day = previousDay
        }
        return streak
    }

    /// The longest run of consecutive goal days in `steps`
    static func best(steps: [HealthMetric], goal: Double, calendar: Calendar = .current) -> Int {
        var best = 0
        var run = 0
        var previousDay: Date?

        for day in goalDays(in: steps, goal: goal, calendar: calendar).sorted() {
            if let previousDay, calendar.date(byAdding: .day, value: 1, to: previousDay) == day {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            previousDay = day
        }
        return best
    }

    /// How many days in `steps` reached the goal
    static func daysMet(steps: [HealthMetric], goal: Double) -> Int {
        steps.filter { $0.value >= goal }.count
    }

    private static func goalDays(in steps: [HealthMetric], goal: Double, calendar: Calendar) -> Set<Date> {
        Set(steps.filter { $0.value >= goal }.map { calendar.startOfDay(for: $0.date) })
    }
}
