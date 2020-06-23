import 'dart:async';

import 'package:flutter/foundation.dart';

import 'config.dart';
import 'device_info.dart';
import 'event.dart';
import 'event_buffer.dart';
import 'identify.dart';
import 'revenue.dart';
import 'service_provider.dart';
import 'session.dart';

class AmplitudeFlutter {
  AmplitudeFlutter(String apiKey, [this.config]) {
    config ??= Config();
    provider = ServiceProvider(
        apiKey: apiKey,
        timeout: config.sessionTimeout,
        getCarrierInfo: config.getCarrierInfo);
    _init();
  }

  AmplitudeFlutter.private(this.provider, this.config) {
    _init();
  }

  bool getCarrierInfo;
  Config config;
  ServiceProvider provider;
  DeviceInfo deviceInfo;
  Session session;
  EventBuffer buffer;
  dynamic userId;

  /// Set the user id associated with events
  Future<void> setUserId(dynamic userId) async {
    this.userId = userId;
    session.userId = userId;
  }

  /// Log an event
  Future<void> logEvent(
      {@required String name,
      Map<String, dynamic> properties = const <String, String>{}}) async {
    await session.refresh();

    if (config.optOut) {
      return Future.value(null);
    }

    final Event event =
        Event(name, sessionId: session.getSessionId(), props: properties)
          ..addProps(await deviceInfo.getPlatformInfo());

    if (userId != null) {
      event.addProp('user_id', userId);
    }

    return buffer.add(event);
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
          name: Revenue.EVENT,
          properties: <String, dynamic>{'event_properties': revenue.payload});
    }
  }

  /// Manually flush events in the buffer
  Future<void> flushEvents() => buffer.flush();

  void _init() {
    deviceInfo = provider.deviceInfo;
    session = provider.session;
    buffer = EventBuffer(provider, config);

    session.start();
  }
}
