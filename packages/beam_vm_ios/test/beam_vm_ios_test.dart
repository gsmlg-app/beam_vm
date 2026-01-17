import 'package:flutter_test/flutter_test.dart';
import 'package:beam_vm_ios/beam_vm_ios.dart';
import 'package:beam_vm_platform_interface/beam_vm_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registerWith registers iOS implementation', () {
    BeamVmIos.registerWith();
    expect(BeamVmPlatform.instance, isA<BeamVmIos>());
  });

  test('BeamVmIos extends MethodChannelBeamVm', () {
    expect(BeamVmIos(), isA<MethodChannelBeamVm>());
  });
}
