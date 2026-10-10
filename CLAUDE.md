# CLAUDE.md

This file guides Claude Code (claude.ai/code) when working in this repository.

## Project

StepBuddy is a SwiftUI iOS app that reads step count and body weight from Apple Health (HealthKit) and visualizes the last 28 days with Swift Charts. Users can also write step/weight entries back to Health.

- Single app target `stepbuddy`, bundle ID `com.vikshitkode.stepbuddy`
- iOS deployment target 18.x, Swift 5 language mode
- Only dependency: [swift-algorithms](https://github.com/apple/swift-algorithms) (SPM, used for `chunked` in `ChartMath`)
- No test target exists yet

## Build

```sh
xcodebuild build \
  -project stepbuddy.xcodeproj \
  -scheme stepbuddy \
  -destination 'generic/platform=iOS Simulator'
```

CI (`.github/workflows/`) runs the same build on `macos-26` for pushes and PRs to `main`, using the newest stable Xcode installed on the runner. There is no test step. GitHub's runners can lag behind the local Xcode (e.g. still Xcode 26 while developing on 27), so code using newer-SDK-only types must be guarded with `#if compiler(...)`, not just `#available`.

## Linting

SwiftLint runs **only in CI**: the `SwiftLint` job (required check on `main`) uses the release pinned by `SWIFTLINT_VERSION` in the workflow, with rules in `.swiftlint.yml`, and posts violations as PR annotations. Only errors fail it. There is deliberately no Xcode build phase, so a Homebrew-upgraded local SwiftLint can't disagree with CI. To bump SwiftLint, change `SWIFTLINT_VERSION` and fix any new violations in the same PR.

HealthKit has no real data in the simulator. To seed it, temporarily uncomment `addSimulatorData()` in `HealthKitManager` and its call in `DashboardView.task` — never commit it uncommented.

## Architecture

```
stepbuddy/
  StepBuddyApp.swift        App entry; creates HealthKitManager, injects via .environment; configures TipKit
  Managers/HealthKitManager.swift  @Observable; all HealthKit auth, queries and writes
  Managers/HealthInsightsManager.swift  @Observable, iOS 26+; all Foundation Models sessions (insight card + chat)
  Model/HealthMetric.swift  { date, value } — one data point per day
  Model/HealthInsight.swift @Generable insight (summary, 3 highlights, suggestion) + ChatMessage
  Charts/                   Chart views + ChartMath (weekday averages, weight diffs) + ChartDataTypes
  Screens/                  DashboardView (root), HealthDataListView, BMI sheet, permission priming, HealthIntelligenceView
  Utilities/                MockData (for #Previews), HealthDataSummary (data → model prompt text), Date/Color extensions
```

- **State:** one `HealthKitManager` instance is shared through SwiftUI's `@Environment(HealthKitManager.self)`. It exposes `stepData`, `weightData`, `weightDiffData` arrays that views read directly.
- **Data fetching:** `HKStatisticsCollectionQueryDescriptor` with daily intervals over the last 28 days (29 for weight diffs, so the first day has a predecessor). Steps use `.cumulativeSum`, weight uses `.mostRecent`. Fetches run in `DashboardView`'s `.task`.
- **Navigation:** `HealthMetricContext` (`.steps` / `.weight`) drives the segmented picker, theme color (pink for steps, indigo for weight) and `navigationDestination` to `HealthDataListView`.
- **Permissions:** `HealthKitPermissionPrimingView` is shown once (`@AppStorage("hasSeenPermissionPriming")`) before requesting HealthKit authorization. Usage strings live in build settings (`INFOPLIST_KEY_NSHealth*UsageDescription`), not an Info.plist file.
- **Units:** weight is in pounds (`.pound()`) throughout; BMI calculator uses lb / ft-in.
- **Health Intelligence:** uses the on-device Foundation Models framework, which needs iOS 26+, while the app targets iOS 18. All FoundationModels code is `@available(iOS 26, *)` and `HealthIntelligenceView` falls back to a "Requires iOS 26" message. `HealthDataSummary` precomputes stats in code (the small model is bad at arithmetic) and the text goes into the session instructions. Errors are mapped for both the iOS 26 `GenerationError` and the iOS 27 `LanguageModelError`.

## Conventions

- The Xcode project uses file-system-synchronized groups: new files under `stepbuddy/` are picked up automatically, no `project.pbxproj` edits needed.
- Every view ends with a `#Preview`; chart previews use `MockData` rather than HealthKit.
- Keep HealthKit access inside `HealthKitManager`; views should not touch `HKHealthStore` directly.
- Use `async`/`await` for HealthKit calls; no `try!` (SwiftLint `force_try`). The fetch and add methods throw: `DashboardView` shows a Retry alert when loading fails and `HealthDataListView` an alert when saving fails.
