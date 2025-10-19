import 'package:flutter/foundation.dart';

class Identify {
  final Map<String, dynamic> payload = {};

  static const String opSet = r'$set';
  static const String opSetOnce = r'$setOnce';
  static const String opAdd = r'$add';
  static const String opAppend = r'$append';
  static const String opUnset = r'$unset';

  void set(String key, dynamic value) {
    addOp(opSet, key, value);
  }

  void setOnce(String key, dynamic value) {
    addOp(opSetOnce, key, value);
  }

  void add(String key, num value) {
    addOp(opAdd, key, value);
  }

  void unset(String key) {
    addOp(opUnset, key, '-');
  }

  void append(String key, dynamic value) {
    addOp(opAppend, key, value);
  }

  @visibleForTesting
  void addOp(String op, String key, dynamic value) {
    assert([opSet, opSetOnce, opAdd, opAppend, opUnset].contains(op));

    _opMap(op)[key] = value;
  }

  Map<String, dynamic> _opMap(String key) {
    return payload.putIfAbsent(key, () => <String, dynamic>{});
  }
}
