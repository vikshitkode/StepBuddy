//
//  HealthDataListView.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 5/3/25.
//

import SwiftUI

struct HealthDataListView: View {
    
    @Environment(HealthKitManager.self) private var hkManager
    
    @State private var isShowingAddData: Bool = false
    @State private var addDataDate: Date = Date()
    @State private var valueToAdd: String = ""
    
    var metric: HealthMetricContext
    var listData: [HealthMetric] {
        metric == .steps ? hkManager.stepData : hkManager.weightData
    }
    
    var body: some View {
        List(listData.reversed(), id: \.date) { data in
            HStack {
                Text(data.date, format: .dateTime.month().day().year())
                Spacer()
                Text(data.value, format: .number.precision(.fractionLength(metric == .steps ? 0 : 1)))
            }
        }
        .navigationTitle(metric.title)
        .sheet(isPresented: $isShowingAddData) {
            addDataView
        }.toolbar {
            Button("Add Data", systemImage: "plus") {
                isShowingAddData = true
            }
        }
    }
    
    var addDataView: some View {
        @State var showInvalidAlert = false

        // Locale-aware parser (handles "," or ".")
        func parseDouble(_ s: String) -> Double? {
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            let f = NumberFormatter()
            f.locale = .current
            f.numberStyle = .decimal
            return f.number(from: trimmed)?.doubleValue
        }

        // Validation rules (adjust ranges if you like)
        var parsedValue: Double? {
            parseDouble(valueToAdd)
        }
        var isValid: Bool {
            guard let v = parsedValue else { return false }
            switch metric {
            case .steps:
                return v >= 1 && v <= 200_000 && v.rounded(.towardZero) == v
            case .weight:
                return v > 1 && v < 500
            }
        }

        return NavigationStack {
            Form {
                DatePicker("Date", selection: $addDataDate, displayedComponents: .date)
                HStack {
                    Text(metric.title)
                    Spacer()
                    TextField("Value", text: $valueToAdd)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 140)
                        .keyboardType(metric == .steps ? .numberPad : .decimalPad)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                if !valueToAdd.isEmpty && !isValid {
                    Text(metric == .steps
                         ? "Enter a whole number between 1 and 200,000."
                         : "Enter a positive number betwwen 1 and 500 lbs")
                    .font(.footnote)
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle(metric.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Dismiss") { isShowingAddData = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Data") {
                        guard let value = parsedValue, isValid else {
                            showInvalidAlert = true
                            return
                        }
                        Task {
                            if metric == .steps {
                                await hkManager.addStepData(for: addDataDate, value: value.rounded())
                                await hkManager.fetchStepCount()
                            } else {
                                await hkManager.addWeightData(for: addDataDate, value: value)
                                await hkManager.fetchWeights()
                                await hkManager.fetchWeightsForDifferentials()
                            }
                            isShowingAddData = false
                        }
                    }
                    .disabled(!isValid)
                }
            }
            .alert("Invalid value", isPresented: $showInvalidAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(metric == .steps
                     ? "Please enter a whole number of steps."
                     : "Please enter a positive number for weight.")
            }
        }
    }
}

#Preview {
    NavigationStack {
        HealthDataListView(metric: .steps).environment(HealthKitManager())
    }
    
}
