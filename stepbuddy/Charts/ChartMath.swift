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
        
        var diffValues: [(date: Date, value: Double)] = []
        
        for i in 1..<weights.count {
            let date = weights[i].date
            let diff = weights[i].value - weights[i-1].value
            
            diffValues.append((date: date, value: diff))
        }
        
//        for value in diffValues {
//            print("\(value.date), \(value.value)")
//        }
        
        let sortedByWeekDay = diffValues.sorted { $0.date.weekdayInt < $1.date.weekdayInt }
        let weekdayArray = sortedByWeekDay.chunked { $0.date.weekdayInt == $1.date.weekdayInt }
        
        var weekDayChartData: [WeekDayChartData] = []
        
        for array in weekdayArray {
            guard let firstValue = array.first else { continue }
            let total = array.reduce(0) { $0 + $1.value }
            let avgWeightDiff = total/Double(array.count)
            
            weekDayChartData.append(.init(date: firstValue.date, value: avgWeightDiff))
        }
        
        return weekDayChartData
    }
    
}
