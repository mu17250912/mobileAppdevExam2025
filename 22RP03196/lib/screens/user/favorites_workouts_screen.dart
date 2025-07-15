import 'package:flutter/material.dart';

class FavoritesWorkoutsScreen extends StatelessWidget {
  const FavoritesWorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = [
      {
        'title': 'Affirm Player Stretch',
        'subtitle': '6 Exercises, 7 min',
        'icon': Icons.self_improvement,
      },
      {
        'title': 'Upper Body',
        'subtitle': '4 Exercises, 7 min',
        'icon': Icons.fitness_center,
      },
      {
        'title': 'Interval Jumping',
        'subtitle': '5 Exercises, 7 min',
        'icon': Icons.directions_run,
      },
      {
        'title': 'For Kids',
        'subtitle': '6 Workouts',
        'icon': Icons.child_care,
      },
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF22A6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF22A6F2),
        elevation: 0,
        title: Text('Favorites', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...favorites.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 18.0),
              child: Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: ListTile(
                  leading: Icon(w['icon'] as IconData, size: 40, color: const Color(0xFF22A6F2)),
                  title: Text(w['title'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF22A6F2))),
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