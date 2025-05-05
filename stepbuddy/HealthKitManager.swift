//
//  HealthKitManager.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 5/4/25.
//

import Foundation
import HealthKit
import Observation

@Observable
class HealthKitManager {
    
    let store = HKHealthStore()
    
    let types: Set = [HKQuantityType(.stepCount), HKQuantityType(.bodyMass)]
}
