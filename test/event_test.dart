import 'package:amplitude_flutter/src/event.dart';
import 'package:flutter_test/flutter_test.dart';

import 'matchers.dart';

void main() {
  group('Event', () {
    late Event subject;

    setUp(() {
      subject = Event.uuid('Event Unit Test');
    });

    group('enableUuid logic', () {
      group('Event.uuid factory', () {
        test('generates a UUID', () {
          final event = Event.uuid('test');
          expect(event.uuid, isNotNull);
        });

        test('generates a valid v4 UUID format', () {
          final event = Event.uuid('test');
          final uuidRegex = RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
              caseSensitive: false);
          expect(event.uuid, matches(uuidRegex));
        });

        test('generates unique UUIDs for different events', () {
          final event1 = Event.uuid('test1');
          final event2 = Event.uuid('test2');
          expect(event1.uuid, isNotNull);
          expect(event2.uuid, isNotNull);
          expect(event1.uuid, isNot(equals(event2.uuid)));
        });

        test('includes UUID in toPayload output', () {
          final event = Event.uuid('test');
          final payload = event.toPayload();
          expect(payload['uuid'], isNotNull);
          expect(payload['uuid'], equals(event.uuid));
        });

        test('preserves all other properties while adding UUID', () {
          final event = Event.uuid('test',
              sessionId: 'session123',
              timestamp: 1234567890,
              id: 42,
              props: {'custom': 'value'});

          expect(event.name, equals('test'));
          expect(event.sessionId, equals('session123'));
          expect(event.timestamp, equals(1234567890));
          expect(event.id, equals(42));
          expect(event.props['custom'], equals('value'));
          expect(event.uuid, isNotNull);
        });
      });

      group('Event.noUuid factory', () {
        test('does not generate a UUID', () {
          final event = Event.noUuid('test');
          expect(event.uuid, isNull);
        });

        test('includes null UUID in toPayload output', () {
          final event = Event.noUuid('test');
          final payload = event.toPayload();
          expect(payload.containsKey('uuid'), isTrue);
          expect(payload['uuid'], isNull);
        });

        test('preserves all other properties without UUID', () {
          final event = Event.noUuid('test',
              sessionId: 'session123',
              timestamp: 1234567890,
              id: 42,
              props: {'custom': 'value'});

          expect(event.name, equals('test'));
          expect(event.sessionId, equals('session123'));
          expect(event.timestamp, equals(1234567890));
          expect(event.id, equals(42));
          expect(event.props['custom'], equals('value'));
          expect(event.uuid, isNull);
        });
      });

      group('UUID persistence', () {
        test('UUID remains constant after creation', () {
          final event = Event.uuid('test');
          final originalUuid = event.uuid;

          event.addProp('newProp', 'newValue');
          event.addProps({'anotherProp': 'anotherValue'});
          final payload1 = event.toPayload();
          final payload2 = event.toPayload();

          expect(event.uuid, equals(originalUuid));
          expect(payload1['uuid'], equals(originalUuid));
          expect(payload2['uuid'], equals(originalUuid));
        });

        test('UUID can be manually set to null', () {
          final event = Event.uuid('test');
          expect(event.uuid, isNotNull);

          event.uuid = null;
          expect(event.uuid, isNull);

          final payload = event.toPayload();
          expect(payload['uuid'], isNull);
        });

        test('UUID can be manually overridden', () {
          final event = Event.uuid('test');
          final originalUuid = event.uuid;

          const customUuid = 'custom-uuid-value';
          event.uuid = customUuid;

          expect(event.uuid, equals(customUuid));
          expect(event.uuid, isNot(equals(originalUuid)));

          final payload = event.toPayload();
          expect(payload['uuid'], equals(customUuid));
        });
      });
    });

    group('default constructor', () {
      test('adds the passed props if any', () {
        expect(subject.props, isEmpty);

        subject = Event.uuid('some props',
            props: <String, dynamic>{'cohort': 'test a'});

        expect(subject.props, containsPair('cohort', 'test a'));
      });
    });

    group('.addProps', () {
      setUp(() {
        subject.addProps(<String, dynamic>{'preexisting': 'data'});
        expect(subject.props, hasLength(1));
      });

      test('handles null props', () {
        subject.addProps(null);
        expect(subject.props, hasLength(1));
      });

      test('adds to existing props', () {
        subject.addProps(<String, dynamic>{'key a': 'value a'});
        expect(subject.props, hasLength(2));

        subject.addProps(<String, dynamic>{'key b': 'value b'});
        expect(subject.props, hasLength(3));

        expect(
            subject.props,
            equals(<String, dynamic>{
              'preexisting': 'data',
              'key a': 'value a',
              'key b': 'value b'
            }));
      });
    });

    group('.addProp', () {
      setUp(() {
        subject.addProps(<String, dynamic>{'preexisting': 'data'});
        expect(subject.props, hasLength(1));
      });

      test('adds a property to existing props', () {
        subject.addProp('key a', 'value a');
        expect(subject.props, hasLength(2));

        subject.addProp('key b', 'value b');
        expect(subject.props, hasLength(3));

        expect(
            subject.props,
            equals(<String, dynamic>{
              'preexisting': 'data',
              'key a': 'value a',
              'key b': 'value b'
            }));
      });
    });

    group('.toPayload', () {
      test('properly formats an API payload', () {
        subject = Event.uuid('click',
            sessionId: '123',
            id: 99,
            props: <String, dynamic>{
              'user_properties': {'cohort': 'test a'}
            })
          ..timestamp = 12345;

        expect(
            subject.toPayload(),
            ContainsSubMap(<String, dynamic>{
              'event_id': 99,
              'event_type': 'click',
              'session_id': '123',
              'timestamp': 12345,
              'user_properties': {'cohort': 'test a'},
              'uuid': isNotNull,
              'library': isNotNull
            }));
      });
    });
  });
}
