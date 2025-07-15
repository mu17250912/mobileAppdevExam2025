import 'package:flutter/material.dart';
import '../models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingScreen extends StatefulWidget {
  final String email;
  final void Function(User) onComplete;
  const OnboardingScreen({Key? key, required this.email, required this.onComplete}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _householdSize;
  double? _averageWaterBill;
  double? _waterUsageGoalPercent;
  bool _usesSmartMeter = false;
  bool _loading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2196F3),
              Color(0xFF64B5F6),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo and App Name
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.water_drop, size: 40, color: Colors.blue.shade700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'AquTrack',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Stepper visual (single step for now)
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue.shade700, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.check, size: 14, color: Color(0xFF2196F3)),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 2,
                        color: Colors.white24,
                      ),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 2,
                        color: Colors.white24,
                      ),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                // Card with form
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Let’s set up your profile',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Household Size',
                              prefixIcon: Icon(Icons.people, color: Colors.blue.shade700),
                              filled: true,
                              fillColor: Colors.blue.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Enter household size';
                              if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Enter a valid number';
                              return null;
                            },
                            onSaved: (value) => _householdSize = int.tryParse(value ?? ''),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Average Water Bill (optional)',
                              prefixIcon: Icon(Icons.attach_money, color: Colors.blue.shade700),
                              filled: true,
                              fillColor: Colors.blue.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onSaved: (value) => _averageWaterBill = double.tryParse(value ?? ''),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Water Usage Goal (% reduction)',
                              prefixIcon: Icon(Icons.flag, color: Colors.blue.shade700),
                              filled: true,
                              fillColor: Colors.blue.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Enter a goal (e.g., 20)';
                              if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Enter a valid percentage';
                              return null;
                            },
                            onSaved: (value) => _waterUsageGoalPercent = double.tryParse(value ?? ''),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'How will you track water usage?',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          RadioListTile<bool>(
                            title: const Text('Connect to Smart Water Meter'),
                            value: true,
                            groupValue: _usesSmartMeter,
                            activeColor: Colors.blue.shade700,
                            onChanged: (val) => setState(() => _usesSmartMeter = val ?? false),
                          ),
                          RadioListTile<bool>(
                            title: const Text('Manual Input'),
                            value: false,
                            groupValue: _usesSmartMeter,
                            activeColor: Colors.blue.shade700,
                            onChanged: (val) => setState(() => _usesSmartMeter = val ?? false),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                elevation: 6,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                    )
                                  : const Text(
                                      'Get Started',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                                    ),
                              onPressed: _loading
                                  ? null
                                  : () async {
                                      print('Get Started button pressed');
                                      print('Email: \'${widget.email}\'');
                                      setState(() {
                                        _loading = true;
                                        _errorMessage = null;
                                      });
                                      print('Loading set to true');
                                      try {
                                        if (_formKey.currentState?.validate() ?? false) {
                                          print('Form validated');
                                          _formKey.currentState?.save();
                                          final String email = widget.email;
                                          print('Saving for email: ' + email);
                                          final user = User(
                                            email: email,
                                            householdSize: _householdSize!,
                                            averageWaterBill: _averageWaterBill,
                                            waterUsageGoalPercent: _waterUsageGoalPercent!,
                                            usesSmartMeter: _usesSmartMeter,
                                          );
                                          await FirebaseFirestore.instance.collection('users').doc(email).set({
                                            'email': user.email,
                                            'householdSize': user.householdSize,
                                            'averageWaterBill': user.averageWaterBill,
                                            'waterUsageGoalPercent': user.waterUsageGoalPercent,
                                            'usesSmartMeter': user.usesSmartMeter,
                                          });
                                          print('Firestore write successful');
                                          widget.onComplete(user);
                                        } else {
                                          print('Form validation failed');
                                        }
                                      } catch (e) {
                                        print('Firestore error: ' + e.toString());
                                        setState(() {
                                          _errorMessage = 'Failed to save data. Please try again.';
                                        });
                                      } finally {
                                        print('Loading set to false');
                                        setState(() {
                                          _loading = false;
                                        });
                                      }
                                    },
                            ),
                          ),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 