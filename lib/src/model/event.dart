part of 'analytics_model.dart';

/// {@template Event}
/// Class representing an analytics event.
/// {@endtemplate}
class Event extends AnalyticsModel {
  /// {@macro Event}
  /// [name] is the name of the event.
  /// [properties] are the optional properties associated with the event.
  const Event(this.name, {Map<String, dynamic>? properties})
      : _properties = properties;

  /// Creates an Event from a JSON map.
  factory Event.fromJson(Map<String, dynamic> json) => Event(
        json['name'] as String,
        properties: json['properties'] as Map<String, dynamic>?,
      );

  @override
  final String name;

  final Map<String, dynamic>? _properties;

  @override
  Map<String, dynamic>? get labels => _properties;

  @override
  Map<String, dynamic> toMap() => {
        '_type': 'event',
        'name': name,
        if (_properties != null) 'properties': _properties,
      };

  @override
  Event withProperties(Map<String, dynamic> properties) => Event(
        name,
        properties: {...?_properties, ...properties},
      );

  @override
  Event copyWith({String? name, Map<String, dynamic>? properties}) => Event(
        name ?? this.name,
        properties: properties ?? _properties,
      );

  @override
  List<Object?> get props => [name, _properties];
}

/// {@template EventExtension}
/// Extension methods for Event.
/// {@endtemplate}
extension EventExtension on Event {
  /// Converts the Event to an EventEntity.
  EventEntity toEntity() {
    return EventEntity.fromEvent(this);
  }
}

// extension EventExtensions on Event {
//   Map<String, dynamic> toPayload() {
//     return <String, dynamic>{
//       'event_id':
//           id, // each event should have a unique id however this id must be unique and based on the installation.
//       // this can be referenced as a sequential id similar to the auto_increment on a database.
//       'event_type': name,
//       'session_id':
//           sessionId, // it's a timestamp when the user start the class. it's in milliseconds. fromEpoch.
//       'timestamp':
//           timestamp, // same format as session_id, but it's only when the event was triggered.
//     }..addAll(properties ?? {});
//   }
// }
