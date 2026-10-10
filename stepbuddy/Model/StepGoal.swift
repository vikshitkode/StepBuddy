//
//  StepGoal.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 10/10/26.
//

import Foundation

/// The user's daily step goal setting, stored with `@AppStorage(StepGoal.storageKey)`
enum StepGoal {
    static let storageKey = "dailyStepGoal"
    static let defaultValue = 10_000
    static let range = 1_000...50_000
    static let increment = 500
}

/// Where the user stands against their daily step goal
struct StepGoalStatus: Equatable {
    let goal: Double
    let todaySteps: Double
    let currentStreak: Int
    let bestStreak: Int

    var progress: Double { todaySteps / goal }
    var isTodayMet: Bool { todaySteps >= goal }

    /// - Parameter history: daily step totals, ideally for the last year so the best streak means something
    init(goal: Int, history: [HealthMetric], today: Date = .now, calendar: Calendar = .current) {
        self.goal = Double(goal)
        self.todaySteps = history.last { calendar.isDate($0.date, inSameDayAs: today) }?.value ?? 0
        self.currentStreak = StepStreak.current(steps: history, goal: self.goal, today: today, calendar: calendar)
        self.bestStreak = StepStreak.best(steps: history, goal: self.goal, calendar: calendar)
    }
}
