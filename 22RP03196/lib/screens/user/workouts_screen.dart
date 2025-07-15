import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/workout_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../screens/user/workout_detail_screen.dart';

import 'package:flutter/foundation.dart';

class WorkoutsScreen extends StatelessWidget {
  final bool showPremiumOnly;
  final String? area;
  const WorkoutsScreen({super.key, this.showPremiumOnly = false, this.area});

  Future<void> _toggleFavorite(String workoutId, AppUser user, bool isFav) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final newFavs = List<String>.from(user.favorites ?? []);
    if (isFav) {
      newFavs.remove(workoutId);
    } else {
      newFavs.add(workoutId);
    }
    await ref.update({'favorites': newFavs});
  }



  @override
  Widget build(BuildContext context) {
    final userStream = AuthService().user;
    final workoutsStream = FirebaseFirestore.instance.collection('workouts').snapshots().map((s) => s.docs.map((d) => Workout.fromMap(d.data(), d.id)).toList());
    return Scaffold(
      backgroundColor: const Color(0xFF22A6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF22A6F2),
        elevation: 0,
        title: Text('Workouts', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<AppUser?>(
        stream: userStream,
        builder: (context, userSnap) {
          if (!userSnap.hasData) return Center(child: CircularProgressIndicator());
          final user = userSnap.data!;
          return StreamBuilder<List<Workout>>(
            stream: workoutsStream,
            builder: (context, snap) {
              if (!snap.hasData) return Center(child: CircularProgressIndicator());
              var workouts = snap.data!;
              if (showPremiumOnly) {
                workouts = workouts.where((w) => w.isPremium).toList();
              }
              if (area != null) {
                workouts = workouts.where((w) => (w.area != null && w.area!.toLowerCase() == area!.toLowerCase())).toList();
              }
              final content = ListView(
                padding: EdgeInsets.all(20),
                children: [
                  ...workouts.map((w) => Column(
                    children: [
                      _WorkoutCard(
                        icon: Icons.fitness_center,
                        title: w.title,
                        subtitle: '${w.steps.length} exercises',
                        isFavorite: (user.favorites ?? []).contains(w.id),
                        onFavorite: () => _toggleFavorite(w.id, user, (user.favorites ?? []).contains(w.id)),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workout: w))),
                      ),
                      SizedBox(height: 18),
                    ],
                  )),
                ],
              );
              return content;
            },
          );
        },
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;
  const _WorkoutCard({required this.icon, required this.title, required this.subtitle, required this.isFavorite, required this.onFavorite, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Card(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF22A6F2).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(16),
                child: Icon(icon, color: const Color(0xFF22A6F2), size: 36),
              ),
              SizedBox(width: 22),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF22A6F2))),
                  SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                ],
              ),
              Spacer(),
              IconButton(
                icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border, color: isFavorite ? Colors.orange : Colors.grey),
                onPressed: onFavorite,
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
} 