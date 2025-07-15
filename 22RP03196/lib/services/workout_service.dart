import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_model.dart';

class WorkoutService {
  final _db = FirebaseFirestore.instance;
  final _collection = 'workouts';

  Stream<List<Workout>> getWorkouts() {
    return _db.collection(_collection).snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => Workout.fromMap(doc.data(), doc.id)).toList()
    );
  }

  Future<void> addWorkout(Workout workout) async {
    final docRef = await _db.collection(_collection).add(workout.toMap());
    // Send notification to all users
    final usersSnapshot = await _db.collection('users').get();
    for (final userDoc in usersSnapshot.docs) {
      await _db.collection('notifications').add({
        'userId': userDoc.id,
        'title': 'New Workout Added',
        'body': 'A new workout "${workout.title}" has been added. Check it out!',
        'timestamp': FieldValue.serverTimestamp(),
        'workoutId': docRef.id,
        'read': false,
      });
    }
  }

  Future<void> updateWorkout(Workout workout) async {
    await _db.collection(_collection).doc(workout.id).update(workout.toMap());
  }

  Future<void> deleteWorkout(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }

  Future<void> togglePremium(String id, bool isPremium) async {
    await _db.collection(_collection).doc(id).update({'isPremium': isPremium});
  }
} 