import 'package:flutter/material.dart';
import 'calculator_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../services/bmi_firebase_service.dart';
import '../models/bmi_entry.dart';
import 'login_screen.dart';
import '../services/profile_service.dart';
import 'dart:io' show Platform;
import 'recommendations_screen.dart';
import 'settings_screen.dart';
// import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/profile.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'upgrade_screen.dart';
import '../services/premium_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<BMIEntry?>? _latestEntryFuture;
  dynamic _profileImage; // File for mobile/desktop, null or ignored for web
  final ProfileService _profileService = ProfileService();
  bool _isPremiumUser = false;

  @override
  void initState() {
    super.initState();
    _loadLatestEntry();
    _loadProfilePhoto();
    _loadPremiumStatus();
  }

  void _loadLatestEntry() {
    setState(() {
      _latestEntryFuture = _fetchLatestEntry();
    });
  }

  Future<BMIEntry?> _fetchLatestEntry() async {
    final entries = await BMIFirebaseService().getUserEntries(LoginScreen.loggedInUserId ?? '');
    if (entries.isNotEmpty) {
      return entries.first;
    }
    return null;
  }

  Future<void> _loadProfilePhoto() async {
    if (!kIsWeb) {
      final photo = await _profileService.getProfilePhoto();
      if (photo != null) {
        setState(() {
          _profileImage = photo;
        });
      }
    }
  }

  String _getUserName() {
    final email = LoginScreen.loggedInEmail ?? '';
    if (email.isEmpty) return 'User';
    // Extract name from email (before @ symbol)
    final name = email.split('@')[0];
    // Capitalize first letter
    return name.isNotEmpty ? name[0].toUpperCase() + name.substring(1) : 'User';
  }

  Future<void> _goToRecommendations(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecommendationsScreen()),
    );
  }

  Future<void> _loadPremiumStatus() async {
    final isPremium = await PremiumService.isPremiumUser();
    setState(() {
      _isPremiumUser = isPremium;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.indigo[400],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLatestEntry,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heart icon and profile section on the left
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.indigo[400],
                      child: const Icon(Icons.person, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Welcome ${_getUserName()}!',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.indigo,
                              ),
                            ),
                            if (_isPremiumUser) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'Premium',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Calculate your BMI',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    FutureBuilder<BMIEntry?>(
                      future: _latestEntryFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final entry = snapshot.data;
                        if (entry == null) {
                          return const Text('No BMI record found.', style: TextStyle(fontSize: 20, color: Colors.black54));
                        }
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.bmi.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo),
                            ),
                            Text(
                              entry.category,
                              style: TextStyle(
                                fontSize: 20,
                                color: entry.category == 'Normal weight' 
                                    ? Colors.green 
                                    : entry.category == 'Obesity Class I' 
                                        ? Colors.orange[400]
                                    : entry.category == 'Obesity Class II' 
                                        ? Colors.red[400]
                                    : entry.category == 'Obesity Class III' 
                                        ? Colors.red[700]
                                        : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Current BMI', style: TextStyle(fontSize: 16, color: Colors.black54)),
                        Text('Category', style: TextStyle(fontSize: 16, color: Colors.black54)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.indigo, width: 2),
                          borderRadius: BorderRadius.circular(100),
                          color: Colors.indigo[50],
                        ),
                        child: const SizedBox(
                          width: 180,
                          child: Column(
                            children: [
                              Text(
                                'Your Health Journey',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Keep tracking your BMI to maintain your health style',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "recommendations",
            onPressed: () => _goToRecommendations(context),
            backgroundColor: Colors.teal[300],
            foregroundColor: Colors.white,
            child: const Icon(Icons.recommend),
          ),
          const SizedBox(width: 16),
          FloatingActionButton.extended(
            heroTag: "calculator",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalculatorScreen()),
              );
            },
            backgroundColor: Colors.indigo[400],
            foregroundColor: Colors.white,
            icon: const Icon(Icons.calculate),
            label: const Text('Calculate New BMI'),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
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
          } else if (index == 4) {
            _goToRecommendations(context);
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
} 