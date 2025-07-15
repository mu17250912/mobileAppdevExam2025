// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_recruitment/main.dart';

void main() {
  testWidgets('Login screen is shown on app start', (WidgetTester tester) async {
    await tester.pumpWidget(ERecruitmentApp());
    expect(find.text('Login'), findsOneWidget);
    // Optionally, check for email/password fields or login button
    // expect(find.byType(TextFormField), findsNWidgets(2));
    // expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });
}
