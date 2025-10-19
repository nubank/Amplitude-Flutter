import 'dart:async';

import 'config.dart';
import 'device_info.dart';
import 'event.dart';
import 'event_buffer.dart';
import 'identify.dart';
import 'revenue.dart';
import 'service_provider.dart';
import 'session.dart';

class AmplitudeFlutter {
  AmplitudeFlutter(String apiKey, [Config? config])
      : config = config ?? Config(),
        provider = ServiceProvider(
          apiKey: apiKey,
          timeout: (config ?? Config()).sessionTimeout,
          getCarrierInfo: (config ?? Config()).getCarrierInfo,
          enableUuid: (config ?? Config()).enableUuid,
        ) {
    _init();
  }

  AmplitudeFlutter.private(this.provider, this.config) {
    _init();
  }

  bool? getCarrierInfo;
  late final bool enableUuid;
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

    final Event event = enableUuid
        ? Event.uuid(name,
            sessionId: session.getSessionId(), props: properties)
        : Event.noUuid(name,
            sessionId: session.getSessionId(), props: properties);

    final Map<String, String> advertisingValues =
        _cachedAdvertisingInfo ?? deviceInfo.getAdvertisingInfo();
    event.addProps(<String, dynamic>{'api_properties': advertisingValues});

    final platformInfo =
        _cachedPlatformInfo ?? await deviceInfo.getPlatformInfo();
    event.addProps(platformInfo);

    if (userId != null) {
      event.addProp('user_id', userId);
    }

    return buffer.add(event);
  }

  /// Log many events
  Future<void> logBulkEvent(List<Map<String, dynamic>> events) async {
    if (config.optOut) {
      return;
    }

    // Optimized: Pre-fetch common properties once
    final Map<String, String> advertisingValues =
        _cachedAdvertisingInfo ?? deviceInfo.getAdvertisingInfo();
    final platformInfo =
        _cachedPlatformInfo ?? await deviceInfo.getPlatformInfo();
    final sessionId = session.getSessionId();

    // Optimized: Build common properties map once
    final commonProps = <String, dynamic>{
      'api_properties': advertisingValues,
      ...?platformInfo,
    };
    if (userId != null) {
      commonProps['user_id'] = userId;
    }

    // Optimized: Create events with properties in single pass
    final eventsList = List<Event>.generate(
      events.length,
      (i) {
        final eventData = events[i];
        final event = enableUuid
            ? Event.uuid(
                eventData['name'],
                sessionId: sessionId,
                props: eventData['properties'],
              )
            : Event.noUuid(
                eventData['name'],
                sessionId: sessionId,
                props: eventData['properties'],
              );
        event.addProps(commonProps);
        return event;
      },
      growable: false,
    );

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
    enableUuid = config.enableUuid;
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
