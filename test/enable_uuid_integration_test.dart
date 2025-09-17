import 'package:amplitude_flutter/amplitude_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'mock_client.dart';
import 'mock_service_provider.dart';

void main() {
  group('EnableUuid Integration Tests', () {
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
      when(() => session.getSessionId()).thenAnswer((_) => 'session-123');

      client.reset();
    });

    group('End-to-end enableUuid flow', () {
      test(
          'Config(enableUuid: true) -> AmplitudeFlutter -> logEvent includes UUID',
          () async {
        final config = Config(enableUuid: true);
        final amplitude = AmplitudeFlutter.private(provider, config);

        await amplitude.logEvent(name: 'test_event');
        await amplitude.flushEvents();

        expect(client.postCalls.single.single['uuid'], isNotNull);
        expect(client.postCalls.single.single['uuid'], isA<String>());

        final uuidRegex = RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            caseSensitive: false);
        expect(client.postCalls.single.single['uuid'], matches(uuidRegex));
      });

      test(
          'Config(enableUuid: false) -> AmplitudeFlutter -> logEvent excludes UUID',
          () async {
        final config = Config(enableUuid: false);
        final amplitude = AmplitudeFlutter.private(provider, config);

        await amplitude.logEvent(name: 'test_event');
        await amplitude.flushEvents();

        expect(client.postCalls.single.single.containsKey('uuid'), isTrue);
        expect(client.postCalls.single.single['uuid'], isNull);
      });

      test(
          'Default Config() -> AmplitudeFlutter -> logEvent includes UUID by default',
          () async {
        final config = Config(); // Default should have enableUuid: true
        final amplitude = AmplitudeFlutter.private(provider, config);

        await amplitude.logEvent(name: 'test_event');
        await amplitude.flushEvents();

        expect(client.postCalls.single.single['uuid'], isNotNull);
        expect(client.postCalls.single.single['uuid'], isA<String>());
      });
    });

    group('Configuration propagation chain', () {
      test('Config -> ServiceProvider -> Store propagation works correctly',
          () {
        final configWithUuid = Config(enableUuid: true);
        final configWithoutUuid = Config(enableUuid: false);

        final amplitudeWithUuid =
            AmplitudeFlutter.private(provider, configWithUuid);
        final amplitudeWithoutUuid =
            AmplitudeFlutter.private(provider, configWithoutUuid);

        expect(amplitudeWithUuid.config!.enableUuid, isTrue);
        expect(amplitudeWithUuid.enableUuid, isTrue);

        expect(amplitudeWithoutUuid.config!.enableUuid, isFalse);
        expect(amplitudeWithoutUuid.enableUuid, isFalse);
      });
    });

    group('Multiple event scenarios', () {
      test('All events in a session respect enableUuid setting consistently',
          () async {
        final amplitude =
            AmplitudeFlutter.private(provider, Config(enableUuid: true));

        // Log multiple events
        await amplitude.logEvent(name: 'event1');
        await amplitude.logEvent(name: 'event2');
        await amplitude.identify(Identify()..set('prop', 'value'));
        await amplitude.logRevenue(Revenue()..setPrice(9.99));
        await amplitude.flushEvents();

        expect(client.postCalls.single, hasLength(4));

        for (final event in client.postCalls.single) {
          expect(event['uuid'], isNotNull);
          expect(event['uuid'], isA<String>());

          final uuidRegex = RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
              caseSensitive: false);
          expect(event['uuid'], matches(uuidRegex));
        }

        // All UUIDs should be unique
        final uuids = client.postCalls.single.map((e) => e['uuid']).toList();
        expect(uuids.toSet().length, equals(4));
      });

      test('Bulk events respect enableUuid setting', () async {
        final amplitude =
            AmplitudeFlutter.private(provider, Config(enableUuid: false));

        final events = [
          {
            'name': 'bulk1',
            'properties': {'prop1': 'value1'}
          },
          {
            'name': 'bulk2',
            'properties': {'prop2': 'value2'}
          },
          {
            'name': 'bulk3',
            'properties': {'prop3': 'value3'}
          },
        ];

        await amplitude.logBulkEvent(events);
        await amplitude.flushEvents();

        expect(client.postCalls.single, hasLength(3));

        for (final event in client.postCalls.single) {
          expect(event.containsKey('uuid'), isTrue);
          expect(event['uuid'], isNull);
        }
      });
    });

    group('Mixed configuration scenarios', () {
      test(
          'Changing enableUuid between AmplitudeFlutter instances works correctly',
          () async {
        // First instance with UUID enabled
        final amplitude1 =
            AmplitudeFlutter.private(provider, Config(enableUuid: true));
        await amplitude1.logEvent(name: 'event_with_uuid');
        await amplitude1.flushEvents();

        client.reset();

        // Second instance with UUID disabled
        final amplitude2 =
            AmplitudeFlutter.private(provider, Config(enableUuid: false));
        await amplitude2.logEvent(name: 'event_without_uuid');
        await amplitude2.flushEvents();

        expect(client.postCalls.single.single['uuid'], isNull);
      });
    });

    group('Error handling', () {
      test('enableUuid setting does not affect error handling', () async {
        final amplitudeWithUuid = AmplitudeFlutter.private(
            provider, Config(enableUuid: true, optOut: true));
        final amplitudeWithoutUuid = AmplitudeFlutter.private(
            provider, Config(enableUuid: false, optOut: true));

        // Both should not log events when opted out
        await amplitudeWithUuid.logEvent(name: 'test');
        await amplitudeWithoutUuid.logEvent(name: 'test');
        await amplitudeWithUuid.flushEvents();
        await amplitudeWithoutUuid.flushEvents();

        expect(client.postCalls, isEmpty);
      });
    });

    group('Performance considerations', () {
      test('UUID generation does not significantly impact bulk operations',
          () async {
        final amplitude =
            AmplitudeFlutter.private(provider, Config(enableUuid: true));

        final largeEventBatch = List.generate(
            100,
            (index) => {
                  'name': 'bulk_event_$index',
                  'properties': {'index': index, 'batch': 'large'},
                });

        final stopwatch = Stopwatch()..start();
        await amplitude.logBulkEvent(largeEventBatch);
        await amplitude.flushEvents();
        stopwatch.stop();

        expect(client.postCalls.single, hasLength(100));

        // All events should have UUIDs
        for (final event in client.postCalls.single) {
          expect(event['uuid'], isNotNull);
        }

        // All UUIDs should be unique
        final uuids = client.postCalls.single.map((e) => e['uuid']).toSet();
        expect(uuids.length, equals(100));

        // Performance check - should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 seconds max
      });
    });
  });
}
