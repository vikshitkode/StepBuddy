// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// Vendored into StepBuddy from github.com/mlalma/kokoro-ios @ 4d6d1d8 (1.0.11), patched (see Packages/README.md):
//  - resources moved from ../../Resources to Sources/KokoroSwift/KokoroData: a top-level "Resources" folder makes the built
//    bundle fail iOS codesign ("bundle format unrecognized"), upstream kokoro-ios#31 / MisakiSwift#20
//  - mlx-swift 0.30.2 -> 0.32.3: 0.30.2 doesn't link against the iOS 26+ SDKs (kokoro-ios#30) and
//    produces static on A18 iPhones (kokoro-ios#29). Builds unchanged on 0.32.3, the latest release.
//  - library type left to SwiftPM instead of .dynamic: Xcode didn't embed the dynamic KokoroSwift.framework,
//    so the app would fail to launch on a device (kokoro-ios#26, MisakiSwift#19)
//  - depends on the vendored MisakiSwift above, and declares MLXFast, which it imports (kokoro-ios#36)
//  - adds KokoroSpeaker (Sources/KokoroSwift/StepBuddy), so the app needs no MLX types or extra package products

let package = Package(
  name: "KokoroSwift",
  platforms: [
    .iOS(.v18), .macOS(.v15)
  ],
  products: [
    .library(
      name: "KokoroSwift",
      targets: ["KokoroSwift"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/ml-explore/mlx-swift", exact: "0.32.3"),
    // .package(url: "https://github.com/mlalma/eSpeakNGSwift", from: "1.0.1"),
    .package(path: "../MisakiSwift"),
    .package(url: "https://github.com/mlalma/MLXUtilsLibrary.git", exact: "0.0.6")
  ],
  targets: [
    .target(
      name: "KokoroSwift",
      dependencies: [
        .product(name: "MLX", package: "mlx-swift"),
        .product(name: "MLXNN", package: "mlx-swift"),
        .product(name: "MLXRandom", package: "mlx-swift"),
        .product(name: "MLXFFT", package: "mlx-swift"),
        .product(name: "MLXFast", package: "mlx-swift"),
        // .product(name: "eSpeakNGLib", package: "eSpeakNGSwift"),
        .product(name: "MisakiSwift", package: "MisakiSwift"),
        .product(name: "MLXUtilsLibrary", package: "MLXUtilsLibrary")
      ],
      resources: [
       .copy("KokoroData")
      ]
    ),
  ]
)
