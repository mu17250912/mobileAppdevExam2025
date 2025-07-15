import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class NotificationsStatsScreen extends StatelessWidget {
  const NotificationsStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: AuthService().user,
      builder: (context, userSnap) {
        if (!userSnap.hasData) return Scaffold(body: Center(child: CircularProgressIndicator()));
        final user = userSnap.data!;
        final progress = user.progress ?? {};
        // Flatten all completion dates
        final allDates = progress.values.expand((v) => v).toList();
        final uniqueDays = allDates.toSet();
        final days = uniqueDays.length;
        final sessions = allDates.length;
        final goals = progress.length;
        // Calculate streak (consecutive days)
        final today = DateTime.now();
        final last7Days = List.generate(7, (i) => today.subtract(Duration(days: i)).toIso8601String().substring(0, 10)).reversed.toList();
        final completionsPerDay = {for (var d in last7Days) d: 0};
        for (var d in allDates) {
          if (completionsPerDay.containsKey(d)) completionsPerDay[d] = completionsPerDay[d]! + 1;
        }
        int streak = 0;
        for (var d in last7Days.reversed) {
          if (completionsPerDay[d]! > 0) {
            streak++;
          } else {
            break;
          }
        }
        final stats = [
          {'label': 'Days', 'value': days.toString()},
          {'label': 'Sessions', 'value': sessions.toString()},
          {'label': 'Goals', 'value': goals.toString()},
          {'label': 'Streak', 'value': streak.toString()},
        ];
        return Scaffold(
          backgroundColor: const Color(0xFF22A6F2),
          appBar: AppBar(
            backgroundColor: const Color(0xFF22A6F2),
            elevation: 0,
            title: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: stats.map((s) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s['value']!, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF22A6F2))),
                      SizedBox(height: 8),
                      Text(s['label']!, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                    ],
                  )).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 