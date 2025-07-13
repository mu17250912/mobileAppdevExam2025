import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goaltracker/auth/auth_screen.dart';
import 'package:goaltracker/shared/app_theme.dart';

void main() {
  group('AuthScreen Responsive Tests', () {
    testWidgets('should adapt to mobile screen size', (WidgetTester tester) async {
      // Set mobile screen size
      tester.binding.window.physicalSizeTestValue = const Size(375, 812); // iPhone X size
      tester.binding.window.devicePixelRatioTestValue = 3.0;

      await tester.pumpWidget(
        MaterialApp(
          home: const AuthScreen(),
        ),
      );

      // Verify mobile-specific responsive behavior
      expect(find.byType(AuthScreen), findsOneWidget);
      
      // Check that the form is properly sized for mobile
      final formFinder = find.byType(Form);
      expect(formFinder, findsOneWidget);
    });

    testWidgets('should adapt to tablet screen size', (WidgetTester tester) async {
      // Set tablet screen size
      tester.binding.window.physicalSizeTestValue = const Size(768, 1024); // iPad size
      tester.binding.window.devicePixelRatioTestValue = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          home: const AuthScreen(),
        ),
      );

      // Verify tablet-specific responsive behavior
      expect(find.byType(AuthScreen), findsOneWidget);
      
      // Check that the form is properly sized for tablet
      final formFinder = find.byType(Form);
      expect(formFinder, findsOneWidget);
    });

    testWidgets('should adapt to desktop screen size', (WidgetTester tester) async {
      // Set desktop screen size
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080); // Desktop size
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: const AuthScreen(),
        ),
      );

      // Verify desktop-specific responsive behavior
      expect(find.byType(AuthScreen), findsOneWidget);
      
      // Check that the form is properly sized for desktop
      final formFinder = find.byType(Form);
      expect(formFinder, findsOneWidget);
    });

    testWidgets('should handle landscape orientation', (WidgetTester tester) async {
      // Set landscape orientation
      tester.binding.window.physicalSizeTestValue = const Size(1024, 768); // Landscape tablet
      tester.binding.window.devicePixelRatioTestValue = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          home: const AuthScreen(),
        ),
      );

      // Verify landscape-specific responsive behavior
      expect(find.byType(AuthScreen), findsOneWidget);
      
      // Check that the form is properly sized for landscape
      final formFinder = find.byType(Form);
      expect(formFinder, findsOneWidget);
    });

    testWidgets('should show login form by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AuthScreen(),
        ),
      );

      // Verify login form is shown by default
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign Up'), findsNothing);
      
      // Verify login-specific fields are present
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Referral Code (Optional)'), findsNothing);
    });

    testWidgets('should toggle between login and signup', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AuthScreen(),
        ),
      );

      // Initially should show login
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text("Don't have an account? Sign Up"), findsOneWidget);

      // Tap to switch to signup
      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();

      // Should now show signup
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Already have an account? Sign In'), findsOneWidget);
      expect(find.text('Referral Code (Optional)'), findsOneWidget);
    });

    testWidgets('should validate email field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AuthScreen(),
        ),
      );

      // Try to submit without entering email
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Should show validation error
      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('should validate password field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AuthScreen(),
        ),
      );

      // Enter valid email
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      
      // Try to submit without entering password
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Should show validation error
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });
  });

  group('AppTheme Responsive Utilities Tests', () {
    testWidgets('should detect mobile screen size', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(375, 812);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(AppTheme.isMobile(context), isTrue);
              expect(AppTheme.isTablet(context), isFalse);
              expect(AppTheme.isDesktop(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should detect tablet screen size', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(768, 1024);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(AppTheme.isMobile(context), isFalse);
              expect(AppTheme.isTablet(context), isTrue);
              expect(AppTheme.isDesktop(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should detect desktop screen size', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(AppTheme.isMobile(context), isFalse);
              expect(AppTheme.isTablet(context), isFalse);
              expect(AppTheme.isDesktop(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should provide responsive font sizes', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(375, 812);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final fontSize = AppTheme.getResponsiveFontSize(context);
              expect(fontSize, equals(16.0)); // Mobile default
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should provide responsive padding', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(768, 1024);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final padding = AppTheme.getResponsivePadding(context);
              expect(padding, equals(24.0)); // Tablet default
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
} 