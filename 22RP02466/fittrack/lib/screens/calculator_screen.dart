import 'package:flutter/material.dart';
import 'results_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/app_drawer.dart';
import 'login_screen.dart';
import '../services/profile_service.dart';
import '../services/bmi_usage_service.dart';
import '../services/premium_service.dart';
import 'dart:io';
import 'recommendations_screen.dart';
import 'settings_screen.dart';
import 'calculations_upgrade_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({Key? key}) : super(key: key);

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  File? _profileImage;
  final ProfileService _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();
  String? _heightError;
  String? _weightError;
  int _remainingCalculations = 3;
  bool _isCalculationsPremium = false;

  Future<void> _calculateBMI() async {
    setState(() {
      _heightError = null;
      _weightError = null;
    });
    final double? height = double.tryParse(_heightController.text);
    final double? weight = double.tryParse(_weightController.text);
    bool hasError = false;
    if (height == null || height <= 0) {
      setState(() {
        _heightError = 'Enter a valid height (> 0)';
      });
      hasError = true;
    }
    if (weight == null || weight <= 0) {
      setState(() {
        _weightError = 'Enter a valid weight (> 0)';
      });
      hasError = true;
    }
    if (hasError) return;

    // Check if user needs to upgrade for calculations
    final needsUpgrade = await BMIUsageService.trackCalculation();
    
    if (needsUpgrade) {
      // Show upgrade dialog
      _showUpgradeDialog();
      return;
    }

    final double bmi = weight! / (height! * height);
    
    // Refresh remaining calculations count
    await _loadRemainingCalculations();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          bmi: bmi,
          userEmail: LoginScreen.loggedInEmail,
          weight: weight,
          height: height,
        ),
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('Upgrade Required'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve reached your daily limit of 3 BMI calculations.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Upgrade to Premium to enjoy:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Unlimited BMI calculations'),
            Text('• Advanced health insights'),
            Text('• Personalized recommendations'),
            Text('• Data export functionality'),
            Text('• Priority support'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
                      ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CalculationsUpgradeScreen()),
                );
                // If user upgraded, refresh the calculations count
                if (result == true) {
                  await _loadRemainingCalculations();
                  await _loadCalculationsPremiumStatus();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Upgrade Calculations Premium'),
            ),
        ],
      ),
    );
  }

  String _getUserName() {
    final email = LoginScreen.loggedInEmail ?? '';
    if (email.isEmpty) return 'User';
    // Extract name from email (before @ symbol)
    final name = email.split('@')[0];
    // Capitalize first letter
    return name.isNotEmpty ? name[0].toUpperCase() + name.substring(1) : 'User';
  }

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
    _loadRemainingCalculations();
    _loadCalculationsPremiumStatus();
  }

  Future<void> _loadProfilePhoto() async {
    final photo = await _profileService.getProfilePhoto();
    if (photo != null) {
      setState(() {
        _profileImage = photo;
      });
    }
  }

  Future<void> _loadRemainingCalculations() async {
    final remaining = await BMIUsageService.getRemainingFreeCalculations();
    setState(() {
      _remainingCalculations = remaining;
    });
  }

  Future<void> _loadCalculationsPremiumStatus() async {
    final isCalculationsPremium = await PremiumService.isCalculationsPremium();
    setState(() {
      _isCalculationsPremium = isCalculationsPremium;
    });
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fit Track BMI'),
        backgroundColor: Colors.indigo[400],
      ),
      drawer: const AppDrawer(),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Illustrative Icon
                // Profile Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome ${_getUserName()}!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
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
                const SizedBox(height: 32),
                
                // Usage Counter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isCalculationsPremium 
                      ? Colors.amber[50] 
                      : (_remainingCalculations > 0 ? Colors.green[50] : Colors.orange[50]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isCalculationsPremium 
                        ? Colors.amber[200]! 
                        : (_remainingCalculations > 0 ? Colors.green[200]! : Colors.orange[200]!),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isCalculationsPremium 
                          ? Icons.star 
                          : (_remainingCalculations > 0 ? Icons.check_circle : Icons.warning),
                        color: _isCalculationsPremium 
                          ? Colors.amber 
                          : (_remainingCalculations > 0 ? Colors.green : Colors.orange),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isCalculationsPremium 
                          ? 'Calculations Premium - Unlimited calculations'
                          : (_remainingCalculations > 0 
                            ? '$_remainingCalculations free calculations remaining today'
                            : 'Daily limit reached - Upgrade for unlimited calculations'),
                        style: TextStyle(
                          fontSize: 14,
                          color: _isCalculationsPremium 
                            ? Colors.amber[700] 
                            : (_remainingCalculations > 0 ? Colors.green[700] : Colors.orange[700]),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Remove the BMI Formula card/section. Only keep the input fields and calculate button.
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: Colors.indigo[50],
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _heightController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Height (meters)',
                              hintText: 'e.g. 1.75',
                              helperText: 'Enter your height in meters (e.g., 1.75)',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.height, color: Colors.indigo),
                              errorText: _heightError,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _weightController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Weight (kg)',
                              hintText: 'e.g. 68',
                              helperText: 'Enter your weight in kilograms (e.g., 68)',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.monitor_weight, color: Colors.indigo),
                              errorText: _weightError,
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: (_isCalculationsPremium || _remainingCalculations > 0) ? _calculateBMI : null,
                              icon: Icon(_isCalculationsPremium ? Icons.star : Icons.calculate),
                              label: Text(_isCalculationsPremium 
                                ? 'Calculate BMI (Premium)' 
                                : (_remainingCalculations > 0 ? 'Calculate BMI' : 'Upgrade Required')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isCalculationsPremium 
                                  ? Colors.amber 
                                  : (_remainingCalculations > 0 ? Colors.indigo[200] : Colors.grey[300]),
                                foregroundColor: _isCalculationsPremium 
                                  ? Colors.white 
                                  : (_remainingCalculations > 0 ? Colors.white : Colors.grey[600]),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: (_isCalculationsPremium || _remainingCalculations > 0) ? 4 : 0,
                              ),
                            ),
                          ),
                          if (!_isCalculationsPremium && _remainingCalculations <= 0) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const CalculationsUpgradeScreen()),
                                  );
                                  // If user upgraded, refresh the calculations count and premium status
                                  if (result == true) {
                                    await _loadRemainingCalculations();
                                    await _loadCalculationsPremiumStatus();
                                  }
                                },
                                icon: const Icon(Icons.star),
                                label: const Text('Upgrade Calculations Premium'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const RecommendationsScreen()),
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
} 