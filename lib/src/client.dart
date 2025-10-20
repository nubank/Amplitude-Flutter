import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'time_utils.dart';

/// Data structure for isolate computation
class _PayloadData {
  _PayloadData({
    required this.eventData,
    required this.apiKey,
    required this.uploadTime,
  });

  final List<Map<String, dynamic>> eventData;
  final String apiKey;
  final String uploadTime;
}

/// Result from isolate computation
class _PreparedPayload {
  _PreparedPayload({
    required this.events,
    required this.checksum,
  });

  final String events;
  final String checksum;
}

/// Computes JSON encoding and MD5 checksum in isolate
/// This is a top-level function for use with compute()
_PreparedPayload _preparePayload(_PayloadData data) {
  const apiVersion = '2';
  final events = json.encode(data.eventData);
  final checksumInput = apiVersion + data.apiKey + events + data.uploadTime;
  final md5 = crypto.md5.convert(utf8.encode(checksumInput)).toString();

  return _PreparedPayload(events: events, checksum: md5);
}

class Client {
  factory Client(String apiKey) {
    if (_instance != null) {
      return _instance!;
    }
    _instance = Client._internal(apiKey);
    return _instance!;
  }

  Client._internal(this.apiKey) {
    _httpClient = http.Client();
  }

  static const String apiUrl = 'https://api.amplitude.com/';
  static const String apiVersion = '2';
  static const int _timeoutSeconds = 30;

  /// Threshold for using isolate computation (number of events)
  /// For payloads smaller than this, inline computation is faster
  static const int _heavyPayloadThreshold = 50;

  static Client? _instance;

  final String apiKey;
  late final http.Client _httpClient;

  /// Synchronous post that awaits response.
  /// Returns HTTP status code.
  Future<int> post(List<Map<String, dynamic>> eventData) async {
    final uploadTime = currentTime().toString();
    try {
      final _PreparedPayload prepared;
      if (eventData.length > _heavyPayloadThreshold) {
        prepared = await compute(
          _preparePayload,
          _PayloadData(
            eventData: eventData,
            apiKey: apiKey,
            uploadTime: uploadTime,
          ),
        );
      } else {
        prepared = _preparePayload(_PayloadData(
          eventData: eventData,
          apiKey: apiKey,
          uploadTime: uploadTime,
        ));
      }
      final response = await _httpClient.post(
        Uri.parse(apiUrl),
        body: <String, String>{
          'client': apiKey,
          'e': prepared.events,
          'v': apiVersion,
          'upload_time': uploadTime,
          'checksum': prepared.checksum,
        },
      ).timeout(
        const Duration(seconds: _timeoutSeconds),
        onTimeout: () => http.Response('Request timeout', 408),
      );

      return response.statusCode;
    } catch (e) {
      debugPrint('Amplitude HTTP error: $e');
      return 500;
    }
  }

  /// Asynchronous post that does not await response.
  /// Useful for background tasks where immediate feedback is not required.
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
  }
}
