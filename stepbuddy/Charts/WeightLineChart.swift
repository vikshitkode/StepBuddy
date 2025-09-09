//
//  WeightLineChart.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 9/6/25.
//

import SwiftUI
import Charts

struct WeightLineChart: View {
    
    var selectedStat: HealthMetricContext
    var chartData: [HealthMetric]
    
    var minValue: Double {
        chartData.map { $0.value }.min() ?? 0
    }
    
    var body: some View {
        VStack {
            NavigationLink(value: selectedStat) {
                HStack {
                    VStack(alignment: .leading) {
                        Label("Weight", systemImage: "figure")
                            .font(.title3.bold())
                            .foregroundStyle(.indigo)
                        Text("Avg: 180 lbs")
                            .font(.caption)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            }
            .foregroundStyle(.secondary)
            .padding(.bottom, 12)
            
            Chart{
                ForEach(chartData, id: \.identifier) { weight in
                    
                    AreaMark(x: .value("Day", weight.date, unit: .day),
                             yStart: .value("Min Value", weight.value),
                             yEnd: .value("Min Value", minValue)
                    )
                    .foregroundStyle(Gradient(colors: [.indigo.opacity(0.5), .clear]))
                    
                    LineMark(
                        x: .value("Day", weight.date, unit: .day),
                        y: .value("Value", weight.value)
                    ).foregroundStyle(.indigo).interpolationMethod(.catmullRom).symbol(.circle)
                }
            }
            .frame(height: 150)
            .chartYScale(domain: .automatic(includesZero: false))
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
    }
}

#Preview {
    WeightLineChart(selectedStat: .weight, chartData: MockData.weights)
}
