import 'package:amplitude_flutter/src/session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Session session;
  const int timeout = 100;

  setUp(() {
    session = Session.private(timeout);
  });

  test('start() creates a session with current timestamp', () {
    session.start();
    final sessionId = session.getSessionId();
    expect(sessionId, isNotNull);
    expect(int.tryParse(sessionId), isNotNull);
    expect(session.sessionStart, isNotNull);
    expect(session.lastActivity, isNotNull);
  });

  test('refresh() updates lastActivity', () async {
    session.start();
    final originalSessionId = session.sessionStart;

    await Future.delayed(const Duration(milliseconds: 10));
    session.refresh();

    expect(session.sessionStart, equals(originalSessionId));
    expect(session.lastActivity, isNotNull);
  });

  test('withinSession() returns true when within timeout', () {
    session.start();
    final currentTime = session.sessionStart! + 50;
    expect(session.withinSession(currentTime), isTrue);
  });

  test('withinSession() returns false when outside timeout', () {
    session.start();
    final currentTime = session.sessionStart! + 150;
    expect(session.withinSession(currentTime), isFalse);
  });

  test('didChangeAppLifecycleState handles app lifecycle changes', () {
    session.start();

    session.didChangeAppLifecycleState(AppLifecycleState.inactive);
    expect(session.lastActivity, isNotNull);

    session.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(session.sessionStart, isNotNull);
  });
}
