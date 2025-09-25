//
//  ChartMath.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 5/13/25.
//

import Foundation
import Algorithms

struct ChartMath {
    
    static func averageWeekdayCount(for metric: [HealthMetric]) -> [WeekDayChartData] {
        
        let sortedByWeekDay = metric.sorted { $0.date.weekdayInt < $1.date.weekdayInt }
        let weekdayArray = sortedByWeekDay.chunked { $0.date.weekdayInt == $1.date.weekdayInt }
        
        var weekdayChartData: [WeekDayChartData] = []
        
        for array in weekdayArray {
            guard let firstValue = array.first else { continue }
            let total = array.reduce(0) { $0 + $1.value }
            let avgSteps = total/Double(array.count)
            
            weekdayChartData.append(.init(date: firstValue.date, value: avgSteps))
        }
        
        return weekdayChartData
    }
    
    static func avgDailyWeightDiff(for weights: [HealthMetric]) -> [WeekDayChartData] {
            // 1) Sort by date and keep only finite values
            let sorted = weights
                .filter { $0.value.isFinite }
                .sorted { $0.date < $1.date }

            // 2) Need at least 2 to compute a diff
            guard sorted.count >= 2 else { return [] }

            // 3) Adjacent diffs (safe, no indices)
            let diffs: [(date: Date, value: Double)] =
                zip(sorted.dropFirst(), sorted).map { curr, prev in
                    (date: curr.date, value: curr.value - prev.value)
                }

            // 4) Group by weekday, average each weekday’s diffs
            let cal = Calendar.current
            let groups = Dictionary(grouping: diffs, by: { cal.component(.weekday, from: $0.date) })

            // Sunday = 1 ... Saturday = 7 (UIKit/Calendar default)
            let weekdayOrder = [1,2,3,4,5,6,7]

            let weekDayChartData: [WeekDayChartData] = weekdayOrder.compactMap { wd in
                guard let values = groups[wd], !values.isEmpty else { return nil }
                let avg = values.map(\.value).reduce(0, +) / Double(values.count)
                // Use first date as representative for that weekday
                return .init(date: values[0].date, value: avg)
            }

            return weekDayChartData
        }
    
}
