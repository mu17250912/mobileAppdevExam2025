import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_storage.dart';
import '../services/analytics_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskStorage _taskStorage = TaskStorage();
  final AnalyticsService _analytics = AnalyticsService();
  List<Task> _tasks = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(hours: 24);
  bool _isRefreshing = false;
  bool _hasCachedData = false;
  bool _hasSyncError = false;
  String _lastSyncError = '';

  TaskProvider() {
    _initializeTasksImmediately();
  }

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isRefreshing => _isRefreshing;
  bool get hasSyncError => _hasSyncError;
  String get lastSyncError => _lastSyncError;
  
  // Improved hasCachedData logic that checks both local state and TaskStorage
  bool get hasCachedData => _hasCachedData || TaskStorage.hasCachedData || _tasks.isNotEmpty;

  // Initialize tasks immediately with local storage
  void _initializeTasksImmediately() {
    // Try to load from memory cache first - this is synchronous
    final cachedTasks = TaskStorage.cachedTasks;
    if (cachedTasks != null && cachedTasks.isNotEmpty) {
      _tasks = cachedTasks;
      _lastFetchTime = DateTime.now();
      _isInitialized = true;
      _hasCachedData = true;
      _hasSyncError = false;
      notifyListeners();
      
      // Load fresh data in background
      _loadTasksInBackground();
      return;
    }
    
    // If no memory cache, try local storage
    _loadFromLocalStorage();
  }

  // Load from local storage
  Future<void> _loadFromLocalStorage() async {
    try {
      await TaskStorage.preloadFromLocalStorage();
      final cachedTasks = TaskStorage.cachedTasks;
      if (cachedTasks != null && cachedTasks.isNotEmpty) {
        _tasks = cachedTasks;
        _lastFetchTime = DateTime.now();
        _isInitialized = true;
        _hasCachedData = true;
        _hasSyncError = false;
        notifyListeners();
        
        // Load fresh data in background
        _loadTasksInBackground();
        return;
      }
    } catch (e) {
      print('Error loading from local storage: $e');
    }
    
    // If no local data, start with empty list and load in background
    _tasks = [];
    _isInitialized = true;
    _hasCachedData = false;
    _hasSyncError = false;
    notifyListeners();
    
    // Load data in background
    _loadTasksInBackground();
  }

  // Load tasks in background without blocking UI
  Future<void> _loadTasksInBackground() async {
    try {
      final newTasks = await _taskStorage.getTasks();
      if (newTasks.isNotEmpty) {
        _tasks = newTasks;
        _lastFetchTime = DateTime.now();
        _hasCachedData = true;
        _hasSyncError = false;
        notifyListeners();
      }
    } catch (e) {
      print('Background task load failed: $e');
      _hasSyncError = true;
      _lastSyncError = e.toString();
      notifyListeners();
    }
  }

  // Smart loading with aggressive cache - only force refresh when absolutely necessary
  Future<void> loadTasks({bool forceRefresh = false}) async {
    // If we have recent data, don't reload
    if (!forceRefresh && 
        _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return; // Use existing data
    }

    // Only show loading if we have no data at all
    if (_tasks.isEmpty) {
      _setLoading(true);
    }

    try {
      final newTasks = await _taskStorage.getTasks();
      _tasks = newTasks;
      _lastFetchTime = DateTime.now();
      _hasCachedData = true;
      _hasSyncError = false;
      _lastSyncError = '';
      notifyListeners();
    } catch (e) {
      print('TaskProvider: Error loading tasks: $e');
      _hasSyncError = true;
      _lastSyncError = e.toString();
      notifyListeners();
      // Keep existing tasks if fetch fails
      // Don't rethrow the error to prevent UI from breaking
    } finally {
      _setLoading(false);
    }
  }

  // Enhanced task addition with better error handling
  Future<void> addTask(Task task) async {
    // Add to local state immediately for optimistic UI
    _tasks.add(task);
    notifyListeners();

    try {
      await _taskStorage.addTask(task);
      await _analytics.trackTaskCreated(task.subject);
      
      // Update the task with the real ID from Firebase
      final index = _tasks.indexWhere((t) => t.id == null);
      if (index != -1) {
        _tasks[index] = task;
        notifyListeners();
      }
      
      // Clear any previous sync errors
      _hasSyncError = false;
      _lastSyncError = '';
      notifyListeners();
    } catch (e) {
      print('Error adding task: $e');
      _hasSyncError = true;
      _lastSyncError = e.toString();
      notifyListeners();
      
      // Show user-friendly error message
      if (e.toString().contains('User not authenticated')) {
        throw Exception('Please log in to add tasks');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error. Task saved locally and will sync when connection is restored.');
      } else {
        throw Exception('Failed to add task. Please try again.');
      }
    }
  }

  // Enhanced task deletion with better error handling
  Future<void> deleteTask(Task task) async {
    // Remove from local state immediately for optimistic UI
    _tasks.removeWhere((t) => t.id == task.id);
    notifyListeners();

    try {
      await _taskStorage.deleteTask(task);
      
      // Clear any previous sync errors
      _hasSyncError = false;
      _lastSyncError = '';
      notifyListeners();
    } catch (e) {
      print('Error deleting task: $e');
      _hasSyncError = true;
      _lastSyncError = e.toString();
      notifyListeners();
      // Keep the deletion even if Firebase fails - it will be synced later
    }
  }

  // Enhanced task update with better error handling
  Future<void> updateTask(Task task) async {
    final oldTask = _tasks.firstWhere((t) => t.id == task.id);
    final wasCompleted = oldTask.isCompleted;
    
    // Update local state immediately for optimistic UI
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      notifyListeners();
    }

    try {
      await _taskStorage.updateTask(task);
      
      // Track task completion if status changed to completed
      if (!wasCompleted && task.isCompleted) {
        await _analytics.trackTaskCompleted(task.subject);
      }
      
      // Clear any previous sync errors
      _hasSyncError = false;
      _lastSyncError = '';
      notifyListeners();
    } catch (e) {
      print('Error updating task: $e');
      _hasSyncError = true;
      _lastSyncError = e.toString();
      notifyListeners();
      // Keep the update even if Firebase fails - it will be synced later
    }
  }

  // Enhanced sync with Firebase
  Future<void> syncWithFirebase() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous syncs
    
    _isRefreshing = true;
    _hasSyncError = false;
    _lastSyncError = '';
    notifyListeners();
    
    try {
      await _taskStorage.syncWithFirebase();
      
      // Refresh local data after sync
      final newTasks = await _taskStorage.getTasks();
      _tasks = newTasks;
      _lastFetchTime = DateTime.now();
      _hasCachedData = true;
      _hasSyncError = false;
      _lastSyncError = '';
      
      notifyListeners();
    } catch (e) {
      print('TaskProvider: Sync failed: $e');
      _hasSyncError = true;
      _lastSyncError = e.toString();
      notifyListeners();
      // Don't rethrow the error, just log it and keep existing data
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // Get tasks by date with local filtering
  List<Task> getTasksByDate(DateTime date) {
    return _tasks
        .where((task) =>
            task.dateTime.year == date.year &&
            task.dateTime.month == date.month &&
            task.dateTime.day == date.day)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // Get upcoming tasks with local filtering
  List<Task> getUpcomingTasks() {
    final now = DateTime.now();
    return _tasks
        .where((task) => !task.isCompleted && task.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // Get completed tasks count
  int get completedTasksCount => _tasks.where((t) => t.isCompleted).length;

  // Get total tasks count
  int get totalTasksCount => _tasks.length;

  // Get progress percentage
  double get progressPercentage => 
      totalTasksCount == 0 ? 0.0 : completedTasksCount / totalTasksCount;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Force refresh for manual refresh
  Future<void> refresh() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous refreshes
    
    _isRefreshing = true;
    _hasSyncError = false;
    _lastSyncError = '';
    notifyListeners();
    
    try {
      await loadTasks(forceRefresh: true);
    } catch (e) {
      print('TaskProvider: Refresh failed: $e');
      _hasSyncError = true;
      _lastSyncError = e.toString();
      notifyListeners();
      // Don't rethrow the error, just log it and keep existing data
      // This prevents the UI from breaking when refresh fails
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // Preload data for better performance
  Future<void> preloadData() async {
    if (!_isInitialized) {
      await _loadFromLocalStorage();
    }
  }

  // Get cached data immediately without any loading
  List<Task> getCachedTasks() {
    return TaskStorage.cachedTasks ?? _tasks;
  }

  // Get tasks immediately without any async operations
  List<Task> getTasksImmediately() {
    return _tasks;
  }

  // Clear sync errors
  void clearSyncErrors() {
    _hasSyncError = false;
    _lastSyncError = '';
    notifyListeners();
  }
}