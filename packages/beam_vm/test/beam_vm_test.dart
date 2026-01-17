import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:beam_vm/beam_vm.dart';
import 'package:beam_vm_platform_interface/beam_vm_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Record of a call() invocation.
class CallRecord {
  final String module;
  final String function;
  final List<dynamic> args;

  CallRecord(this.module, this.function, this.args);
}

/// Record of a send() invocation.
class SendRecord {
  final String processName;
  final dynamic message;

  SendRecord(this.processName, this.message);
}

/// Record of an onMessage() registration.
class OnMessageRecord {
  final String tag;
  final void Function(dynamic) callback;

  OnMessageRecord(this.tag, this.callback);
}

/// Mock implementation of [BeamVmPlatform] for testing.
class MockBeamVmPlatform extends BeamVmPlatform
    with MockPlatformInterfaceMixin {
  // Configuration
  bool initializeResult = true;
  BeamVmException? initializeError;
  dynamic callResult;
  BeamVmException? callError;
  BeamVmException? sendError;
  String mockOtpVersion = '28';
  BeamVmStatus mockStatus = BeamVmStatus.uninitialized;

  // Call tracking
  final List<String> initializeCalls = [];
  final List<CallRecord> callCalls = [];
  final List<SendRecord> sendCalls = [];
  final List<OnMessageRecord> onMessageCalls = [];
  bool shutdownCalled = false;

  // Status stream
  final _statusController = StreamController<BeamVmStatus>.broadcast();

  @override
  Stream<BeamVmStatus> get statusStream => _statusController.stream;

  @override
  BeamVmStatus get status => mockStatus;

  void emitStatus(BeamVmStatus status) {
    mockStatus = status;
    _statusController.add(status);
  }

  @override
  Future<bool> initialize(String erlangPath) async {
    initializeCalls.add(erlangPath);

    if (initializeError != null) {
      throw initializeError!;
    }

    if (initializeResult) {
      mockStatus = BeamVmStatus.running;
    } else {
      mockStatus = BeamVmStatus.error;
    }

    return initializeResult;
  }

  @override
  Future<dynamic> call(
    String module,
    String function,
    List<dynamic> args,
  ) async {
    callCalls.add(CallRecord(module, function, args));

    if (callError != null) {
      throw callError!;
    }

    return callResult;
  }

  @override
  Future<void> send(String processName, dynamic message) async {
    sendCalls.add(SendRecord(processName, message));

    if (sendError != null) {
      throw sendError!;
    }
  }

  @override
  StreamSubscription<dynamic> onMessage(
    String tag,
    void Function(dynamic message) callback,
  ) {
    onMessageCalls.add(OnMessageRecord(tag, callback));

    final controller = StreamController<dynamic>();
    return controller.stream.listen((_) {});
  }

  @override
  Future<void> shutdown() async {
    shutdownCalled = true;
    mockStatus = BeamVmStatus.uninitialized;
  }

  @override
  Future<String> get otpVersion async => mockOtpVersion;

  /// Simulate receiving a message from native side.
  void simulateMessage(String tag, dynamic message) {
    for (final record in onMessageCalls) {
      if (record.tag == tag) {
        record.callback(message);
      }
    }
  }

  /// Reset all tracking state.
  void reset() {
    initializeCalls.clear();
    callCalls.clear();
    sendCalls.clear();
    onMessageCalls.clear();
    shutdownCalled = false;
    mockStatus = BeamVmStatus.uninitialized;
    initializeResult = true;
    initializeError = null;
    callResult = null;
    callError = null;
    sendError = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBeamVmPlatform mockPlatform;
  late BeamVm beamVm;

  setUp(() {
    mockPlatform = MockBeamVmPlatform();
    BeamVmPlatform.instance = mockPlatform;
    beamVm = BeamVm();
  });

  group('BeamVm', () {
    test('is a singleton', () {
      final vm1 = BeamVm();
      final vm2 = BeamVm();
      expect(identical(vm1, vm2), isTrue);
    });

    test('initial status is uninitialized', () {
      expect(beamVm.status, equals(BeamVmStatus.uninitialized));
      expect(beamVm.isInitialized, isFalse);
    });

    group('initialize', () {
      test('returns true on success', () async {
        mockPlatform.initializeResult = true;

        final result = await beamVm.initialize('/path/to/erlang');

        expect(result, isTrue);
        expect(mockPlatform.initializeCalls, equals(['/path/to/erlang']));
      });

      test('returns false on failure', () async {
        mockPlatform.initializeResult = false;

        final result = await beamVm.initialize('/invalid/path');

        expect(result, isFalse);
      });

      test('throws BeamVmException on error', () async {
        mockPlatform.initializeError = BeamVmException(
          'Init failed',
          code: 'INIT_ERROR',
        );

        expect(
          () => beamVm.initialize('/path'),
          throwsA(isA<BeamVmException>()),
        );
      });
    });

    group('isInitialized', () {
      test('returns true when status is running', () {
        mockPlatform.mockStatus = BeamVmStatus.running;
        expect(beamVm.isInitialized, isTrue);
      });

      test('returns false when status is not running', () {
        mockPlatform.mockStatus = BeamVmStatus.uninitialized;
        expect(beamVm.isInitialized, isFalse);

        mockPlatform.mockStatus = BeamVmStatus.initializing;
        expect(beamVm.isInitialized, isFalse);

        mockPlatform.mockStatus = BeamVmStatus.error;
        expect(beamVm.isInitialized, isFalse);

        mockPlatform.mockStatus = BeamVmStatus.shuttingDown;
        expect(beamVm.isInitialized, isFalse);
      });
    });

    group('call', () {
      test('forwards call to platform', () async {
        mockPlatform.mockStatus = BeamVmStatus.running;
        mockPlatform.callResult = 42;

        final result = await beamVm.call('Elixir.Math', 'add', [1, 2]);

        expect(result, equals(42));
        expect(mockPlatform.callCalls.length, equals(1));
        expect(mockPlatform.callCalls.first.module, equals('Elixir.Math'));
        expect(mockPlatform.callCalls.first.function, equals('add'));
        expect(mockPlatform.callCalls.first.args, equals([1, 2]));
      });

      test('returns complex results', () async {
        mockPlatform.mockStatus = BeamVmStatus.running;
        mockPlatform.callResult = {'name': 'Alice', 'age': 30};

        final result = await beamVm.call('Elixir.User', 'get', [1]);

        expect(result, isA<Map>());
        expect(result['name'], equals('Alice'));
        expect(result['age'], equals(30));
      });
    });

    group('send', () {
      test('forwards send to platform', () async {
        mockPlatform.mockStatus = BeamVmStatus.running;

        await beamVm.send('MyProcess', {'type': 'ping'});

        expect(mockPlatform.sendCalls.length, equals(1));
        expect(mockPlatform.sendCalls.first.processName, equals('MyProcess'));
        expect(mockPlatform.sendCalls.first.message, equals({'type': 'ping'}));
      });
    });

    group('onMessage', () {
      test('registers callback and returns subscription', () {
        final messages = <dynamic>[];
        final subscription = beamVm.onMessage('events', messages.add);

        expect(subscription, isA<StreamSubscription>());
        expect(mockPlatform.onMessageCalls.length, equals(1));
        expect(mockPlatform.onMessageCalls.first.tag, equals('events'));

        subscription.cancel();
      });
    });

    group('shutdown', () {
      test('calls platform shutdown', () async {
        mockPlatform.mockStatus = BeamVmStatus.running;

        await beamVm.shutdown();

        expect(mockPlatform.shutdownCalled, isTrue);
      });
    });

    group('otpVersion', () {
      test('returns version from platform', () async {
        mockPlatform.mockOtpVersion = '28.3';

        final version = await beamVm.otpVersion;

        expect(version, equals('28.3'));
      });
    });

    group('statusStream', () {
      test('emits status changes', () async {
        final statuses = <BeamVmStatus>[];
        final subscription = beamVm.statusStream.listen(statuses.add);

        mockPlatform.emitStatus(BeamVmStatus.initializing);
        mockPlatform.emitStatus(BeamVmStatus.running);

        await Future.delayed(Duration.zero);

        expect(statuses, contains(BeamVmStatus.initializing));
        expect(statuses, contains(BeamVmStatus.running));

        await subscription.cancel();
      });
    });
  });
}
