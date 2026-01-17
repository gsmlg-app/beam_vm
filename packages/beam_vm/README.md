# beam_vm

[![pub package](https://img.shields.io/pub/v/beam_vm.svg)](https://pub.dev/packages/beam_vm)

Flutter plugin to embed and run the Erlang/Elixir BEAM VM on Android and iOS.

## Features

- Run Erlang/Elixir code natively on mobile devices
- Call Erlang/Elixir functions from Dart
- Send messages to Erlang/Elixir processes
- Receive messages from Erlang/Elixir in Dart
- Pre-bundled BEAM runtime binaries (no manual download required)

## Supported Platforms

| Platform | Architectures |
|----------|--------------|
| Android  | armeabi-v7a, arm64-v8a, x86_64 |
| iOS      | arm64 (devices), arm64/x86_64 (simulators) |

## Installation

Add `beam_vm` to your `pubspec.yaml`:

```yaml
dependencies:
  beam_vm: ^1.0.0
```

## Usage

```dart
import 'package:beam_vm/beam_vm.dart';

// Get the singleton instance
final beamVm = BeamVm();

// Listen to status changes
beamVm.statusStream.listen((status) {
  print('BEAM VM status: $status');
});

// Initialize with path to Elixir release
await beamVm.initialize('/path/to/erlang');

// Check if running
if (beamVm.isInitialized) {
  print('BEAM VM is running');
}

// Call an Elixir function
final result = await beamVm.call('Elixir.MyApp.Math', 'add', [1, 2]);
print('Result: $result'); // 3

// Send a message to a named process
await beamVm.send('MyApp.Server', {'type': 'ping'});

// Register a callback for messages
final subscription = beamVm.onMessage('events', (message) {
  print('Received: $message');
});

// Get OTP version
final version = await beamVm.otpVersion;
print('OTP version: $version');

// Cleanup
subscription.cancel();
await beamVm.shutdown();
```

## Bundling Your Elixir Release

To run Elixir code, you need to bundle a release in your app's assets:

1. Create an Elixir release: `MIX_ENV=prod mix release`
2. Copy the release to your app's assets directory
3. Extract it at runtime and pass the path to `initialize()`

See the [example app](https://github.com/gsmlg-app/beam_vm/tree/main/packages/beam_vm_example) for a complete demonstration.

## Requirements

- Flutter 3.10.0 or higher
- Android: API level 26+ (Android 8.0 Oreo)
- iOS: 12.0+

## License

MIT License - see [LICENSE](LICENSE) for details.
