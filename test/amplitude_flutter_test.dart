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
    when(() => deviceInfo.getAdvertisingInfo())
        .thenReturn(<String, String>{});
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

  group('enableUuid configuration', () {
    group('when enableUuid is true (default)', () {
      test('logEvent creates events with UUIDs', () async {
        amplitude =
            AmplitudeFlutter.private(provider, Config(enableUuid: true));
        await amplitude.logEvent(name: 'test');
        await amplitude.flushEvents();

        expect(client.postCalls.single.single['uuid'], isNotNull);
        expect(client.postCalls.single.single['uuid'], isA<String>());

        final uuidRegex = RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            caseSensitive: false);
        expect(client.postCalls.single.single['uuid'], matches(uuidRegex));
      });

      test('logBulkEvent creates events with UUIDs', () async {
        amplitude =
            AmplitudeFlutter.private(provider, Config(enableUuid: true));
        final events = [
          {
            'name': 'test1',
            'properties': {'prop1': 'value1'}
          },
          {
            'name': 'test2',
            'properties': {'prop2': 'value2'}
          },
        ];

        await amplitude.logBulkEvent(events);
        await amplitude.flushEvents();

        expect(client.postCalls.single, hasLength(2));

        for (final event in client.postCalls.single) {
          expect(event['uuid'], isNotNull);
          expect(event['uuid'], isA<String>());

          final uuidRegex = RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
              caseSensitive: false);
          expect(event['uuid'], matches(uuidRegex));
        }

        expect(client.postCalls.single[0]['uuid'],
            isNot(equals(client.postCalls.single[1]['uuid'])));
      });

      test('identify events include UUIDs', () async {
        amplitude =
            AmplitudeFlutter.private(provider, Config(enableUuid: true));
        await amplitude.identify(Identify()..set('cohort', 'test'));
        await amplitude.flushEvents();

        expect(client.postCalls.single.single['uuid'], isNotNull);
        expect(client.postCalls.single.single['uuid'], isA<String>());
      });

      test('revenue events include UUIDs', () async {
        amplitude =
            AmplitudeFlutter.private(provider, Config(enableUuid: true));
        final revenue = Revenue()
          ..setPrice(10.99)
          ..setQuantity(2);
        await amplitude.logRevenue(revenue);
        await amplitude.flushEvents();

        expect(client.postCalls.single.single['uuid'], isNotNull);
        expect(client.postCalls.single.single['uuid'], isA<String>());
      });
    });

    group('when enableUuid is false', () {
      test('logEvent creates events without UUIDs', () async {
        amplitude =
            AmplitudeFlutter.private(provider, Config(enableUuid: false));
        await amplitude.logEvent(name: 'test');
        await amplitude.flushEvents();

        expect(client.postCalls.single.single.containsKey('uuid'), isTrue);
        expect(client.postCalls.single.single['uuid'], isNull);
      });

      test('logBulkEvent creates events without UUIDs', () async {
        amplitude =
            AmplitudeFlutter.private(provider, Config(enableUuid: false));
        final events = [
          {
            'name': 'test1',
            'properties': {'prop1': 'value1'}
          },
          {
            'name': 'test2',
            'properties': {'prop2': 'value2'}
          },
        ];

        await amplitude.logBulkEvent(events);
        await amplitude.flushEvents();

        expect(client.postCalls.single, hasLength(2));

        for (final event in client.postCalls.single) {
          expect(event.containsKey('uuid'), isTrue);
          expect(event['uuid'], isNull);
        }
      });

      test('identify events do not include UUIDs', () async {
        amplitude =
            AmplitudeFlutter.private(provider, Config(enableUuid: false));
        await amplitude.identify(Identify()..set('cohort', 'test'));
        await amplitude.flushEvents();

        expect(client.postCalls.single.single.containsKey('uuid'), isTrue);
        expect(client.postCalls.single.single['uuid'], isNull);
      });

      test('revenue events do not include UUIDs', () async {
        amplitude =
            AmplitudeFlutter.private(provider, Config(enableUuid: false));
        final revenue = Revenue()
          ..setPrice(10.99)
          ..setQuantity(2);
        await amplitude.logRevenue(revenue);
        await amplitude.flushEvents();

        expect(client.postCalls.single.single.containsKey('uuid'), isTrue);
        expect(client.postCalls.single.single['uuid'], isNull);
      });
    });

    group('enableUuid configuration propagation', () {
      test('config enableUuid propagates to AmplitudeFlutter instance', () {
        final configWithUuid = Config(enableUuid: true);
        final amplitudeWithUuid =
            AmplitudeFlutter.private(provider, configWithUuid);
        expect(amplitudeWithUuid.enableUuid, isTrue);

        final configWithoutUuid = Config(enableUuid: false);
        final amplitudeWithoutUuid =
            AmplitudeFlutter.private(provider, configWithoutUuid);
        expect(amplitudeWithoutUuid.enableUuid, isFalse);
      });

      test('default config has enableUuid set to true', () {
        final defaultConfig = Config();
        expect(defaultConfig.enableUuid, isTrue);
      });
    });
  });
}
