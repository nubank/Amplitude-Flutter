import 'package:flutter/widgets.dart';

import './time_utils.dart';

class Session with WidgetsBindingObserver {
  factory Session(int timeout) {
    if (_instance != null) {
      return _instance!;
    }
    _instance = Session._internal(timeout);
    return _instance!;
  }

  Session._internal(this.timeout) {
    final widgetsBinding = WidgetsBinding.instance;
    widgetsBinding.addObserver(this);
  }

  @visibleForTesting
  Session.private(this.timeout);

  static Session? _instance;

  int timeout;
  int? sessionStart;
  int? lastActivity;

  void start() {
    sessionStart = currentTime();
    lastActivity = sessionStart;
  }

  void refresh() {
    final int now = currentTime();
    if (!withinSession(now)) {
      sessionStart = now;
    }
    lastActivity = now;
  }

  bool withinSession(int timestamp) {
    if (sessionStart == null) {
      return false;
    }
    return timestamp - sessionStart! < timeout;
  }

  void enterBackground() {
    // Track when app goes to background
  }

  void exitBackground() {
    // Track when app returns from background
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
        lastActivity = currentTime();
        break;
      case AppLifecycleState.resumed:
        refresh();
        exitBackground();
        break;
      default:
    }
  }
}
