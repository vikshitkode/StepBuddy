//
//  StepPieChart.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 5/22/25.
//

import SwiftUI
import Charts

struct StepPieChart: View {
    
    @State private var rawSelectedChartValue: Double? = 0
    
    var selectedWeekDay: WeekDayChartData? {
        guard let rawSelectedChartValue else { return nil }
            var total = 0.0
            
            return chartData.first{
                total = total + $0.value
                return rawSelectedChartValue <= total
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
            
            Chart {
                ForEach(chartData) { weekday in
                    SectorMark(angle: .value("Average Steps", weekday.value),
                               innerRadius: .ratio(0.618),
                               outerRadius: selectedWeekDay?.date.weekdayInt == weekday.date.weekdayInt ? 140 : 110,
                               angularInset: 1).foregroundStyle(.pink.gradient).cornerRadius(6).opacity(selectedWeekDay?.date.weekdayInt == weekday.date.weekdayInt ? 1 : 0.3)
                }
            }
            .chartAngleSelection(value: $rawSelectedChartValue.animation(.easeInOut))
            .frame(height: 240)
            .chartBackground { proxy in
                GeometryReader { geo in
                    if let plotFrame = proxy.plotFrame{
                        let frame = geo[plotFrame]
                        if let selectedWeekDay{
                            VStack{
                                Text(selectedWeekDay.date.weekdayTitle).font(.title3.bold()).contentTransition(.identity)
                                
                                Text(selectedWeekDay.value, format: .number.precision(.fractionLength(0))).fontWeight(.medium).foregroundStyle(.secondary).contentTransition(.numericText())
                            }
                            .position(x: frame.midX, y: frame.midY)
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
    StepPieChart(chartData: ChartMath.averageWeekdayCount(for: HealthMetric.mockData))
}
