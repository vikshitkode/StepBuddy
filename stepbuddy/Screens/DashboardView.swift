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
    @State private var isShowingAppleIntelligenceSheet = false
    private let appleIntelligenceTip = AppleIntelligenceTip()
    
    var isSteps: Bool { selectedStat == .steps }
    
    var backgroundColor: Color {
        selectedStat == .steps ? .pink : .indigo
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
                            Spacer()
                            /// App Review
                            Button("Leave us a Review!") {
                                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                    AppStore.requestReview(in: scene)
                                }
                            }
                            .foregroundStyle(.indigo)
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
                if selectedStat == .weight {
                    // BMI Button shown only in weight tab
                    ToolbarItem {
                        Button {
                            isShowingBMISheet = true
                            print("BMI button tapped")
                        } label: {
                            Image(systemName: "gauge.with.dots.needle.67percent")
                        }
                    }
                }
                // Apple Intelligence Button
                ToolbarItem {
                    appleIntelligenceButton
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
            .sheet(isPresented: $isShowingAppleIntelligenceSheet) {
                AppleIntelligenceView()
            }
            
        }.tint(isSteps ? .pink : .indigo)
    }
    
    @ViewBuilder
    private var appleIntelligenceButton: some View {
        let button = Button {
            isShowingAppleIntelligenceSheet = true
        } label: {
            LinearGradient.customGradientColor
                .frame(width: 24, height: 24)
                .mask {
                    Image(systemName: "apple.intelligence")
                        .resizable()
                        .scaledToFit()
                }
        }

        if hasSeenPermissionPriming {
            button
                .popoverTip(appleIntelligenceTip)
        } else {
            button
        }
    }
}


#Preview {
    DashboardView().environment(HealthKitManager())
}
