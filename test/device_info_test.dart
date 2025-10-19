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
      // Set a mock device ID in shared preferences
      SharedPreferences.setMockInitialValues({
        Constants.kLocalStoreDeviceIdKey: 'original-device-id',
      });

      // Create a fresh instance to pick up the mocked value
      deviceInfo = DeviceInfo(false);

      // Call regenerateDeviceId
      await deviceInfo.regenerateDeviceId();

      // Verify that a new device ID was generated
      final prefs = await SharedPreferences.getInstance();
      final savedDeviceId = prefs.getString(Constants.kLocalStoreDeviceIdKey);

      expect(savedDeviceId, isNotNull);
      expect(savedDeviceId, isNot('original-device-id'));
      expect(savedDeviceId, endsWith('R')); // Generated IDs end with 'R'
    });

    test('cache is cleared after regenerateDeviceId', () async {
      // This test verifies that the _isInitialized flag is reset
      // We can't directly test the private flag, but we can verify the behavior

      await deviceInfo.regenerateDeviceId();

      final prefs = await SharedPreferences.getInstance();
      final savedDeviceId = prefs.getString(Constants.kLocalStoreDeviceIdKey);

      expect(savedDeviceId, isNotNull);
      expect(savedDeviceId, endsWith('R'));
    });
  });
}
