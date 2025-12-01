//
//  ContentView.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 5/1/25.
//

import SwiftUI
import Charts
import StoreKit

enum HealthMetricContext: CaseIterable, Identifiable {
    case steps, weight
    var id: Self { self }
    
    var title: String {
        switch self {
        case .steps:
            return "Steps"
        case .weight:
            return "Weight"
        }
    }
}

struct DashboardView: View {
    
    @Environment(HealthKitManager.self) private var hkManager
    
    @AppStorage("hasSeenPermissionPriming") private var hasSeenPermissionPriming: Bool = false
    
    @State private var isShowingPermissionPrimingSheet: Bool = false
    @State private var selectedStat: HealthMetricContext = .steps
    @State private  var isShowingBMISheet: Bool = false
    
    var isSteps: Bool { selectedStat == .steps }
    
    var backgroundColor: Color {
        selectedStat == .steps ? .pink : .indigo
    }
    
    var customGradientColor: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.70, blue: 0.20),
                Color(red: 0.99, green: 0.30, blue: 0.50),
                Color(red: 0.32, green: 0.57, blue: 1.0),
                Color(red: 0.30, green: 0.80, blue: 0.90)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                
                VStack(spacing: 25){
                    Picker("Selected Stats", selection: $selectedStat) {
                        ForEach(HealthMetricContext.allCases) {
                            Text($0.title)
                        }
                    }.pickerStyle(.segmented)
                    
                    switch selectedStat {
                    case .steps:
                        StepBarChart(selectedStat: selectedStat, chartData: hkManager.stepData)
                        StepPieChart(chartData: ChartMath.averageWeekdayCount(for: hkManager.stepData))
                    case .weight:
                        WeightLineChart(selectedStat: selectedStat, chartData: hkManager.weightData)
                        WeightDiffBarChart(chartData: ChartMath.avgDailyWeightDiff(for: hkManager.weightDiffData))
                        
                        VStack(spacing: 30){
                            /// BMI Calculation
                            Button("Calculate BMI") {
                                isShowingBMISheet = true
                            }
                            .buttonStyle(.bordered)
                            .padding(.top, 8)
                            
                            /// Review for the App
                            Button("Leave us a Review!") {
                                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                    AppStore.requestReview(in: scene)
                                }
                            }.foregroundStyle(.indigo)
                        }
                    }
                    
                }.padding()
                
            }
            
            .task {
                await hkManager.fetchStepCount()
                await hkManager.fetchWeights()
                await hkManager.fetchWeightsForDifferentials()
                ChartMath.averageWeekdayCount(for: hkManager.stepData)
//                await hkManager.addSimulatorData()
                isShowingPermissionPrimingSheet = !hasSeenPermissionPriming
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem {
                    customGradientColor
                    .frame(width: 24, height: 24)
                    .mask {
                        Image(systemName: "apple.intelligence")
                            .resizable()
                            .scaledToFit()
                    }
                }
            }
            .toolbarTitleDisplayMode(.inlineLarge)
            .background(
                LinearGradient(
                    colors: [backgroundColor.opacity(0.25), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationDestination(for: HealthMetricContext.self) { metric in
                HealthDataListView(metric: metric)
            }
            .sheet(isPresented: $isShowingPermissionPrimingSheet) {
                HealthKitPermissionPrimingView(hasSeen: $hasSeenPermissionPriming)
            }
            .sheet(isPresented: $isShowingBMISheet) {
                BMICalculatorSheet()
            }
            
        }.tint(isSteps ? .pink : .indigo)
    }
}

#Preview {
    DashboardView().environment(HealthKitManager())
}
