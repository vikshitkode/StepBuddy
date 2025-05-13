//
//  HealthMetric.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 5/12/25.
//

import Foundation

struct HealthMetric: Identifiable {
    
    var id = UUID()
    var date: Date
    var value: Double
    
    static var mockData: [HealthMetric] {
        var array: [HealthMetric] = []
        
        for i in 0..<28 {
            let metric = HealthMetric(date: Calendar.current.date(byAdding: .day, value: -i, to: .now)!, value: .random(in: 4_000...15_000))
            array.append(metric)
        }
        return array
    }
}
