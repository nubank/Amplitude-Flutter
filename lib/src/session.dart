import 'package:flutter/widgets.dart';

import './time_utils.dart';

class Session with WidgetsBindingObserver {
  factory Session(int timeout) {
    if (_instance != null) {
      return _instance;
    }
    _instance = Session._internal(timeout);
    return _instance;
  }

  Session._internal(this.timeout) {
    _time = TimeUtils();
    final widgetsBinding = WidgetsBinding.instance;
    if (widgetsBinding != null) {
      widgetsBinding.addObserver(this);
    }
  }

  @visibleForTesting
  Session.private(TimeUtils time, this.timeout) {
    _time = time;
  }

  static Session _instance;
  TimeUtils _time;

  int timeout;
  int sessionStart;
  int lastActivity;

  void start() {
    sessionStart = _time.currentTime();
  }

  String getSessionId() {
    return sessionStart.toString();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        enterBackground();
        break;
      case AppLifecycleState.resumed:
        break;
      default:
    }
  }
}
