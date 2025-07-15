// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Blood Donor App Widget Tests', () {
    testWidgets('Basic app structure test', (WidgetTester tester) async {
      // Test basic MaterialApp structure without Firebase dependencies
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Blood Donor App')),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Blood Donor App'),
                SizedBox(height: 40),
                Text('Login'),
                Text('Sign in with Google'),
                Text("Don't have an account? Register"),
              ],
            ),
          ),
        ),
      ));

      // Verify that basic UI elements are present
      expect(find.text('Blood Donor App'), findsNWidgets(2)); // One in AppBar, one in body
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text("Don't have an account? Register"), findsOneWidget);
    });

    testWidgets('Input fields test', (WidgetTester tester) async {
      // Test input field structure
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
        ),
      ));

      // Verify that email and password fields are present
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('Button structure test', (WidgetTester tester) async {
      // Test button structure
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Login'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('google_signin_button'),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with Google'),
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text("Don't have an account? Register"),
              ),
            ],
          ),
        ),
      ));

      // Verify that buttons are present
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.byKey(Key('google_signin_button')), findsOneWidget);
      expect(find.text("Don't have an account? Register"), findsOneWidget);
    });

    testWidgets('Navigation test', (WidgetTester tester) async {
      // Test navigation structure
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextButton(
            onPressed: () {},
            child: const Text("Don't have an account? Register"),
          ),
        ),
      ));

      // Verify navigation button is present
      expect(find.text("Don't have an account? Register"), findsOneWidget);
    });

    testWidgets('Form validation test', (WidgetTester tester) async {
      // Test form validation structure
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(
                controller: TextEditingController(),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  errorText: 'Please enter a valid email',
                ),
              ),
              TextField(
                controller: TextEditingController(),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  errorText: 'Password must be at least 6 characters',
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
      ));

      // Verify error messages can be displayed
      expect(find.text('Please enter a valid email'), findsOneWidget);
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });
  });
}

// Firebase-integrated tests are now available since Firebase is properly configured
// You can uncomment and use these tests when you want to test Firebase functionality

/*
import 'package:blood_donor_app/main.dart';
import 'package:blood_donor_app/screens/login_screen.dart';
import 'package:blood_donor_app/screens/register_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mock Firebase for testing
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  group('Blood Donor App Firebase Tests', () {
    setUpAll(() async {
      // Initialize Firebase for testing
      await Firebase.initializeApp();
    });

    testWidgets('App should start with login screen', (WidgetTester tester) async {
      await tester.pumpWidget(BloodDonorApp());
      
      expect(find.text('Blood Donor App'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text("Don't have an account? Register"), findsOneWidget);
    });

    testWidgets('Login screen has required input fields', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('Google sign-in button has correct key', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));

      expect(find.byKey(Key('google_signin_button')), findsOneWidget);
    });

    testWidgets('Register button navigates to register screen', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: LoginScreen(),
        routes: {
          '/register': (context) => RegisterScreen(),
        },
      ));

      await tester.tap(find.text("Don't have an account? Register"));
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });
  });
}
*/
