import 'dart:convert';
import 'package:amplitude_flutter/amplitude_flutter.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// {@template client}
/// Client for interacting with the Amplitude HTTP API.
/// {@endtemplate}
class Client {
  /// {@macro client}
  /// Singleton factory constructor to ensure only one instance exists.
  factory Client(String apiKey) => _instance ??= Client._internal(apiKey);

  /// Internal constructor for singleton pattern.
  Client._internal(this.apiKey) {
    _httpClient = http.Client();
    _uri = Uri.parse(_apiUrl);
  }

  static const String _apiUrl = 'https://api.amplitude.com/';
  static const String _apiVersion = '2';

  /// Get the API version used by the client
  static String get apiVersion => _apiVersion;
  static const Duration _timeout = Duration(seconds: 30);

  static Client? _instance;
  final String apiKey;

  /// HTTP client for making requests.
  late final http.Client _httpClient;

  /// URI for the Amplitude API endpoint.
  late final Uri _uri;

  /// Synchronous post that awaits response.
  /// Returns HTTP status code.
  Future<int> post(List<Map<String, dynamic>> eventData) async {
    final uploadTime = DateTime.now().toMs().toString();
    try {
      final events = json.encode(eventData);
      final checksumInput = '$_apiVersion$apiKey$events$uploadTime';
      final checksum =
          crypto.md5.convert(utf8.encode(checksumInput)).toString();
      final response = await _httpClient.post(
        _uri,
        body: <String, String>{
          'client': apiKey,
          'e': events,
          'v': _apiVersion,
          'upload_time': uploadTime,
          'checksum': checksum,
        },
      ).timeout(
        _timeout,
        onTimeout: () => http.Response('Request timeout', 408),
      );
      return response.statusCode;
    } catch (e) {
      debugPrint('Amplitude HTTP error: $e');
      return 500;
    }
  }

  /// Asynchronous post that does not await response.
  void postAsync(List<Map<String, dynamic>> eventData) {
    post(eventData).then((statusCode) {
      if (statusCode != 200) {
        debugPrint('Amplitude async post failed with status: $statusCode');
      }
    }).catchError((error) {
      debugPrint('Amplitude async post error: $error');
    });
  }

  /// Cleanup resources when client is no longer needed
  void dispose() {
    _httpClient.close();
    _instance = null;
  }
}
