import 'package:flutter/material.dart';
import 'calculator_screen.dart';
import 'history_screen.dart';
import '../models/bmi_entry.dart';
import '../services/bmi_history_service.dart';
import '../services/bmi_firebase_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'recommendations_screen.dart';
import '../services/notification_service.dart';
import '../services/premium_service.dart';
import 'advice_upgrade_screen.dart';

class ResultsScreen extends StatefulWidget {
  final double bmi;
  final String? userEmail;
  final double? weight;
  final double? height;
  const ResultsScreen({Key? key, required this.bmi, this.userEmail, this.weight, this.height}) : super(key: key);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  String getBMICategory() {
    if (widget.bmi < 18.5) return 'Underweight';
    if (widget.bmi < 25.0) return 'Normal weight';
    if (widget.bmi < 30.0) return 'Overweight';
    if (widget.bmi < 35.0) return 'Obesity Class I';
    if (widget.bmi < 40.0) return 'Obesity Class II';
    return 'Obesity Class III';
  }

  String getHealthInsight() {
    if (widget.bmi < 18.5) {
      return 'You are underweight. It is recommended to consult a healthcare provider or nutritionist to ensure you are getting enough nutrients.';
    } else if (widget.bmi < 25.0) {
      return 'You have a normal body weight. Keep up the good work with a balanced diet and regular physical activity!';
    } else if (widget.bmi < 30.0) {
      return 'You are overweight. Consider adopting a healthier diet and increasing your physical activity to reach a normal weight.';
    } else if (widget.bmi < 35.0) {
      return 'You are in Obesity Class I. It is important to consult a healthcare provider for guidance on achieving a healthier weight through diet and exercise.';
    } else if (widget.bmi < 40.0) {
      return 'You are in Obesity Class II. Medical supervision is recommended for weight management. Consult a healthcare provider for a comprehensive treatment plan.';
    } else {
      return 'You are in Obesity Class III (Severe Obesity). Immediate medical consultation is strongly recommended for comprehensive health management and treatment options.';
    }
  }

  @override
  void initState() {
    super.initState();
    _saveBMI();
    _checkForHealthAlerts();
  }

  Future<void> _checkForHealthAlerts() async {
    try {
      // Get the last BMI entry for comparison
      final entries = await BMIFirebaseService().getUserEntries(LoginScreen.loggedInUserId ?? '');
      if (entries.length > 1) {
        // Compare with the previous entry (second to last)
        final previousBMI = entries[entries.length - 2].bmi;
        final currentBMI = widget.bmi;
        
        // Check for significant changes (5% or more)
        final difference = (currentBMI - previousBMI).abs();
        final percentageChange = (difference / previousBMI) * 100;
        
        if (percentageChange >= 5) {
          // Show alert dialog
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showHealthAlertDialog(previousBMI, currentBMI, percentageChange);
          });
          // Send notification for significant BMI change
          NotificationService.checkForSignificantChanges(previousBMI, currentBMI);
        }
      }
    } catch (e) {
      print('Error checking for health alerts: $e');
    }
  }

  void _showHealthAlertDialog(double previousBMI, double currentBMI, double percentageChange) {
    final isIncrease = currentBMI > previousBMI;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isIncrease ? Icons.trending_up : Icons.trending_down,
              color: isIncrease ? Colors.orange : Colors.green,
            ),
            const SizedBox(width: 8),
            const Text('BMI Change Alert'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your BMI has ${isIncrease ? 'increased' : 'decreased'} by ${percentageChange.toStringAsFixed(1)}%.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Previous BMI: ${previousBMI.toStringAsFixed(1)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Current BMI: ${currentBMI.toStringAsFixed(1)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Text(
              isIncrease 
                ? 'Consider reviewing your health habits and consult with a healthcare provider if this trend continues.'
                : 'Great progress! Keep up the healthy lifestyle changes.',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (isIncrease)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to recommendations for guidance
                Navigator.pushNamed(context, '/recommendations');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[400]),
              child: const Text('Get Advice'),
            ),
        ],
      ),
    );
  }

  Future<void> _saveBMI() async {
    final bmiEntry = BMIEntry(
      bmi: widget.bmi,
      category: getBMICategory(),
      date: DateTime.now(),
    );
    // Save to local history
    BMIHistoryService().addEntry(bmiEntry);
    // Save to Firebase if userId, weight, and height are provided
    if (LoginScreen.loggedInUserId != null && LoginScreen.loggedInUserId!.isNotEmpty && widget.weight != null && widget.height != null) {
      print('Trying to save to Firestore for user: ${LoginScreen.loggedInUserId}');
      BMIFirebaseService().addEntry(bmiEntry, LoginScreen.loggedInUserId!, widget.weight!, widget.height!)
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('BMI saved to your history!'), backgroundColor: Colors.green),
          );
          print('BMI saved to Firestore!');
        })
        .catchError((e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save BMI to Firestore: $e'), backgroundColor: Colors.red),
          );
          print('Failed to save BMI to Firestore: $e');
        });
    } else {
      print('Not saving to Firestore: missing userId, weight, or height');
    }
  }

  void _showUpgradeDialogForAdvice() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('Premium Feature'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personalized health advice is a premium feature.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Upgrade to Premium to unlock:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Personalized meal recommendations'),
            Text('• Custom exercise plans'),
            Text('• Advanced health insights'),
            Text('• Progress tracking analytics'),
            Text('• Expert health guidance'),
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
                  MaterialPageRoute(builder: (context) => const AdviceUpgradeScreen()),
                );
                // If user upgraded, allow access to recommendations
                if (result == true) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RecommendationsScreen()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Upgrade Advice Premium'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String category = getBMICategory();
    final String insight = getHealthInsight();
    final bool isNormal = category == 'Normal weight';
    final bool isObesityClassI = category == 'Obesity Class I';
    final bool isObesityClassII = category == 'Obesity Class II';
    final bool isObesityClassIII = category == 'Obesity Class III';
    
    // Enhanced color coding for BMI categories
    Color getCategoryColor() {
      if (isNormal) return Colors.green[300]!;
      if (isObesityClassI) return Colors.orange[400]!;
      if (isObesityClassII) return Colors.red[400]!;
      if (isObesityClassIII) return Colors.red[700]!;
      return Colors.orange[200]!; // For overweight and underweight
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your BMI Result'),
        backgroundColor: Colors.indigo[400],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.bmi.toStringAsFixed(1),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
              decoration: BoxDecoration(
                color: getCategoryColor(),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category,
                style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Health insight',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo[400]),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              insight,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final isAdvicePremium = await PremiumService.isAdvicePremium();
                  if (isAdvicePremium) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RecommendationsScreen()),
                    );
                  } else {
                    _showUpgradeDialogForAdvice();
                  }
                },
                icon: const Icon(Icons.recommend),
                label: const Text('Get Personalized Advice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[200],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
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
          }
        },
      ),
    );
  }
} 