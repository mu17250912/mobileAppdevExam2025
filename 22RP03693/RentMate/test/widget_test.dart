// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile_exam_22rp03693/main.dart';
import 'package:mobile_exam_22rp03693/providers/auth_provider.dart';

void main() {
  testWidgets('RentMate app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the app starts with the splash screen
    expect(find.text('RentMate'), findsOneWidget);
    expect(find.text('Find Your Perfect Student Home'), findsOneWidget);
  });
}
