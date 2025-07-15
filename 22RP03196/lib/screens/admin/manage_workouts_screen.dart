import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/workout_model.dart';
import '../../services/workout_service.dart';

class ManageWorkoutsScreen extends StatelessWidget {
  ManageWorkoutsScreen({super.key});
  final WorkoutService _workoutService = WorkoutService();

  void _showWorkoutDialog(BuildContext context, {Workout? workout}) {
    final titleController = TextEditingController(text: workout?.title ?? '');
    final descController = TextEditingController(text: workout?.description ?? '');
    final stepsController = TextEditingController(text: workout?.steps.join('\n') ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(workout == null ? 'Add Workout' : 'Edit Workout'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
              TextField(controller: descController, decoration: InputDecoration(labelText: 'Description')),
              TextField(controller: stepsController, decoration: InputDecoration(labelText: 'Steps (one per line)'), maxLines: 4),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final desc = descController.text.trim();
              final steps = stepsController.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              if (title.isEmpty || desc.isEmpty) return;
              if (workout == null) {
                await _workoutService.addWorkout(Workout(id: '', title: title, description: desc, steps: steps));
              } else {
                await _workoutService.updateWorkout(Workout(id: workout.id, title: title, description: desc, steps: steps, isPremium: workout.isPremium));
              }
              Navigator.pop(ctx);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF22A6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF22A6F2),
        elevation: 0,
        title: Text('Manage Workouts', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Workout>>(
        stream: _workoutService.getWorkouts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final workouts = snapshot.data!;
          return ListView(
            padding: EdgeInsets.all(24),
            children: [
              ...workouts.map((w) => Column(
                children: [
                  _WorkoutAdminCard(
                    icon: Icons.fitness_center,
                    title: w.title,
                    onEdit: () => _showWorkoutDialog(context, workout: w),
                    onDelete: () => _workoutService.deleteWorkout(w.id),
                  ),
                  SizedBox(height: 18),
                ],
              )),
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: ListTile(
                  leading: Icon(Icons.add, color: const Color(0xFF22A6F2)),
                  title: Text('Add New Workout', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () => _showWorkoutDialog(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WorkoutAdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _WorkoutAdminCard({required this.icon, required this.title, required this.onEdit, required this.onDelete});

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
            IconButton(icon: Icon(Icons.edit, color: Colors.orange), onPressed: onEdit),
            IconButton(icon: Icon(Icons.delete, color: Colors.redAccent), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
} 