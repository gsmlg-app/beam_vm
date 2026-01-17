/// Flutter plugin to embed and run the Erlang/Elixir BEAM VM.
///
/// This plugin allows Flutter apps to run Erlang and Elixir code natively
/// on Android and iOS devices.
///
/// ## Getting Started
///
/// ```dart
/// import 'package:beam_vm/beam_vm.dart';
///
/// final beamVm = BeamVm();
///
/// // Initialize with path to Elixir release
/// await beamVm.initialize('/path/to/erlang');
///
/// // Check status
/// if (beamVm.isInitialized) {
///   print('BEAM VM is running');
/// }
///
/// // Call Elixir function
/// final result = await beamVm.call('Elixir.MyApp.Math', 'add', [1, 2]);
/// print(result); // 3
/// ```
library;

import 'dart:async';
import 'package:beam_vm_platform_interface/beam_vm_platform_interface.dart';

export 'package:beam_vm_platform_interface/beam_vm_platform_interface.dart'
    show BeamVmStatus, BeamVmException;

/// Main class for interacting with the BEAM VM.
///
/// This is a singleton - use `BeamVm()` to get the shared instance.
///
/// Example usage:
/// ```dart
/// final beamVm = BeamVm();
///
/// // Initialize with path to Elixir release
/// await beamVm.initialize('/path/to/erlang');
///
/// // Check status
/// if (beamVm.isInitialized) {
///   print('BEAM VM is running');
/// }
///
/// // Send message to Elixir
/// final response = await beamVm.call('MyModule', 'my_function', ['arg1', 'arg2']);
/// ```
class BeamVm {
  static final BeamVm _instance = BeamVm._internal();

  /// Returns the singleton instance of [BeamVm].
  factory BeamVm() => _instance;

  BeamVm._internal();

  /// Stream of status changes.
  Stream<BeamVmStatus> get statusStream => BeamVmPlatform.instance.statusStream;

  /// Current VM status.
  BeamVmStatus get status => BeamVmPlatform.instance.status;

  /// Whether the BEAM VM is initialized and running.
  bool get isInitialized => status == BeamVmStatus.running;

  /// Initialize the BEAM VM with the given Erlang/Elixir release path.
  ///
  /// [erlangPath] should point to a directory containing:
  /// - `lib/` - Compiled BEAM files
  /// - `releases/start.boot` - Boot script
  ///
  /// Returns `true` if initialization succeeded.
  ///
  /// Throws [BeamVmException] if initialization fails.
  Future<bool> initialize(String erlangPath) async {
    return BeamVmPlatform.instance.initialize(erlangPath);
  }

  /// Execute an Erlang/Elixir function and return the result.
  ///
  /// [module] - The module name (e.g., 'Elixir.MyApp.Worker')
  /// [function] - The function name
  /// [args] - List of arguments (must be JSON-serializable)
  ///
  /// Returns the result as a dynamic value (decoded from Erlang term).
  ///
  /// Example:
  /// ```dart
  /// final result = await beamVm.call('Elixir.MyApp.Math', 'add', [1, 2]);
  /// print(result); // 3
  /// ```
  Future<dynamic> call(String module, String function, List<dynamic> args) {
    return BeamVmPlatform.instance.call(module, function, args);
  }

  /// Send a message to a named Elixir process.
  ///
  /// [processName] - Registered process name (e.g., 'MyApp.Server')
  /// [message] - Message to send (must be JSON-serializable)
  ///
  /// This is fire-and-forget; use [call] for request-response patterns.
  Future<void> send(String processName, dynamic message) {
    return BeamVmPlatform.instance.send(processName, message);
  }

  /// Register a callback to receive messages from Elixir.
  ///
  /// [tag] - Message tag to filter on
  /// [callback] - Function called when a message with this tag arrives
  ///
  /// Returns a subscription that can be cancelled.
  StreamSubscription<dynamic> onMessage(
    String tag,
    void Function(dynamic message) callback,
  ) {
    return BeamVmPlatform.instance.onMessage(tag, callback);
  }

  /// Shutdown the BEAM VM.
  ///
  /// Note: The BEAM VM cannot be cleanly stopped without terminating
  /// the process. This marks the VM as uninitialized but may not
  /// fully release resources until app restart.
  Future<void> shutdown() {
    return BeamVmPlatform.instance.shutdown();
  }

  /// Get the OTP version of the embedded runtime.
  Future<String> get otpVersion => BeamVmPlatform.instance.otpVersion;
}
