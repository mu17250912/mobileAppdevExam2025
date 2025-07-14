import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';
import 'notification_service.dart';
import 'performance_service.dart';
import 'dart:async';

class TaskStorage {
  final _notificationService = NotificationService();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  // Cache for offline support
  static List<Task>? _cachedTasks;
  static DateTime? _lastCacheTime;
  static const Duration _cacheValidDuration = Duration(hours: 24);
  static bool _isLoading = false;
  static bool _hasInitialized = false;
  static const String _localStorageKey = 'cached_tasks_data';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _pendingChangesKey = 'pending_changes';

  String? get _userId => _auth.currentUser?.uid;

  // Enhanced Firebase connectivity check
  Future<bool> canConnectToFirebase() async {
    if (_userId == null) return false;
    
    try {
      // Test both read and write operations
      final testDoc = _firestore
          .collection('tasks')
          .doc(_userId)
          .collection('userTasks')
          .doc('_test_connection');
      
      // Try to read (should fail gracefully if no permissions)
      await testDoc.get().timeout(const Duration(seconds: 3));
      
      // Try to write a test document (will be deleted immediately)
      await testDoc.set({
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 3));
      
      // Clean up test document
      await testDoc.delete().timeout(const Duration(seconds: 2));
      
      return true;
    } catch (e) {
      print('TaskStorage: Cannot connect to Firebase: $e');
      return false;
    }
  }

  // Get tasks with improved caching strategy
  Future<List<Task>> getTasks() async {
    if (_userId == null) {
      print('TaskStorage: No user ID available');
      return [];
    }

    print('TaskStorage: Getting tasks for user: $_userId');

    // First, try to get from memory cache
    if (_cachedTasks != null && _cachedTasks!.isNotEmpty) {
      print('TaskStorage: Returning ${_cachedTasks!.length} tasks from memory cache');
      return _cachedTasks!;
    }

    // Then, try to get from local storage
    final localTasks = await _getTasksFromLocalStorage();
    if (localTasks.isNotEmpty) {
      _cachedTasks = localTasks;
      _lastCacheTime = DateTime.now();
      _hasInitialized = true;
      print('TaskStorage: Loaded ${localTasks.length} tasks from local storage');
      
      // Sync with Firebase in background if possible
      _syncWithFirebaseInBackground();
      return localTasks;
    }

    // If no local data, try Firebase immediately
    if (!_isLoading) {
      return await _loadFromFirebase();
    }

    return [];
  }

  // Enhanced Firebase loading with better error handling
  Future<List<Task>> _loadFromFirebase() async {
    if (_isLoading) return [];
    
    try {
      _isLoading = true;
      print('TaskStorage: Loading tasks from Firebase for user: $_userId');
      
      final snapshot = await _firestore
          .collection('tasks')
          .doc(_userId)
          .collection('userTasks')
          .orderBy('dateTime', descending: false)
          .get()
          .timeout(const Duration(seconds: 15));
      
      final tasks = snapshot.docs
          .map((doc) {
            try {
              return Task.fromMap(doc.data(), doc.id);
            } catch (e) {
              print('TaskStorage: Error parsing task ${doc.id}: $e');
              return null;
            }
          })
          .where((task) => task != null)
          .cast<Task>()
          .toList();
      
      print('TaskStorage: Loaded ${tasks.length} tasks from Firebase');
      
      // Update cache and local storage
      _cachedTasks = tasks;
      _lastCacheTime = DateTime.now();
      _hasInitialized = true;
      
      await _saveTasksToLocalStorage(tasks);
      await _updateLastSyncTime();
      
      return tasks;
    } catch (e) {
      print('TaskStorage: Firebase load failed: $e');
      return [];
    } finally {
      _isLoading = false;
    }
  }

  // Background sync with Firebase
  void _syncWithFirebaseInBackground() {
    if (_isLoading) return;
    
    Future.microtask(() async {
      try {
        await _loadFromFirebase();
      } catch (e) {
        print('TaskStorage: Background Firebase sync failed: $e');
      }
    });
  }

  // Get tasks from local storage with error handling
  Future<List<Task>> _getTasksFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getString(_localStorageKey);
      if (tasksJson != null) {
        final List<dynamic> tasksList = json.decode(tasksJson);
        return tasksList.map((taskMap) => Task.fromMap(taskMap, taskMap['id'] ?? '')).toList();
      }
    } catch (e) {
      print('TaskStorage: Error reading from local storage: $e');
    }
    return [];
  }

  // Save tasks to local storage with error handling
  Future<void> _saveTasksToLocalStorage(List<Task> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = json.encode(tasks.map((task) => task.toMap()).toList());
      await prefs.setString(_localStorageKey, tasksJson);
      print('TaskStorage: Saved ${tasks.length} tasks to local storage');
    } catch (e) {
      print('TaskStorage: Error saving to local storage: $e');
    }
  }

  // Update last sync timestamp
  Future<void> _updateLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('TaskStorage: Error updating sync timestamp: $e');
    }
  }

  // Enhanced task addition with better error handling
  Future<void> addTask(Task task) async {
    if (_userId == null) {
      print('TaskStorage: Cannot add task - no user ID');
      throw Exception('User not authenticated');
    }
    
    print('TaskStorage: Adding task: ${task.subject}');
    
    // Add to local cache immediately for optimistic UI
    _cachedTasks?.add(task);
    _lastCacheTime = DateTime.now();
    
    // Save to local storage immediately
    await _saveTasksToLocalStorage(_cachedTasks ?? []);
    
    try {
      // Try to save to Firebase
      final docRef = await _firestore
          .collection('tasks')
          .doc(_userId)
          .collection('userTasks')
          .add(task.toMap());
      
      // Update task with Firebase ID
      task.id = docRef.id;
      
      // Update cache with the task that has the real ID
      final index = _cachedTasks?.indexWhere((t) => t.subject == task.subject && t.dateTime == task.dateTime);
      if (index != null && index != -1 && _cachedTasks != null) {
        _cachedTasks![index] = task;
        await _saveTasksToLocalStorage(_cachedTasks!);
      }
      
      // Schedule notification if needed
      if (task.hasReminder) {
        await _notificationService.scheduleTaskNotification(task);
      }
      
      print('TaskStorage: Task added successfully with ID: ${task.id}');
    } catch (e) {
      print('TaskStorage: Failed to save task to Firebase: $e');
      // Task is still saved locally, will sync later
      // Don't throw error to prevent UI from breaking
    }
  }

  // Enhanced task update with better error handling
  Future<void> updateTask(Task task) async {
    if (_userId == null || task.id == null) {
      print('TaskStorage: Cannot update task - missing user ID or task ID');
      return;
    }
    
    print('TaskStorage: Updating task: ${task.subject} (ID: ${task.id})');
    
    // Update cache and local storage immediately
    if (_cachedTasks != null) {
      final index = _cachedTasks!.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _cachedTasks![index] = task;
        _lastCacheTime = DateTime.now();
        await _saveTasksToLocalStorage(_cachedTasks!);
      }
    }
    
    try {
      final taskData = task.toMap();
      print('TaskStorage: Updating task data: $taskData');
      
      await _firestore
          .collection('tasks')
          .doc(_userId)
          .collection('userTasks')
          .doc(task.id)
          .update(taskData)
          .timeout(const Duration(seconds: 10));
      
      print('TaskStorage: Task updated successfully in Firebase');
      
      // Handle notifications in background
      _handleTaskNotificationsInBackground(task);
    } catch (e) {
      print('TaskStorage: Error updating task in Firebase: $e');
      // Store pending change for later sync
      await _storePendingChange('update', task);
    }
  }

  // Enhanced task deletion with better error handling
  Future<void> deleteTask(Task task) async {
    if (_userId == null || task.id == null) {
      print('TaskStorage: Cannot delete task - missing user ID or task ID');
      return;
    }
    
    print('TaskStorage: Deleting task: ${task.subject} (ID: ${task.id})');
    
    // Remove from cache and local storage immediately
    _cachedTasks?.removeWhere((t) => t.id == task.id);
    _lastCacheTime = DateTime.now();
    if (_cachedTasks != null) {
      await _saveTasksToLocalStorage(_cachedTasks!);
    }
    
    try {
      await _firestore
          .collection('tasks')
          .doc(_userId)
          .collection('userTasks')
          .doc(task.id)
          .delete()
          .timeout(const Duration(seconds: 10));
      
      print('TaskStorage: Task deleted successfully from Firebase');
      
      // Cancel notification in background
      _cancelNotificationInBackground(task);
    } catch (e) {
      print('TaskStorage: Error deleting task from Firebase: $e');
      // Store pending change for later sync
      await _storePendingChange('delete', task);
    }
  }

  // Store pending changes for later sync
  Future<void> _storePendingChange(String operation, Task task) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingChanges = prefs.getStringList(_pendingChangesKey) ?? [];
      
      final change = json.encode({
        'operation': operation,
        'task': task.toMap(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      pendingChanges.add(change);
      await prefs.setStringList(_pendingChangesKey, pendingChanges);
      print('TaskStorage: Stored pending $operation change for task: ${task.subject}');
    } catch (e) {
      print('TaskStorage: Error storing pending change: $e');
    }
  }

  // Sync pending changes with Firebase
  Future<void> _syncPendingChanges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingChanges = prefs.getStringList(_pendingChangesKey) ?? [];
      
      if (pendingChanges.isEmpty) return;
      
      print('TaskStorage: Syncing ${pendingChanges.length} pending changes');
      
      for (final changeJson in pendingChanges) {
        try {
          final change = json.decode(changeJson);
          final operation = change['operation'];
          final taskData = change['task'];
          final task = Task.fromMap(taskData, taskData['id'] ?? '');
          
          switch (operation) {
            case 'add':
              await _firestore
                  .collection('tasks')
                  .doc(_userId)
                  .collection('userTasks')
                  .add(taskData);
              break;
            case 'update':
              if (task.id != null) {
                await _firestore
                    .collection('tasks')
                    .doc(_userId)
                    .collection('userTasks')
                    .doc(task.id)
                    .update(taskData);
              }
              break;
            case 'delete':
              if (task.id != null) {
                await _firestore
                    .collection('tasks')
                    .doc(_userId)
                    .collection('userTasks')
                    .doc(task.id)
                    .delete();
              }
              break;
          }
        } catch (e) {
          print('TaskStorage: Error syncing pending change: $e');
        }
      }
      
      // Clear pending changes after successful sync
      await prefs.remove(_pendingChangesKey);
      print('TaskStorage: Successfully synced all pending changes');
    } catch (e) {
      print('TaskStorage: Error syncing pending changes: $e');
    }
  }

  // Enhanced sync with Firebase including pending changes
  Future<void> syncWithFirebase() async {
    if (_userId == null) {
      throw Exception('Cannot sync - no user ID available. Please log in again.');
    }
    
    print('TaskStorage: Forcing sync with Firebase for user: $_userId');
    
    try {
      _isLoading = true;
      
      // First, sync any pending changes
      await _syncPendingChanges();
      
      // Then, fetch fresh data from Firebase
      final snapshot = await _firestore
          .collection('tasks')
          .doc(_userId)
          .collection('userTasks')
          .orderBy('dateTime', descending: false)
          .get()
          .timeout(const Duration(seconds: 20));
      
      final tasks = snapshot.docs
          .map((doc) {
            try {
              return Task.fromMap(doc.data(), doc.id);
            } catch (e) {
              print('TaskStorage: Error parsing task ${doc.id}: $e');
              return null;
            }
          })
          .where((task) => task != null)
          .cast<Task>()
          .toList();
      
      print('TaskStorage: Sync completed - ${tasks.length} tasks loaded from Firebase');
      
      // Update cache and local storage
      _cachedTasks = tasks;
      _lastCacheTime = DateTime.now();
      _hasInitialized = true;
      
      await _saveTasksToLocalStorage(tasks);
      await _updateLastSyncTime();
      
      print('TaskStorage: Tasks saved to local storage successfully');
    } catch (e) {
      print('TaskStorage: Sync failed: $e');
      
      // Provide more specific error messages
      String errorMessage;
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Access denied. Please check your login status.';
      } else if (e.toString().contains('unavailable')) {
        errorMessage = 'Firebase service is temporarily unavailable. Please try again later.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else {
        errorMessage = 'Sync failed: ${e.toString()}';
      }
      
      throw Exception(errorMessage);
    } finally {
      _isLoading = false;
    }
  }

  // Get upcoming tasks
  Future<List<Task>> getUpcomingTasks() async {
    final now = DateTime.now();
    final allTasks = await getTasks();
    return allTasks
        .where((task) => !task.isCompleted && task.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // Get tasks by date
  Future<List<Task>> getTasksByDate(DateTime date) async {
    final allTasks = await getTasks();
    return allTasks
        .where((task) =>
            task.dateTime.year == date.year &&
            task.dateTime.month == date.month &&
            task.dateTime.day == date.day)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // Background operations
  void _scheduleNotificationInBackground(Task task) {
    Future.microtask(() async {
      try {
        await _notificationService.scheduleTaskNotification(task);
        print('TaskStorage: Notification scheduled for task: ${task.subject}');
      } catch (e) {
        print('TaskStorage: Error scheduling notification: $e');
      }
    });
  }

  void _handleTaskNotificationsInBackground(Task task) {
    Future.microtask(() async {
      try {
        if (task.isCompleted) {
          await _notificationService.cancelNotification(task.hashCode);
          print('TaskStorage: Notification cancelled for completed task: ${task.subject}');
        } else {
          await _notificationService.scheduleTaskNotification(task);
          print('TaskStorage: Notification rescheduled for task: ${task.subject}');
        }
      } catch (e) {
        print('TaskStorage: Error handling task notifications: $e');
      }
    });
  }

  void _cancelNotificationInBackground(Task task) {
    Future.microtask(() async {
      try {
        await _notificationService.cancelNotification(task.hashCode);
        print('TaskStorage: Notification cancelled for deleted task: ${task.subject}');
      } catch (e) {
        print('TaskStorage: Error canceling notification: $e');
      }
    });
  }

  // Clear cache and local storage
  static Future<void> clearCache() async {
    print('TaskStorage: Clearing cache and local storage');
    _cachedTasks = null;
    _lastCacheTime = null;
    _hasInitialized = false;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localStorageKey);
      await prefs.remove(_lastSyncKey);
      await prefs.remove(_pendingChangesKey);
      print('TaskStorage: Cache cleared successfully');
    } catch (e) {
      print('TaskStorage: Error clearing local storage: $e');
    }
  }

  // Check if we have cached data
  static bool get hasCachedData => _cachedTasks != null && _cachedTasks!.isNotEmpty && _lastCacheTime != null;

  // Get cached data without network call
  static List<Task>? get cachedTasks => _cachedTasks;

  // Force refresh cache
  static void invalidateCache() {
    print('TaskStorage: Invalidating cache');
    _lastCacheTime = null;
  }

  // Check if data has been initialized
  static bool get isInitialized => _hasInitialized;
  
  // Check if we're currently loading
  static bool get isLoading => _isLoading;

  // Preload data from local storage
  static Future<void> preloadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getString(_localStorageKey);
      if (tasksJson != null) {
        final List<dynamic> tasksList = json.decode(tasksJson);
        _cachedTasks = tasksList.map((taskMap) => Task.fromMap(taskMap, taskMap['id'] ?? '')).toList();
        _lastCacheTime = DateTime.now();
        _hasInitialized = true;
        print('TaskStorage: Preloaded ${_cachedTasks!.length} tasks from local storage');
      } else {
        // Mark as initialized even if no data
        _hasInitialized = true;
        print('TaskStorage: No local data found, marked as initialized');
      }
    } catch (e) {
      print('TaskStorage: Error preloading from local storage: $e');
      // Mark as initialized even on error
      _hasInitialized = true;
    }
  }
}
