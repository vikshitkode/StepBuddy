# Vendored packages

Local copies of [kokoro-ios](https://github.com/mlalma/kokoro-ios) (`KokoroSwift`) and its G2P dependency
[MisakiSwift](https://github.com/mlalma/MisakiSwift), both MIT licensed. The published releases (kokoro-ios 1.0.11,
MisakiSwift 1.0.6) can't be built into an iOS app, and the upstream fixes are open but unmerged.

| Package | Upstream commit | Patches |
|---|---|---|
| KokoroSwift | `4d6d1d8` (1.0.11) | Resources moved, mlx-swift 0.32.3, not `.dynamic`, local MisakiSwift, declares `MLXFast`, adds `KokoroSpeaker` |
| MisakiSwift | `6835a1c` (1.0.6) | Resources moved, mlx-swift 0.32.3, not `.dynamic` |

Why:

- **Resources moved** from `../../Resources` to `Sources/<Target>/<Name>Data`, and the `Bundle.module` lookups'
  `subdirectory:` changed to match. A top-level `Resources` folder in a flat iOS bundle makes `codesign` reject it with
  "bundle format unrecognized, invalid, or unsuitable" ([kokoro-ios#31](https://github.com/mlalma/kokoro-ios/issues/31),
  [MisakiSwift#20](https://github.com/mlalma/MisakiSwift/pull/20)).
- **mlx-swift 0.30.2 → 0.32.3** (the latest release; the packages build against it unchanged). 0.30.2 references `MTLIOErrorDomain`/`MTLTensorDomain` and doesn't link against the
  iOS 26+ SDKs ([kokoro-ios#30](https://github.com/mlalma/kokoro-ios/issues/30)); it also produces static instead of
  speech on A18 iPhones ([kokoro-ios#29](https://github.com/mlalma/kokoro-ios/pull/29)).
- **Not `.dynamic`.** Both products forced a dynamic library, and Xcode linked `KokoroSwift.framework` without embedding
  it: the app only ran where the Debug rpath into DerivedData exists (Simulator), and would fail to launch on a device
  ([kokoro-ios#26](https://github.com/mlalma/kokoro-ios/issues/26), [MisakiSwift#19](https://github.com/mlalma/MisakiSwift/pull/19)).
- **`MLXFast`** is imported by `LayerNormInference.swift` but wasn't declared, which fails iOS device builds
  ([kokoro-ios#36](https://github.com/mlalma/kokoro-ios/pull/36)).
- **`KokoroSpeaker`** (`Sources/KokoroSwift/StepBuddy/`, new) loads the model and voices and returns plain `[Float]`
  samples. The app target depends only on the `KokoroSwift` product, so calling MLX or MLXUtilsLibrary from app code
  fails to link (e.g. `NpyzReader`); this keeps MLX types inside the package instead of adding more products to the app.

Tests weren't vendored. If upstream merges these fixes, switch StepBuddy back to the remote package and delete this folder.
