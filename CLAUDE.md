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

CI (`.github/workflows/`) runs the same build on `macos-latest` for pushes and PRs to `main`, picking the first available iPhone simulator. There is no test step.

HealthKit has no real data in the simulator. To seed it, temporarily uncomment `addSimulatorData()` in `HealthKitManager` and its call in `DashboardView.task` — never commit it uncommented.

## Architecture

```
stepbuddy/
  StepBuddyApp.swift        App entry; creates HealthKitManager, injects via .environment; configures TipKit
  Managers/HealthKitManager.swift  @Observable; all HealthKit auth, queries and writes
  Model/HealthMetric.swift  { date, value } — one data point per day
  Charts/                   Chart views + ChartMath (weekday averages, weight diffs) + ChartDataTypes
  Screens/                  DashboardView (root), HealthDataListView, BMI sheet, permission priming, Apple Intelligence placeholder
  Utilities/                MockData (for #Previews), Date/Color extensions
```

- **State:** one `HealthKitManager` instance is shared through SwiftUI's `@Environment(HealthKitManager.self)`. It exposes `stepData`, `weightData`, `weightDiffData` arrays that views read directly.
- **Data fetching:** `HKStatisticsCollectionQueryDescriptor` with daily intervals over the last 28 days (29 for weight diffs, so the first day has a predecessor). Steps use `.cumulativeSum`, weight uses `.mostRecent`. Fetches run in `DashboardView`'s `.task`.
- **Navigation:** `HealthMetricContext` (`.steps` / `.weight`) drives the segmented picker, theme color (pink for steps, indigo for weight) and `navigationDestination` to `HealthDataListView`.
- **Permissions:** `HealthKitPermissionPrimingView` is shown once (`@AppStorage("hasSeenPermissionPriming")`) before requesting HealthKit authorization. Usage strings live in build settings (`INFOPLIST_KEY_NSHealth*UsageDescription`), not an Info.plist file.
- **Units:** weight is in pounds (`.pound()`) throughout; BMI calculator uses lb / ft-in.

## Conventions

- The Xcode project uses file-system-synchronized groups: new files under `stepbuddy/` are picked up automatically, no `project.pbxproj` edits needed.
- Every view ends with a `#Preview`; chart previews use `MockData` rather than HealthKit.
- Keep HealthKit access inside `HealthKitManager`; views should not touch `HKHealthStore` directly.
- Use `async`/`await` for HealthKit calls; avoid `try!` in new code (existing `addStepData`/`addWeightData` still use it).

## Known issues

- `WeightLineChart` shows a hardcoded "Avg: 180 lbs".
- `addStepData` / `addWeightData` crash via `try!` if the save fails (e.g. write permission denied).
- `fetchWeights` and `fetchWeightsForDifferentials` are near-duplicates and silently ignore errors.
- `AppleIntelligenceView` is a "Coming soon" placeholder.
