import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:saferide/firebase_options.dart';
import 'package:saferide/services/auth_service.dart';
import 'package:saferide/models/user_model.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  final AuthService authService = AuthService();

  group('AuthService', () {
    test('Registration fails with invalid email', () async {
      expect(
        () async => await authService.registerWithEmailAndPassword(
          email: 'invalid-email',
          password: 'password123',
          name: 'Test User',
          phone: '1234567890',
          userType: UserType.passenger,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Login fails with wrong credentials', () async {
      expect(
        () async => await authService.signInWithEmailAndPassword(
          email: 'notfound@example.com',
          password: 'wrongpassword',
        ),
        throwsA(isA<Exception>()),
      );
    });

    // Add more tests for successful registration/login with mocks or test Firebase project
  });
}
