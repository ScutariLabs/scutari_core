import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'scutari_core_platform_interface.dart';

/// An implementation of [ScutariCorePlatform] that uses method channels.
class MethodChannelScutariCore extends ScutariCorePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('com.scutarilabs.core/methods');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<Map<String, dynamic>?> inspectDevice() async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'inspectDevice',
    );
    return result;
  }
}

