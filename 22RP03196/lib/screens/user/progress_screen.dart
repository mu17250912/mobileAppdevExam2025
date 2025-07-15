import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/workout_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

import 'package:flutter/foundation.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});



  @override
  Widget build(BuildContext context) {
    final userStream = AuthService().user;
    final workoutsStream = FirebaseFirestore.instance.collection('workouts').snapshots().map((s) => s.docs.map((d) => Workout.fromMap(d.data(), d.id)).toList());
    return StreamBuilder<AppUser?>(
      stream: userStream,
      builder: (context, userSnap) {
        if (!userSnap.hasData) return Scaffold(body: Center(child: CircularProgressIndicator()));
        final user = userSnap.data!;
        final progressContent = Scaffold(
          backgroundColor: const Color(0xFF22A6F2),
          appBar: AppBar(
            backgroundColor: const Color(0xFF22A6F2),
            elevation: 0,
            title: Text('Progress', style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: StreamBuilder<List<Workout>>(
            stream: workoutsStream,
            builder: (context, snap) {
              if (!snap.hasData) return Center(child: CircularProgressIndicator());
              final completedIds = user.completed ?? [];
              final completedWorkouts = snap.data!.where((w) => completedIds.contains(w.id)).toList();
              final progress = user.progress ?? {};
              // Flatten all completion dates
              final allDates = progress.values.expand((v) => v).toList();
              final totalCompletions = allDates.length;
              // Count completions per day (last 7 days)
              final today = DateTime.now();
              final last7Days = List.generate(7, (i) => today.subtract(Duration(days: i)).toIso8601String().substring(0, 10)).reversed.toList();
              final completionsPerDay = {for (var d in last7Days) d: 0};
              for (var d in allDates) {
                if (completionsPerDay.containsKey(d)) completionsPerDay[d] = completionsPerDay[d]! + 1;
              }
              // Calculate streak
              int streak = 0;
              for (var d in last7Days.reversed) {
                if (completionsPerDay[d]! > 0) {
                  streak++;
                } else {
                  break;
                }
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                        child: Column(
                          children: [
                            Icon(Icons.bar_chart, size: 60, color: const Color(0xFF22A6F2)),
                            SizedBox(height: 24),
                            Text('Completed Workouts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF22A6F2))),
                            SizedBox(height: 16),
                            Text('$totalCompletions completions', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                            SizedBox(height: 8),
                            Text('Current Streak: $streak days', style: TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: last7Days.map((d) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: Column(
                                  children: [
                                    Text('${d.substring(5)}', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    Container(
                                      width: 18, height: 18,
                                      decoration: BoxDecoration(
                                        color: completionsPerDay[d]! > 0 ? Colors.orange : Colors.grey[300],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(child: Text('${completionsPerDay[d]}', style: TextStyle(fontSize: 10, color: Colors.white))),
                                    ),
                                  ],
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Expanded(
                      child: completedWorkouts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.emoji_emotions, color: Colors.orange, size: 60),
                                SizedBox(height: 16),
                                Text(
                                  'No completed workouts yet!',
                                  style: TextStyle(fontSize: 18, color: Colors.grey[700], fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Start your first workout and begin your fitness journey!',
                                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 24),
                                ElevatedButton.icon(
                                  icon: Icon(Icons.fitness_center, color: Colors.white),
                                  label: Text('Start Workout', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF22A6F2),
                                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pushNamed('/workouts');
                                  },
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: completedWorkouts.length,
                            separatorBuilder: (_, __) => SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final w = completedWorkouts[i];
                              return Card(
                                color: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: ListTile(
                                  leading: Icon(Icons.fitness_center, color: const Color(0xFF22A6F2)),
                                  title: Text(w.title, style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF22A6F2))),
                                  subtitle: Text('${w.steps.length} exercises'),
                                ),
                              );
                            },
                          ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
        return progressContent;
      },
    );
  }
} 