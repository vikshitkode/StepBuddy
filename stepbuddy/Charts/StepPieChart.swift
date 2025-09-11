//
//  StepPieChart.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 5/22/25.
//

import SwiftUI
import Charts

struct StepPieChart: View {
    
    @State private var rawSelectedChartValue: Double? = nil
    @State private var isInteracting: Bool = false

    
    var selectedWeekDay: WeekDayChartData? {
        guard let rawSelectedChartValue, !chartData.isEmpty else { return nil }
        
        let total = chartData.reduce(0.0) { $0 + $1.value }
        let normalizedValue = min(max(0, rawSelectedChartValue), total)
        
        var runningTotal = 0.0
        return chartData.first { weekDay in
            runningTotal += weekDay.value
            return normalizedValue <= runningTotal
        }
    }
    
    var chartData: [WeekDayChartData]
    
    var body: some View {
        VStack(alignment: .leading){
            VStack(alignment: .leading){
                Label("Averages", systemImage: "calendar").font(.title3.bold()).foregroundStyle(.pink)
                Text("Last 28 days").font(.caption).foregroundStyle(.secondary)
            }
            .padding(.bottom, 12)
            
            if chartData.isEmpty {
                Text("No data available")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(height: 240)
            } else {
                
                if !isInteracting {
                        Text("Touch a slice to see details")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 4)
                            .transition(.opacity)
                }
                
                Chart {
                    ForEach(chartData) { weekday in
                        SectorMark(
                            angle: .value("Average Steps", weekday.value),
                            innerRadius: .ratio(0.618),
                            outerRadius: selectedWeekDay?.date.weekdayInt == weekday.date.weekdayInt
                                ? 140
                                : 110,
                            angularInset: 1
                        )
                        .foregroundStyle(.pink.gradient)
                        .cornerRadius(6)
                        .opacity(selectedWeekDay?.date.weekdayInt == weekday.date.weekdayInt
                            ? 1
                            : 0.3)
                    }
                }
                .chartAngleSelection(value: $rawSelectedChartValue.animation(.easeInOut))
                .frame(height: 240)
                .onChange(of: rawSelectedChartValue) { oldValue, newValue in
                    if newValue != nil { isInteracting = true } else { isInteracting = false }
                }
                .chartBackground { proxy in
                    GeometryReader { geo in
                        if let plotFrame = proxy.plotFrame {
                            let frame = geo[plotFrame]
                            if let selectedWeekDay {
                                VStack {
                                    Text(selectedWeekDay.date.weekdayTitle)
                                        .font(.title3.bold())
                                        .contentTransition(.identity)
                                    
                                    Text(selectedWeekDay.value, format: .number.precision(.fractionLength(0)))
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)
                                        .contentTransition(.numericText())
                                        .transition(.opacity)
                                }
                                .position(x: frame.midX, y: frame.midY)
                                .animation(.easeInOut, value: selectedWeekDay)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
    }
}

#Preview {
    StepPieChart(chartData: ChartMath.averageWeekdayCount(for: MockData.steps))
}
