import 'package:amplitude_flutter/src/constants.dart';
import 'package:amplitude_flutter/src/device_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    // Mock do DeviceInfoPlugin via MethodChannel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/device_info'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getDeviceInfo') {
          return getDeviceInfo();
        }
        return null;
      },
    );

    // Mock do PackageInfo
    PackageInfo.setMockInitialValues(
      appName: 'Test App',
      packageName: 'com.test.app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  group('#regenerateDeviceId', () {
    test('when platform is Android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final deviceInfo = DeviceInfo(false);
      final platformInfo = (await deviceInfo.getPlatformInfo())!;

      print('[PLATAFORM INFO] $platformInfo');
      expect(
          platformInfo,
          allOf(
            containsPair('platform', 'Android'),
            containsPair('device_model', 'android-model'),
            containsPair('device_id', isNotNull),
          ));

      final deviceId = platformInfo['device_id'];

      await deviceInfo.regenerateDeviceId();

      final newPlatformInfo = (await deviceInfo.getPlatformInfo())!;
      final newDeviceId = newPlatformInfo['device_id'];

      expect(newDeviceId, isNot(deviceId));

      final prefs = await SharedPreferences.getInstance();
      final savedDeviceId = prefs.getString(Constants.kLocalStoreDeviceIdKey);

      expect(savedDeviceId, equals(newDeviceId));
    });
  });
}

Map<String, dynamic> getDeviceInfo() {
  return {
    'version': {
      'sdkInt': 20,
      'codename': 'test',
      'incremental': 'test',
      'release': 'test',
      'previewSdkInt': 20,
    },
    'board': 'test',
    'bootloader': 'test',
    'brand': 'test',
    'device': 'test',
    'display': 'test',
    'fingerprint': 'test',
    'hardware': 'test',
    'host': 'test',
    'id': 'test',
    'manufacturer': 'test',
    'model': 'android-model',
    'product': 'test',
    'tags': 'test',
    'type': 'test',
    'isPhysicalDevice': true,
    'serialNumber': 'test',
    'isLowRamDevice': false,
    'freeDiskSize': 1000000,
    'totalDiskSize': 100000,
    'physicalRamSize': 10000,
    'availableRamSize': 10000,
    'displayMetrics': {
      'widthPx': 100.0,
      'heightPx': 100.0,
      'xDpi': 100.0,
      'yDpi': 100.0,
    }
  };
}
