import 'dart:convert';

import 'package:amplitude_flutter/amplitude_flutter.dart';

@Entity()
final class EventEntity {
  EventEntity({
    this.id = 0,
    required this.name,
    this.propertiesJson,
    DateTime? createdAt,
    DateTime? sessionId,
  })  : createdAt = createdAt ?? DateTime.now(),
        sessionId = sessionId ?? DateTime.now();

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

extension EventEntityExtensions on EventEntity {
  Map<String, dynamic> toPayload() {
    return {
      'event_id': id,
      'event_type': name,
      'timestamp': createdAt.toIso8601String(),
      'session_id': sessionId.toIso8601String(),
    }..addAll(properties ?? {});
  }

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
