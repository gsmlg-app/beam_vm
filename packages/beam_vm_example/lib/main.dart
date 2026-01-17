import 'package:flutter/material.dart';
import 'package:beam_vm/beam_vm.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _beamVm = BeamVm();
  String _otpVersion = 'Unknown';
  BeamVmStatus _status = BeamVmStatus.uninitialized;

  @override
  void initState() {
    super.initState();
    _initBeamVm();
  }

  Future<void> _initBeamVm() async {
    // Listen to status changes
    _beamVm.statusStream.listen((status) {
      if (mounted) {
        setState(() => _status = status);
      }
    });

    // Get OTP version
    try {
      final version = await _beamVm.otpVersion;
      if (mounted) {
        setState(() => _otpVersion = version);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _otpVersion = 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('BEAM VM Example')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('OTP Version: $_otpVersion'),
              const SizedBox(height: 8),
              Text('Status: ${_status.name}'),
              const SizedBox(height: 24),
              const Text(
                'The BEAM VM runtime is bundled with this plugin.\n\n'
                'To run Elixir code, you need to:\n'
                '1. Bundle an Elixir release in your app assets\n'
                '2. Extract it at runtime\n'
                '3. Call beamVm.initialize() with the path',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
