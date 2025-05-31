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
    
}
