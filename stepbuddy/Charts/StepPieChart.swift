//
//  StepPieChart.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 5/22/25.
//

import SwiftUI
import Charts

struct StepPieChart: View {
    
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
                               angularInset: 1).foregroundStyle(.pink.gradient).cornerRadius(6)
                }
            }.frame(height: 240)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
    }
}

#Preview {
    StepPieChart(chartData: ChartMath.averageWeekdayCount(for: HealthMetric.mockData))
}
