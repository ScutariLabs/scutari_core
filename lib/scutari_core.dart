import 'package:flutter/foundation.dart';


import 'scutari_core_platform_interface.dart';

/// Categorization of device compute capability.
enum DeviceTier { low, mid, flagship }

/// Hardware accelerator delegates available on edge platforms.
enum AcceleratorDelegate { cpu, nnapi, gpu, coreMl, metal }

/// Hardware execution profile captured from device hardware sensors.
class HardwareProfile {
  final int totalRamMb;
  final int availableRamMb;
  final int cpuCores;
  final DeviceTier tier;
  final List<AcceleratorDelegate> supportedDelegates;

  const HardwareProfile({
    required this.totalRamMb,
    required this.availableRamMb,
    required this.cpuCores,
    required this.tier,
    required this.supportedDelegates,
  });

  /// Derives [DeviceTier] deterministically from RAM and CPU core count.
  static DeviceTier calculateTier({
    required int totalRamMb,
    required int cpuCores,
  }) {
    if (totalRamMb >= 6000 && cpuCores >= 6) {
      return DeviceTier.flagship;
    } else if (totalRamMb >= 3500 && cpuCores >= 4) {
      return DeviceTier.mid;
    } else {
      return DeviceTier.low;
    }
  }

  /// Parses a hardware profile from a native method channel map.
  factory HardwareProfile.fromMap(Map<dynamic, dynamic> map) {
    final int totalRamMb = (map['totalRamMb'] as num?)?.toInt() ?? 0;
    final int availableRamMb = (map['availableRamMb'] as num?)?.toInt() ?? 0;
    final int cpuCores = (map['cpuCores'] as num?)?.toInt() ?? 1;

    final DeviceTier tier;
    if (map['tier'] != null) {
      final tierStr = map['tier'].toString().toLowerCase();
      tier = DeviceTier.values.firstWhere(
        (t) => t.name.toLowerCase() == tierStr,
        orElse: () => calculateTier(totalRamMb: totalRamMb, cpuCores: cpuCores),
      );
    } else {
      tier = calculateTier(totalRamMb: totalRamMb, cpuCores: cpuCores);
    }

    final List<AcceleratorDelegate> delegates = [];
    if (map['supportedDelegates'] is List) {
      for (final item in map['supportedDelegates'] as List) {
        final str = item.toString().toLowerCase();
        if (str == 'cpu') {
          delegates.add(AcceleratorDelegate.cpu);
        } else if (str == 'nnapi') {
          delegates.add(AcceleratorDelegate.nnapi);
        } else if (str == 'gpu') {
          delegates.add(AcceleratorDelegate.gpu);
        } else if (str == 'coreml' || str == 'core_ml') {
          delegates.add(AcceleratorDelegate.coreMl);
        } else if (str == 'metal') {
          delegates.add(AcceleratorDelegate.metal);
        }
      }
    }
    if (!delegates.contains(AcceleratorDelegate.cpu)) {
      delegates.insert(0, AcceleratorDelegate.cpu);
    }

    return HardwareProfile(
      totalRamMb: totalRamMb,
      availableRamMb: availableRamMb,
      cpuCores: cpuCores,
      tier: tier,
      supportedDelegates: delegates,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalRamMb': totalRamMb,
      'availableRamMb': availableRamMb,
      'cpuCores': cpuCores,
      'tier': tier.name,
      'supportedDelegates': supportedDelegates.map((d) => d.name).toList(),
    };
  }

  @override
  String toString() {
    return 'HardwareProfile(totalRamMb: $totalRamMb, availableRamMb: $availableRamMb, cpuCores: $cpuCores, tier: ${tier.name}, delegates: ${supportedDelegates.map((d) => d.name).toList()})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HardwareProfile) return false;
    return other.totalRamMb == totalRamMb &&
        other.availableRamMb == availableRamMb &&
        other.cpuCores == cpuCores &&
        other.tier == tier &&
        listEquals(other.supportedDelegates, supportedDelegates);
  }

  @override
  int get hashCode => Object.hash(
        totalRamMb,
        availableRamMb,
        cpuCores,
        tier,
        Object.hashAll(supportedDelegates),
      );
}

/// Offline Hardware Profiler & Dynamic Model Router.
class ScutariProfiler {
  /// Inspects device hardware (RAM, CPU cores, accelerators) via native channels.
  static Future<HardwareProfile> inspectDevice() async {
    final raw = await ScutariCorePlatform.instance.inspectDevice();
    if (raw == null) {
      // Default safe fallback if platform returns null
      return const HardwareProfile(
        totalRamMb: 2048,
        availableRamMb: 1024,
        cpuCores: 2,
        tier: DeviceTier.low,
        supportedDelegates: [AcceleratorDelegate.cpu],
      );
    }
    return HardwareProfile.fromMap(raw);
  }

  /// Routes to the optimal model path based on the hardware profile.
  ///
  /// [midTierModelPath] is optional so a 2-tier INT8/FP16 call compiles cleanly.
  /// If omitted, falls back cleanly based on tier and RAM headroom.
  static String routeModel({
    required HardwareProfile profile,
    required String lowTierModelPath,
    String? midTierModelPath,
    required String highTierModelPath,
  }) {
    if (midTierModelPath != null) {
      // 3-Tier routing
      switch (profile.tier) {
        case DeviceTier.flagship:
          return highTierModelPath;
        case DeviceTier.mid:
          return midTierModelPath;
        case DeviceTier.low:
          return lowTierModelPath;
      }
    } else {
      // 2-Tier routing (midTierModelPath is omitted)
      switch (profile.tier) {
        case DeviceTier.flagship:
          return highTierModelPath;
        case DeviceTier.low:
          return lowTierModelPath;
        case DeviceTier.mid:
          // Fall back cleanly based on memory headroom
          if (profile.availableRamMb >= 1800 || profile.totalRamMb >= 4000) {
            return highTierModelPath;
          }
          return lowTierModelPath;
      }
    }
  }
}

/// Helper for general platform information.
class ScutariCore {
  Future<String?> getPlatformVersion() {
    return ScutariCorePlatform.instance.getPlatformVersion();
  }
}

