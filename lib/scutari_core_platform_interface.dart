import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'scutari_core_method_channel.dart';

abstract class ScutariCorePlatform extends PlatformInterface {
  /// Constructs a ScutariCorePlatform.
  ScutariCorePlatform() : super(token: _token);

  static final Object _token = Object();

  static ScutariCorePlatform _instance = MethodChannelScutariCore();

  /// The default instance of [ScutariCorePlatform] to use.
  static ScutariCorePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ScutariCorePlatform] when
  /// they register themselves.
  static set instance(ScutariCorePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Inspects device hardware specs including RAM, CPU cores, and supported accelerators.
  Future<Map<String, dynamic>?> inspectDevice() {
    throw UnimplementedError('inspectDevice() has not been implemented.');
  }
}

