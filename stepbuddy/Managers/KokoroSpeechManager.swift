//
//  KokoroSpeechManager.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 10/16/26.
//

import AVFAudio
import Foundation
import KokoroSwift
import Observation

/// Reads Health Intelligence responses aloud with Kokoro-82M, a neural text-to-speech model run on the device with MLX.
/// Text is synthesized a sentence at a time and queued for playback, so speech starts after the first sentence.
@MainActor
@Observable
final class KokoroSpeechManager {
    enum Availability: Equatable {
        case available
        /// MLX needs a Metal GPU family the iOS Simulator doesn't provide.
        case simulator
        /// The model files are only bundled on machines that downloaded them (see CLAUDE.md).
        case modelMissing
    }

    nonisolated static let availability: Availability = {
        #if targetEnvironment(simulator)
        return .simulator
        #else
        return KokoroEngine.modelFiles == nil ? .modelMissing : .available
        #endif
    }()

    /// The item being read aloud, so its button can offer Stop.
    private(set) var speakingID: String?
    /// True until the first sentence is ready to play, including loading the model on first use.
    private(set) var isPreparing = false
    private(set) var errorMessage: String?

    /// Created on first use: setting up an audio engine takes tens of milliseconds on the main thread, and SwiftUI
    /// runs `@State`'s initial value every time the view struct is re-created, so `init` has to stay cheap.
    @ObservationIgnored private var output: AudioOutput?
    @ObservationIgnored private var speakTask: Task<Void, Never>?
    /// Identifies the current request; buffers from an earlier one finishing late are ignored.
    @ObservationIgnored private var request = 0
    @ObservationIgnored private var buffersPlaying = 0
    @ObservationIgnored private var isSynthesizing = false
    /// The latest audio session change. Each one waits for the one before it, so on and off stay in order.
    @ObservationIgnored private var audioSessionUpdate: Task<Void, Never>?

    func toggle(_ text: String, id: String, voiceID: String) {
        if speakingID == id {
            stop()
        } else {
            speak(text, id: id, voiceID: voiceID)
        }
    }

    func speak(_ text: String, id: String, voiceID: String) {
        guard Self.availability == .available else { return }
        let chunks = KokoroText.chunks(text)
        guard !chunks.isEmpty else { return }

        stop()
        request += 1
        let current = request
        speakingID = id
        isPreparing = true
        isSynthesizing = true
        errorMessage = nil

        speakTask = Task {
            await activateAudioSession()
            do {
                for chunk in chunks {
                    let samples = try await KokoroEngine.shared.synthesize(chunk, voiceID: voiceID)
                    guard current == request, !Task.isCancelled else { return }
                    try play(samples, request: current)
                }
                guard current == request else { return }
                isSynthesizing = false
                finishIfDone(request: current)
            } catch {
                guard current == request else { return }
                errorMessage = "Kokoro couldn't read this aloud."
                reset()
            }
        }
    }

    func stop() {
        guard speakingID != nil else { return }
        reset()
    }


    private func play(_ samples: [Float], request current: Int) throws {
        guard let output = output ?? AudioOutput() else { return }
        self.output = output
        let audioEngine = output.engine
        let player = output.player

        guard let buffer = AVAudioPCMBuffer(pcmFormat: output.format, frameCapacity: AVAudioFrameCount(samples.count)),
              let channel = buffer.floatChannelData?[0]
        else { return }

        buffer.frameLength = buffer.frameCapacity
        samples.withUnsafeBufferPointer { source in
            guard let base = source.baseAddress else { return }
            channel.update(from: base, count: samples.count)
        }

        if !audioEngine.isRunning {
            try audioEngine.start()
        }

        buffersPlaying += 1
        player.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { _ in
            Task { @MainActor in
                self.bufferPlayed(request: current)
            }
        }

        if isPreparing {
            isPreparing = false
            player.play()
        }
    }

    private func bufferPlayed(request current: Int) {
        guard current == request else { return }
        buffersPlaying -= 1
        finishIfDone(request: current)
    }

    private func finishIfDone(request current: Int) {
        guard current == request, !isSynthesizing, buffersPlaying == 0 else { return }
        reset()
    }

    /// Stops playback and synthesis of the current request and releases the audio session.
    private func reset() {
        request += 1
        speakTask?.cancel()
        speakTask = nil
        output?.player.stop()
        output?.engine.stop()
        buffersPlaying = 0
        isSynthesizing = false
        isPreparing = false
        speakingID = nil
        setAudioSessionActive(false)
    }

    private func activateAudioSession() async {
        setAudioSessionActive(true)
        // The engine has to start on an active session, or it activates it synchronously on the main thread
        await audioSessionUpdate?.value
    }

    private func setAudioSessionActive(_ active: Bool) {
        let previous = audioSessionUpdate
        audioSessionUpdate = Task {
            await previous?.value
            await KokoroAudioSession.setActive(active)
        }
    }
}


/// The engine and player node that play Kokoro's 24 kHz mono samples.
@MainActor
private final class AudioOutput {
    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    let format: AVAudioFormat

    init?() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: Double(KokoroTTS.Constants.samplingRate), channels: 1) else {
            return nil
        }
        self.format = format
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }
}


/// Owns the Kokoro model. It's loaded on first use (several seconds, ~330 MB) and kept for later requests.
/// MLX work is slow and synchronous, so the actor runs on its own serial queue rather than blocking
/// the main thread or Swift concurrency's shared threads. The model and voices never leave it.
actor KokoroEngine {
    static let shared = KokoroEngine()

    enum EngineError: Error {
        case unavailable
    }

    /// The bundled weights and voice styles, or nil when they weren't downloaded on this machine.
    nonisolated static var modelFiles: (weights: URL, voices: URL)? {
        guard let weights = Bundle.main.url(forResource: "kokoro-v1_0", withExtension: "safetensors"),
              let voices = Bundle.main.url(forResource: "voices", withExtension: "npz")
        else { return nil }
        return (weights, voices)
    }

    private let queue = DispatchSerialQueue(label: "com.vikshitkode.stepbuddy.kokoro")
    private var speaker: KokoroSpeaker?

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        queue.asUnownedSerialExecutor()
    }

    /// The voice identifiers in voices.npz, e.g. "af_heart".
    func voiceIDs() throws -> [String] {
        try loadedSpeaker().voiceIDs
    }

    /// 24 kHz mono samples for one chunk of text. A voice that's no longer in voices.npz falls back to the default.
    func synthesize(_ text: String, voiceID: String) throws -> [Float] {
        let speaker = try loadedSpeaker()
        let voiceID = speaker.voiceIDs.contains(voiceID) ? voiceID : KokoroVoice.defaultID
        return try speaker.synthesize(text, voiceID: voiceID)
    }

    private func loadedSpeaker() throws -> KokoroSpeaker {
        if let speaker {
            return speaker
        }
        // MLX crashes in the Simulator (and SwiftUI previews), and KokoroTTS crashes (try!) on a missing model file
        guard KokoroSpeechManager.availability == .available, let files = Self.modelFiles else {
            throw EngineError.unavailable
        }

        // A small MLX buffer cache: memory matters more than buffer reuse speed on a phone
        let speaker = try KokoroSpeaker(modelURL: files.weights, voicesURL: files.voices, cacheLimit: 32 * 1024 * 1024)
        self.speaker = speaker
        return speaker
    }
}


/// The shared audio session, configured and switched on and off without touching the main thread:
/// AVAudioSession calls there can block the UI (`SessionCore.mm … main thread while the audio session is active`).
/// Kokoro only plays after activation completes, so the category can be set here too.
private enum KokoroAudioSession {
    /// The synchronous AVAudioSession calls block until the audio hardware responds. They run here rather than
    /// on a Swift concurrency thread, which shouldn't be blocked either.
    private static let blockingQueue = DispatchQueue(label: "com.vikshitkode.stepbuddy.kokoro-audio-session")

    /// Only read and written on `blockingQueue`.
    nonisolated(unsafe) private static var isConfigured = false

    /// Deactivating also lets music or podcasts that were ducked come back to full volume.
    static func setActive(_ active: Bool) async {
        if active {
            await configure()
        }

        // The async activate/deactivate API only exists in the iOS 27 SDK (Xcode 27 / Swift 6.4).
        // CI builds with Xcode 26, so the runtime #available check alone doesn't compile there.
        #if compiler(>=6.4)
        if #available(iOS 27, *) {
            let session = AVAudioSession.sharedInstance()
            if active {
                _ = try? await session.activate(options: [])
            } else {
                _ = try? await session.deactivate(options: .notifyOthersOnDeactivation)
            }
            return
        }
        #endif

        await withCheckedContinuation { continuation in
            blockingQueue.async {
                try? AVAudioSession.sharedInstance().setActive(active, options: active ? [] : .notifyOthersOnDeactivation)
                continuation.resume()
            }
        }
    }

    /// Playback so speech is heard with the silent switch on, ducking other audio while it talks.
    /// Set only once: the category outlives deactivation.
    private static func configure() async {
        await withCheckedContinuation { continuation in
            blockingQueue.async {
                if !isConfigured {
                    do {
                        try AVAudioSession.sharedInstance().setCategory(
                            .playback,
                            mode: .spokenAudio,
                            options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers]
                        )
                        isConfigured = true
                    } catch {
                        // Retried before the next request
                    }
                }
                continuation.resume()
            }
        }
    }
}
