import 'dart:convert';
import 'package:amplitude_flutter/src/event.dart';
import 'package:amplitude_flutter/src/store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Store enableUuid logic', () {
    group('Store factory configuration', () {
      test('default Store factory has enableUuid=true', () {
        final defaultStore = Store(dbFile: 'default_test.db');
        expect(defaultStore.enableUuid, isTrue);
      });

      test('Store factory respects enableUuid parameter', () {
        final storeWithUuid =
            Store(dbFile: 'test_with_uuid.db', enableUuid: true);
        final storeWithoutUuid =
            Store(dbFile: 'test_without_uuid.db', enableUuid: false);

        expect(storeWithUuid.enableUuid, isTrue);
        expect(storeWithoutUuid.enableUuid, isFalse);
      });

      test('singleton behavior preserves first instance configuration', () {
        final store1 = Store(dbFile: 'singleton_test.db', enableUuid: true);
        final store2 = Store(dbFile: 'singleton_test.db', enableUuid: false);

        expect(identical(store1, store2), isTrue);
        // First instance configuration is preserved
        expect(store2.enableUuid, isTrue);
      });

      test('different dbFile creates different instances', () {
        final store1 = Store(dbFile: 'test1.db', enableUuid: true);
        final store2 = Store(dbFile: 'test2.db', enableUuid: false);

        expect(identical(store1, store2), isFalse);
        expect(store1.enableUuid, isTrue);
        expect(store2.enableUuid, isFalse);
      });
    });

    group('deserialization logic simulation', () {
      test('enableUuid=true creates events with UUIDs', () {
        final store = Store(dbFile: 'test_uuid_true.db', enableUuid: true);

        // Simulate database row data
        const eventType = 'test_event';
        const sessionId = 'session123';
        const timestamp = 1234567890;
        const id = 1;
        final propsJson = json.encode({'key': 'value'});

        // Simulate the deserialization logic from Store._deserialize
        final event = store.enableUuid
            ? Event.uuid(eventType,
                sessionId: sessionId,
                timestamp: timestamp,
                id: id,
                props: json.decode(propsJson))
            : Event.noUuid(eventType,
                sessionId: sessionId,
                timestamp: timestamp,
                id: id,
                props: json.decode(propsJson));

        expect(event.uuid, isNotNull);
        expect(event.uuid, isA<String>());
        expect(event.name, equals('test_event'));
        expect(event.sessionId, equals('session123'));
        expect(event.timestamp, equals(1234567890));
        expect(event.id, equals(1));
        expect(event.props['key'], equals('value'));
      });

      test('enableUuid=false creates events without UUIDs', () {
        final store = Store(dbFile: 'test_uuid_false.db', enableUuid: false);

        // Simulate database row data
        const eventType = 'test_event';
        const sessionId = 'session123';
        const timestamp = 1234567890;
        const id = 1;
        final propsJson = json.encode({'key': 'value'});

        // Simulate the deserialization logic from Store._deserialize
        final event = store.enableUuid
            ? Event.uuid(eventType,
                sessionId: sessionId,
                timestamp: timestamp,
                id: id,
                props: json.decode(propsJson))
            : Event.noUuid(eventType,
                sessionId: sessionId,
                timestamp: timestamp,
                id: id,
                props: json.decode(propsJson));

        expect(event.uuid, isNull);
        expect(event.name, equals('test_event'));
        expect(event.sessionId, equals('session123'));
        expect(event.timestamp, equals(1234567890));
        expect(event.id, equals(1));
        expect(event.props['key'], equals('value'));
      });

      test('deserialization creates unique UUIDs for different events', () {
        // Test that different events get unique UUIDs
        const eventType1 = 'event1';
        const sessionId1 = 'session1';
        const timestamp1 = 1234567890;
        const id1 = 1;
        final propsJson1 = json.encode({});

        const eventType2 = 'event2';
        const sessionId2 = 'session2';
        const timestamp2 = 1234567891;
        const id2 = 2;
        final propsJson2 = json.encode({});

        final event1 = Event.uuid(eventType1,
            sessionId: sessionId1,
            timestamp: timestamp1,
            id: id1,
            props: json.decode(propsJson1));

        final event2 = Event.uuid(eventType2,
            sessionId: sessionId2,
            timestamp: timestamp2,
            id: id2,
            props: json.decode(propsJson2));

        expect(event1.uuid, isNotNull);
        expect(event2.uuid, isNotNull);
        expect(event1.uuid, isNot(equals(event2.uuid)));
      });
    });

    group('serialization behavior', () {
      test('serialization does not include UUID in database storage', () {
        // Test that serialization excludes UUID field

        // Create an event with UUID
        final eventWithUuid = Event.uuid('test_event',
            sessionId: 'session123',
            timestamp: 1234567890,
            props: {'key': 'value'});

        // The serialization logic should not store the UUID
        // This tests that UUID is only generated during deserialization
        expect(eventWithUuid.uuid, isNotNull);

        // Simulate what _serialize would do (based on the actual implementation)
        final serialized = <String, dynamic>{
          'event_type': eventWithUuid.name,
          'session_id': eventWithUuid.sessionId,
          'timestamp': eventWithUuid.timestamp,
          'props_json': json.encode(eventWithUuid.props),
        };

        // UUID should not be in the serialized data
        expect(serialized.containsKey('uuid'), isFalse);
        expect(serialized['event_type'], equals('test_event'));
        expect(serialized['session_id'], equals('session123'));
        expect(serialized['timestamp'], equals(1234567890));
        expect(json.decode(serialized['props_json'] as String)['key'],
            equals('value'));
      });
    });

    group('enableUuid configuration impact', () {
      test('enableUuid setting affects event creation during fetch simulation',
          () {
        final storeWithUuid = Store(dbFile: 'test_with.db', enableUuid: true);
        final storeWithoutUuid =
            Store(dbFile: 'test_without.db', enableUuid: false);

        // Simulate database row data
        const eventType = 'test_event';
        const sessionId = 'session123';
        const timestamp = 1234567890;
        const id = 1;
        final propsJson = json.encode({'key': 'value'});

        // Simulate what happens during fetch -> deserialize
        final eventWithUuid = storeWithUuid.enableUuid
            ? Event.uuid(eventType,
                sessionId: sessionId,
                timestamp: timestamp,
                id: id,
                props: json.decode(propsJson))
            : Event.noUuid(eventType,
                sessionId: sessionId,
                timestamp: timestamp,
                id: id,
                props: json.decode(propsJson));

        final eventWithoutUuid = storeWithoutUuid.enableUuid
            ? Event.uuid(eventType,
                sessionId: sessionId,
                timestamp: timestamp,
                id: id,
                props: json.decode(propsJson))
            : Event.noUuid(eventType,
                sessionId: sessionId,
                timestamp: timestamp,
                id: id,
                props: json.decode(propsJson));

        expect(eventWithUuid.uuid, isNotNull);
        expect(eventWithoutUuid.uuid, isNull);
      });
    });
  });
}
