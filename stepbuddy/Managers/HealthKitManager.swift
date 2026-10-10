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
    
    var stepData: [HealthMetric] = []
    var weightData: [HealthMetric] = []
    var weightDiffData: [HealthMetric] = []
    
    
    /// Fetching the Step Count of the User
    func fetchStepCount() async throws {
        let stepCounts = try await dailyStatistics(for: HKQuantityType(.stepCount), options: .cumulativeSum, days: 28)
        stepData = stepCounts.map {
            .init(date: $0.startDate, value: $0.sumQuantity()?.doubleValue(for: .count()) ?? 0)
        }
    }
    
    /// Fetching the Weights of the User
    func fetchWeights() async throws {
        weightData = try await dailyWeights(days: 28)
    }
    
    /// Fetching the Weights of the User, plus one earlier day so the first day has a previous weight to diff against
    func fetchWeightsForDifferentials() async throws {
        weightDiffData = try await dailyWeights(days: 29)
    }
    
    private func dailyWeights(days: Int) async throws -> [HealthMetric] {
        let weights = try await dailyStatistics(for: HKQuantityType(.bodyMass), options: .mostRecent, days: days)
        return weights.map {
            .init(date: $0.startDate, value: $0.mostRecentQuantity()?.doubleValue(for: .pound()) ?? 0)
        }
    }
    
    /// One statistics value per day for the last `days` days, today included
    private func dailyStatistics(for type: HKQuantityType, options: HKStatisticsOptions, days: Int) async throws -> [HKStatistics] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        guard let endDate = calendar.date(byAdding: .day, value: 1, to: today) else { return [] }
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)
        
        let queryPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let samplePredicate = HKSamplePredicate.quantitySample(type: type, predicate: queryPredicate)
        let query = HKStatisticsCollectionQueryDescriptor(
            predicate: samplePredicate,
            options: options,
            anchorDate: endDate,
            intervalComponents: .init(day: 1)
        )
        
        return try await query.result(for: store).statistics()
    }
    
    /// Req auth to Read and Write Data
    func requestAuthorization() async throws {
        try await store.requestAuthorization(toShare: types, read: types)
    }
    
    /// Function to write StepData into HealthKit
    func addStepData(for date: Date, value: Double) async throws {
        let stepQuantity = HKQuantity(unit: .count(), doubleValue: value)
        let stepSample = HKQuantitySample(type: HKQuantityType(.stepCount), quantity: stepQuantity, start: date, end: date)
        try await store.save(stepSample)
    }
    
    /// Function to write weightData into HealthKit
    func addWeightData(for date: Date, value: Double) async throws {
        let weightQuantity = HKQuantity(unit: .pound(), doubleValue: value)
        let weightSample = HKQuantitySample(type: HKQuantityType(.bodyMass), quantity: weightQuantity, start: date, end: date)
        try await store.save(weightSample)
    }
    
    
    /// Sample Mock data to populate the Health App
//    func addSimulatorData() async {
//        var mockSamples: [HKQuantitySample] = []
//        
//        for i in 0..<28 {
//            let stepQuantity = HKQuantity(unit: .count(), doubleValue: .random(in: 4_000...20_000))
//            let weightQuantity = HKQuantity(unit: .pound(), doubleValue: .random(in: (160 + Double(i/3))...(165 + Double(i/3))))
//            
//            let startDate = Calendar.current.date(byAdding: .day, value: -i, to: .now)!
//            let endDate = Calendar.current.date(byAdding: .second, value: 1, to: startDate)!
//            
//            let stepSample = HKQuantitySample(type: HKQuantityType(.stepCount), quantity: stepQuantity, start: startDate, end: endDate)
//            let weightSample = HKQuantitySample(type: HKQuantityType(.bodyMass), quantity: weightQuantity, start: startDate, end: endDate)
//            
//            mockSamples.append(stepSample)
//            mockSamples.append(weightSample)
//        }
//        
//        try! await requestAuthorization()
//        try! await store.save(mockSamples)
//        
//        print("Dummy data is sent up ✅")
//        
//    }
}
