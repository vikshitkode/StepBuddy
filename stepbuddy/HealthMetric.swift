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
}
