//
//  KokoroVoicePickerSheet.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 10/16/26.
//

import SwiftUI

/// Chooses the Kokoro voice Health Intelligence reads aloud with. Picking a voice saves it and plays a sample.
struct KokoroVoicePickerSheet: View {
    let speech: KokoroSpeechManager

    @Environment(\.dismiss) private var dismiss
    @AppStorage(KokoroVoice.storageKey) private var voiceID = KokoroVoice.defaultID
    @State private var sections: [KokoroVoice.Section]?
    @State private var loadFailed = false

    private static let sampleID = "kokoro-voice-sample"
    private static let sampleText = "Hi! I'll read your health insights in this voice."

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Kokoro Voice")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
        .task {
            await loadVoices()
        }
        .onDisappear {
            if speech.speakingID == Self.sampleID {
                speech.stop()
            }
        }
    }

    @ViewBuilder private var content: some View {
        if let sections {
            List {
                ForEach(sections) { section in
                    Section(section.title) {
                        ForEach(section.voices) { voice in
                            row(for: voice)
                        }
                    }
                }

                Section {
                } footer: {
                    Text("Kokoro-82M runs on this iPhone with MLX. Nothing is sent to a server.")
                }
            }
        } else if loadFailed {
            ContentUnavailableView(
                "Couldn't Load Kokoro",
                systemImage: "exclamationmark.triangle",
                description: Text("The voice files couldn't be read.")
            )
        } else {
            // Loading the model the first time takes a few seconds
            ProgressView("Loading Kokoro…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func row(for voice: KokoroVoice) -> some View {
        let isSelected = voice.id == voiceID

        return Button {
            voiceID = voice.id
            speech.speak(Self.sampleText, id: Self.sampleID, voiceID: voice.id)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(voice.name)
                        .foregroundStyle(.primary)

                    Text(voice.accentName)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if speech.speakingID == Self.sampleID, speech.isPreparing, isSelected {
                    ProgressView()
                } else if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.pink)
                }
            }
            .contentShape(Rectangle())
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func loadVoices() async {
        do {
            let ids = try await KokoroEngine.shared.voiceIDs()
            sections = KokoroVoice.sections(ids)
        } catch {
            loadFailed = true
        }
    }
}

#Preview {
    KokoroVoicePickerSheet(speech: KokoroSpeechManager())
}
