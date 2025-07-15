import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/workout_model.dart';
import '../../services/workout_service.dart';

class ManagePremiumScreen extends StatelessWidget {
  ManagePremiumScreen({super.key});
  final WorkoutService _workoutService = WorkoutService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF22A6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF22A6F2),
        elevation: 0,
        title: Text('Manage Premium Content', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Workout>>(
        stream: _workoutService.getWorkouts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final workouts = snapshot.data!;
          if (workouts.isEmpty) return Center(child: Text('No workouts found.'));
          return ListView.separated(
            padding: EdgeInsets.all(24),
            itemCount: workouts.length,
            separatorBuilder: (_, __) => SizedBox(height: 18),
            itemBuilder: (context, i) {
              final w = workouts[i];
              return _PremiumCard(
                icon: Icons.fitness_center,
                title: w.title,
                isPremium: w.isPremium,
                onChanged: (v) => _workoutService.togglePremium(w.id, v),
              );
            },
          );
        },
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isPremium;
  final ValueChanged<bool> onChanged;
  const _PremiumCard({required this.icon, required this.title, required this.isPremium, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF22A6F2).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(14),
              child: Icon(icon, color: const Color(0xFF22A6F2), size: 30),
            ),
            SizedBox(width: 18),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF22A6F2))),
            ),
            Switch(
              value: isPremium,
              onChanged: onChanged,
              activeColor: Colors.orange,
            ),
            SizedBox(width: 8),
            Text(isPremium ? 'Premium' : 'Free', style: TextStyle(fontWeight: FontWeight.bold, color: isPremium ? Colors.orange : Colors.grey)),
          ],
        ),
      ),
    );
  }
} 