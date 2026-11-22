# scutari_core

**Open-Core Edge AI Hardware Profiler & Model Router for Flutter**  
*Licensed under the MIT License — Zero-Cloud & Zero-Telemetry Guarantee.*

---

## Overview

`scutari_core` is a lightweight, zero-cloud Flutter plugin designed to profile handset compute capability (RAM, CPU core count, and hardware accelerator support) and dynamically route on-device AI inference models (such as INT8 quantized, FP16, or full FP32) based on real-time device capability.

- **Zero-Cloud & Zero-Telemetry**: No network permissions, no telemetry, no analytics, no external tracking.
- **Hardware-Aware**: Automatically queries native `ActivityManager` (Android) and `ProcessInfo` / `Metal` (iOS) to categorize hardware tiers.
- **Dynamic Model Router**: Supports both 2-tier (INT8 / FP16 fallback) and 3-tier (Low / Mid / Flagship) model dispatching.

---

## Installation

Add `scutari_core` to your `pubspec.yaml` using:

```bash
flutter pub add scutari_core
```

Or declare it directly in `pubspec.yaml`:

```yaml
dependencies:
  scutari_core: ^0.0.1
```

---

## Quickstart

### 1. Inspect Device Hardware

```dart
import 'package:scutari_core/scutari_core.dart';

Future<void> profileDevice() async {
  final HardwareProfile profile = await ScutariProfiler.inspectDevice();

  print('Total RAM: ${profile.totalRamMb} MB');
  print('Available RAM: ${profile.availableRamMb} MB');
  print('CPU Cores: ${profile.cpuCores}');
  print('Device Tier: ${profile.tier}'); // DeviceTier.low, DeviceTier.mid, DeviceTier.flagship
  print('Supported Accelerators: ${profile.supportedDelegates}');
}
```

### 2. Dynamic Model Routing

#### 3-Tier Deployment (Low / Mid / Flagship)

```dart
final modelPath = ScutariProfiler.routeModel(
  profile: profile,
  lowTierModelPath: 'assets/models/yamnet_int8.tflite',
  midTierModelPath: 'assets/models/yamnet_fp16.tflite',
  highTierModelPath: 'assets/models/yamnet_fp32.tflite',
);
```

#### 2-Tier Deployment (`midTierModelPath` omitted)

```dart
// midTierModelPath is optional; mid-tier devices cleanly fall back based on RAM headroom
final modelPath = ScutariProfiler.routeModel(
  profile: profile,
  lowTierModelPath: 'assets/models/model_int8.tflite',
  highTierModelPath: 'assets/models/model_fp16.tflite',
);
```

---

## API Reference

### `enum DeviceTier`
- `low`: Low-end devices (< 3.5 GB RAM or < 4 CPU cores).
- `mid`: Mid-range devices (3.5 GB – 6 GB RAM, 4+ CPU cores).
- `flagship`: Flagship devices (6 GB+ RAM, 6+ CPU cores).

### `enum AcceleratorDelegate`
- `cpu`: Fallback CPU execution (always supported).
- `nnapi`: Android Neural Networks API (API 29+).
- `gpu`: GPU acceleration (OpenGL ES 3.0+ / Vulkan).
- `coreMl`: Apple CoreML on iOS.
- `metal`: Apple Metal on iOS.

---

## License

MIT License. See [LICENSE](LICENSE) for details.

