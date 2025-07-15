import 'package:flutter/material.dart';
import '../services/bmi_recommendations_service.dart';
import '../services/bmi_firebase_service.dart';
import '../models/bmi_entry.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'calculator_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../services/profile_service.dart';
import 'dart:io';
import 'upgrade_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({Key? key}) : super(key: key);

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  BMIEntry? _latestEntry;
  String _category = '';
  List<String> _mealAdvice = [];
  List<String> _exerciseAdvice = [];
  String _motivationalMessage = '';
  bool _isLoading = true;
  File? _profileImage;
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    _loadProfilePhoto();
  }

  Future<void> _loadRecommendations() async {
    try {
      final entries = await BMIFirebaseService().getUserEntries(LoginScreen.loggedInUserId ?? '');
      if (entries.isNotEmpty) {
        final latestEntry = entries.first;
        final category = BMIRecommendationsService.getBMICategory(latestEntry.bmi);
        
        setState(() {
          _latestEntry = latestEntry;
          _category = category;
          _mealAdvice = BMIRecommendationsService.getMealAdvice(category);
          _exerciseAdvice = BMIRecommendationsService.getExerciseAdvice(category);
          _motivationalMessage = BMIRecommendationsService.getMotivationalMessage(category);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProfilePhoto() async {
    try {
      final photo = await _profileService.getProfilePhoto();
      if (photo != null) {
        setState(() {
          _profileImage = photo;
        });
      }
    } catch (e) {
      print('Error loading profile photo: $e');
    }
  }

  String _getUserName() {
    final email = LoginScreen.loggedInEmail ?? '';
    if (email.isEmpty) return 'User';
    final name = email.split('@')[0];
    return name.isNotEmpty ? name[0].toUpperCase() + name.substring(1) : 'User';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Health Plan'),
        backgroundColor: Colors.indigo[400],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _latestEntry == null
              ? const Center(
                  child: Text(
                    'Calculate your BMI first to get personalized recommendations.',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ListView(
                    children: [
                      // Profile Section
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.indigo[400],
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : null,
                            child: _profileImage == null
                                ? const Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome ${_getUserName()} to FitTrack BMI',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your personalized health plan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Current BMI Card
                      Card(
                        color: Colors.indigo[50],
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Text(
                                'Current BMI: ${_latestEntry!.bmi.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _category == 'Normal weight' 
                                      ? Colors.green 
                                      : _category == 'Obesity Class I' 
                                          ? Colors.orange[400]
                                      : _category == 'Obesity Class II' 
                                          ? Colors.red[400]
                                      : _category == 'Obesity Class III' 
                                          ? Colors.red[700]
                                          : Colors.orange,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // BMI Categories Card (WHO Standard)
                      Card(
                        color: Colors.indigo[50],
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'BMI Categories (WHO Standard)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo),
                              ),
                              SizedBox(height: 8),
                              Text('• Underweight: BMI less than 18.5'),
                              Text('• Normal weight: BMI 18.5 to 24.9'),
                              Text('• Overweight: BMI 25.0 to 29.9'),
                              Text('• Obesity Class I: BMI 30.0 to 34.9'),
                              Text('• Obesity Class II: BMI 35.0 to 39.9'),
                              Text('• Obesity Class III: BMI 40.0 and above'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Motivational Message
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text(
                          _motivationalMessage,
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Meal Advice Section
                      _buildAdviceSection(
                        '🍽️ Meal Advice',
                        _mealAdvice,
                        Colors.green[50]!,
                        Colors.green[200]!,
                        Colors.green,
                      ),
                      const SizedBox(height: 24),

                      // Exercise Advice Section
                      _buildAdviceSection(
                        '🏃‍♀️ Exercise Recommendations',
                        _exerciseAdvice,
                        Colors.orange[50]!,
                        Colors.orange[200]!,
                        Colors.orange,
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 4, // New index for recommendations
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const CalculatorScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          } else if (index == 5) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _buildAdviceSection(String title, List<String> advice, Color bgColor, Color borderColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            ...advice.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: textColor, fontSize: 16)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
} 