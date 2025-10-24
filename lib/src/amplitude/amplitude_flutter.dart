import 'dart:async';

import 'package:amplitude_flutter/amplitude_flutter.dart';

/// {@template amplitude_flutter}
/// Main Amplitude Flutter class for logging events and managing user sessions.
/// {@endtemplate}
class AmplitudeFlutter {
  /// {@macro amplitude_flutter}
  ///
  /// [apiKey] is the Amplitude API key for your project.
  /// [config] is an optional configuration object.
  AmplitudeFlutter(String apiKey, [Config? config])
      : config = config ?? Config(),
        provider = ServiceProvider(
          apiKey: apiKey,
          timeout: (config ?? Config()).sessionTimeout,
          getCarrierInfo: (config ?? Config()).getCarrierInfo,
        ) {
    _init();
  }

  AmplitudeFlutter.private(this.provider, this.config) {
    _init();
  }

  bool? getCarrierInfo;
  final Config config;
  final ServiceProvider provider;
  late final DeviceInfo deviceInfo;
  late final Session session;
  late final EventBuffer buffer;
  dynamic userId;

  /// Cached device info to avoid repeated async calls
  Map<String, String>? _cachedAdvertisingInfo;

  /// Cached platform info to avoid repeated async calls
  Map<String, String?>? _cachedPlatformInfo;

  void setSessionId(int sessionId) {
    session.sessionStart = sessionId;
  }

  /// Set the user id associated with events
  void setUserId(dynamic userId) {
    this.userId = userId;
  }

  /// Log an event
  Future<void> logEvent(
      {required String name,
      Map<String, dynamic> properties = const <String, String>{}}) async {
    if (config.optOut) {
      return;
    }

    final Event event = Event(name, properties: properties);

    final Map<String, String> advertisingValues =
        _cachedAdvertisingInfo ?? deviceInfo.getAdvertisingInfo();
    event.labels
        ?.addAll(<String, dynamic>{'api_properties': advertisingValues});

    final platformInfo =
        _cachedPlatformInfo ?? await deviceInfo.getPlatformInfo();
    event.labels?.addAll(platformInfo ?? <String, dynamic>{});

    if (userId != null) {
      event.labels?.addAll({'user_id': userId});
    }

    return buffer.add(event.toEntity());
  }

  /// Log many events
  Future<void> logBulkEvent(List<Map<String, dynamic>> events) async {
    if (config.optOut) {
      return;
    }
    final Map<String, String> advertisingValues =
        _cachedAdvertisingInfo ?? deviceInfo.getAdvertisingInfo();
    final platformInfo =
        _cachedPlatformInfo ?? await deviceInfo.getPlatformInfo();
    final commonProps = <String, dynamic>{
      'api_properties': advertisingValues,
      ...?platformInfo,
    };
    if (userId != null) {
      commonProps['user_id'] = userId;
    }
    final eventsList = events.map((eventData) {
      return Event(
        eventData['name'],
        properties: <String, dynamic>{
          ...?eventData['properties'],
          ...commonProps,
        },
      ).toEntity();
    }).toList(growable: false);

    return buffer.addAll(eventsList);
  }

  /// Identify the current user
  Future<void> identify(Identify identify,
      {Map<String, dynamic> properties = const <String, dynamic>{}}) async {
    return logEvent(
        name: r'$identify',
        properties: <String, dynamic>{'user_properties': identify.payload}
          ..addAll(properties));
  }

  /// Adds the current user to a group
  Future<void> setGroup(String groupType, dynamic groupValue) async {
    return identify(Identify()..set(groupType, groupValue),
        properties: <String, dynamic>{
          'groups': <String, dynamic>{groupType: groupValue}
        });
  }

  /// Sets properties on a group
  Future<void> groupIdentify(
      String groupType, dynamic groupValue, Identify identify) async {
    return logEvent(name: r'$groupidentify', properties: <String, dynamic>{
      'group_properties': identify.payload,
      'groups': <String, dynamic>{groupType: groupValue}
    });
  }

  /// Log a revenue event
  Future<void> logRevenue(Revenue revenue) async {
    if (revenue.isValid()) {
      return logEvent(
          name: Revenue.event,
          properties: <String, dynamic>{'event_properties': revenue.payload});
    }
  }

  /// Manually flush events in the buffer
  Future<void> flushEvents() => buffer.flush();

  /// Dispose resources
  void dispose() {
    buffer.dispose();
  }

  void _init() {
    deviceInfo = provider.deviceInfo;
    session = provider.session;
    buffer = EventBuffer(provider, config);

    session.start();
    _loadDeviceInfo();
  }

  /// Pre-load and cache device info to avoid repeated async calls
  Future<void> _loadDeviceInfo() async {
    _cachedAdvertisingInfo = deviceInfo.getAdvertisingInfo();
    _cachedPlatformInfo = await deviceInfo.getPlatformInfo();
  }
}
