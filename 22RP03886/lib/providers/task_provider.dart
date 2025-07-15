import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  List<Task> _tasks = [];

  List<Task> get tasks => _tasks;

  TaskProvider() {
    loadTasks();
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      loadTasks();
    });
  }

  Future<void> loadTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _tasks = [];
      notifyListeners();
      return;
    }

    try {
      print('Loading tasks for user: ${user.uid}');
      
      final snapshot = await _firestore
          .collection('tasks')
          .orderBy('date')
          .get();
      
      print('Received ${snapshot.docs.length} tasks from Firestore');
      
      _tasks = snapshot.docs.map((doc) {
        final data = doc.data();
        print('Task data: $data');
        return Task(
          docId: doc.id,
          id: doc.id.hashCode, // For legacy/local use
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          category: data['category'] ?? 'General',
          date: DateTime.parse(data['date']),
          time: TimeOfDay(
            hour: int.parse(data['time'].split(':')[0]),
            minute: int.parse(data['time'].split(':')[1]),
          ),
          isCompleted: data['isCompleted'] ?? false,
          reminder: data['reminder'] ?? false,
        );
      }).toList();
      
      notifyListeners();
    } catch (e) {
      print('Error loading tasks: $e');
      _tasks = [];
      notifyListeners();
    }
  }

  Future<void> addTask(Task task) async {
    try {
      // Get current user ID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('tasks').add({
        'userId': user.uid, // Add user ID to associate tasks with user
        'title': task.title,
        'description': task.description,
        'category': task.category,
        'date': task.date.toIso8601String(),
        'time': '${task.time.hour}:${task.time.minute}',
        'isCompleted': task.isCompleted,
        'reminder': task.reminder,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      // Reload tasks after adding
      await loadTasks();
      
      // Track task creation analytics
      _trackTaskCreated(task.category);
    } catch (e) {
      print('Error adding task: $e');
      rethrow; // Re-throw to show error in UI
    }
  }

  Future<void> updateTask(Task task) async {
    if (task.docId == null) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('tasks').doc(task.docId).update({
        'title': task.title,
        'description': task.description,
        'category': task.category,
        'date': task.date.toIso8601String(),
        'time': '${task.time.hour}:${task.time.minute}',
        'isCompleted': task.isCompleted,
        'reminder': task.reminder,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Reload tasks after updating
      await loadTasks();
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(Task task) async {
    if (task.docId == null) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('tasks').doc(task.docId).delete();
      
      // Reload tasks after deleting
      await loadTasks();
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }

  // Refresh tasks manually
  void refreshTasks() {
    loadTasks();
  }

  // Analytics tracking methods
  void _trackTaskCreated(String category) {
    try {
      // Note: Analytics tracking will be handled by the UI layer
      // where we have access to BuildContext
      print('Task created tracked: $category');
    } catch (e) {
      print('Error tracking task created: $e');
    }
  }
} 