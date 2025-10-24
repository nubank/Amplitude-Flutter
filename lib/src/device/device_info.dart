import 'dart:developer' as developer;

import 'package:amplitude_flutter/amplitude_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

class DeviceInfo {
  DeviceInfo(this.getCarrierInfo);
  bool getCarrierInfo;
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  Map<String, String?>? _deviceData = <String, String>{};
  final Map<String, String> _advData = <String, String>{};
  bool _isInitialized = false;

  Future<Map<String, String?>?> getPlatformInfo() async {
    if (_isInitialized && _deviceData!.isNotEmpty) {
      return _deviceData;
    }

    Map<String, String?> deviceData = {};
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        deviceData =
            await _parseAndroidInfo(await deviceInfoPlugin.androidInfo);
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        deviceData = await _parseIosInfo(await deviceInfoPlugin.iosInfo);
      }
      deviceData.addAll(await _getApplicationInfo());
      deviceData.addAll(await _getCurrentLocale());
      if (getCarrierInfo == true) {
        deviceData.addAll(await _getCarrierName());
      }
    } catch (e) {
      // error
    }
    _deviceData = deviceData;
    _isInitialized = true;
    return deviceData;
  }

  /// Returns advertising info (currently disabled for performance and stability)
  /// Made synchronous since it always returns empty map
  Map<String, String> getAdvertisingInfo() {
    return const {};

    // We are removing this block because since April 1 2022 it started crashing
    // on some Android Devices when it was trying to get the advertisingId
    // We need to keep it commented until to be able to bump Amplitude

    /*if (_advData.isNotEmpty) {
      return _advData;
    }

    final String advertisingId = await deviceAdvertisingId;
    if (advertisingId == null) {
      _advData = <String, String>{};
      return _advData;
    }

    if (Platform.isAndroid) {
      _advData = <String, String> { 'androidADID': advertisingId };
    } else if (Platform.isIOS) {
      _advData = <String, String> {
        Constants.kPayloadIosIdfa: advertisingId,
        Constants.kPayloadIosIdfv: (await deviceInfoPlugin.iosInfo).identifierForVendor
      };
    } else {
      _advData = <String, String>{};
    }

    return _advData; */
  }

  Future<Map<String, String>> _getCarrierName() async {
    final String? name = await getDeviceCarrierName;
    if (name != null && name.isNotEmpty) {
      return <String, String>{'carrier': name};
    } else {
      return <String, String>{};
    }
  }

  Future<Map<String, String?>> _getCurrentLocale() async {
    final String? name = await currentDeviceLocale;
    return <String, String?>{'language': name};
  }

  Future<void> regenerateDeviceId() async {
    await MetadataStore().setDeviceId(const Uuid().v4() + 'R');
    _deviceData = {};
    _isInitialized = false;
  }

  Future<Map<String, String?>> _parseAndroidInfo(
      AndroidDeviceInfo build) async {
    developer.log('buildDataAndroid", $build');

    String? deviceId = await MetadataStore().getDeviceId();

    // If deviceId is null and invalid, we will use AAID or
    // generate a NEW random number followed by 'R'
    if (deviceId == null ||
        Constants.kInvalidAndroidDeviceIds.contains(deviceId)) {
      deviceId = _advData[Constants.kPayloadAndroidAaid];
      deviceId ??= const Uuid().v4() + 'R';

      // Persist deviceId locally.
      MetadataStore().setDeviceId(deviceId);
    }

    return <String, String?>{
      'os_name': 'android',
      'os_version': build.version.release,
      'device_brand': build.brand,
      'device_manufacturer': build.manufacturer,
      'device_model': build.model,
      'device_id': deviceId,
      'platform': 'Android'
    };
  }

  Future<Map<String, String?>> _parseIosInfo(IosDeviceInfo data) async {
    developer.log('buildDataIos", $data');

    String? deviceId = await MetadataStore().getDeviceId();

    // If deviceId is null and invalid, we will use idfa or
    // generate a NEW random number followed by 'R'
    if (deviceId == null || Constants.kInvalidIosDeviceIds.contains(deviceId)) {
      deviceId = _advData[Constants.kPayloadIosIdfa];
      deviceId ??= const Uuid().v4() + 'R';

      // Persist deviceId locally.
      MetadataStore().setDeviceId(deviceId);
    }

    final String? deviceModel = await deviceModelInfo;
    return <String, String?>{
      'os_name': data.systemName,
      'os_version': data.systemVersion,
      'device_brand': null,
      'device_manufacturer': 'Apple',
      'device_model': deviceModel,
      'device_id': deviceId,
      'platform': 'iOS'
    };
  }

  Future<Map<String, String>> _getApplicationInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();

    return <String, String>{'version_name': info.version};
  }
}
