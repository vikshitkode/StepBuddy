//
//  ChartDataTypes.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 5/13/25.
//

import Foundation

struct WeekDayChartData: Identifiable {
    
    let id: UUID = UUID()
    let date: Date
    let value: Double
}
