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
    @State private var addDataDate = Date()
    @State private var valueToAdd: String = ""
    @State private var saveErrorMessage: String?
    
    var metric: HealthMetricContext
    var listData: [HealthMetric] {
        metric == .steps ? hkManager.stepData : hkManager.weightData
    }
    
    var backgroundColor: Color {
        metric == .steps ? .pink : .indigo
    }
    
    var body: some View {
        List {
            Section(
                header: Text("Only last 28 days are shown on this screen.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            ) {
                ForEach(listData.reversed(), id: \.date) { data in
                    HStack {
                        Text(data.date, format: .dateTime.month().day().year())
                        Spacer()
                        Text(data.value, format: .number.precision(.fractionLength(metric == .steps ? 0 : 1)))
                    }
                }
            }
        }
        .navigationTitle(metric.title)
        .scrollContentBackground(.hidden)
        .background(
            LinearGradient(
                colors: [backgroundColor.opacity(0.25), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .sheet(isPresented: $isShowingAddData) { addDataView }
        .toolbar {
            Button("Add Data", systemImage: "plus") { isShowingAddData = true }
        }
    }
    
    var addDataView: some View {
        @State var showInvalidAlert = false

        // Locale-aware parser (handles "," or ".")
        func parseDouble(_ text: String) -> Double? {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            let formatter = NumberFormatter()
            formatter.locale = .current
            formatter.numberStyle = .decimal
            return formatter.number(from: trimmed)?.doubleValue
        }

        // Validation rules (adjust ranges if you like)
        var parsedValue: Double? {
            parseDouble(valueToAdd)
        }
        var isValid: Bool {
            guard let number = parsedValue else { return false }
            switch metric {
            case .steps:
                return number >= 1 && number <= 200_000 && number.rounded(.towardZero) == number
            case .weight:
                return number > 1 && number < 500
            }
        }

        return NavigationStack {
            Form {
                DatePicker("Date", selection: $addDataDate, in: ...Date(), displayedComponents: .date)
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
                    Text(
                        metric == .steps
                            ? "Enter a whole number between 1 and 200,000."
                            : "Enter a positive number betwwen 1 and 500 lbs"
                    )
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
                            do {
                                if metric == .steps {
                                    try await hkManager.addStepData(for: addDataDate, value: value.rounded())
                                    await hkManager.fetchStepCount()
                                } else {
                                    try await hkManager.addWeightData(for: addDataDate, value: value)
                                    await hkManager.fetchWeights()
                                    await hkManager.fetchWeightsForDifferentials()
                                }
                                isShowingAddData = false
                            } catch {
                                // Used to crash via try! (e.g. when write access to Health is denied)
                                saveErrorMessage = error.localizedDescription
                            }
                        }
                    }
                    .disabled(!isValid)
                }
            }
            .alert("Invalid value", isPresented: $showInvalidAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(
                    metric == .steps
                        ? "Please enter a whole number of steps."
                        : "Please enter a positive number for weight."
                )
            }
            .alert(
                "Couldn't Save to Apple Health",
                isPresented: Binding(
                    get: { saveErrorMessage != nil },
                    set: { if !$0 { saveErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(saveErrorMessage ?? "")
            }
        }
    }
}

#Preview {
    NavigationStack {
        HealthDataListView(metric: .steps).environment(HealthKitManager())
    }
}
