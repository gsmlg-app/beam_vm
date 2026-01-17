import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'beam_vm_exception.dart';
import 'beam_vm_platform.dart';
import 'beam_vm_status.dart';

/// Method channel implementation of [BeamVmPlatform].
///
/// This is the default implementation that uses platform channels to
/// communicate with native code.
class MethodChannelBeamVm extends BeamVmPlatform {
  /// The method channel used to interact with the native platform.
  final methodChannel = const MethodChannel('io.beamvm/beam_vm');

  /// Event channel for receiving messages from Elixir.
  final eventChannel = const EventChannel('io.beamvm/beam_vm_events');

  final _statusController = StreamController<BeamVmStatus>.broadcast();
  BeamVmStatus _status = BeamVmStatus.uninitialized;

  final Map<String, List<void Function(dynamic)>> _messageCallbacks = {};

  /// Creates a new [MethodChannelBeamVm] instance.
  MethodChannelBeamVm() {
    // Set up method call handler for native -> Dart calls
    methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onMessage':
        final tag = call.arguments['tag'] as String;
        final message = call.arguments['message'];
        _dispatchMessage(tag, message);
        return null;
      case 'onStatusChange':
        final statusStr = call.arguments as String;
        _updateStatus(_parseStatus(statusStr));
        return null;
      default:
        throw PlatformException(
          code: 'UNIMPLEMENTED',
          message: 'Method ${call.method} not implemented',
        );
    }
  }

  void _dispatchMessage(String tag, dynamic message) {
    final callbacks = _messageCallbacks[tag];
    if (callbacks != null) {
      for (final callback in callbacks) {
        callback(message);
      }
    }
  }

  BeamVmStatus _parseStatus(String status) {
    switch (status) {
      case 'uninitialized':
        return BeamVmStatus.uninitialized;
      case 'initializing':
        return BeamVmStatus.initializing;
      case 'running':
        return BeamVmStatus.running;
      case 'error':
        return BeamVmStatus.error;
      case 'shuttingDown':
        return BeamVmStatus.shuttingDown;
      default:
        return BeamVmStatus.uninitialized;
    }
  }

  void _updateStatus(BeamVmStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(newStatus);
    }
  }

  @override
  Stream<BeamVmStatus> get statusStream => _statusController.stream;

  @override
  BeamVmStatus get status => _status;

  @override
  Future<bool> initialize(String erlangPath) async {
    _updateStatus(BeamVmStatus.initializing);

    try {
      final result = await methodChannel.invokeMethod<bool>('initialize', {
        'erlangPath': erlangPath,
      });

      if (result == true) {
        _updateStatus(BeamVmStatus.running);
        return true;
      } else {
        _updateStatus(BeamVmStatus.error);
        return false;
      }
    } on PlatformException catch (e) {
      _updateStatus(BeamVmStatus.error);
      throw BeamVmException(
        e.message ?? 'Initialization failed',
        code: e.code,
        details: e.details,
      );
    }
  }

  @override
  Future<dynamic> call(
    String module,
    String function,
    List<dynamic> args,
  ) async {
    if (_status != BeamVmStatus.running) {
      throw BeamVmException('BEAM VM is not running');
    }

    try {
      final result = await methodChannel.invokeMethod<String>('call', {
        'module': module,
        'function': function,
        'args': jsonEncode(args),
      });

      if (result != null) {
        return jsonDecode(result);
      }
      return null;
    } on PlatformException catch (e) {
      throw BeamVmException(
        e.message ?? 'Call failed',
        code: e.code,
        details: e.details,
      );
    }
  }

  @override
  Future<void> send(String processName, dynamic message) async {
    if (_status != BeamVmStatus.running) {
      throw BeamVmException('BEAM VM is not running');
    }

    try {
      await methodChannel.invokeMethod<void>('send', {
        'processName': processName,
        'message': jsonEncode(message),
      });
    } on PlatformException catch (e) {
      throw BeamVmException(
        e.message ?? 'Send failed',
        code: e.code,
        details: e.details,
      );
    }
  }

  @override
  StreamSubscription<dynamic> onMessage(
    String tag,
    void Function(dynamic message) callback,
  ) {
    _messageCallbacks.putIfAbsent(tag, () => []).add(callback);

    // Register with native side
    methodChannel.invokeMethod<void>('registerMessageHandler', {'tag': tag});

    // Return a subscription that removes the callback when cancelled
    final controller = StreamController<dynamic>();
    controller.onCancel = () {
      _messageCallbacks[tag]?.remove(callback);
      if (_messageCallbacks[tag]?.isEmpty ?? false) {
        _messageCallbacks.remove(tag);
        methodChannel.invokeMethod<void>('unregisterMessageHandler', {
          'tag': tag,
        });
      }
    };

    return controller.stream.listen((_) {});
  }

  @override
  Future<void> shutdown() async {
    _updateStatus(BeamVmStatus.shuttingDown);

    try {
      await methodChannel.invokeMethod<void>('shutdown');
      _updateStatus(BeamVmStatus.uninitialized);
    } on PlatformException catch (e) {
      _updateStatus(BeamVmStatus.error);
      throw BeamVmException(
        e.message ?? 'Shutdown failed',
        code: e.code,
        details: e.details,
      );
    }
  }

  @override
  Future<String> get otpVersion async {
    try {
      final version = await methodChannel.invokeMethod<String>('getOtpVersion');
      return version ?? 'unknown';
    } on PlatformException {
      return 'unknown';
    }
  }
}
