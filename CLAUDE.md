# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter plugin that embeds the Erlang/Elixir BEAM Virtual Machine on Android and iOS. Uses a federated plugin architecture with pre-compiled `liberlang.a` static libraries sourced from [Gao-OS/mobile-BEAM-OTP](https://github.com/Gao-OS/mobile-BEAM-OTP).

**Requirements**: Git LFS must be installed to clone binary assets (`*.a` files).

## Development Commands

```bash
# Bootstrap workspace (required before other commands)
melos bs

# Analysis and testing
melos run analyze       # Lint all packages
melos run test          # Run unit tests
melos run format        # Format Dart code

# Build example app
melos run build:example:android
melos run build:example:ios

# Publishing
melos run publish:dry-run   # Verify publishability
```

Run a single package's tests:
```bash
cd packages/beam_vm && flutter test
cd packages/beam_vm && flutter test test/beam_vm_test.dart  # single file
```

## Architecture

### Federated Plugin Structure

```
packages/
├── beam_vm/                    # App-facing package (what users import)
├── beam_vm_platform_interface/ # Abstract interface + MethodChannel impl
├── beam_vm_android/            # Android implementation (Kotlin + JNI)
├── beam_vm_ios/                # iOS implementation (Swift + C bridge)
└── beam_vm_example/            # Example Flutter app
```

### Communication Flow

```
Dart (BeamVm) → MethodChannel "io.beamvm/beam_vm" → Platform Plugin → Native liberlang.a
```

- **Dart API**: `BeamVm` singleton in `packages/beam_vm/lib/beam_vm.dart`
- **Platform Interface**: `BeamVmPlatform` abstract class defines the contract
- **Android**: `BeamVmAndroidPlugin.kt` uses JNI via `BeamVmNative` object to call into `liberlang.a`
- **iOS**: `BeamVmIosPlugin.swift` uses `BeamVmBridge` to call C functions (`beam_init`, `beam_cleanup`, etc.)

### Binary Assets

Pre-compiled BEAM runtime libraries are stored via Git LFS:
- Android: `packages/beam_vm_android/android/src/main/jniLibs/{abi}/liberlang.a`
- iOS: `packages/beam_vm_ios/ios/Assets/liberlang.xcframework/`

Updated via `update-package-binaries.yml` workflow which pulls from Gao-OS/mobile-BEAM-OTP releases.

## Key Files

| File | Purpose |
|------|---------|
| `pubspec.yaml` (root) | Melos workspace config with all scripts |
| `packages/beam_vm/lib/beam_vm.dart` | Public API (`BeamVm` class) |
| `packages/beam_vm_platform_interface/lib/src/beam_vm_platform.dart` | Platform interface contract |
| `packages/beam_vm_android/.../BeamVmAndroidPlugin.kt` | Android MethodChannel handler + JNI |
| `packages/beam_vm_ios/.../BeamVmIosPlugin.swift` | iOS MethodChannel handler + C bridge |

## CI/CD Workflows

- `packages-ci.yml`: Main CI (analyze, format, test, pana, publish dry-run)
- `flutter-plugin-integration.yml`: Integration tests with actual BEAM binaries (manual trigger)
- `update-package-binaries.yml`: Pulls binaries from Gao-OS/mobile-BEAM-OTP and creates PR
- `publish-packages.yml`: Publishes to pub.dev (manual trigger)

## API Summary

The `BeamVm` class (singleton) provides:
- `initialize(erlangPath)` - Start BEAM VM with Erlang/Elixir release
- `call(module, function, args)` - Call Erlang/Elixir function, get result
- `send(processName, message)` - Fire-and-forget message to named process
- `onMessage(tag, callback)` - Subscribe to messages from Elixir
- `shutdown()` - Stop VM (note: cannot fully release until app restart)
- `statusStream` / `status` - Monitor VM state
- `otpVersion` - Get OTP version string
