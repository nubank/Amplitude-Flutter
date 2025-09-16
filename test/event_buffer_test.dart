import 'package:amplitude_flutter/src/client.dart';
import 'package:amplitude_flutter/src/config.dart';
import 'package:amplitude_flutter/src/event.dart';
import 'package:amplitude_flutter/src/event_buffer.dart';
import 'package:amplitude_flutter/src/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'matchers.dart';
import 'mock_client.dart';
import 'mock_service_provider.dart';

class MockitoClient extends Mock implements Client {}

class MockitoStore extends Mock implements Store {}

void main() {
  group('EventBuffer', () {
    late MockServiceProvider provider;
    late MockClient client;

    late EventBuffer subject;

    setUp(() {
      provider = MockServiceProvider();
      client = provider.client as MockClient;
      subject = EventBuffer(provider, Config());
    });

    group('.length', () {
      test('returns the length of events in the store', () async {
        expect(subject.length, equals(0));

        await subject.add(Event.uuid('event 1'));
        expect(subject.length, equals(1));

        await subject.add(Event.uuid('event 2'));
        expect(subject.length, equals(2));
      });
    });

    group('.add', () {
      test('adds an event to the store, and adds a timestamp property',
          () async {
        await subject.add(Event.uuid('event 1'));
        expect(subject.length, equals(1));

        final List<Event> events = await subject.fetch(1);
        final Event event = events[0];

        expect(event.timestamp, isInstanceOf<int>());
      });

      test('flushes the buffer when the buffer size is reached', () async {
        subject = EventBuffer(provider, Config(bufferSize: 2));

        await subject.add(Event.uuid('flush test'));
        expect(client.postCallCount, equals(0));

        await subject.add(Event.uuid('event 2'));
        expect(client.postCallCount, equals(1));
        expect(subject.length, equals(2));

        expect(
            client.postCalls.single.first,
            ContainsSubMap(<String, dynamic>{
              'event_type': 'flush test',
              'timestamp': isInstanceOf<int>()
            }));
        expect(client.postCalls.single, isList);
      });

      test('limits number of events added to the store', () async {
        // Have the client return an unhandled status code so the store doesn't get cleared
        provider.client = MockClient(httpStatus: 218);
        subject =
            EventBuffer(provider, Config(bufferSize: 1, maxStoredEvents: 2));

        await subject.add(Event.uuid('test 1'));
        await subject.add(Event.uuid('test 2'));
        expect(subject.length, equals(2));

        await subject.add(Event.uuid('test 3'));
        expect(subject.length, equals(2));
      });
    });

    group('.addAll', () {
      test('adds many events to the store, and adds a timestamp property',
          () async {
        await subject.addAll([
          Event.uuid('event 1'),
          Event.uuid('event 2'),
          Event.uuid('event 3'),
        ]);
        expect(subject.length, equals(3));

        final List<Event> events = await subject.fetch(3);

        for (final Event event in events) {
          expect(event.timestamp, isInstanceOf<int>());
        }
      });

      test('limits number of events added to the store', () async {
        // Have the client return an unhandled status code so the store doesn't get cleared
        provider.client = MockClient(httpStatus: 218);
        subject = EventBuffer(
            provider,
            Config(
              bufferSize: 1,
              maxStoredEvents: 3,
            ));

        await subject.addAll([
          Event.uuid('test 1'),
          Event.uuid('test 2'),
        ]);
        expect(subject.length, equals(2));

        await subject.addAll([
          Event.uuid('test 3'),
          Event.uuid('test 4'),
        ]);
        expect(subject.length, equals(3));

        await subject.addAll([
          Event.uuid('test 5'),
          Event.uuid('test 6'),
        ]);
        expect(subject.length, equals(3));
      });
    });

    group('.fetch', () {
      test('returns a specified number of the oldest events in the store',
          () async {
        expect(subject.length, equals(0));

        await subject.add(Event.uuid('event 1'));
        await subject.add(Event.uuid('event 2'));
        await subject.add(Event.uuid('event 3'));
        expect(subject.length, equals(3));

        final List<Event> firstTwoEvents = await subject.fetch(2);
        expect(firstTwoEvents.length, equals(2));
        expect(firstTwoEvents[0].name, equals('event 1'));
        expect(firstTwoEvents[1].name, equals('event 2'));

        final List<Event> lastEvent = await subject.fetch(1);
        expect(lastEvent.length, equals(1));
        expect(lastEvent[0].name, equals('event 1'));

        expect(subject.length, equals(3));
      });

      test('works with numbers greater than the event count', () async {
        await subject.add(Event.uuid('event 1'));
        await subject.add(Event.uuid('event 2'));
        expect(subject.length, equals(2));

        final List<Event> poppedEvents = await subject.fetch(100);
        expect(poppedEvents.length, equals(2));
      });
    });

    group('.flush', () {
      late Client mockClient;
      late Store mockStore;

      setUp(() {
        mockClient = MockitoClient();
        mockStore = MockitoStore();
        provider = MockServiceProvider(client: mockClient, store: mockStore);
        subject = EventBuffer(provider, Config());

        final events = [
          Event.uuid('flush 1', id: 1),
          Event.uuid('flush 2', id: 2),
          Event.uuid('flush 3', id: 3)
        ];

        when(() => mockStore.length).thenReturn(events.length);
        when(() => mockStore.fetch(any()))
            .thenAnswer((_) => Future.value(events));
      });

      test('deletes events on success', () async {
        when(() => mockStore.delete(any())).thenAnswer((_) => Future.value());
        when(() => mockClient.post(any())).thenAnswer((_) => Future.value(200));

        await subject.flush();

        verify(() => mockClient.post(any())).called(1);
        verify(() => mockStore.delete([1, 2, 3])).called(1);
      });

      test('does not delete events on failure', () async {
        when(() => mockClient.post(any())).thenAnswer((_) => Future.value(400));

        await subject.flush();

        verify(() => mockClient.post(any())).called(1);
        verifyNever(() => mockStore.delete(any()));
      });

      test('reduces num events when payload too large', () async {
        when(() => mockStore.delete(any())).thenAnswer((_) => Future.value());
        when(() => mockClient.post(any())).thenAnswer((_) => Future.value(413));
        expect(subject.numEvents, equals(null));

        await subject.flush();

        verify(() => mockClient.post(any())).called(1);
        verifyNever(() => mockStore.delete(any()));
        expect(subject.numEvents, equals(1));

        when(() => mockClient.post(any())).thenAnswer((_) => Future.value(200));

        await subject.flush();
        verify(() => mockStore.delete(any())).called(1);
        expect(subject.numEvents, equals(null));
      });

      test('drops an event if it is too large', () async {
        when(() => mockStore.delete(any())).thenAnswer((_) => Future.value());
        when(() => mockClient.post(any())).thenAnswer((_) => Future.value(413));
        subject.numEvents = 1;
        final event = Event.uuid('massive event', id: 99);
        when(() => mockStore.fetch(any()))
            .thenAnswer((_) => Future.value([event]));

        await subject.flush();

        verify(() => mockStore.delete([99])).called(1);
        expect(subject.numEvents, equals(null));
      });
    });
  });
}
