import 'package:beam_vm_platform_interface/beam_vm_platform_interface.dart';

/// The Android implementation of [BeamVmPlatform].
///
/// This class registers itself as the default instance of [BeamVmPlatform]
/// and uses method channels to communicate with native Android code.
class BeamVmAndroid extends MethodChannelBeamVm {
  /// Registers this class as the default instance of [BeamVmPlatform].
  static void registerWith() {
    BeamVmPlatform.instance = BeamVmAndroid();
  }
}
