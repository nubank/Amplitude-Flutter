import 'package:uuid/uuid.dart';

import 'constants.dart';

class Event {
  Event(this.name,
      {this.sessionId, this.timestamp, this.id, Map<String, dynamic>? props}) {
    addProps(props);
    uuid = const Uuid().v4();
  }

  final int? id;
  final String? sessionId;
  late final int? timestamp;
  final String name;
  final Map<String, dynamic> props = <String, dynamic>{};
  late String uuid;

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
        'version': Constants.packageVersion
      }
    }..addAll(props);
  }
}
