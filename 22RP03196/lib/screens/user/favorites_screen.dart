import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/workout_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Future<void> _removeFavorite(String workoutId, AppUser user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final newFavs = List<String>.from(user.favorites ?? []);
    newFavs.remove(workoutId);
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
        title: Text('Favorites', style: TextStyle(fontWeight: FontWeight.bold)),
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
              final favIds = user.favorites ?? [];
              final favWorkouts = snap.data!.where((w) => favIds.contains(w.id)).toList();
              if (favWorkouts.isEmpty) {
                return Center(child: Text('Your favorite workouts will appear here!', style: TextStyle(fontSize: 16, color: Colors.grey[700])));
              }
              return ListView.separated(
                padding: EdgeInsets.all(24),
                itemCount: favWorkouts.length,
                separatorBuilder: (_, __) => SizedBox(height: 18),
                itemBuilder: (context, i) {
                  final w = favWorkouts[i];
                  return Card(
                    color: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: ListTile(
                      leading: Icon(Icons.fitness_center, color: const Color(0xFF22A6F2)),
                      title: Text(w.title, style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF22A6F2))),
                      subtitle: Text('${w.steps.length} exercises'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeFavorite(w.id, user),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
} 