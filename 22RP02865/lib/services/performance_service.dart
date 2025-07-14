import 'dart:async';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final Map<String, Stopwatch> _activeTimers = {};
  final Map<String, List<Duration>> _performanceHistory = {};

  // Start timing an operation
  void startTimer(String operationName) {
    _activeTimers[operationName] = Stopwatch()..start();
  }

  // End timing an operation
  Duration endTimer(String operationName) {
    final stopwatch = _activeTimers.remove(operationName);
    if (stopwatch == null) return Duration.zero;
    
    stopwatch.stop();
    final duration = stopwatch.elapsed;
    
    // Store in history
    _performanceHistory.putIfAbsent(operationName, () => []);
    _performanceHistory[operationName]!.add(duration);
    
    // Keep only last 10 measurements
    if (_performanceHistory[operationName]!.length > 10) {
      _performanceHistory[operationName]!.removeAt(0);
    }
    
    // Log if operation takes too long
    if (duration.inMilliseconds > 1000) {
      print('⚠️ Slow operation detected: $operationName took ${duration.inMilliseconds}ms');
    }
    
    return duration;
  }

  // Get average time for an operation
  Duration getAverageTime(String operationName) {
    final history = _performanceHistory[operationName];
    if (history == null || history.isEmpty) return Duration.zero;
    
    final totalMilliseconds = history.fold<int>(
      0, 
      (sum, duration) => sum + duration.inMilliseconds
    );
    
    return Duration(milliseconds: totalMilliseconds ~/ history.length);
  }

  // Get the slowest operations
  List<MapEntry<String, Duration>> getSlowestOperations({int limit = 5}) {
    final averages = _performanceHistory.entries.map((entry) {
      return MapEntry(entry.key, getAverageTime(entry.key));
    }).toList();
    
    averages.sort((a, b) => b.value.compareTo(a.value));
    return averages.take(limit).toList();
  }

  // Clear performance history
  void clearHistory() {
    _performanceHistory.clear();
  }

  // Get performance summary
  Map<String, dynamic> getPerformanceSummary() {
    final summary = <String, dynamic>{};
    
    for (final entry in _performanceHistory.entries) {
      final operationName = entry.key;
      final history = entry.value;
      
      if (history.isNotEmpty) {
        final average = getAverageTime(operationName);
        final min = history.reduce((a, b) => a < b ? a : b);
        final max = history.reduce((a, b) => a > b ? a : b);
        
        summary[operationName] = {
          'average': average.inMilliseconds,
          'min': min.inMilliseconds,
          'max': max.inMilliseconds,
          'count': history.length,
        };
      }
    }
    
    return summary;
  }
} 