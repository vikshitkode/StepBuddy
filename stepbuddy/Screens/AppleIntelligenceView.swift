//
//  AppleIntelligenceView.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 9/19/26.
//

import SwiftUI
import TipKit

struct AppleIntelligenceTip: Tip {
    var title: Text {
        Text("Apple Intelligence")
    }

    var message: Text? {
        Text("Use AI to understand your health data.")
    }

    var image: Image? {
        Image(systemName: "apple.intelligence")
    }
}

struct AppleIntelligenceView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Apple Intelligence")
                    .font(.title)
                    .bold()
                    .foregroundStyle(LinearGradient.customGradientColor)
                
                Text("Coming soon...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AppleIntelligenceView()
}
