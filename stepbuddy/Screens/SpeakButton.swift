//
//  SpeakButton.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 10/16/26.
//

import SwiftUI

/// Reads a response aloud, or stops it. Shows a spinner while the first sentence is synthesized
/// and pulses the stop symbol while it talks.
struct SpeakButton: View {
    let isSpeaking: Bool
    var isPreparing = false
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Group {
                if isPreparing {
                    ProgressView()
                } else {
                    Image(systemName: isSpeaking ? "stop.circle.fill" : "speaker.wave.2")
                        .font(.body.weight(.medium))
                        .contentTransition(.symbolEffect(.replace))
                        .symbolEffect(.pulse, isActive: isSpeaking && !reduceMotion)
                }
            }
            .frame(width: 32, height: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .tint(.pink)
        .accessibilityLabel(isSpeaking ? "Stop reading aloud" : "Read aloud")
        .accessibilityValue(isPreparing ? "Preparing" : "")
    }
}

#Preview {
    HStack(spacing: 20) {
        SpeakButton(isSpeaking: false) {}
        SpeakButton(isSpeaking: true, isPreparing: true) {}
        SpeakButton(isSpeaking: true) {}
    }
}
