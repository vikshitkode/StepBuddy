<div align="center">

<img src="App%20Icons/StepBuddy%20App%20Icon-iOS-Default-1024x1024@1x.png" alt="StepBuddy app icon" width="120" />

# StepBuddy

**Your steps and weight from Apple Health, beautifully charted.**

[![StepBuddy iOS CI](https://github.com/vikshitkode/StepBuddy/actions/workflows/stepbuddy-ios-ci.yml/badge.svg)](https://github.com/vikshitkode/StepBuddy/actions/workflows/stepbuddy-ios-ci.yml)
![Platform](https://img.shields.io/badge/platform-iOS%2018%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-informational)

</div>

StepBuddy is a SwiftUI app that reads your daily step count and body weight from Apple Health (HealthKit) and visualizes the last 28 days with Swift Charts. You can also log new step and weight entries back to Health.

## Features

- **Steps and weight dashboard**: switch between metrics with a segmented picker. Steps use a pink theme and weight uses indigo.
- **Rich charts** built with Swift Charts:
  - Daily steps bar chart
  - Average steps by weekday (pie chart)
  - Weight line chart
  - Day-over-day weight change bar chart
- **Data list**: drill into every recorded value, and add new entries to Apple Health.
- **BMI calculator**: a quick sheet that takes pounds and feet/inches.
- **Health Intelligence** (iOS 26+): on-device insights and chat powered by Apple's Foundation Models framework. Your health data never leaves the device. On older iOS versions the screen shows a "Requires iOS 26" message.
- **Permission priming**: a short explainer shown once before the HealthKit authorization prompt.

## Requirements

- Xcode 26 or later
- iOS 18.4+ deployment target (Health Intelligence needs iOS 26+ with Apple Intelligence available)
- A device or simulator with Apple Health. The simulator has no real data, so see [Simulator data](#simulator-data).

## Getting started

```sh
git clone https://github.com/vikshitkode/StepBuddy.git
cd StepBuddy
open stepbuddy.xcodeproj
```

Select the `stepbuddy` scheme, pick a simulator or device, and run. Swift Package dependencies resolve automatically.

To build from the command line:

```sh
xcodebuild build \
  -project stepbuddy.xcodeproj \
  -scheme stepbuddy \
  -destination 'generic/platform=iOS Simulator'
```

### Simulator data

HealthKit is empty in the simulator. To seed sample data, temporarily uncomment `addSimulatorData()` in `HealthKitManager` and its call in `DashboardView.task`. Don't commit it uncommented.

## Project structure

```
stepbuddy/
  StepBuddyApp.swift                 App entry point; injects HealthKitManager, configures TipKit
  Managers/
    HealthKitManager.swift           HealthKit authorization, queries and writes
    HealthInsightsManager.swift      Foundation Models sessions (iOS 26+)
  Model/                             HealthMetric, HealthInsight
  Charts/                            Chart views, ChartMath, chart data types
  Screens/                           Dashboard, data list, BMI sheet, permission priming, Health Intelligence
  Utilities/                         MockData for previews, HealthDataSummary, extensions
```

## Tech stack

- SwiftUI and the Observation framework
- HealthKit (`HKStatisticsCollectionQueryDescriptor`)
- Swift Charts
- Foundation Models (iOS 26+)
- TipKit
- [swift-algorithms](https://github.com/apple/swift-algorithms), the only dependency

## Privacy

StepBuddy reads and writes only the step count and body weight types in Apple Health, and only with your permission. All processing, including AI insights, happens on your device.

## Contributing

CI builds the app on every push and pull request to `main`. See [`CLAUDE.md`](CLAUDE.md) for architecture notes and conventions.
