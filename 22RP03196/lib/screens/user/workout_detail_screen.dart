import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/workout_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'package:flutter/material.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final Workout workout;
  const WorkoutDetailScreen({super.key, required this.workout});

  Future<void> _markCompleted(AppUser user, BuildContext context) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final completed = List<String>.from(user.completed ?? []);
    final progress = Map<String, List<String>>.from(user.progress ?? {});
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (!completed.contains(workout.id)) {
      completed.add(workout.id);
    }
    final progList = List<String>.from(progress[workout.id] ?? []);
    if (!progList.contains(today)) {
      progList.add(today);
      progress[workout.id] = progList;
    }
    await ref.update({'completed': completed, 'progress': progress});
    // Show feedback and navigate
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Workout marked as completed!'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
      );
      await Future.delayed(Duration(seconds: 2));
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/progress');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF22A6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF22A6F2),
        elevation: 0,
        title: Text('Workout Detail', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<AppUser?>(
        stream: AuthService().user,
        builder: (context, userSnap) {
          if (!userSnap.hasData) return Center(child: CircularProgressIndicator());
          final user = userSnap.data!;
          final isCompleted = (user.completed ?? []).contains(workout.id);

          if (workout.isPremium && !(user.isPremium ?? false)) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 60, color: Colors.orange),
                        SizedBox(height: 24),
                        Text('Premium Workout', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)),
                        SizedBox(height: 16),
                        Text('Unlock this workout by going premium!', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                        SizedBox(height: 28),
                        ElevatedButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'isPremium': true});
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                            child: Text('Go Premium', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Icon(Icons.accessibility_new, size: 60, color: const Color(0xFF22A6F2)),
                      ),
                      SizedBox(height: 24),
                      Text(workout.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF22A6F2))),
                      SizedBox(height: 18),
                      Text('STEPS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 14)),
                      SizedBox(height: 10),
                      ...workout.steps.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('${e.key + 1}. ${e.value}', style: TextStyle(fontSize: 16)),
                      )),
                      SizedBox(height: 28),
                      Center(
                        child: ElevatedButton(
                          onPressed: isCompleted ? null : () => _markCompleted(user, context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                            child: Text(isCompleted ? 'COMPLETED' : 'MARK AS COMPLETED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCompleted ? Colors.grey : Color(0xFFFF885A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 