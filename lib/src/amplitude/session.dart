import 'package:amplitude_flutter/amplitude_flutter.dart';
import 'package:flutter/widgets.dart';

/// {@template session}
/// Class for managing user sessions.
/// {@endtemplate}
class Session with WidgetsBindingObserver {
  /// Creates a new Session instance with the given timeout.
  factory Session(int timeout) => _instance ??= Session._internal(timeout);

  /// Private constructor for singleton pattern
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

  /// Starts a new session by setting the sessionStart and lastActivity
  /// to the current timestamp.
  void start() {
    sessionStart = DateTime.now().toMs();
    lastActivity = sessionStart;
  }

  /// Refreshes the session by updating the lastActivity timestamp.
  void refresh() {
    final int now = DateTime.now().toMs();
    if (!withinSession(now)) {
      sessionStart = now;
    }
    lastActivity = now;
  }

  /// Checks if the given timestamp is within the current session.
  bool withinSession(int timestamp) {
    if (sessionStart == null) {
      return false;
    }
    return timestamp - sessionStart! < timeout;
  }

  /// Handles app lifecycle changes to manage session state.
  void enterBackground() {
    // Track when app goes to background
  }

  /// Handles when the app returns from background.
  void exitBackground() {
    // Track when app returns from background
  }

  /// Retrieves the current session ID as a string.
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
        lastActivity = DateTime.now().toMs();
        break;
      case AppLifecycleState.resumed:
        refresh();
        exitBackground();
        break;
      default:
    }
  }
}
