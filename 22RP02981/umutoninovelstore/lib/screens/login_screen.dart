import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/firebase_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  final FirebaseService _firebaseService = FirebaseService();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Create user profile in Firestore
      if (userCredential.user != null) {
        await _firebaseService.createUserProfile(userCredential.user!);
        // Create sample notifications for new users
        await _firebaseService.createSampleNotifications(userCredential.user!.uid);
      }
      
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
      return userCredential;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: ${e.toString()}')),
        );
      }
      return null;
    }
  }

  Future<void> signInWithEmail(BuildContext context) async {
    print('Attempting login with email: \'${emailController.text.trim()}\'');
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      print('Login successful!');
      // Create user profile in Firestore if it doesn't exist
      if (userCredential.user != null) {
        await _firebaseService.createUserProfile(userCredential.user!);
        // Create sample notifications for new users
        await _firebaseService.createSampleNotifications(userCredential.user!.uid);
      }
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      print('Login failed: $e');
      String errorMessage = 'Login failed. Please try again.';
      final errorStr = e.toString();
      if (errorStr.contains('invalid-credential') ||
          errorStr.contains('wrong-password') ||
          errorStr.contains('user-not-found')) {
        errorMessage = 'Incorrect email or password. Please try again.';
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F5E8), // Soft green background
      appBar: AppBar(title: const Text("Login")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                signInWithEmail(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text("Submit"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 48),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text("Sign Up"),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/4/4a/Logo_2013_Google.png',
                height: 24,
                width: 24,
              ),
              label: const Text('Sign in with Google', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: Colors.grey),
              ),
              onPressed: () => signInWithGoogle(context),
            ),
          ],
        ),
      ),
    );
  }
} 