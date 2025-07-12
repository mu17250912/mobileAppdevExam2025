import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../services/profile_service.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _profileImage;
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
  }

  Future<void> _loadProfilePhoto() async {
    final photo = await _profileService.getProfilePhoto();
    if (photo != null) {
      setState(() {
        _profileImage = photo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double radius = 20.0; // Define your desired radius

    return Scaffold(
      backgroundColor: Colors.indigo[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Image.asset(
                  'assets/icon/bmi.jpg',
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'FitTrak',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Maintain your health style',
                style: TextStyle(fontSize: 18, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                  textStyle: const TextStyle(fontSize: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
