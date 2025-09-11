//
//  BMICalculatorSheet.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 9/10/25.
//

import SwiftUI

struct BMICalculatorSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    
    // Pickers
    @State private var weightLb: Int = 180
    @State private var feet: Int = 5
    @State private var inches: Int = 9
    
    @State private var bmi: Double? = nil
    @State private var category: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                GroupBox("Weight") {
                    HStack {
                        Picker("Weight (lb)", selection: $weightLb) {
                            ForEach(70...440, id: \.self) {
                                Text("\($0) lb")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .labelsHidden()
                    }
                }
                
                GroupBox("Height") {
                    HStack(spacing: 5) {
                        Picker("Feet", selection: $feet) {
                            ForEach(4...7, id: \.self) {
                                Text("\($0) ft")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .labelsHidden()
                        
                        Picker("Inches", selection: $inches) {
                            ForEach(0...11, id: \.self) { Text("\($0) in") }
                        }
                        .frame(maxWidth: .infinity)
                        .labelsHidden()
                    }
                }
                
                Button("Calculate") {
                    withAnimation {
                        bmi = computeBMI()
                        category = bmiCategory(bmi ?? 0)
                    }
                }
                .buttonStyle(.borderedProminent)
                
                if let bmi {
                    VStack(spacing: 6) {
                        Text("Your BMI")
                            .font(.headline)
                        Text(bmi.formatted(.number.precision(.fractionLength(1))))
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                        Text(category)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .scale))
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("BMI Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.fraction(0.7)])
        .presentationDragIndicator(.hidden)
        .tint(.indigo)
    }
    
    /// BMI Calculation Code
    private func computeBMI() -> Double {
        let totalInches = Double(feet * 12 + inches)
        guard totalInches > 0 else { return 0 }
        return 703.0 * Double(weightLb) / (totalInches * totalInches)
    }
    
    /// BMI Category Message
    private func bmiCategory(_ bmi: Double) -> String {
        switch bmi {
        case ..<18.5: return "Underweight 🙇"
        case 18.5..<25: return "Normal ✅"
        case 25..<30: return "Overweight ⚠️"
        default: return "Obesity 🚩"
        }
    }
}

#Preview {
    BMICalculatorSheet()
}
