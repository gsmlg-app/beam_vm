# beam_vm_ios

The iOS implementation of [`beam_vm`](https://pub.dev/packages/beam_vm).

## Usage

This package is [endorsed](https://flutter.dev/to/federated-plugins), which means you can simply use `beam_vm` normally. This package will be automatically included in your app when you do, so you do not need to add it to your `pubspec.yaml`.

However, if you `import` this package directly, you should add it to your `pubspec.yaml` as usual.

## Bundled Binaries

This package bundles `liberlang.xcframework` containing pre-compiled static libraries for:

- `ios-arm64` (64-bit ARM devices)
- `ios-arm64_x86_64-simulator` (M1/M2 and Intel simulators)

The xcframework is approximately 32 MB and is downloaded from [mobile-BEAM-OTP releases](https://github.com/Gao-OS/mobile-BEAM-OTP/releases).

## Requirements

- iOS 12.0+
- Xcode for native code compilation
