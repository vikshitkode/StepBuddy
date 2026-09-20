//
//  stepbuddyApp.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 5/1/25.
//

import SwiftUI
import TipKit

@main
struct StepBuddyApp: App {
    
    let hkManager = HealthKitManager()
    
    init() {
        try? Tips.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environment(hkManager)
        }
    }
}
