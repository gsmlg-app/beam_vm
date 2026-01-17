import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:beam_vm_platform_interface/beam_vm_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBeamVmPlatform extends BeamVmPlatform
    with MockPlatformInterfaceMixin {
  bool initializeResult = true;
  BeamVmException? initializeError;
  dynamic callResult;
  String mockOtpVersion = '28';
  BeamVmStatus mockStatus = BeamVmStatus.uninitialized;

  final _statusController = StreamController<BeamVmStatus>.broadcast();

  @override
  Stream<BeamVmStatus> get statusStream => _statusController.stream;

  @override
  BeamVmStatus get status => mockStatus;

  @override
  Future<bool> initialize(String erlangPath) async {
    if (initializeError != null) throw initializeError!;
    return initializeResult;
  }

  @override
  Future<dynamic> call(
    String module,
    String function,
    List<dynamic> args,
  ) async {
    return callResult;
  }

  @override
  Future<void> send(String processName, dynamic message) async {}

  @override
  StreamSubscription<dynamic> onMessage(
    String tag,
    void Function(dynamic message) callback,
  ) {
    return const Stream.empty().listen((_) {});
  }

  @override
  Future<void> shutdown() async {
    mockStatus = BeamVmStatus.uninitialized;
  }

  @override
  Future<String> get otpVersion async => mockOtpVersion;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BeamVmPlatform', () {
    test('default instance is MethodChannelBeamVm', () {
      expect(BeamVmPlatform.instance, isA<MethodChannelBeamVm>());
    });

    test('can be set to a mock implementation', () {
      final mock = MockBeamVmPlatform();
      BeamVmPlatform.instance = mock;

      expect(BeamVmPlatform.instance, equals(mock));
    });

    test('mock implementation works', () async {
      final mock = MockBeamVmPlatform();
      mock.initializeResult = true;
      mock.mockOtpVersion = '28.3';

      BeamVmPlatform.instance = mock;

      expect(await BeamVmPlatform.instance.initialize('/path'), isTrue);
      expect(await BeamVmPlatform.instance.otpVersion, equals('28.3'));
    });
  });

  group('BeamVmStatus', () {
    test('has all expected values', () {
      expect(BeamVmStatus.values.length, equals(5));
      expect(BeamVmStatus.values, contains(BeamVmStatus.uninitialized));
      expect(BeamVmStatus.values, contains(BeamVmStatus.initializing));
      expect(BeamVmStatus.values, contains(BeamVmStatus.running));
      expect(BeamVmStatus.values, contains(BeamVmStatus.error));
      expect(BeamVmStatus.values, contains(BeamVmStatus.shuttingDown));
    });
  });

  group('BeamVmException', () {
    test('toString includes message', () {
      final exception = BeamVmException('Test error');
      expect(exception.toString(), equals('BeamVmException: Test error'));
    });

    test('toString includes code when present', () {
      final exception = BeamVmException('Test error', code: 'ERR_001');
      expect(
        exception.toString(),
        equals('BeamVmException: Test error (ERR_001)'),
      );
    });

    test('stores details', () {
      final exception = BeamVmException(
        'Test error',
        code: 'ERR_001',
        details: {'key': 'value'},
      );
      expect(exception.details, equals({'key': 'value'}));
    });
  });
}
