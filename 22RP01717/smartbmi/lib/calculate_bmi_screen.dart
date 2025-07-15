import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'health_tips_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalculateBMIScreen extends StatefulWidget {
  const CalculateBMIScreen({super.key});

  @override
  State<CalculateBMIScreen> createState() => _CalculateBMIScreenState();
}

class _CalculateBMIScreenState extends State<CalculateBMIScreen> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightFeetController = TextEditingController();
  final TextEditingController _heightInchController = TextEditingController();
  final TextEditingController _weightLbsController = TextEditingController();

  String _gender = 'Male';
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';
  double? _bmi;
  String? _category;

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _heightFeetController.dispose();
    _heightInchController.dispose();
    _weightLbsController.dispose();
    super.dispose();
  }

  void _calculateBMI() async {
    final age = int.tryParse(_ageController.text);
    if (age == null || age <= 0) {
      setState(() {
        _bmi = null;
        _category = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid age.')),
      );
      return;
    }

    double? heightCm;
    double? heightValue;
    double? heightM;
    if (_heightUnit == 'cm') {
      heightCm = double.tryParse(_heightController.text);
      // Auto-fix if user enters a number less than 3 (likely meant meters)
      if (heightCm != null && heightCm < 3.0) {
        heightCm = heightCm * 100; // Convert meters to cm
      }
      heightValue = heightCm;
      heightM = (heightCm != null) ? heightCm / 100 : null;
    } else {
      final feet = double.tryParse(_heightFeetController.text) ?? 0;
      final inches = double.tryParse(_heightInchController.text) ?? 0;
      heightCm = (feet * 30.48) + (inches * 2.54);
      heightValue = feet * 12 + inches;
      heightM = heightCm / 100;
    }
    if (heightCm == null || heightCm <= 0 || heightM == null || heightM <= 0) {
      setState(() {
        _bmi = null;
        _category = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid height.')),
      );
      return;
    }

    double? weightKg;
    double? weightValue;
    if (_weightUnit == 'kg') {
      weightKg = double.tryParse(_weightController.text);
      weightValue = weightKg;
    } else {
      final lbs = double.tryParse(_weightLbsController.text);
      if (lbs != null) {
        weightKg = lbs * 0.453592;
        weightValue = lbs;
      }
    }
    if (weightKg == null || weightKg <= 0) {
      setState(() {
        _bmi = null;
        _category = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight.')),
      );
      return;
    }

    // Correct BMI formula: BMI = weight (kg) / (height in meters)^2
    final bmi = weightKg / (heightM * heightM);
    String category;
    if (bmi < 18.5) {
      category = 'Underweight';
    } else if (bmi < 25) {
      category = 'Normal';
    } else if (bmi < 30) {
      category = 'Overweight';
    } else {
      category = 'Obese';
    }
    setState(() {
      _bmi = bmi;
      _category = category;
    });

    // Store in Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bmi_history')
          .add({
        'age': age,
        'gender': _gender,
        'height': heightValue,
        'heightUnit': _heightUnit,
        'weight': weightValue,
        'weightUnit': _weightUnit,
        'bmi': bmi,
        'category': category,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  String _getHealthTip(String category) {
    switch (category) {
      case 'Underweight':
        return 'Consider a balanced diet with more calories and consult a nutritionist.';
      case 'Normal':
        return 'Great job! Maintain your healthy lifestyle.';
      case 'Overweight':
        return 'Try to increase physical activity and watch your calorie intake.';
      case 'Obese':
        return 'Consult a healthcare provider for a personalized plan.';
      default:
        return '';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Underweight':
        return Colors.blue;
      case 'Normal':
        return Colors.green;
      case 'Overweight':
        return Colors.orange;
      case 'Obese':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFE8ECF2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF5676EA), Color(0xFF7F6AB2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: const Icon(Icons.bar_chart, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'BMI Calculator',
                        style: GoogleFonts.montserrat(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.cake),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text('Gender:', style: GoogleFonts.montserrat(fontSize: 16)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Row(
                          children: [
                            Radio<String>(
                              value: 'Male',
                              groupValue: _gender,
                              onChanged: (value) {
                                setState(() {
                                  _gender = value!;
                                });
                              },
                            ),
                            const Text('Male'),
                            Radio<String>(
                              value: 'Female',
                              groupValue: _gender,
                              onChanged: (value) {
                                setState(() {
                                  _gender = value!;
                                });
                              },
                            ),
                            const Text('Female'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _heightUnit,
                          decoration: InputDecoration(
                            labelText: 'Height Unit',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'cm', child: Text('cm')),
                            DropdownMenuItem(value: 'ft', child: Text('ft/in')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _heightUnit = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _heightUnit == 'cm'
                            ? TextField(
                                controller: _heightController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Height (cm)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.height),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _heightFeetController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'ft',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _heightInchController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'in',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _weightUnit,
                          decoration: InputDecoration(
                            labelText: 'Weight Unit',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'kg', child: Text('kg')),
                            DropdownMenuItem(value: 'lbs', child: Text('lbs')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _weightUnit = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _weightUnit == 'kg'
                            ? TextField(
                                controller: _weightController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Weight (kg)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.monitor_weight),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              )
                            : TextField(
                                controller: _weightLbsController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Weight (lbs)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.monitor_weight),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _calculateBMI,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5676EA),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Calculate',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_bmi != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Your BMI is:',
                          style: GoogleFonts.montserrat(fontSize: 18, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _bmi!.toStringAsFixed(2),
                          style: GoogleFonts.montserrat(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: _getCategoryColor(_category ?? ''),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _category == 'Normal' ? 'Normal Weight' : _category ?? '',
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: _getCategoryColor(_category ?? ''),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                            side: BorderSide(color: _getCategoryColor(_category ?? '')),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Back to Home',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _getCategoryColor(_category ?? ''),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 