import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'personalized_diet_plan_screen.dart';
import 'workout_plan_screen.dart';
import 'progress_tracker_screen.dart';
import 'water_intake_tracker_screen.dart';
import 'calorie_nutrition_counter_screen.dart';

class PremiumFeaturesScreen extends StatefulWidget {
  const PremiumFeaturesScreen({super.key});

  @override
  State<PremiumFeaturesScreen> createState() => _PremiumFeaturesScreenState();
}

class _PremiumFeaturesScreenState extends State<PremiumFeaturesScreen> {
  bool userHasPremiumAccess = false;
  bool tempPremiumAccess = false;
  DateTime? accessExpiresAt;

  final features = [
    {
      'title': 'Personalized Diet Plan',
      'desc': 'Custom meal suggestions based on BMI, age, gender, and fitness goals. Option to select: “Lose Weight”, “Gain Weight”, “Stay Fit”',
    },
    {
      'title': 'Workout Plan Generator',
      'desc': '7-day or 30-day plan with beginner-friendly exercises. Based on your weight category and fitness level.',
    },
    {
      'title': 'Progress Tracker',
      'desc': 'Track BMI progress over time with interactive graphs. Weekly/Monthly weight chart comparison.',
    },
    {
      'title': 'Water Intake Tracker',
      'desc': 'Daily water goal and reminders. Log glasses of water consumed.',
    },
    {
      'title': 'Calorie & Nutrition Counter',
      'desc': 'Log meals and snacks. Show total daily calories + suggestions.',
    },
    {
      'title': 'Sleep & Stress Coach',
      'desc': 'Tips and relaxation sounds (meditation, breathing guide). Sleep duration logging.',
    },
    {
      'title': 'Daily Voice Tips (Audio Coach)',
      'desc': 'Get motivational health tips via audio. Available in Kinyarwanda and English.',
    },
    {
      'title': 'Premium Skins & Themes',
      'desc': 'Unlock beautiful themes or background designs for the app.',
    },
    {
      'title': 'BMI Comparison Tool',
      'desc': 'Compare your BMI with average national or global stats. Fun facts based on your age group and gender.',
    },
    {
      'title': 'Offline Access',
      'desc': 'Use the BMI calculator, tips, and diet logs offline. Useful for users with limited internet access.',
    },
  ];

  void _onFeatureTap(int index) {
    if (userHasPremiumAccess || (tempPremiumAccess && accessExpiresAt != null && accessExpiresAt!.isAfter(DateTime.now()))) {
      // Navigate to the feature screen
      Widget? screen;
      switch (index) {
        case 0:
          screen = const PersonalizedDietPlanScreen();
          break;
        case 1:
          screen = const WorkoutPlanScreen();
          break;
        case 2:
          screen = const ProgressTrackerScreen();
          break;
        case 3:
          screen = const WaterIntakeTrackerScreen();
          break;
        case 4:
          screen = const CalorieNutritionCounterScreen();
          break;
      }
      if (screen != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen!),
        );
      }
    } else {
      _showUnlockOptions(index);
    }
  }

  void _showUnlockOptions(int featureIndex) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unlock Premium', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _optionTile(Icons.card_giftcard, 'One-Time Unlock', 'Pay once (e.g., RWF 1500) for lifetime access.', onTap: () {
                    setState(() {
                      userHasPremiumAccess = true;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Premium unlocked!')),
                    );
                  }),
                  const SizedBox(height: 10),
                  _optionTile(Icons.calendar_month, 'Monthly/Yearly Subscription', 'Flexible plans for ongoing access.', onTap: () {
                    setState(() {
                      userHasPremiumAccess = true;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Subscribed to premium!')),
                    );
                  }),
                  const SizedBox(height: 10),
                  _optionTile(Icons.ondemand_video, 'Watch Ads', 'Watch an ad to temporarily unlock a feature.', onTap: () {
                    setState(() {
                      tempPremiumAccess = true;
                      accessExpiresAt = DateTime.now().add(const Duration(hours: 6));
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feature unlocked for 6 hours!')),
                    );
                  }),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Premium Features', style: GoogleFonts.montserrat()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF333333)),
      ),
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Advanced Tools for Premium Users', style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                const SizedBox(height: 24),
                ...features.sublist(0, 5).asMap().entries.map((entry) {
                  final i = entry.key;
                  final f = entry.value;
                  return GestureDetector(
                    onTap: () => _onFeatureTap(i),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lock, color: Colors.amber, size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(f['title']!, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 18)),
                                const SizedBox(height: 4),
                                Text(f['desc']!, style: GoogleFonts.montserrat(fontSize: 15, color: Colors.black54)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 32),
                Text('Unlock Premium', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5676EA))),
                const SizedBox(height: 16),
                _optionTile(Icons.card_giftcard, 'One-Time Unlock', 'Pay once (e.g., RWF 1500) for lifetime access.'),
                const SizedBox(height: 10),
                _optionTile(Icons.calendar_month, 'Monthly/Yearly Subscription', 'Flexible plans for ongoing access.'),
                const SizedBox(height: 10),
                _optionTile(Icons.ondemand_video, 'Watch Ads', 'Watch an ad to temporarily unlock a feature.'),
                const SizedBox(height: 32),
                Center(
                  child: Text('Upgrade to unlock all features!', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: Colors.grey[700])),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionTile(IconData icon, String title, String desc, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF5676EA)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(desc, style: GoogleFonts.montserrat(fontSize: 14, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 