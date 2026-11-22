import 'package:flutter_test/flutter_test.dart';
import 'package:scutari_core/scutari_core.dart';
import 'package:scutari_core/scutari_core_platform_interface.dart';
import 'package:scutari_core/scutari_core_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockScutariCorePlatform
    with MockPlatformInterfaceMixin
    implements ScutariCorePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('Android 14');

  @override
  Future<Map<String, dynamic>?> inspectDevice() => Future.value({
        'totalRamMb': 8192,
        'availableRamMb': 4096,
        'cpuCores': 8,
        'supportedDelegates': ['cpu', 'nnapi', 'gpu'],
      });
}

void main() {
  final ScutariCorePlatform initialPlatform = ScutariCorePlatform.instance;

  test('$MethodChannelScutariCore is default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelScutariCore>());
  });

  group('ScutariProfiler Hardware Profiling', () {
    setUp(() {
      ScutariCorePlatform.instance = MockScutariCorePlatform();
    });

    test('inspectDevice parses profile correctly', () async {
      final profile = await ScutariProfiler.inspectDevice();
      expect(profile.totalRamMb, 8192);
      expect(profile.availableRamMb, 4096);
      expect(profile.cpuCores, 8);
      expect(profile.tier, DeviceTier.flagship);
      expect(profile.supportedDelegates, [
        AcceleratorDelegate.cpu,
        AcceleratorDelegate.nnapi,
        AcceleratorDelegate.gpu,
      ]);
    });

    test('HardwareProfile boundary tier calculation', () {
      expect(HardwareProfile.calculateTier(totalRamMb: 2048, cpuCores: 4), DeviceTier.low);
      expect(HardwareProfile.calculateTier(totalRamMb: 8192, cpuCores: 2), DeviceTier.low);
      expect(HardwareProfile.calculateTier(totalRamMb: 3000, cpuCores: 8), DeviceTier.low);
      expect(HardwareProfile.calculateTier(totalRamMb: 4000, cpuCores: 4), DeviceTier.mid);
      expect(HardwareProfile.calculateTier(totalRamMb: 5900, cpuCores: 8), DeviceTier.mid);
      expect(HardwareProfile.calculateTier(totalRamMb: 6000, cpuCores: 6), DeviceTier.flagship);
      expect(HardwareProfile.calculateTier(totalRamMb: 12000, cpuCores: 8), DeviceTier.flagship);
    });

    test('HardwareProfile serialization and equality', () {
      const profile1 = HardwareProfile(
        totalRamMb: 4096,
        availableRamMb: 2048,
        cpuCores: 4,
        tier: DeviceTier.mid,
        supportedDelegates: [AcceleratorDelegate.cpu, AcceleratorDelegate.coreMl],
      );

      final map = profile1.toMap();
      final profile2 = HardwareProfile.fromMap(map);

      expect(profile1, equals(profile2));
      expect(profile1.hashCode, equals(profile2.hashCode));
    });
  });

  group('ScutariProfiler.routeModel', () {
    const flagshipProfile = HardwareProfile(
      totalRamMb: 8192,
      availableRamMb: 4500,
      cpuCores: 8,
      tier: DeviceTier.flagship,
      supportedDelegates: [AcceleratorDelegate.cpu, AcceleratorDelegate.nnapi],
    );

    const midHighRam = HardwareProfile(
      totalRamMb: 4096,
      availableRamMb: 2200,
      cpuCores: 4,
      tier: DeviceTier.mid,
      supportedDelegates: [AcceleratorDelegate.cpu],
    );

    const midLowRam = HardwareProfile(
      totalRamMb: 3600,
      availableRamMb: 1200,
      cpuCores: 4,
      tier: DeviceTier.mid,
      supportedDelegates: [AcceleratorDelegate.cpu],
    );

    const lowProfile = HardwareProfile(
      totalRamMb: 2048,
      availableRamMb: 900,
      cpuCores: 2,
      tier: DeviceTier.low,
      supportedDelegates: [AcceleratorDelegate.cpu],
    );

    const lowModel = 'assets/models/model_int8.tflite';
    const midModel = 'assets/models/model_fp16.tflite';
    const highModel = 'assets/models/model_fp32.tflite';

    test('3-Tier routing: routes correctly to low, mid, and high', () {
      expect(
        ScutariProfiler.routeModel(
          profile: flagshipProfile,
          lowTierModelPath: lowModel,
          midTierModelPath: midModel,
          highTierModelPath: highModel,
        ),
        equals(highModel),
      );

      expect(
        ScutariProfiler.routeModel(
          profile: midHighRam,
          lowTierModelPath: lowModel,
          midTierModelPath: midModel,
          highTierModelPath: highModel,
        ),
        equals(midModel),
      );

      expect(
        ScutariProfiler.routeModel(
          profile: lowProfile,
          lowTierModelPath: lowModel,
          midTierModelPath: midModel,
          highTierModelPath: highModel,
        ),
        equals(lowModel),
      );
    });

    test('2-Tier routing (midTierModelPath omitted): routes correctly', () {
      expect(
        ScutariProfiler.routeModel(
          profile: flagshipProfile,
          lowTierModelPath: lowModel,
          highTierModelPath: highModel,
        ),
        equals(highModel),
      );

      expect(
        ScutariProfiler.routeModel(
          profile: lowProfile,
          lowTierModelPath: lowModel,
          highTierModelPath: highModel,
        ),
        equals(lowModel),
      );

      expect(
        ScutariProfiler.routeModel(
          profile: midHighRam,
          lowTierModelPath: lowModel,
          highTierModelPath: highModel,
        ),
        equals(highModel),
      );

      expect(
        ScutariProfiler.routeModel(
          profile: midLowRam,
          lowTierModelPath: lowModel,
          highTierModelPath: highModel,
        ),
        equals(lowModel),
      );
    });
  });
}

