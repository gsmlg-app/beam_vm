# beam_vm_platform_interface

A common platform interface for the [`beam_vm`](https://pub.dev/packages/beam_vm) plugin.

This interface allows platform-specific implementations of the `beam_vm` plugin, as well as the plugin itself, to ensure they are supporting the same interface.

## Usage

To implement a new platform-specific implementation of `beam_vm`, extend [`BeamVmPlatform`](lib/src/beam_vm_platform.dart) with an implementation that performs the platform-specific behavior, and when the plugin is loaded, set the default `BeamVmPlatform.instance` to your implementation.

```dart
class BeamVmMyPlatform extends BeamVmPlatform {
  /// Registers this class as the default instance of [BeamVmPlatform].
  static void registerWith() {
    BeamVmPlatform.instance = BeamVmMyPlatform();
  }

  @override
  Future<bool> initialize(String erlangPath) {
    // platform-specific implementation
  }

  // ... implement other methods
}
```

## Note on breaking changes

Strongly prefer non-breaking changes (such as adding a method to the interface) over breaking changes for this package.

See https://flutter.dev/to/platform-interface-breaking-changes for a discussion on why a less-clean interface is preferable to a breaking change.
