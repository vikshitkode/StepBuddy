//
//  KokoroSpeaker.swift
//  StepBuddy addition to the vendored KokoroSwift (see Packages/README.md)
//

import Foundation
import MLX
import MLXUtilsLibrary

/// The model plus its voice styles behind a plain Swift API, so apps never touch MLX types.
///
/// An app that depends only on the KokoroSwift product can't call MLX or MLXUtilsLibrary itself: those symbols
/// don't link (e.g. `NpyzReader`). Not thread-safe: use one instance from one thread or actor at a time.
public final class KokoroSpeaker {
  public enum SpeakerError: Error {
    case voicesUnreadable
    case unknownVoice(String)
  }

  private let tts: KokoroTTS
  /// Keyed by voice ID without the ".npy" extension, e.g. "af_heart"
  private let voices: [String: MLXArray]

  /// Loads the model weights and voice styles, which takes several seconds and ~330 MB of memory.
  /// - Parameters:
  ///   - modelURL: `kokoro-v1_0.safetensors`. KokoroTTS crashes if it's missing or unreadable, so check first.
  ///   - voicesURL: `voices.npz` of voice style arrays
  ///   - cacheLimit: Bytes MLX may keep in its buffer cache; smaller saves memory at some speed cost.
  public init(modelURL: URL, voicesURL: URL, cacheLimit: Int) throws {
    Memory.cacheLimit = cacheLimit

    guard let arrays = NpyzReader.read(fileFromPath: voicesURL), !arrays.isEmpty else {
      throw SpeakerError.voicesUnreadable
    }
    voices = Dictionary(uniqueKeysWithValues: arrays.map { key, value in
      (key.hasSuffix(".npy") ? String(key.dropLast(4)) : key, value)
    })
    tts = KokoroTTS(modelPath: modelURL)
  }

  public var voiceIDs: [String] {
    Array(voices.keys)
  }

  /// 24 kHz mono samples for at most 510 phoneme tokens of text. Voice IDs starting with "b" are British English,
  /// all others American English.
  public func synthesize(_ text: String, voiceID: String, speed: Float = 1.0) throws -> [Float] {
    guard let voice = voices[voiceID] else {
      throw SpeakerError.unknownVoice(voiceID)
    }

    let language: Language = voiceID.hasPrefix("b") ? .enGB : .enUS
    return try tts.generateAudio(voice: voice, language: language, text: text, speed: speed).0
  }
}
