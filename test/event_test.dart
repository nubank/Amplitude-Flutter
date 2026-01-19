import 'package:amplitude_flutter/src/event.dart';
import 'package:flutter_test/flutter_test.dart';

import 'matchers.dart';

void main() {
  group('Event', () {
    late Event subject;

    setUp(() {
      subject = Event.create('Event Unit Test');
    });

    group('Event.create factory', () {
      test('creates event with basic properties', () {
        final event = Event.create('test');
        expect(event.name, equals('test'));
      });

      test('creates event with all properties', () {
        final event = Event.create('test',
            sessionId: 'session123',
            timestamp: 1234567890,
            id: 42,
            props: {'custom': 'value'});

        expect(event.name, equals('test'));
        expect(event.sessionId, equals('session123'));
        expect(event.timestamp, equals(1234567890));
        expect(event.id, equals(42));
        expect(event.props['custom'], equals('value'));
      });

      test('does not include UUID in toPayload output', () {
        final event = Event.create('test');
        final payload = event.toPayload();
        expect(payload.containsKey('uuid'), isFalse);
      });
    });

    group('default constructor', () {
      test('adds the passed props if any', () {
        expect(subject.props, isEmpty);

        subject = Event.create('some props',
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
        subject = Event.create('click',
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
              'library': isNotNull
            }));
      });

      test('includes all required fields in payload', () {
        final event = Event.create('test_event',
            sessionId: 'session123',
            timestamp: 1234567890,
            id: 42);

        final payload = event.toPayload();

        expect(payload['event_id'], equals(42));
        expect(payload['event_type'], equals('test_event'));
        expect(payload['session_id'], equals('session123'));
        expect(payload['timestamp'], equals(1234567890));
        expect(payload.containsKey('uuid'), isFalse);
        expect(payload['library'], isNotNull);
        expect(payload['library']['name'], isNotNull);
        expect(payload['library']['version'], isNotNull);
      });
    });

  });
}