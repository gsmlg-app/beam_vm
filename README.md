# beam_vm

Flutter plugin to embed and run the Erlang/Elixir BEAM Virtual Machine on Android and iOS.

## Packages

| Package | Description | pub.dev |
|---------|-------------|---------|
| [beam_vm](packages/beam_vm) | Main plugin package | [![pub](https://img.shields.io/pub/v/beam_vm.svg)](https://pub.dev/packages/beam_vm) |
| [beam_vm_android](packages/beam_vm_android) | Android implementation | [![pub](https://img.shields.io/pub/v/beam_vm_android.svg)](https://pub.dev/packages/beam_vm_android) |
| [beam_vm_ios](packages/beam_vm_ios) | iOS implementation | [![pub](https://img.shields.io/pub/v/beam_vm_ios.svg)](https://pub.dev/packages/beam_vm_ios) |
| [beam_vm_platform_interface](packages/beam_vm_platform_interface) | Platform interface | [![pub](https://img.shields.io/pub/v/beam_vm_platform_interface.svg)](https://pub.dev/packages/beam_vm_platform_interface) |

## Installation

Add `beam_vm` to your `pubspec.yaml`:

```yaml
dependencies:
  beam_vm: ^1.0.0
```

## Usage

```dart
import 'package:beam_vm/beam_vm.dart';

final beamVm = BeamVm();

// Initialize with path to your Erlang release
await beamVm.initialize('/path/to/erlang/release');

// Start the BEAM VM
await beamVm.start();
```

## Requirements

- **Android**: API level 26+ (Android 8.0 Oreo)
- **iOS**: 12.0+

## Bundled Binaries

The platform packages bundle pre-compiled `liberlang.a` static libraries from [beam_vm releases](https://github.com/gsmlg-app/beam_vm/releases).

**Android architectures:**
- `armeabi-v7a` (32-bit ARM)
- `arm64-v8a` (64-bit ARM)
- `x86_64` (Intel/AMD 64-bit emulators)

**iOS architectures:**
- `arm64` (devices)
- `arm64-simulator` (Apple Silicon simulators)
- `x86_64-simulator` (Intel simulators)

## Development

This project uses [Melos](https://melos.invertase.dev/) for monorepo management.

```bash
# Install melos
dart pub global activate melos

# Bootstrap workspace
melos bootstrap

# Run analysis
melos analyze

# Run tests
melos test

# Build example app
melos build:example:android
melos build:example:ios
```

## License

MIT License - see [LICENSE](LICENSE) for details.
