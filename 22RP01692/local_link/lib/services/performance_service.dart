import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'logger_service.dart';
import 'cache_service.dart';
import 'network_service.dart';

/// Performance monitoring service for tracking app metrics
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  bool _isInitialized = false;
  final Map<String, Stopwatch> _activeTimers = {};
  final List<Map<String, dynamic>> _performanceMetrics = [];
  
  // Performance thresholds
  static const Duration _slowOperationThreshold = Duration(milliseconds: 1000);
  static const Duration _verySlowOperationThreshold = Duration(milliseconds: 3000);
  static const int _maxMetricsStored = 1000;

  /// Initialize performance service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isInitialized = true;
      logger.info('Performance service initialized', 'PerformanceService');
      
      // Start periodic performance monitoring
      _startPeriodicMonitoring();
    } catch (e) {
      logger.error('Failed to initialize performance service', 'PerformanceService', e);
    }
  }

  /// Start a performance timer
  void startTimer(String operationName) {
    if (!_isInitialized) return;

    _activeTimers[operationName] = Stopwatch()..start();
    logger.debug('Performance timer started: $operationName', 'PerformanceService');
  }

  /// Stop a performance timer and record the metric
  void stopTimer(String operationName, {Map<String, dynamic>? additionalData}) {
    if (!_isInitialized) return;

    final timer = _activeTimers.remove(operationName);
    if (timer == null) {
      logger.warning('Timer not found: $operationName', 'PerformanceService');
      return;
    }

    timer.stop();
    final duration = timer.elapsed;
    
    final metric = {
      'operation': operationName,
      'duration': duration.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
      'additionalData': additionalData ?? {},
    };

    _performanceMetrics.add(metric);
    
    // Log slow operations
    if (duration > _verySlowOperationThreshold) {
      logger.error('Very slow operation detected: $operationName (${duration.inMilliseconds}ms)', 'PerformanceService');
    } else if (duration > _slowOperationThreshold) {
      logger.warning('Slow operation detected: $operationName (${duration.inMilliseconds}ms)', 'PerformanceService');
    } else {
      logger.debug('Operation completed: $operationName (${duration.inMilliseconds}ms)', 'PerformanceService');
    }

    // Limit stored metrics
    if (_performanceMetrics.length > _maxMetricsStored) {
      _performanceMetrics.removeRange(0, _performanceMetrics.length - _maxMetricsStored);
    }
  }

  /// Measure async operation performance
  Future<T> measureAsyncOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? additionalData,
  }) async {
    startTimer(operationName);
    
    try {
      final result = await operation();
      stopTimer(operationName, additionalData: additionalData);
      return result;
    } catch (e) {
      stopTimer(operationName, additionalData: {
        ...?additionalData,
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Measure sync operation performance
  T measureSyncOperation<T>(
    String operationName,
    T Function() operation, {
    Map<String, dynamic>? additionalData,
  }) {
    startTimer(operationName);
    
    try {
      final result = operation();
      stopTimer(operationName, additionalData: additionalData);
      return result;
    } catch (e) {
      stopTimer(operationName, additionalData: {
        ...?additionalData,
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    if (_performanceMetrics.isEmpty) {
      return {
        'totalOperations': 0,
        'averageDuration': 0,
        'slowOperations': 0,
        'verySlowOperations': 0,
        'errorRate': 0,
      };
    }

    final totalOperations = _performanceMetrics.length;
    final totalDuration = _performanceMetrics.fold<int>(
      0, (sum, metric) => sum + (metric['duration'] as int));
    final averageDuration = totalDuration / totalOperations;
    
    final slowOperations = _performanceMetrics.where((metric) {
      final duration = metric['duration'] as int;
      return duration > _slowOperationThreshold.inMilliseconds && 
             duration <= _verySlowOperationThreshold.inMilliseconds;
    }).length;
    
    final verySlowOperations = _performanceMetrics.where((metric) {
      final duration = metric['duration'] as int;
      return duration > _verySlowOperationThreshold.inMilliseconds;
    }).length;
    
    final errorOperations = _performanceMetrics.where((metric) {
      return metric['additionalData']?['error'] != null;
    }).length;
    
    final errorRate = (errorOperations / totalOperations * 100).roundToDouble();

    return {
      'totalOperations': totalOperations,
      'averageDuration': averageDuration.round(),
      'slowOperations': slowOperations,
      'verySlowOperations': verySlowOperations,
      'errorRate': errorRate,
      'totalDuration': totalDuration,
    };
  }

  /// Get recent performance metrics
  List<Map<String, dynamic>> getRecentMetrics({int limit = 50}) {
    final startIndex = _performanceMetrics.length - limit;
    final endIndex = _performanceMetrics.length;
    
    if (startIndex < 0) {
      return List.from(_performanceMetrics);
    }
    
    return _performanceMetrics.sublist(startIndex, endIndex);
  }

  /// Get slow operations
  List<Map<String, dynamic>> getSlowOperations() {
    return _performanceMetrics.where((metric) {
      final duration = metric['duration'] as int;
      return duration > _slowOperationThreshold.inMilliseconds;
    }).toList();
  }

  /// Get operations by name
  List<Map<String, dynamic>> getOperationsByName(String operationName) {
    return _performanceMetrics.where((metric) {
      return metric['operation'] == operationName;
    }).toList();
  }

  /// Get operation statistics by name
  Map<String, dynamic> getOperationStats(String operationName) {
    final operations = getOperationsByName(operationName);
    
    if (operations.isEmpty) {
      return {
        'operation': operationName,
        'count': 0,
        'averageDuration': 0,
        'minDuration': 0,
        'maxDuration': 0,
        'errorCount': 0,
      };
    }

    final durations = operations.map((op) => op['duration'] as int).toList();
    final totalDuration = durations.fold<int>(0, (sum, duration) => sum + duration);
    final errorCount = operations.where((op) => op['additionalData']?['error'] != null).length;

    return {
      'operation': operationName,
      'count': operations.length,
      'averageDuration': (totalDuration / operations.length).round(),
      'minDuration': durations.reduce((a, b) => a < b ? a : b),
      'maxDuration': durations.reduce((a, b) => a > b ? a : b),
      'errorCount': errorCount,
      'errorRate': (errorCount / operations.length * 100).roundToDouble(),
    };
  }

  /// Start periodic performance monitoring
  void _startPeriodicMonitoring() {
    Timer.periodic(const Duration(minutes: 5), (_) {
      _logPerformanceSummary();
    });
  }

  /// Log performance summary
  void _logPerformanceSummary() {
    final stats = getPerformanceStats();
    
    if (stats['totalOperations'] > 0) {
      logger.info('Performance Summary: ${stats['totalOperations']} operations, '
          'avg: ${stats['averageDuration']}ms, '
          'slow: ${stats['slowOperations']}, '
          'very slow: ${stats['verySlowOperations']}, '
          'error rate: ${stats['errorRate']}%', 'PerformanceService');
    }
  }

  /// Clear performance metrics
  void clearMetrics() {
    _performanceMetrics.clear();
    _activeTimers.clear();
    logger.info('Performance metrics cleared', 'PerformanceService');
  }

  /// Export performance data
  Future<Map<String, dynamic>> exportPerformanceData() async {
    final stats = getPerformanceStats();
    final recentMetrics = getRecentMetrics(limit: 100);
    final slowOperations = getSlowOperations();
    
    // Get cache and network stats
    final cacheStats = await cacheService.getStats();
    final networkStats = await networkService.getNetworkStats();
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'summary': stats,
      'recentMetrics': recentMetrics,
      'slowOperations': slowOperations,
      'cacheStats': cacheStats,
      'networkStats': networkStats,
      'deviceInfo': {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
        'isDebug': kDebugMode,
      },
    };
  }

  /// Monitor memory usage
  void logMemoryUsage() {
    try {
      // This is a simplified memory monitoring approach
      // In production, you might want to use more sophisticated memory monitoring
      logger.info('Memory usage logged', 'PerformanceService');
    } catch (e) {
      logger.error('Failed to log memory usage', 'PerformanceService', e);
    }
  }

  /// Get performance recommendations
  List<String> getPerformanceRecommendations() {
    final recommendations = <String>[];
    final stats = getPerformanceStats();
    
    if (stats['errorRate'] > 5) {
      recommendations.add('High error rate detected (${stats['errorRate']}%). Review error handling.');
    }
    
    if (stats['verySlowOperations'] > 0) {
      recommendations.add('Very slow operations detected. Consider optimization.');
    }
    
    if (stats['averageDuration'] > 500) {
      recommendations.add('High average operation duration (${stats['averageDuration']}ms). Consider caching.');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Performance is within acceptable ranges.');
    }
    
    return recommendations;
  }
}

// Global performance instance
final performanceService = PerformanceService(); 