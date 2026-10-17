# CLAUDE.md

This file guides Claude Code (claude.ai/code) when working in this repository.

## Project

StepBuddy is a SwiftUI iOS app that reads step count and body weight from Apple Health (HealthKit) and visualizes the last 28 days with Swift Charts. Users can also write step/weight entries back to Health, and set a daily step goal with streaks.

- Single app target `stepbuddy`, bundle ID `com.vikshitkode.stepbuddy`
- iOS deployment target 18.x, Swift 6 language mode (complete data-race checking; keep it warning-free)
- Dependencies: [swift-algorithms](https://github.com/apple/swift-algorithms) (SPM, used for `chunked` in `ChartMath`) and, on the Kokoro experiment, the vendored local packages in `Packages/` (KokoroSwift + MisakiSwift, which pull in mlx-swift; see below)
- Unit tests: `stepbuddyTests` (Swift Testing), hosted in the app so they can `@testable import stepbuddy`

## Build and test

```sh
xcodebuild build \
  -project stepbuddy.xcodeproj \
  -scheme stepbuddy \
  -destination 'generic/platform=iOS Simulator'

xcodebuild test \
  -project stepbuddy.xcodeproj \
  -scheme stepbuddy \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

CI (`.github/workflows/`) runs on `macos-26` for pushes and PRs to `main` with the newest stable Xcode installed on the runner. Three jobs run in parallel and are all required checks on `main`: `SwiftLint`, `Build` (the build command above) and `Test` (`xcodebuild test` on an iPhone simulator from the runner's newest iOS runtime). GitHub's runners can lag behind the local Xcode (e.g. still Xcode 26 while developing on 27), so code using newer-SDK-only types must be guarded with `#if compiler(...)`, not just `#available`.

## Linting

SwiftLint runs **only in CI**: the `SwiftLint` job (required check on `main`) uses the release pinned by `SWIFTLINT_VERSION` in the workflow, with rules in `.swiftlint.yml`, and posts violations as PR annotations. Only errors fail it. There is deliberately no Xcode build phase, so a Homebrew-upgraded local SwiftLint can't disagree with CI. To bump SwiftLint, change `SWIFTLINT_VERSION` and fix any new violations in the same PR.

HealthKit has no real data in the simulator. To seed it, temporarily uncomment `addSimulatorData()` in `HealthKitManager` and its call in `DashboardView.task` — never commit it uncommented.

## Architecture

```
stepbuddy/
  StepBuddyApp.swift        App entry; creates HealthKitManager, injects via .environment; configures TipKit
  Managers/HealthKitManager.swift  @MainActor @Observable; all HealthKit auth, queries and writes
  Managers/HealthInsightsManager.swift  @Observable, iOS 26+; all Foundation Models sessions (insight card + chat)
  Managers/KokoroSpeechManager.swift  @MainActor @Observable; reads responses aloud with Kokoro (KokoroEngine actor owns the model)
  Model/HealthMetric.swift  { date, value } — one data point per day
  Model/HealthInsight.swift @Generable insight (summary, 3 highlights, suggestion) + ChatMessage
  Model/StepGoal.swift      Daily step goal setting (@AppStorage key, range) + StepGoalStatus (today's progress, streaks)
  Model/KokoroVoice.swift   Kokoro voice ID parsing ("af_heart" → American female "Heart"), picker sections, @AppStorage key
  Charts/                   Chart views + ChartMath (weekday averages, weight diffs) + ChartDataTypes
  Screens/                  DashboardView (root), HealthDataListView, BMI sheet, permission priming, HealthIntelligenceView, KokoroVoicePickerSheet, SpeakButton
  Utilities/                MockData (for #Previews), HealthDataSummary (data → model prompt text), KokoroText (sentence chunks for TTS), StepStreak (goal streak math), Date/Color extensions
stepbuddyTests/             Swift Testing unit tests for the pure logic (ChartMath, HealthDataSummary, KokoroText, KokoroVoice, StepStreak)
```

- **State:** one `HealthKitManager` instance is shared through SwiftUI's `@Environment(HealthKitManager.self)`. It exposes `stepData`, `weightData`, `weightDiffData` arrays that views read directly, plus `stepHistory` (a year of daily step totals for goal streaks; `stepData` is its last 28 days). It is `@MainActor`, so views call it without crossing actors; HealthKit does its work off the main thread inside the awaited queries.
- **Data fetching:** `HKStatisticsCollectionQueryDescriptor` with daily intervals over the last 28 days (29 for weight diffs, so the first day has a predecessor). Steps use `.cumulativeSum`, weight uses `.mostRecent`. Fetches run in `DashboardView`'s `.task`.
- **Navigation:** `HealthMetricContext` (`.steps` / `.weight`) drives the segmented picker, theme color (pink for steps, indigo for weight) and `navigationDestination` to `HealthDataListView`.
- **Permissions:** `HealthKitPermissionPrimingView` is shown once (`@AppStorage("hasSeenPermissionPriming")`) before requesting HealthKit authorization. Usage strings live in build settings (`INFOPLIST_KEY_NSHealth*UsageDescription`), not an Info.plist file.
- **Step goal:** stored with `@AppStorage(StepGoal.storageKey)` (default 10,000, 1,000–50,000 in steps of 500). A streak is consecutive calendar days with steps ≥ the goal; until today's goal is met the streak runs through yesterday. Changing the goal recalculates past streaks (no per-day goal history). `StepGoalCard` + `StepGoalSheet` on the Steps tab; `StepBarChart` draws the goal line and dims days below it. The goal and streak are also in the Health Intelligence prompt.
- **Units:** weight is in pounds (`.pound()`) throughout; BMI calculator uses lb / ft-in.
- **Health Intelligence:** uses the on-device Foundation Models framework, which needs iOS 26+, while the app targets iOS 18. All FoundationModels code is `@available(iOS 26, *)` and `HealthIntelligenceView` falls back to a "Requires iOS 26" message. `HealthDataSummary` precomputes stats in code (the small model is bad at arithmetic) and the text goes into the session instructions. Errors are mapped for both the iOS 26 `GenerationError` and the iOS 27 `LanguageModelError`.
- **Kokoro read-aloud (experiment):** the insight card and finished assistant replies get a speaker button, and the toolbar a voice picker (28 voices from `voices.npz`, saved under `@AppStorage(KokoroVoice.storageKey)`, default `af_heart`). [Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M) runs on the device with MLX via the vendored `Packages/KokoroSwift`, which only exposes `KokoroSpeaker` to the app (no MLX types in app code). `KokoroEngine` is an actor on its own `DispatchSerialQueue` executor so the slow, synchronous MLX work never blocks the main thread or the cooperative pool; it loads the model on first use (several seconds, ~330 MB of memory) and keeps it. Text is synthesized one sentence at a time (`KokoroText.chunks`, under Kokoro's 510-token limit) and queued on an `AVAudioPlayerNode`, so playback starts after the first sentence. The audio session is activated/deactivated off the main thread (iOS 27 async API, else a background queue).
  - **Real device only.** MLX can't run in the iOS Simulator (no suitable Metal GPU family), so `KokoroSpeechManager.availability` is `.simulator` there and the buttons are hidden. Tests and CI still build and link it.
  - **Metal API Validation must be off** in the scheme's Run diagnostics. MLX binds empty buffers with `setBytes(nil, 0, …)` ([ml-explore/mlx#4061](https://github.com/ml-explore/mlx/issues/4061)), which the validation layer aborts on (`failed assertion 'bytes argument cannot be nil'`). Validation only exists when running from Xcode, never in shipped builds. MLX fixed it in [#4622](https://github.com/ml-explore/mlx/pull/4622) (`08298bb`, Oct 5 2026), but as of mlx-swift 0.32.3 (and its `main` on Oct 16) mlx-swift still pins MLX `1f8e74e` from Aug 25, without it. Re-enable validation once an mlx-swift release pins MLX at or after `08298bb` (check `Source/Cmlx/mlx` at the release tag).
  - **Model files are local-only and gitignored** (`stepbuddy/Resources/Kokoro/`, 327 MB + 14.6 MB). Without them the app builds and Kokoro reports `.modelMissing`. Never construct `KokoroTTS` without checking the files exist: it `try!`-crashes on a missing model. To fetch them (the weights are Git LFS in [KokoroTestApp](https://github.com/mlalma/KokoroTestApp); check the SHA-256 against its LFS pointer, `4e9ecdf0…acd8`):
    ```sh
    mkdir -p stepbuddy/Resources/Kokoro
    curl -fL -o stepbuddy/Resources/Kokoro/kokoro-v1_0.safetensors https://media.githubusercontent.com/media/mlalma/KokoroTestApp/main/Resources/kokoro-v1_0.safetensors
    curl -fL -o stepbuddy/Resources/Kokoro/voices.npz https://raw.githubusercontent.com/mlalma/KokoroTestApp/main/Resources/voices.npz
    ```
  - **`Packages/` is vendored and patched**, because the published kokoro-ios 1.0.11 / MisakiSwift 1.0.6 can't be built into an iOS app (resource bundles fail codesign, mlx-swift 0.30.2 doesn't link with the iOS 26+ SDKs, so they use 0.32.3; `.dynamic` frameworks weren't embedded). `Packages/README.md` lists each patch and the upstream issue. SwiftLint excludes `Packages`.

## Conventions

- The Xcode project uses file-system-synchronized groups: new files under `stepbuddy/` are picked up automatically, no `project.pbxproj` edits needed.
- Every view ends with a `#Preview`; chart previews use `MockData` rather than HealthKit.
- Tests use fixed dates from `TestDates` and build expected numbers with the same `FormatStyle` as the code, so they pass in any locale.
- Keep HealthKit access inside `HealthKitManager`; views should not touch `HKHealthStore` directly.
- Use `async`/`await` for HealthKit calls; no `try!` (SwiftLint `force_try`). The fetch and add methods throw: `DashboardView` shows a Retry alert when loading fails and `HealthDataListView` an alert when saving fails.
