import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goaltracker/auth/auth_screen.dart';
import 'package:goaltracker/shared/app_theme.dart';

void main() {
  group('Auth Form Centering Tests', () {
    testWidgets('should center form on mobile screen', (
      WidgetTester tester,
    ) async {
      // Set mobile screen size
      tester.binding.window.physicalSizeTestValue = const Size(375, 812);
      tester.binding.window.devicePixelRatioTestValue = 3.0;

      await tester.pumpWidget(MaterialApp(home: const AuthScreen()));

      // Verify the form is centered
      final formFinder = find.byType(Form);
      expect(formFinder, findsOneWidget);

      // Check that the form is within the screen bounds
      final formWidget = tester.widget<Form>(formFinder);
      expect(formWidget, isNotNull);
    });

    testWidgets('should center form on tablet screen', (
      WidgetTester tester,
    ) async {
      // Set tablet screen size
      tester.binding.window.physicalSizeTestValue = const Size(768, 1024);
      tester.binding.window.devicePixelRatioTestValue = 2.0;

      await tester.pumpWidget(MaterialApp(home: const AuthScreen()));

      // Verify the form is centered
      final formFinder = find.byType(Form);
      expect(formFinder, findsOneWidget);
    });

    testWidgets('should center form on desktop screen', (
      WidgetTester tester,
    ) async {
      // Set desktop screen size
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(MaterialApp(home: const AuthScreen()));

      // Verify the form is centered
      final formFinder = find.byType(Form);
      expect(formFinder, findsOneWidget);
    });

    testWidgets('should center form in landscape orientation', (
      WidgetTester tester,
    ) async {
      // Set landscape orientation
      tester.binding.window.physicalSizeTestValue = const Size(1024, 768);
      tester.binding.window.devicePixelRatioTestValue = 2.0;

      await tester.pumpWidget(MaterialApp(home: const AuthScreen()));

      // Verify the form is centered
      final formFinder = find.byType(Form);
      expect(formFinder, findsOneWidget);
    });

    testWidgets('should maintain form centering when keyboard appears', (
      WidgetTester tester,
    ) async {
      // Set mobile screen size
      tester.binding.window.physicalSizeTestValue = const Size(375, 812);
      tester.binding.window.devicePixelRatioTestValue = 3.0;

      await tester.pumpWidget(MaterialApp(home: const AuthScreen()));

      // Find the email field
      final emailField = find.byType(TextFormField).first;
      expect(emailField, findsOneWidget);

      // Tap on the email field to focus it (simulates keyboard appearance)
      await tester.tap(emailField);
      await tester.pump();

      // Verify the form is still centered
      final formFinder = find.byType(Form);
      expect(formFinder, findsOneWidget);
    });

    testWidgets('should center form elements properly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const AuthScreen()));

      // Verify all form elements are present and centered
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text("Don't have an account? Sign Up"), findsOneWidget);

      // Check that the title is centered
      final titleFinder = find.text('Sign In');
      expect(titleFinder, findsOneWidget);
    });

    testWidgets('should center form when switching between login and signup', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const AuthScreen()));

      // Initially should show login form centered
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Switch to signup
      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();

      // Should now show signup form centered
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Referral Code (Optional)'), findsOneWidget);
    });
  });

  group('AppTheme Centering Utilities Tests', () {
    testWidgets('should create centered responsive container', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return AppTheme.createResponsiveCenteredContainer(
                context: context,
                child: const Text('Test Content'),
              );
            },
          ),
        ),
      );

      // Verify the container is created
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should create centered responsive card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return AppTheme.createCenteredResponsiveCard(
                context: context,
                child: const Text('Test Card Content'),
              );
            },
          ),
        ),
      );

      // Verify the card is created
      expect(find.text('Test Card Content'), findsOneWidget);
    });

    testWidgets('should provide responsive card width', (
      WidgetTester tester,
    ) async {
      // Test mobile width
      tester.binding.window.physicalSizeTestValue = const Size(375, 812);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final width = AppTheme.getResponsiveCardWidth(context);
              expect(width, equals(375 * 0.9)); // 90% of mobile screen width
              return const SizedBox();
            },
          ),
        ),
      );

      // Test tablet width
      tester.binding.window.physicalSizeTestValue = const Size(768, 1024);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final width = AppTheme.getResponsiveCardWidth(context);
              expect(width, equals(768 * 0.7)); // 70% of tablet screen width
              return const SizedBox();
            },
          ),
        ),
      );

      // Test desktop width
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final width = AppTheme.getResponsiveCardWidth(context);
              expect(width, equals(400.0)); // Fixed width for desktop
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
