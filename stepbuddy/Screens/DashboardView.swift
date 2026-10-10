//
//  ContentView.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 5/1/25.
//

import SwiftUI
import Charts
import HealthKit
import StoreKit
import TipKit

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
    @AppStorage(StepGoal.storageKey) private var dailyStepGoal = StepGoal.defaultValue
    
    @State private var isShowingPermissionPrimingSheet: Bool = false
    @State private var selectedStat: HealthMetricContext = .steps
    @State private  var isShowingBMISheet: Bool = false
    @State private var isShowingStepGoalSheet = false
    @State private var isShowingHealthIntelligenceSheet = false
    @State private var healthIntelligenceStore = HealthIntelligenceStore()
    @State private var fetchErrorMessage: String?
    private let healthIntelligenceTip = HealthIntelligenceTip()
    
    var isSteps: Bool { selectedStat == .steps }
    
    var backgroundColor: Color {
        selectedStat == .steps ? .pink : .indigo
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    // Inline instead of a popover: on iOS 26 the popover's Liquid Glass bubble
                    // can't be made opaque, and the large title showed through it
                    TipView(healthIntelligenceTip)
                        .tipViewStyle(CompactTipViewStyle())
                        // The card draws its own background
                        .tipBackground(Color.clear)

                    Picker("Selected Stats", selection: $selectedStat) {
                        ForEach(HealthMetricContext.allCases) {
                            Text($0.title)
                        }
                    }.pickerStyle(.segmented)
                    
                    switch selectedStat {
                    case .steps:
                        StepGoalCard(status: StepGoalStatus(goal: dailyStepGoal, history: hkManager.stepHistory)) {
                            isShowingStepGoalSheet = true
                        }
                        StepBarChart(selectedStat: selectedStat, chartData: hkManager.stepData, goal: Double(dailyStepGoal))
                        StepPieChart(chartData: ChartMath.averageWeekdayCount(for: hkManager.stepData))
                    case .weight:
                        WeightLineChart(selectedStat: selectedStat, chartData: hkManager.weightData)
                        WeightDiffBarChart(chartData: ChartMath.avgDailyWeightDiff(for: hkManager.weightDiffData))
                        
                        VStack(spacing: 30) {
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
                await loadHealthData()
                // await hkManager.addSimulatorData()
                isShowingPermissionPrimingSheet = !hasSeenPermissionPriming
            }
            .navigationTitle("Dashboard")
            .toolbar {
                if selectedStat == .weight {
                    ToolbarItem {
                        Button {
                            isShowingBMISheet = true
                        } label: {
                            Image(systemName: "gauge.with.dots.needle.67percent")
                        }
                    }
                }
                
                ToolbarItem {
                    Button {
                        isShowingHealthIntelligenceSheet = true
                        healthIntelligenceTip.invalidate(reason: .actionPerformed)
                    } label: {
                        LinearGradient.customGradientColor
                            .frame(width: 24, height: 24)
                            .mask {
                                Image(systemName: "apple.intelligence")
                                    .resizable()
                                    .scaledToFit()
                            }
                    }
                    .buttonStyle(.plain)
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
            // Access may have just been granted, so load again when the sheet closes
            .sheet(isPresented: $isShowingPermissionPrimingSheet, onDismiss: {
                Task { await loadHealthData() }
            }) {
                HealthKitPermissionPrimingView(hasSeen: $hasSeenPermissionPriming)
            }
            .sheet(isPresented: $isShowingBMISheet) {
                BMICalculatorSheet()
            }
            .sheet(isPresented: $isShowingStepGoalSheet) {
                StepGoalSheet(goal: $dailyStepGoal)
            }
            .sheet(isPresented: $isShowingHealthIntelligenceSheet) {
                HealthIntelligenceView(store: healthIntelligenceStore)
            }
            .alert(
                "Couldn't Load Health Data",
                isPresented: Binding(
                    get: { fetchErrorMessage != nil },
                    set: { if !$0 { fetchErrorMessage = nil } }
                )
            ) {
                Button("Retry") { Task { await loadHealthData() } }
                Button("OK", role: .cancel) { }
            } message: {
                Text(fetchErrorMessage ?? "")
            }
        }.tint(isSteps ? .pink : .indigo)
    }

    private func loadHealthData() async {
        do {
            try await hkManager.fetchStepCount()
            try await hkManager.fetchWeights()
            try await hkManager.fetchWeightsForDifferentials()
        } catch let error as HKError where error.code == .errorAuthorizationNotDetermined {
            // First launch: the permission sheet asks for access, and data loads when it closes
        } catch {
            fetchErrorMessage = error.localizedDescription
        }
    }
}

#Preview {
    DashboardView().environment(HealthKitManager())
}
