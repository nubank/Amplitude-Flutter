import 'dart:convert';

import 'package:amplitude_flutter/amplitude_flutter.dart';

@Entity()

/// {@template EventEntity}
/// EventEntity is a class that represents an event stored in the local
/// database using ObjectBox. It includes fields for the event's ID, name,
/// properties (as a JSON string), creation timestamp, and session ID.
/// It also provides methods to convert between EventEntity and Event objects.
/// {@endtemplate}
final class EventEntity {
  /// {@macro EventEntity}
  /// [id] is the unique identifier for the event.
  /// [name] is the name of the event.
  /// [propertiesJson] is the JSON string representation of the event's properties.
  /// [createdAt] is the timestamp when the event was created.
  /// [sessionId] is the session identifier associated with the event.
  EventEntity({
    this.id = 0,
    required this.name,
    this.propertiesJson,
    DateTime? createdAt,
    DateTime? sessionId,
  })  : createdAt = createdAt ?? DateTime.now(),
        sessionId = sessionId ?? DateTime.now();

  /// Creates an EventEntity from an Event.
  factory EventEntity.fromEvent(Event event) {
    return EventEntity(
      name: event.name,
      propertiesJson: event.labels != null ? jsonEncode(event.labels) : null,
    );
  }
  @Id()
  int id;

  String? name;

  String? propertiesJson;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime sessionId;

  /// Converts the EventEntity back to an Event.
  Event toEvent() {
    return Event(
      name ?? '',
      properties: propertiesJson != null && propertiesJson!.isNotEmpty
          ? (jsonDecode(propertiesJson!) as Map<String, dynamic>)
          : null,
    );
  }

  @Transient()
  Map<String, dynamic>? get properties {
    if (propertiesJson == null || propertiesJson!.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(propertiesJson!) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  @Transient()
  set properties(Map<String, dynamic>? value) {
    propertiesJson = value != null ? jsonEncode(value) : null;
  }
}

/// {@template EventEntityExtensions}
/// Extension methods for EventEntity.
/// {@endtemplate}
extension EventEntityExtensions on EventEntity {
  /// Converts the EventEntity to a payload map.
  Map<String, dynamic> toPayload() {
    return {
      'event_id': id,
      'event_type': name,
      'timestamp': createdAt.toIso8601String(),
      'session_id': sessionId.toIso8601String(),
    }..addAll(properties ?? {});
  }

  /// Converts the EventEntity to an Event with metadata.
  Event toEventWithMetadata() {
    final event = toEvent();
    return Event(
      event.name,
      properties: {
        ...?event.labels,
        'event_id': id,
        'session_id': sessionId.toMs(),
        'timestamp': createdAt.toMs(),
      },
    );
  }
}
