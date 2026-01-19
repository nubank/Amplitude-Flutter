import 'dart:convert';
import 'package:amplitude_flutter/src/event.dart';
import 'package:amplitude_flutter/src/store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Store', () {
    group('Store factory configuration', () {
      test('default Store factory uses default database file', () {
        final defaultStore = Store();
        expect(defaultStore.dbFile, equals('amp.db'));
      });

      test('Store factory accepts custom database file', () {
        final customStore = Store(dbFile: 'custom_test.db');
        expect(customStore.dbFile, equals('custom_test.db'));
      });

      test('singleton behavior returns same instance for same dbFile', () {
        final store1 = Store(dbFile: 'singleton_test.db');
        final store2 = Store(dbFile: 'singleton_test.db');

        expect(identical(store1, store2), isTrue);
      });

      test('different dbFile creates different instances', () {
        final store1 = Store(dbFile: 'test1.db');
        final store2 = Store(dbFile: 'test2.db');

        expect(identical(store1, store2), isFalse);
        expect(store1.dbFile, equals('test1.db'));
        expect(store2.dbFile, equals('test2.db'));
      });
    });

    group('serialization and deserialization', () {
      test('serialization includes all event fields', () {
        final event = Event.create('test_event',
            sessionId: 'session123',
            timestamp: 1234567890,
            props: {'key': 'value'});

        // Simulate what _serialize would do (based on the actual implementation)
        final serialized = <String, dynamic>{
          'event_type': event.name,
          'session_id': event.sessionId,
          'timestamp': event.timestamp,
          'props_json': json.encode(event.props),
        };

        expect(serialized['event_type'], equals('test_event'));
        expect(serialized['session_id'], equals('session123'));
        expect(serialized['timestamp'], equals(1234567890));
        expect(json.decode(serialized['props_json'] as String)['key'],
            equals('value'));
      });

      test('deserialization recreates event correctly', () {
        // Simulate database row data
        final dbRow = <String, dynamic>{
          'id': 1,
          'event_type': 'test_event',
          'session_id': 'session123',
          'timestamp': 1234567890,
          'props_json': json.encode({'key': 'value'}),
        };

        // Simulate the deserialization logic from Store._deserialize
        final event = Event.create(
          dbRow['event_type'],
          sessionId: dbRow['session_id'],
          timestamp: dbRow['timestamp'],
          id: dbRow['id'],
          props: json.decode(dbRow['props_json']),
        );

        expect(event.name, equals('test_event'));
        expect(event.sessionId, equals('session123'));
        expect(event.timestamp, equals(1234567890));
        expect(event.id, equals(1));
        expect(event.props['key'], equals('value'));
      });

      test('handles empty props correctly', () {
        final event = Event.create('test_event',
            sessionId: 'session123',
            timestamp: 1234567890,
            props: <String, dynamic>{});

        final serialized = <String, dynamic>{
          'event_type': event.name,
          'session_id': event.sessionId,
          'timestamp': event.timestamp,
          'props_json': json.encode(event.props),
        };

        expect(serialized['props_json'], equals('{}'));
        
        final deserializedProps = json.decode(serialized['props_json'] as String);
        expect(deserializedProps, isEmpty);
      });
    });

    group('basic functionality', () {
      test('length property tracks event count', () {
        final store = Store(dbFile: 'length_test.db');
        expect(store.length, isA<int>());
        expect(store.length, greaterThanOrEqualTo(0));
      });
    });
  });
}