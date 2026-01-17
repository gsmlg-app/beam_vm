import 'package:beam_vm_platform_interface/beam_vm_platform_interface.dart';

/// The iOS implementation of [BeamVmPlatform].
///
/// This class registers itself as the default instance of [BeamVmPlatform]
/// and uses method channels to communicate with native iOS code.
class BeamVmIos extends MethodChannelBeamVm {
  /// Registers this class as the default instance of [BeamVmPlatform].
  static void registerWith() {
    BeamVmPlatform.instance = BeamVmIos();
  }
}
