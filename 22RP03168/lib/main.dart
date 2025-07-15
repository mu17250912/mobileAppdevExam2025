import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/role_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TradeWear',
      theme: ThemeData(
        primaryColor: const Color(0xFF3DDAD7),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFF3DDAD7),
        ),
        fontFamily: 'Montserrat',
      ),
      debugShowCheckedModeBanner: false,
      home: const RoleSelectionScreen(),
    );
  }
}
