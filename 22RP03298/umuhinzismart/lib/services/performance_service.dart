import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';
import 'error_reporting_service.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  // Lazy initialization to avoid Firebase initialization issues
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Performance thresholds
  static const int _slowLoadThreshold = 3000; // 3 seconds
  static const int _verySlowLoadThreshold = 5000; // 5 seconds
  static const int _memoryWarningThreshold = 100; // MB

  /// Track screen load time
  static Future<void> trackScreenLoad(String screenName, {int? loadTimeMs, String? userRole}) async {
    try {
      final performance = PerformanceService();
      final analytics = AnalyticsService();
      
      // Use provided load time or default to 0
      final actualLoadTime = loadTimeMs ?? 0;
      
      // Track in analytics
      await AnalyticsService.trackPerformance(
        metric: 'screen_load_time',
        value: actualLoadTime.toDouble(),
        unit: 'ms',
        context: screenName,
      );

      // Check if load time is concerning
      if (actualLoadTime > _verySlowLoadThreshold) {
        await ErrorReportingService.reportError(
          errorType: 'performance_issue',
          errorMessage: 'Very slow screen load: $screenName took ${actualLoadTime}ms',
          screen: screenName,
          userRole: userRole,
          additionalData: {
            'loadTimeMs': actualLoadTime,
            'threshold': _verySlowLoadThreshold,
          },
        );
      } else if (actualLoadTime > _slowLoadThreshold) {
        await AnalyticsService.trackFeatureUsage(
          feature: 'slow_screen_load',
          userRole: userRole ?? 'unknown',
          additionalData: 'Screen: $screenName, Time: ${actualLoadTime}ms',
        );
      }

      print('✅ Performance: Screen $screenName loaded in ${actualLoadTime}ms');
    } catch (e) {
      print('❌ Performance: Failed to track screen load: $e');
    }
  }

  /// Track API call performance
  Future<void> trackApiCall({
    required String endpoint,
    required int responseTimeMs,
    required bool success,
    String? userRole,
    Map<String, dynamic>? requestData,
  }) async {
    try {
      // Track in analytics
      await AnalyticsService.trackPerformance(
        metric: 'api_response_time',
        value: responseTimeMs.toDouble(),
        unit: 'ms',
        context: endpoint,
      );

      // Check if response time is concerning
      if (responseTimeMs > _verySlowLoadThreshold) {
        await ErrorReportingService.reportError(
          errorType: 'api_performance_issue',
          errorMessage: 'Very slow API call: $endpoint took ${responseTimeMs}ms',
          userRole: userRole,
          additionalData: {
            'endpoint': endpoint,
            'responseTimeMs': responseTimeMs,
            'success': success,
            'requestData': requestData,
          },
        );
      }

      print('✅ Performance: API $endpoint responded in ${responseTimeMs}ms (success: $success)');
    } catch (e) {
      print('❌ Performance: Failed to track API call: $e');
    }
  }

  /// Track database operation performance
  Future<void> trackDatabaseOperation({
    required String operation,
    required int durationMs,
    required bool success,
    String? collection,
    String? userRole,
  }) async {
    try {
      // Track in analytics
      await AnalyticsService.trackPerformance(
        metric: 'database_operation_time',
        value: durationMs.toDouble(),
        unit: 'ms',
        context: '$operation${collection != null ? ':$collection' : ''}',
      );

      // Check if operation is concerning
      if (durationMs > _slowLoadThreshold) {
        await AnalyticsService.trackFeatureUsage(
          feature: 'slow_database_operation',
          userRole: userRole ?? 'unknown',
          additionalData: 'Operation: $operation, Time: ${durationMs}ms',
        );
      }

      print('✅ Performance: DB operation $operation completed in ${durationMs}ms (success: $success)');
    } catch (e) {
      print('❌ Performance: Failed to track database operation: $e');
    }
  }

  /// Track memory usage
  Future<void> trackMemoryUsage({
    required double memoryUsageMB,
    String? userRole,
  }) async {
    try {
      // Track in analytics
      await AnalyticsService.trackPerformance(
        metric: 'memory_usage',
        value: memoryUsageMB,
        unit: 'MB',
        context: 'app_memory',
      );

      // Check if memory usage is concerning
      if (memoryUsageMB > _memoryWarningThreshold) {
        await AnalyticsService.trackFeatureUsage(
          feature: 'high_memory_usage',
          userRole: userRole ?? 'unknown',
          additionalData: 'Usage: ${memoryUsageMB}MB',
        );
      }

      print('✅ Performance: Memory usage: ${memoryUsageMB}MB');
    } catch (e) {
      print('❌ Performance: Failed to track memory usage: $e');
    }
  }

  /// Track app startup time
  Future<void> trackAppStartup({
    required int startupTimeMs,
    String? userRole,
  }) async {
    try {
      // Track in analytics
      await AnalyticsService.trackPerformance(
        metric: 'app_startup_time',
        value: startupTimeMs.toDouble(),
        unit: 'ms',
        context: 'app_launch',
      );

      // Check if startup time is concerning
      if (startupTimeMs > _verySlowLoadThreshold) {
        await ErrorReportingService.reportError(
          errorType: 'startup_performance_issue',
          errorMessage: 'Slow app startup: ${startupTimeMs}ms',
          userRole: userRole,
          additionalData: {
            'startupTimeMs': startupTimeMs,
            'threshold': _verySlowLoadThreshold,
          },
        );
      }

      print('✅ Performance: App startup completed in ${startupTimeMs}ms');
    } catch (e) {
      print('❌ Performance: Failed to track app startup: $e');
    }
  }

  /// Track image load performance
  Future<void> trackImageLoad({
    required String imageUrl,
    required int loadTimeMs,
    required bool success,
    String? userRole,
  }) async {
    try {
      // Track in analytics
      await AnalyticsService.trackPerformance(
        metric: 'image_load_time',
        value: loadTimeMs.toDouble(),
        unit: 'ms',
        context: 'image_loading',
      );

      // Check if image load is concerning
      if (loadTimeMs > _slowLoadThreshold) {
        await AnalyticsService.trackFeatureUsage(
          feature: 'slow_image_load',
          userRole: userRole ?? 'unknown',
          additionalData: 'Image: $imageUrl, Time: ${loadTimeMs}ms',
        );
      }

      print('✅ Performance: Image loaded in ${loadTimeMs}ms (success: $success)');
    } catch (e) {
      print('❌ Performance: Failed to track image load: $e');
    }
  }

  /// Track user interaction response time
  Future<void> trackInteractionResponse({
    required String interaction,
    required int responseTimeMs,
    String? screen,
    String? userRole,
  }) async {
    try {
      // Track in analytics
      await AnalyticsService.trackPerformance(
        metric: 'interaction_response_time',
        value: responseTimeMs.toDouble(),
        unit: 'ms',
        context: interaction,
      );

      // Check if response time is concerning
      if (responseTimeMs > 1000) { // 1 second threshold for interactions
        await AnalyticsService.trackFeatureUsage(
          feature: 'slow_interaction_response',
          userRole: userRole ?? 'unknown',
          additionalData: 'Interaction: $interaction, Time: ${responseTimeMs}ms',
        );
      }

      print('✅ Performance: Interaction $interaction responded in ${responseTimeMs}ms');
    } catch (e) {
      print('❌ Performance: Failed to track interaction response: $e');
    }
  }

  /// Get performance summary for dashboard
  Future<Map<String, dynamic>> getPerformanceSummary() async {
    try {
      final now = DateTime.now();
      final last24Hours = now.subtract(Duration(hours: 24));

      // Get performance metrics from analytics
      final performanceMetrics = await _firestore
          .collection('analytics')
          .where('event', isEqualTo: 'performance_metric')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(last24Hours))
          .get();

      // Calculate averages
      final metrics = <String, List<double>>{};
      for (var doc in performanceMetrics.docs) {
        final data = doc.data();
        final metric = data['metric'] as String?;
        final value = data['value'] as num?;
        
        if (metric != null && value != null) {
          metrics.putIfAbsent(metric, () => []).add(value.toDouble());
        }
      }

      final averages = <String, double>{};
      metrics.forEach((metric, values) {
        if (values.isNotEmpty) {
          averages[metric] = values.reduce((a, b) => a + b) / values.length;
        }
      });

      return {
        'period': '24_hours',
        'averages': averages,
        'totalMetrics': performanceMetrics.docs.length,
      };
    } catch (e) {
      print('❌ Performance: Failed to get summary: $e');
      return {
        'period': '24_hours',
        'averages': {},
        'totalMetrics': 0,
        'error': e.toString(),
      };
    }
  }

  /// Monitor widget build performance
  void monitorWidgetBuild(String widgetName, VoidCallback buildFunction) {
    final stopwatch = Stopwatch()..start();
    
    try {
      buildFunction();
    } finally {
      stopwatch.stop();
      final buildTime = stopwatch.elapsedMilliseconds;
      
      if (buildTime > 100) { // 100ms threshold for widget builds
        print('⚠️ Performance: Widget $widgetName took ${buildTime}ms to build');
      }
    }
  }

  /// Track scroll performance
  Future<void> trackScrollPerformance({
    required String screen,
    required int scrollDistance,
    required int scrollTimeMs,
    String? userRole,
  }) async {
    try {
      final scrollSpeed = scrollDistance / scrollTimeMs; // pixels per millisecond
      
      await AnalyticsService.trackPerformance(
        metric: 'scroll_speed',
        value: scrollSpeed,
        unit: 'pixels/ms',
        context: screen,
      );

      print('✅ Performance: Scroll in $screen: ${scrollSpeed.toStringAsFixed(2)} pixels/ms');
    } catch (e) {
      print('❌ Performance: Failed to track scroll performance: $e');
    }
  }

  /// Track battery usage (if available)
  Future<void> trackBatteryUsage({
    required double batteryLevel,
    String? userRole,
  }) async {
    try {
      await AnalyticsService.trackPerformance(
        metric: 'battery_level',
        value: batteryLevel,
        unit: 'percentage',
        context: 'device_battery',
      );

      if (batteryLevel < 20) {
        await AnalyticsService.trackFeatureUsage(
          feature: 'low_battery_usage',
          userRole: userRole ?? 'unknown',
          additionalData: 'Battery: ${batteryLevel}%',
        );
      }

      print('✅ Performance: Battery level: ${batteryLevel}%');
    } catch (e) {
      print('❌ Performance: Failed to track battery usage: $e');
    }
  }

  /// Track operation performance (legacy method for compatibility)
  static Future<void> trackOperation(
    String operationName,
    Future<void> Function() operation, {
    int thresholdMs = 1000,
    Map<String, dynamic>? metadata,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      await operation();
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;
      
      await PerformanceService().trackDatabaseOperation(
        operation: operationName,
        durationMs: duration,
        success: true,
        userRole: 'unknown',
      );
      
      if (duration > thresholdMs) {
        await AnalyticsService.trackFeatureUsage(
          feature: 'slow_operation',
          userRole: 'unknown',
          additionalData: 'Operation: $operationName, Time: ${duration}ms',
        );
      }
    } catch (e) {
      stopwatch.stop();
      await PerformanceService().trackDatabaseOperation(
        operation: operationName,
        durationMs: stopwatch.elapsedMilliseconds,
        success: false,
        userRole: 'unknown',
      );
      rethrow;
    }
  }

  /// Track feature usage (legacy method for compatibility)
  Future<void> trackFeatureUsage({
    required String feature,
    required String userRole,
    String? additionalData,
  }) async {
    try {
      await AnalyticsService.trackFeatureUsage(
        feature: feature,
        userRole: userRole,
        additionalData: additionalData,
      );
    } catch (e) {
      print('❌ Performance: Failed to track feature usage: $e');
    }
  }
} 