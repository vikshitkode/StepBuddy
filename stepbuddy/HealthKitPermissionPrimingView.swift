//
//  HealthKitPermissionPrimingView.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 5/4/25.
//

import SwiftUI
import HealthKitUI

struct HealthKitPermissionPrimingView: View {
    
    @Environment(HealthKitManager.self) private var hkManager
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingHealthKitPermissions = false
    
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
                isShowingHealthKitPermissions = true
            }.buttonStyle(.borderedProminent).tint(.pink)

        }.padding(30)
            .healthDataAccessRequest(
                store: hkManager.store,
                shareTypes: hkManager.types,
                readTypes: hkManager.types,
                trigger: isShowingHealthKitPermissions) { result in
                    switch result {
                    case .success(_):
                        dismiss()
                    case .failure(_):
                        dismiss()
                    }
                }
    }
}

#Preview {
    HealthKitPermissionPrimingView().environment(HealthKitManager())
}
