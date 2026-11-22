import 'package:flutter/material.dart';
import 'package:scutari_core/scutari_core.dart';

void main() => runApp(const ScutariCoreExampleApp());

class ScutariCoreExampleApp extends StatelessWidget {
  const ScutariCoreExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Scutari Core Demo',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117),
      ),
      home: const ProfilerScreen(),
    );
  }
}

class ProfilerScreen extends StatefulWidget {
  const ProfilerScreen({super.key});

  @override
  State<ProfilerScreen> createState() => _ProfilerScreenState();
}

class _ProfilerScreenState extends State<ProfilerScreen> {
  HardwareProfile? _profile;
  String? _routedModel2Tier;
  String? _routedModel3Tier;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runProfiling();
  }

  Future<void> _runProfiling() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ScutariProfiler.inspectDevice();
      final r2 = ScutariProfiler.routeModel(
        profile: profile,
        lowTierModelPath: 'assets/models/model_int8.tflite',
        highTierModelPath: 'assets/models/model_fp16.tflite',
      );
      final r3 = ScutariProfiler.routeModel(
        profile: profile,
        lowTierModelPath: 'assets/models/model_int8.tflite',
        midTierModelPath: 'assets/models/model_fp16.tflite',
        highTierModelPath: 'assets/models/model_fp32.tflite',
      );
      if (mounted) {
        setState(() {
          _profile = profile;
          _routedModel2Tier = r2;
          _routedModel3Tier = r3;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scutari Core — Hardware Profiler'),
        backgroundColor: const Color(0xFF161B22),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_profile != null) ...[
              _row('Tier', _profile!.tier.name.toUpperCase()),
              _row('Total RAM', '${_profile!.totalRamMb} MB'),
              _row('Available RAM', '${_profile!.availableRamMb} MB'),
              _row('CPU Cores', '${_profile!.cpuCores}'),
              _row('Delegates', _profile!.supportedDelegates.map((d) => d.name).join(', ')),
              const Divider(height: 30),
              _row('2-Tier Route', _routedModel2Tier ?? ''),
              _row('3-Tier Route', _routedModel3Tier ?? ''),
            ],
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
              ),
              onPressed: _isLoading ? null : _runProfiling,
              child: const Text('Re-Inspect Device'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

