import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:beam_vm/beam_vm.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('BeamVm singleton works', (WidgetTester tester) async {
    final vm1 = BeamVm();
    final vm2 = BeamVm();
    expect(identical(vm1, vm2), isTrue);
  });

  testWidgets('Initial status is uninitialized', (WidgetTester tester) async {
    final beamVm = BeamVm();
    expect(beamVm.status, equals(BeamVmStatus.uninitialized));
    expect(beamVm.isInitialized, isFalse);
  });

  testWidgets('OTP version can be retrieved', (WidgetTester tester) async {
    final beamVm = BeamVm();
    final version = await beamVm.otpVersion;
    expect(version, isNotEmpty);
  });
}
