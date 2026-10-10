# CLAUDE.md

This file guides Claude Code (claude.ai/code) when working in this repository.

## Project

StepBuddy is a SwiftUI iOS app that reads step count and body weight from Apple Health (HealthKit) and visualizes the last 28 days with Swift Charts. Users can also write step/weight entries back to Health, and set a daily step goal with streaks.

- Single app target `stepbuddy`, bundle ID `com.vikshitkode.stepbuddy`
- iOS deployment target 18.x, Swift 6 language mode (complete data-race checking; keep it warning-free)
- Only dependency: [swift-algorithms](https://github.com/apple/swift-algorithms) (SPM, used for `chunked` in `ChartMath`)
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
  Model/HealthMetric.swift  { date, value } — one data point per day
  Model/HealthInsight.swift @Generable insight (summary, 3 highlights, suggestion) + ChatMessage
  Model/StepGoal.swift      Daily step goal setting (@AppStorage key, range) + StepGoalStatus (today's progress, streaks)
  Charts/                   Chart views + ChartMath (weekday averages, weight diffs) + ChartDataTypes
  Screens/                  DashboardView (root), HealthDataListView, BMI sheet, permission priming, HealthIntelligenceView
  Utilities/                MockData (for #Previews), HealthDataSummary (data → model prompt text), StepStreak (goal streak math), Date/Color extensions
stepbuddyTests/             Swift Testing unit tests for the pure logic (ChartMath, HealthDataSummary, StepStreak)
```

- **State:** one `HealthKitManager` instance is shared through SwiftUI's `@Environment(HealthKitManager.self)`. It exposes `stepData`, `weightData`, `weightDiffData` arrays that views read directly, plus `stepHistory` (a year of daily step totals for goal streaks; `stepData` is its last 28 days). It is `@MainActor`, so views call it without crossing actors; HealthKit does its work off the main thread inside the awaited queries.
- **Data fetching:** `HKStatisticsCollectionQueryDescriptor` with daily intervals over the last 28 days (29 for weight diffs, so the first day has a predecessor). Steps use `.cumulativeSum`, weight uses `.mostRecent`. Fetches run in `DashboardView`'s `.task`.
- **Navigation:** `HealthMetricContext` (`.steps` / `.weight`) drives the segmented picker, theme color (pink for steps, indigo for weight) and `navigationDestination` to `HealthDataListView`.
- **Permissions:** `HealthKitPermissionPrimingView` is shown once (`@AppStorage("hasSeenPermissionPriming")`) before requesting HealthKit authorization. Usage strings live in build settings (`INFOPLIST_KEY_NSHealth*UsageDescription`), not an Info.plist file.
- **Step goal:** stored with `@AppStorage(StepGoal.storageKey)` (default 10,000, 1,000–50,000 in steps of 500). A streak is consecutive calendar days with steps ≥ the goal; until today's goal is met the streak runs through yesterday. Changing the goal recalculates past streaks (no per-day goal history). `StepGoalCard` + `StepGoalSheet` on the Steps tab; `StepBarChart` draws the goal line and dims days below it. The goal and streak are also in the Health Intelligence prompt.
- **Units:** weight is in pounds (`.pound()`) throughout; BMI calculator uses lb / ft-in.
- **Health Intelligence:** uses the on-device Foundation Models framework, which needs iOS 26+, while the app targets iOS 18. All FoundationModels code is `@available(iOS 26, *)` and `HealthIntelligenceView` falls back to a "Requires iOS 26" message. `HealthDataSummary` precomputes stats in code (the small model is bad at arithmetic) and the text goes into the session instructions. Errors are mapped for both the iOS 26 `GenerationError` and the iOS 27 `LanguageModelError`.

## Conventions

- The Xcode project uses file-system-synchronized groups: new files under `stepbuddy/` are picked up automatically, no `project.pbxproj` edits needed.
- Every view ends with a `#Preview`; chart previews use `MockData` rather than HealthKit.
- Tests use fixed dates from `TestDates` and build expected numbers with the same `FormatStyle` as the code, so they pass in any locale.
- Keep HealthKit access inside `HealthKitManager`; views should not touch `HKHealthStore` directly.
- Use `async`/`await` for HealthKit calls; no `try!` (SwiftLint `force_try`). The fetch and add methods throw: `DashboardView` shows a Retry alert when loading fails and `HealthDataListView` an alert when saving fails.
