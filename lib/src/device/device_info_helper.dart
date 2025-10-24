import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('amplitude_flutter');

/// Returns the carrier name of the device.
Future<String?> get getDeviceCarrierName async {
  try {
    final String? carrierName = await _channel.invokeMethod('carrierName');
    return carrierName;
  } on PlatformException catch (e) {
    debugPrint('Amplitude: Error retrieving carrier info: ${e.message}');
    return '';
  }
}

/// Returns a [List] of locales from the device
/// the first in the list should be the current one set on the device
/// for example iOS **['en-GB', 'es-GB'] or for Android **['en_GB, 'es_GB]**
Future<List?> get preferredDeviceLanguages async {
  final List? version = await _channel.invokeMethod('preferredLanguages');
  return version;
}

/// Returns a [String] of the currently set DEVICE locale made up of the language and the region
/// (e.g. en-US or en_US)
Future<String?> get currentDeviceLocale async {
  final String? locale = await _channel.invokeMethod('currentLocale');
  return locale;
}

/// Returns a [String] for adverstingId.
/// iOS: idfa
/// Android: androidADID
Future<String?> get deviceAdvertisingId async {
  final String? advertisingId = await _channel.invokeMethod('advertisingId');
  return advertisingId;
}

/// Returns a [String] for deviceModel.
/// This is only for iOS, android not needed.
Future<String?> get deviceModelInfo async {
  final String? deviceModel = await _channel.invokeMethod('deviceModel');
  return deviceModel;
}
