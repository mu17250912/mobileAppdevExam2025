import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'user/free_workouts_screen.dart';
import 'user/workouts_screen.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  void _onExploreTap(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => FreeWorkoutsScreen()));
  }

  void _onAdvancedTap(BuildContext context, AppUser? user) {
    if (user?.isPremium == true) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => WorkoutsScreen(showPremiumOnly: true)));
    } else {
      Navigator.pushNamed(context, '/go_premium');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: AuthService().user,
      builder: (context, snap) {
        final user = snap.data;
        return Scaffold(
          backgroundColor: const Color(0xFF22A6F2),
          appBar: AppBar(
            backgroundColor: const Color(0xFF22A6F2),
            elevation: 0,
            title: Text('Plans', style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Icon(Icons.directions_run, size: 80, color: const Color(0xFF22A6F2)),
                        ),
                        SizedBox(height: 18),
                        Text('Beginner\'s Plan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF22A6F2))),
                        SizedBox(height: 8),
                        Text('A great way to start your fitness journey!', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                        SizedBox(height: 18),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _onExploreTap(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF22A6F2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Explore'),
                            ),
                            SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () => _onAdvancedTap(context, user),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF22A6F2),
                                side: BorderSide(color: const Color(0xFF22A6F2)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Advanced'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 