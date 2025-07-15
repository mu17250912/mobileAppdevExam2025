// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:goaltracker/app.dart';

void main() {
  testWidgets('GoalTracker app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GoalTrackerApp());

    // Verify that the app starts and shows the title
    expect(find.text('GoalTracker'), findsOneWidget);

    // Verify that the app has a MaterialApp structure
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
