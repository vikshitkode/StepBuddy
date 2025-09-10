//
//  WightDiffBarChart.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 9/10/25.
//

import SwiftUI
import Charts

struct WeightDiffBarChart: View {
    @State private var rawSelectedDate: Date?

    var chartData: [WeekDayChartData]

    var selectedData: WeekDayChartData? {
        guard let rawSelectedDate else { return nil }
        return chartData.first { Calendar.current.isDate(rawSelectedDate, inSameDayAs: $0.date) }
    }


    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Label("Avg Weight Change", systemImage: "figure")
                        .font(.title3.bold())
                        .foregroundStyle(.indigo)
                    Text("Per WeekDay (Last 28 days)")
                        .font(.caption)
                }
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(.bottom, 12)

            chartView
                .frame(height: 150)
                .chartXSelection(value: $rawSelectedDate.animation(.easeInOut))
                .onChange(of: rawSelectedDate) { _, newValue in
                    print(newValue as Any)
                }
                .chartXAxis {
                    
                    AxisMarks(values: .stride(by: .day)) {
                        AxisValueLabel(format: .dateTime.weekday(), centered: true)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine().foregroundStyle(Color.secondary.opacity(0.3))
                        AxisValueLabel()
                    }
                }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
    }


    @ViewBuilder
    private var chartView: some View {
        
        Chart {
            if let selectedData {
                RuleMark(x: .value("Selected Data", selectedData.date, unit: .day))
                    .foregroundStyle(Color.secondary.opacity(0.3))
                    .offset(y: -10)
                    .annotation(
                        position: .top,
                        spacing: 0,
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                    ) { annotationView }
            }


            ForEach(chartData, id: \.date) { weightdiff in
                BarMark(
                    x: .value("Date", weightdiff.date, unit: .day),
                    y: .value("Weights", weightdiff.value)
                )
                .foregroundStyle(weightdiff.value >= 0 ? Color.indigo.gradient : Color.mint.gradient)
            }
        }
    }


    private var annotationView: some View {
        VStack(alignment: .leading) {
            Text(selectedData?.date ?? .now,
                 format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                .font(.footnote.bold())
                .foregroundStyle(.secondary)

            Text(selectedData?.value ?? 0, format: .number.precision(.fractionLength(2)))
                .fontWeight(.heavy)
                .foregroundStyle((selectedData?.value ?? 0) >= 0 ? .indigo : .mint)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .secondary.opacity(0.3), radius: 2, x: 2, y: 2)
        )
    }
}

#Preview {
    WeightDiffBarChart(chartData: MockData.weightDiffs)
}
