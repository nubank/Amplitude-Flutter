import 'package:amplitude_flutter/amplitude_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// {@template metadata_store}
/// MetadataStore is a singleton class that manages the storage and retrieval
/// of metadata such as device IDs using SharedPreferences.
/// {@endtemplate}
class MetadataStore {
  /// {@macro metadata_store}
  factory MetadataStore() => _instance ??= MetadataStore._();

  /// Private constructor for singleton pattern
  MetadataStore._();

  /// Singleton instance
  static MetadataStore? _instance;

  /// Cached SharedPreferences instance
  SharedPreferences? _cachedPrefs;

  Future<SharedPreferences> _getPrefs() async {
    if (_cachedPrefs != null) {
      return _cachedPrefs!;
    }
    _cachedPrefs = await SharedPreferences.getInstance();
    return _cachedPrefs!;
  }

  /// Sets the device ID in SharedPreferences.
  Future<void> setDeviceId(String deviceId) async {
    final SharedPreferences prefs = await _getPrefs();
    await prefs.setString(Constants.kLocalStoreDeviceIdKey, deviceId);
  }

  /// Retrieves the device ID from SharedPreferences.
  Future<String?> getDeviceId() async {
    final SharedPreferences prefs = await _getPrefs();
    return prefs.getString(Constants.kLocalStoreDeviceIdKey);
  }
}
