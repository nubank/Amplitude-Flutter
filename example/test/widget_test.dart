// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:amplitude_flutter_example/my_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MyApp shows Send Event button', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MyApp('API_KEY'));

      final Finder button = find.widgetWithText(ElevatedButton, 'Send Event');

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(button, findsOneWidget);
      expect(tester.widget<ElevatedButton>(button).onPressed.runtimeType, VoidCallback);
    });
  });
}
