import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> setupFirebaseForTesting() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for testing
  await Firebase.initializeApp();
}

void main() {
  // This file is used for test setup
}
