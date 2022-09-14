import 'package:amplitude_flutter/src/constants.dart';
import 'package:amplitude_flutter/src/device_info.dart';
import 'package:device_info_platform_interface/device_info_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDeviceInfoPlatform
    with MockPlatformInterfaceMixin
    implements DeviceInfoPlatform {
  @override
  Future<AndroidDeviceInfo> androidInfo() async =>
      AndroidDeviceInfo.fromMap(<String, dynamic>{'model': 'android-model'});

  @override
  Future<IosDeviceInfo> iosInfo() async =>
      IosDeviceInfo.fromMap(<String, dynamic>{
        'model': 'ios-model',
      });
}

void main() {
  DeviceInfo deviceInfo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DeviceInfoPlatform.instance = MockDeviceInfoPlatform();
    deviceInfo = DeviceInfo(false);
  });

  group('#regenerateDeviceId', () {
    test('when platform is Android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final platformInfo = await deviceInfo.getPlatformInfo();
      expect(
          platformInfo,
          allOf(
            containsPair('platform', 'Android'),
            containsPair('device_model', 'android-model'),
            containsPair('device_id', isNotNull),
          ));

      final deviceId = platformInfo['device_id'];

      await deviceInfo.regenerateDeviceId();

      final newPlatformInfo = await deviceInfo.getPlatformInfo();
      final newDeviceId = newPlatformInfo['device_id'];

      expect(newDeviceId, isNot(deviceId));

      final prefs = await SharedPreferences.getInstance();
      final savedDeviceId = prefs.getString(Constants.kLocalStoreDeviceIdKey);

      expect(savedDeviceId, equals(newDeviceId));
    });
  });
}
