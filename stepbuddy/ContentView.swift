//
//  ContentView.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 5/1/25.
//

import SwiftUI

enum HealthMetricContent: CaseIterable, Identifiable {
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

struct ContentView: View {
    
    @State private var selectedStat: HealthMetricContent = .steps
    var isSteps: Bool { selectedStat == .steps }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Picker("Selected Stats", selection: $selectedStat) {
                        ForEach(HealthMetricContent.allCases) { metric in
                            Text(metric.title)
                        }
                    }.pickerStyle(.segmented)
                    
                    VStack{
                        NavigationLink(value: selectedStat){
                            HStack {
                                VStack(alignment: .leading){
                                    Label("Steps", systemImage: "figure.walk").font(.title3.bold()).foregroundStyle(.pink)
                                    Text("Avg: 10K Steps").font(.caption)
                                }
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                
                            }}.foregroundStyle(.secondary)
                            .padding(.bottom, 12)
                        
                        RoundedRectangle(cornerRadius: 12).foregroundStyle(.secondary).frame(height: 150)
                    }.padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                    
                    VStack(alignment: .leading){
                        
                        VStack(alignment: .leading){
                            Label("Averages", systemImage: "calendar").font(.title3.bold()).foregroundStyle(.pink)
                            Text("Last 28 days").font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.bottom, 12)
                        
                        RoundedRectangle(cornerRadius: 12).foregroundStyle(.secondary).frame(height: 240)
                    }.padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                }
                
            }.padding()
                .navigationTitle("Dashboard")
                .navigationDestination(for: HealthMetricContent.self) { metric in
                    Text(metric.title)
                }
        }.tint(isSteps ? .pink : .indigo)
    }
}

#Preview {
    ContentView()
}
