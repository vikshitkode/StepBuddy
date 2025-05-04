//
//  HealthKitPermissionPrimingView.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 5/4/25.
//

import SwiftUI
import HealthKit

struct HealthKitPermissionPrimingView: View {
    
    var description: String = """
 This app displays your step and weight data in interactive charts.
 
 You can also add new step and weight data to Apple Health from this app. Your data is private and secure.
 """
    
    var body: some View {
        VStack(spacing: 130){
            VStack(alignment: .leading, spacing: 10){
                
                Image(.appleHealth).resizable().frame(width: 90, height: 90).shadow(color: .gray.opacity(0.5), radius: 16).padding(.bottom, 12)
                
                Text("Apple Health Integration").font(.title2).bold()
                
                Text(description).foregroundStyle(.secondary)
            }
            
            Button("Connect Apple Health"){
                // TODO
            }.buttonStyle(.borderedProminent).tint(.pink)

        }.padding(30)
    }
}

#Preview {
    HealthKitPermissionPrimingView()
}
