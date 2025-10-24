import 'dart:async';
import 'dart:math';

import 'package:amplitude_flutter/amplitude_flutter.dart';
import 'package:flutter/foundation.dart';

/// {@template event_buffer}
/// Buffer for storing and flushing events to Amplitude servers.
/// {@endtemplate}
class EventBuffer {
  /// {@macro event_buffer}
  /// Buffer for storing and flushing events to Amplitude servers.
  /// [provider] is the ServiceProvider instance.
  /// [config] is the configuration for the Amplitude SDK.
  EventBuffer(this.provider, this.config)
      : store = provider.store,
        client = provider.client;

  /// Configuration for the Amplitude SDK.
  final Config config;

  /// Service provider for accessing client and storage.
  final ServiceProvider provider;

  /// HTTP client for sending events.
  Client? client;

  /// Local storage datasource for persisting events.
  StorageDatasource<EventEntity>? store;

  Future<void>? _flushFuture;
  Timer? _flushTimer;

  /// Number of events to flush in the next operation
  int? numEvents;

  /// Returns number of events in buffer
  int get length => store?.length ?? 0;

  /// Schedules a periodic timer to flush the buffer
  void _scheduleFlushTimer() {
    if (_flushTimer != null) {
      return;
    }
    _flushTimer = Timer.periodic(
      Duration(seconds: config.flushPeriod),
      (Timer timer) {
        if (length > 0) {
          flush();
        } else {
          timer.cancel();
          _flushTimer = null;
        }
      },
    );
  }

  /// Adds a raw event hash to the buffer
  Future<void> add(EventEntity event) async {
    if (length >= config.maxStoredEvents) {
      debugPrint('Amplitude: Max stored events reached. Drop first event');
      await store!.drop(1);
    }
    await store!.add(event);
    if (length == 1) {
      _scheduleFlushTimer();
    }
    if (length >= config.bufferSize) {
      await flush();
    }
  }

  /// Adds many raw event hash to the buffer
  Future<void> addAll(List<EventEntity> eventsList) async {
    if (eventsList.isEmpty) {
      return;
    }
    final previousLength = length;
    if (length + eventsList.length >= config.maxStoredEvents) {
      final dropCount = length + eventsList.length - config.maxStoredEvents;
      debugPrint(
          'Amplitude: Max stored events reached. Drop first $dropCount events');
      await store!.drop(dropCount);
    }
    await store!.addAll(eventsList);
    if (previousLength == 0 && length > 0) {
      _scheduleFlushTimer();
    }
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
  Future<List<EventEntity>> fetch(int count) async {
    assert(count >= 0);
    final endRange = min(count, store!.length);
    return await store!.fetch(endRange);
  }

  Future<void> _handlePayloadTooLarge(List<int?> eventIds) async {
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

  /// Disposes the buffer and cancels any active timers
  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
  }
}
