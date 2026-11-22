import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scutari_core/scutari_core_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannelScutariCore platform = MethodChannelScutariCore();
  const MethodChannel channel = MethodChannel('com.scutarilabs.core/methods');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getPlatformVersion') {
        return 'Android 14';
      }
      if (methodCall.method == 'inspectDevice') {
        return <String, dynamic>{
          'totalRamMb': 8192,
          'availableRamMb': 4200,
          'cpuCores': 8,
          'supportedDelegates': ['cpu', 'nnapi', 'gpu'],
        };
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion returns mock platform string', () async {
    expect(await platform.getPlatformVersion(), 'Android 14');
  });

  test('inspectDevice returns hardware profile map', () async {
    final result = await platform.inspectDevice();
    expect(result, isNotNull);
    expect(result!['totalRamMb'], 8192);
    expect(result['availableRamMb'], 4200);
    expect(result['cpuCores'], 8);
    expect(result['supportedDelegates'], ['cpu', 'nnapi', 'gpu']);
  });
}

