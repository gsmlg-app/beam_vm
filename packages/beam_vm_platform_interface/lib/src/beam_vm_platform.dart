import 'dart:async';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'beam_vm_status.dart';
import 'method_channel_beam_vm.dart';

/// Platform interface for BEAM VM operations.
///
/// Platform-specific implementations should extend this class and register
/// themselves as the default instance using [instance].
abstract class BeamVmPlatform extends PlatformInterface {
  /// Constructs a BeamVmPlatform.
  BeamVmPlatform() : super(token: _token);

  static final Object _token = Object();

  static BeamVmPlatform _instance = MethodChannelBeamVm();

  /// The default instance of [BeamVmPlatform] to use.
  ///
  /// Defaults to [MethodChannelBeamVm].
  static BeamVmPlatform get instance => _instance;

  /// Platform-specific implementations should set this to their own
  /// platform-specific class that extends [BeamVmPlatform].
  static set instance(BeamVmPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Stream of VM status changes.
  Stream<BeamVmStatus> get statusStream;

  /// Current VM status.
  BeamVmStatus get status;

  /// Initialize the BEAM VM.
  ///
  /// [erlangPath] should point to a directory containing:
  /// - `lib/` - Compiled BEAM files
  /// - `releases/start.boot` - Boot script
  ///
  /// Returns `true` if initialization succeeded.
  Future<bool> initialize(String erlangPath);

  /// Call an Erlang/Elixir function.
  ///
  /// [module] - The module name (e.g., 'Elixir.MyApp.Worker')
  /// [function] - The function name
  /// [args] - List of arguments (must be JSON-serializable)
  ///
  /// Returns the result as a dynamic value (decoded from Erlang term).
  Future<dynamic> call(String module, String function, List<dynamic> args);

  /// Send a message to a named process.
  ///
  /// [processName] - Registered process name (e.g., 'MyApp.Server')
  /// [message] - Message to send (must be JSON-serializable)
  ///
  /// This is fire-and-forget; use [call] for request-response patterns.
  Future<void> send(String processName, dynamic message);

  /// Register a message callback.
  ///
  /// [tag] - Message tag to filter on
  /// [callback] - Function called when a message with this tag arrives
  ///
  /// Returns a subscription that can be cancelled.
  StreamSubscription<dynamic> onMessage(
    String tag,
    void Function(dynamic message) callback,
  );

  /// Shutdown the VM.
  ///
  /// Note: The BEAM VM cannot be cleanly stopped without terminating
  /// the process. This marks the VM as uninitialized but may not
  /// fully release resources until app restart.
  Future<void> shutdown();

  /// Get OTP version.
  Future<String> get otpVersion;
}
