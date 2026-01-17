import 'package:flutter_test/flutter_test.dart';
import 'package:beam_vm_android/beam_vm_android.dart';
import 'package:beam_vm_platform_interface/beam_vm_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registerWith registers Android implementation', () {
    BeamVmAndroid.registerWith();
    expect(BeamVmPlatform.instance, isA<BeamVmAndroid>());
  });

  test('BeamVmAndroid extends MethodChannelBeamVm', () {
    expect(BeamVmAndroid(), isA<MethodChannelBeamVm>());
  });
}
