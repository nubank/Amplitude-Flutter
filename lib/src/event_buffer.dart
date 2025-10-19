import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'client.dart';
import 'config.dart';
import 'event.dart';
import 'service_provider.dart';
import 'store.dart';
import 'time_utils.dart';

class EventBuffer {
  EventBuffer(this.provider, this.config) {
    client = provider.client;
    store = provider.store;

    _flushTimer = Timer.periodic(
      Duration(seconds: config.flushPeriod),
      (Timer _t) => flush(),
    );
  }

  final Config config;
  final ServiceProvider provider;
  Client? client;
  Store? store;

  Future<void>? _flushFuture;
  Timer? _flushTimer;
  int? numEvents;

  /// Returns number of events in buffer
  int get length => store?.length ?? 0;

  /// Adds a raw event hash to the buffer
  Future<void> add(Event event) async {
    if (length >= config.maxStoredEvents) {
      print('Max stored events reached.  Drop first event');
      await store!.drop(1);
    }

    event.timestamp = currentTime();
    await store!.add(event);

    if (length >= config.bufferSize) {
      await flush();
    }
  }

  /// Adds many raw event hash to the buffer
  Future<void> addAll(List<Event> eventsList) {
    if (eventsList.isEmpty) {
      return Future.value();
    }

    if (length + eventsList.length >= config.maxStoredEvents) {
      final dropCount = length + eventsList.length - config.maxStoredEvents;
      print('Max stored events reached.  Drop first $dropCount events');
      store!.drop(dropCount);
    }

    final events = eventsList.map((e) {
      e.timestamp = currentTime();
      return e;
    }).toList();
    return store!.addAll(events);
  }

  /// Flushes all events in buffer
  Future<void> flush() async {
    if (_flushFuture != null) {
      return _flushFuture;
    }
    if (length < 1) {
      return;
    }

    _flushFuture = _performFlush();
    try {
      await _flushFuture;
    } finally {
      _flushFuture = null;
    }
  }

  Future<void> _performFlush() async {
    numEvents ??= length;
    final events = await fetch(numEvents!);
    final List<Map<String, dynamic>> payload =
        events.map((e) => e.toPayload()).toList();
    final eventIds = events.map((e) => e.id).toList();

    final status = await client!.post(payload);
    switch (status) {
      case 200:
        await _deleteEvents(eventIds);
        break;
      case 413:
        await _handlePayloadTooLarge(eventIds);
        break;
      default:
      // error
    }
  }

  @visibleForTesting
  Future<List<Event>> fetch(int count) async {
    assert(count >= 0);

    final endRange = min(count, store!.length);
    return await store!.fetch(endRange);
  }

  Future<void> _handlePayloadTooLarge(List<int?> eventIds) async {
    // drop a single event that is too large
    if (eventIds.length == 1) {
      await _deleteEvents(eventIds);
    } else {
      numEvents = numEvents! ~/ 2;
    }
  }

  Future<void> _deleteEvents(List<int?> eventIds) async {
    await store!.delete(eventIds);
    numEvents = null;
  }

  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
  }
}
