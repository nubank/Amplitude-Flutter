class Constants {
  static const packageName = 'amplitude-flutter';
  static const packageVersion = '1.3.2';

  // Local storage
  static const kLocalStoreDeviceIdKey = 'amp:device_id';

  static const kInvalidAndroidDeviceIds = {
    '',
    '9774d56d682e549c',
    'unknown',
    '000000000000000',
    'Android',
    'DEFACE',
    '00000000-0000-0000-0000-000000000000'
  };

  static const kInvalidIosDeviceIds = {
    '',
    '00000000-0000-0000-0000-000000000000'
  };

  static const kPayloadAndroidAaid = 'androidADID';
  static const kPayloadIosIdfa = 'ios_idfa';
  static const kPayloadIosIdfv = 'ios_idfv';
}
