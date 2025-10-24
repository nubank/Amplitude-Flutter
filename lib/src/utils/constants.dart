/// {@template Utils}
/// Constants used throughout the SDK.
/// {@endtemplate}
abstract class Constants {
  // Local storage
  static const kLocalStoreDeviceIdKey = 'amp:device_id';

  /// Invalid device IDs for Android and iOS platforms
  static const kInvalidAndroidDeviceIds = {
    '',
    '9774d56d682e549c',
    'unknown',
    '000000000000000',
    'Android',
    'DEFACE',
    '00000000-0000-0000-0000-000000000000'
  };

  /// Invalid device IDs for iOS platform
  static const kInvalidIosDeviceIds = {
    '',
    '00000000-0000-0000-0000-000000000000'
  };

  /// Payload keys for device identifiers
  static const kPayloadAndroidAaid = 'androidADID';

  /// Payload keys for device identifiers
  static const kPayloadIosIdfa = 'ios_idfa';

  /// Payload keys for device identifiers
  static const kPayloadIosIdfv = 'ios_idfv';
}
