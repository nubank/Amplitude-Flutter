import 'constants.dart';

class Event {
  Event._(
    this.name, {
    this.sessionId,
    this.timestamp,
    this.id,
    Map<String, dynamic>? props,
  }) {
    addProps(props);
  }

  /// Factory method that creates an Event without a UUID
  factory Event.create(
    String name, {
    String? sessionId,
    int? timestamp,
    int? id,
    Map<String, dynamic>? props,
  }) {
    return Event._(
      name,
      sessionId: sessionId,
      timestamp: timestamp,
      id: id,
      props: props,
    );
  }

  int? id;
  String? sessionId;
  int? timestamp;
  String? name;
  Map<String, dynamic> props = <String, dynamic>{};
  String? uuid;

  void addProps(Map<String, dynamic>? props) {
    if (props != null) {
      this.props.addAll(props);
    }
  }

  void addProp(String key, dynamic value) {
    props[key] = value;
  }

  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      'event_id': id,
      'event_type': name,
      'session_id': sessionId,
      'timestamp': timestamp,
      'uuid': uuid,
      'library': {
        'name': Constants.packageName,
        'version': Constants.packageVersion,
      },
    }..addAll(props);
  }
}
