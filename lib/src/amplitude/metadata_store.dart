import 'package:amplitude_flutter/amplitude_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MetadataStore {
  factory MetadataStore() => _instance ??= MetadataStore._();
  MetadataStore._();

  static MetadataStore? _instance;
  SharedPreferences? _cachedPrefs;

  Future<SharedPreferences> _getPrefs() async {
    if (_cachedPrefs != null) {
      return _cachedPrefs!;
    }
    _cachedPrefs = await SharedPreferences.getInstance();
    return _cachedPrefs!;
  }

  Future<void> setDeviceId(String deviceId) async {
    final SharedPreferences prefs = await _getPrefs();
    await prefs.setString(Constants.kLocalStoreDeviceIdKey, deviceId);
  }

  Future<String?> getDeviceId() async {
    final SharedPreferences prefs = await _getPrefs();
    return prefs.getString(Constants.kLocalStoreDeviceIdKey);
  }
}
