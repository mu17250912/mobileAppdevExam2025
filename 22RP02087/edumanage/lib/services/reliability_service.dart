import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'security_service.dart';

class ReliabilityService {
  static final Connectivity _connectivity = Connectivity();
  static final Stopwatch _appStartTimer = Stopwatch();
  static final Map<String, Stopwatch> _screenTimers = {};
  
  // Error tracking
  static final List<ErrorLog> _errorLogs = [];
  static const int maxErrorLogs = 100;

  // Performance thresholds
  static const int maxScreenLoadTime = 3000; // 3 seconds
  static const int maxApiResponseTime = 5000; // 5 seconds

  // Initialize reliability monitoring
  static Future<void> initialize() async {
    // Start app load timer
    _appStartTimer.start();
    
    // Set up connectivity monitoring
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty) {
        _handleConnectivityChange(results.first);
      }
    });
    
    // Initialize crash reporting (only if not web)
    if (!kIsWeb) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    }
    
    // Set up global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      handleError(details.exception, details.stack);
    };
  }

  // Global error handling
  static void handleError(dynamic error, StackTrace? stackTrace) {
    // Log error for debugging
    print('ERROR: $error');
    if (stackTrace != null) {
      print('STACK TRACE: $stackTrace');
    }
    
    // Add to error logs
    _addErrorLog(error, stackTrace);
    
    // Send to crash reporting (only if not web)
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
    
    // Show user-friendly error message
    _showErrorDialog(error);
  }

  // Add error to local logs
  static void _addErrorLog(dynamic error, StackTrace? stackTrace) {
    final errorLog = ErrorLog(
      error: error.toString(),
      stackTrace: stackTrace?.toString(),
      timestamp: DateTime.now(),
      type: error.runtimeType.toString(),
    );
    
    _errorLogs.add(errorLog);
    
    // Keep only recent logs
    if (_errorLogs.length > maxErrorLogs) {
      _errorLogs.removeAt(0);
    }
  }

  // Show user-friendly error dialog
  static void _showErrorDialog(dynamic error) {
    String message = 'An unexpected error occurred. Please try again.';
    
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          message = 'You don\'t have permission to perform this action.';
          break;
        case 'unavailable':
          message = 'Service is temporarily unavailable. Please try again later.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your connection.';
          break;
      }
    } else if (error is TimeoutException) {
      message = 'Request timed out. Please try again.';
    } else if (error is SocketException) {
      message = 'Network connection failed. Please check your internet connection.';
    } else if (error is FormatException) {
      message = 'Data format error. Please try again.';
    }
    
    // In a real app, you would show a dialog here
    print('SHOW ERROR DIALOG: $message');
  }

  // Network connectivity management
  static Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      handleError(e, StackTrace.current);
      return false;
    }
  }

  // Handle connectivity changes
  static void _handleConnectivityChange(ConnectivityResult result) {
    final isOnline = result != ConnectivityResult.none;
    
    if (!isOnline) {
      // Show offline message
      print('Network connection lost');
    } else {
      // Sync pending data when back online
      _syncPendingData();
    }
  }

  // Sync pending data when back online
  static Future<void> _syncPendingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingData = prefs.getStringList('pending_sync') ?? [];
      
      if (pendingData.isNotEmpty) {
        print('Syncing ${pendingData.length} pending items...');
        
        // Process pending data
        for (final data in pendingData) {
          // Process each pending item
          // This would be implemented based on your data sync needs
        }
        
        // Clear pending data
        await prefs.remove('pending_sync');
        
      }
    } catch (e) {
      handleError(e, StackTrace.current);
    }
  }

  // Retry mechanism for failed requests
  static Future<T> retryRequest<T>(
    Future<T> Function() request, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    String? operationName,
  }) async {
    int attempts = 0;
    final stopwatch = Stopwatch()..start();
    
    while (attempts < maxRetries) {
      try {
        final result = await request();
        
        // Log successful request
        if (operationName != null) {
        }
        
        return result;
      } catch (e) {
        attempts++;
        
        // Log retry attempt
        if (attempts >= maxRetries) {
          // Log final failure
          rethrow;
        }
        
        // Exponential backoff
        final backoffDelay = delay * attempts;
        await Future.delayed(backoffDelay);
      }
    }
    
    throw Exception('Max retries exceeded for operation: $operationName');
  }

  // Performance monitoring
  static void startAppLoadTimer() {
    _appStartTimer.start();
  }

  static void endAppLoadTimer() {
    _appStartTimer.stop();
    
    final loadTime = _appStartTimer.elapsedMilliseconds;
    
    // Alert if startup time is too slow
    if (loadTime > maxScreenLoadTime) {
    }
  }

  // Track screen load time
  static void startScreenTimer(String screenName) {
    _screenTimers[screenName] = Stopwatch()..start();
  }

  static void endScreenTimer(String screenName) {
    final timer = _screenTimers[screenName];
    if (timer != null) {
      timer.stop();
      
      final loadTime = timer.elapsedMilliseconds;
      
      // Alert if screen load time is too slow
      if (loadTime > maxScreenLoadTime) {
      }
      
      _screenTimers.remove(screenName);
    }
  }

  // Track API response time
  static Future<T> trackApiCall<T>(
    Future<T> Function() apiCall,
    String operationName,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await apiCall();
      
      final responseTime = stopwatch.elapsedMilliseconds;
      
      // Alert if API response time is too slow
      if (responseTime > maxApiResponseTime) {
      }
      
      return result;
    } catch (e) {
      final responseTime = stopwatch.elapsedMilliseconds;
      
      rethrow;
    }
  }

  // Data integrity checks
  static Future<bool> validateDataIntegrity() async {
    try {
      // Check if user data is consistent
      final user = SecurityService.getCurrentUser();
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (!userDoc.exists) {
          // Recreate user document if missing
          await _recreateUserDocument(user);
          return false;
        }
      }
      
      return true;
    } catch (e) {
      handleError(e, StackTrace.current);
      return false;
    }
  }

  static Future<void> _recreateUserDocument(User user) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'email': user.email,
        'displayName': user.displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isPremium': false,
        'role': 'teacher',
      });
      
    } catch (e) {
      handleError(e, StackTrace.current);
    }
  }

  // Health check
  static Future<HealthStatus> performHealthCheck() async {
    final healthStatus = HealthStatus();
    
    try {
      // Check network connectivity
      healthStatus.networkConnected = await isConnected();
      
      // Check Firebase connection
      try {
        await FirebaseFirestore.instance.collection('health').doc('check').get();
        healthStatus.firebaseConnected = true;
      } catch (e) {
        healthStatus.firebaseConnected = false;
        healthStatus.errors.add('Firebase connection failed: $e');
      }
      
      // Check data integrity
      healthStatus.dataIntegrity = await validateDataIntegrity();
      
      // Check app performance
      healthStatus.appPerformance = _appStartTimer.elapsedMilliseconds < maxScreenLoadTime;
      
    } catch (e) {
      handleError(e, StackTrace.current);
      healthStatus.errors.add('Health check failed: $e');
    }
    
    return healthStatus;
  }

  // Get error logs
  static List<ErrorLog> getErrorLogs() {
    return List.unmodifiable(_errorLogs);
  }

  // Clear error logs
  static void clearErrorLogs() {
    _errorLogs.clear();
  }

  // Set user identifier for crash reporting
  static void setUserIdentifier(String userId) {
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.setUserIdentifier(userId);
    }
  }

  // Log custom message to crash reporting
  static void log(String message) {
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.log(message);
    }
  }

  // Add custom key to crash reports
  static void setCustomKey(String key, dynamic value) {
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.setCustomKey(key, value);
    }
  }
}

// Error log model
class ErrorLog {
  final String error;
  final String? stackTrace;
  final DateTime timestamp;
  final String type;

  ErrorLog({
    required this.error,
    this.stackTrace,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'stackTrace': stackTrace,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
    };
  }
}

// Health status model
class HealthStatus {
  bool networkConnected = false;
  bool firebaseConnected = false;
  bool dataIntegrity = false;
  bool appPerformance = false;
  final List<String> errors = [];

  bool get isHealthy {
    return networkConnected && 
           firebaseConnected && 
           dataIntegrity && 
           appPerformance && 
           errors.isEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'networkConnected': networkConnected,
      'firebaseConnected': firebaseConnected,
      'dataIntegrity': dataIntegrity,
      'appPerformance': appPerformance,
      'errors': errors,
      'isHealthy': isHealthy,
    };
  }
} 