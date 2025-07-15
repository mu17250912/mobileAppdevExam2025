import 'package:flutter/material.dart';

class FreeWorkoutsScreen extends StatelessWidget {
  const FreeWorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workouts = [
      {
        'title': "Beginner's Plan",
        'subtitle': '4 Exercises, 5 min',
        'icon': Icons.directions_run,
      },
      {
        'title': 'Upper Body',
        'subtitle': '4 Exercises, 5 min',
        'icon': Icons.fitness_center,
      },
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF22A6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF22A6F2),
        elevation: 0,
        title: Text('Free Workouts', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...workouts.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 18.0),
              child: Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: ListTile(
                  leading: Icon(w['icon'] as IconData, size: 48, color: const Color(0xFF22A6F2)),
                  title: Text(w['title'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF22A6F2))),
                  subtitle: Text(w['subtitle'] as String),
                  onTap: () {},
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
} 