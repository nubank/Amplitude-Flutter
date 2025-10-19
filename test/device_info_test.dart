import 'package:amplitude_flutter/src/constants.dart';
import 'package:amplitude_flutter/src/device_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DeviceInfo deviceInfo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    deviceInfo = DeviceInfo(false);
  });

  group('#regenerateDeviceId', () {
    test('regenerates device ID and clears cache', () async {
      SharedPreferences.setMockInitialValues({
        Constants.kLocalStoreDeviceIdKey: 'original-device-id',
      });

      deviceInfo = DeviceInfo(false);

      await deviceInfo.regenerateDeviceId();

      final prefs = await SharedPreferences.getInstance();
      final savedDeviceId = prefs.getString(Constants.kLocalStoreDeviceIdKey);

      expect(savedDeviceId, isNotNull);
      expect(savedDeviceId, isNot('original-device-id'));
      expect(savedDeviceId, endsWith('R'));
    });

    test('cache is cleared after regenerateDeviceId', () async {
      await deviceInfo.regenerateDeviceId();

      final prefs = await SharedPreferences.getInstance();
      final savedDeviceId = prefs.getString(Constants.kLocalStoreDeviceIdKey);

      expect(savedDeviceId, isNotNull);
      expect(savedDeviceId, endsWith('R'));
    });
  });
}
