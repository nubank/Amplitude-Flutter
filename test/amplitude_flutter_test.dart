import 'package:amplitude_flutter/amplitude_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'matchers.dart';
import 'mock_client.dart';
import 'mock_service_provider.dart';

void main() {
  late AmplitudeFlutter amplitude;

  late MockClient client;
  late MockDeviceInfo deviceInfo;
  late MockSession session;
  late MockServiceProvider provider;

  setUp(() {
    provider = MockServiceProvider();
    client = provider.client as MockClient;
    deviceInfo = provider.deviceInfo as MockDeviceInfo;
    session = provider.session as MockSession;

    when(() => deviceInfo.getPlatformInfo()).thenAnswer(
        (_) => Future<Map<String, String>>.value({'platform': 'iOS'}));
    when(() => deviceInfo.getAdvertisingInfo()).thenAnswer(
        (_) => Future<Map<String, String>>.value(<String, String>{}));
    when(() => session.getSessionId()).thenAnswer((_) => '123');

    client.reset();

    amplitude = AmplitudeFlutter.private(provider, Config());
  });

  test('logEvent', () async {
    await amplitude.logEvent(name: 'test');
    await amplitude.flushEvents();

    expect(
        client.postCalls.single.single,
        ContainsSubMap(<String, dynamic>{
          'event_type': 'test',
          'session_id': '123',
          'platform': 'iOS',
          'timestamp': isInstanceOf<int>()
        }));
  });

  test('logBulkEvent', () async {
    final List<Map<String, dynamic>> events = [
      {
        'name': 'test1',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'properties': {'property-1': 'value-1', 'property-2': 'value-2'},
      },
      {
        'name': 'test2',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'properties': {'property-3': 'value-3', 'property-4': 'value-4'},
      }
    ];

    await amplitude.logBulkEvent(events);
    await amplitude.flushEvents();

    expect(2, client.postCalls.single.length);

    expect(
        client.postCalls.single[0],
        ContainsSubMap(<String, dynamic>{
          'event_type': 'test1',
          'session_id': '123',
          'platform': 'iOS',
          'timestamp': isInstanceOf<int>(),
          'property-1': 'value-1',
          'property-2': 'value-2',
        }));

    expect(
        client.postCalls.single[1],
        ContainsSubMap(<String, dynamic>{
          'event_type': 'test2',
          'session_id': '123',
          'platform': 'iOS',
          'timestamp': isInstanceOf<int>(),
          'property-3': 'value-3',
          'property-4': 'value-4',
        }));
  });

  test('identify', () async {
    await amplitude.identify(Identify()..set('cohort', 'test a'));
    await amplitude.flushEvents();

    expect(
        client.postCalls.single.single,
        ContainsSubMap(<String, dynamic>{
          'event_type': r'$identify',
          'session_id': '123',
          'user_properties': {
            r'$set': {'cohort': 'test a'}
          },
          'platform': 'iOS',
          'timestamp': isInstanceOf<int>()
        }));
  });

  test('setUser', () async {
    amplitude.setUserId('user-123');
    await amplitude.logEvent(name: 'test');
    await amplitude.flushEvents();

    expect(
        client.postCalls.single.single,
        ContainsSubMap(<String, dynamic>{
          'event_type': 'test',
          'session_id': '123',
          'user_id': 'user-123',
          'platform': 'iOS',
          'timestamp': isInstanceOf<int>()
        }));
  });

  test('groupIdentify', () async {
    await amplitude.groupIdentify(
        'orgId', 15, Identify()..set('num employees', '1000+'));
    await amplitude.flushEvents();

    expect(
        client.postCalls.single.single,
        ContainsSubMap(<String, dynamic>{
          'event_type': r'$groupidentify',
          'session_id': '123',
          'group_properties': {
            r'$set': {'num employees': '1000+'}
          },
          'groups': {'orgId': 15},
          'platform': 'iOS',
          'timestamp': isInstanceOf<int>()
        }));
  });

  test('setGroup', () async {
    await amplitude.setGroup('orgId', 15);
    await amplitude.flushEvents();

    expect(
        client.postCalls.single.single,
        ContainsSubMap(<String, dynamic>{
          'event_type': r'$identify',
          'session_id': '123',
          'user_properties': {
            r'$set': {'orgId': 15}
          },
          'groups': {'orgId': 15},
          'platform': 'iOS',
          'timestamp': isInstanceOf<int>()
        }));
  });

  group('with properties', () {
    test('logEvent', () async {
      final Map<String, Map<String, String>> properties =
          <String, Map<String, String>>{
        'user_properties': <String, String>{
          'first_name': 'Joe',
          'last_name': 'Sample'
        }
      };
      await amplitude.logEvent(name: 'test', properties: properties);
      await amplitude.flushEvents();

      expect(
          client.postCalls.single.single,
          ContainsSubMap(<String, dynamic>{
            'event_type': 'test',
            'session_id': '123',
            'user_properties': {'first_name': 'Joe', 'last_name': 'Sample'},
            'platform': 'iOS',
            'timestamp': isInstanceOf<int>()
          }));
    });
  });

  test('revenue', () async {
    final revenue = Revenue()
      ..setPrice(43.43)
      ..setQuantity(3);
    await amplitude.logRevenue(revenue);
    await amplitude.flushEvents();

    expect(
        client.postCalls.single.single,
        ContainsSubMap(<String, dynamic>{
          'event_type': 'revenue_amount',
          'event_properties': {r'$price': 43.43, r'$quantity': 3}
        }));
  });

  group('when the user opts out of events', () {
    test('does not log events', () async {
      amplitude = AmplitudeFlutter.private(provider, Config(optOut: true));
      await amplitude.logEvent(name: 'test');
      await amplitude.flushEvents();

      expect(client.postCalls, isEmpty);
    });
  });
}
