# beam_vm

[![CI](https://github.com/gsmlg-app/beam_vm/actions/workflows/packages-ci.yml/badge.svg)](https://github.com/gsmlg-app/beam_vm/actions/workflows/packages-ci.yml)

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

// Listen to status changes
beamVm.statusStream.listen((status) {
  print('BEAM VM status: $status');
});

// Initialize with path to your Erlang/Elixir release
await beamVm.initialize('/path/to/erlang/release');

// Check if running
if (beamVm.isInitialized) {
  print('BEAM VM is running');
}

// Call an Erlang/Elixir function
final result = await beamVm.call('Elixir.MyApp.Math', 'add', [1, 2]);
print('Result: $result'); // 3

// Send a message to a named process
await beamVm.send('MyApp.Server', {'type': 'ping'});

// Register a callback for messages from Elixir
final subscription = beamVm.onMessage('events', (message) {
  print('Received: $message');
});

// Cleanup
subscription.cancel();
await beamVm.shutdown();
```

## Requirements

| Platform | Minimum Version |
|----------|-----------------|
| Android  | API 26 (Android 8.0 Oreo) |
| iOS      | 12.0 |
| Flutter  | 3.10.0 |

## Bundled Binaries

The platform packages bundle pre-compiled `liberlang.a` static libraries from [mobile-BEAM-OTP](https://github.com/Gao-OS/mobile-BEAM-OTP) releases.

| Platform | Architectures |
|----------|---------------|
| Android  | armeabi-v7a, arm64-v8a, x86_64 |
| iOS      | arm64 (devices), arm64/x86_64 (simulators) |

## Development

This project uses [Melos](https://melos.invertase.dev/) for monorepo management.

```bash
# Install melos
dart pub global activate melos

# Bootstrap workspace
melos bs

# Run analysis
melos run analyze

# Run tests
melos run test

# Check formatting
melos run format

# Build example app
melos run build:example:android
melos run build:example:ios

# Publish dry run
melos run publish:dry-run
```

## License

MIT License - see [LICENSE](LICENSE) for details.
