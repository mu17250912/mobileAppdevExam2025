import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';

class ErrorReportingService {
  static final ErrorReportingService _instance = ErrorReportingService._internal();
  factory ErrorReportingService() => _instance;
  ErrorReportingService._internal();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Report an error with context
  static Future<void> reportError({
    required String errorType,
    required String errorMessage,
    String? screen,
    String? userRole,
    String? username,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Get user context
      final prefs = await SharedPreferences.getInstance();
      final currentUser = username ?? prefs.getString('username');
      final currentRole = userRole ?? prefs.getString('user_role');

      // Prepare error data
      final errorData = {
        'errorType': errorType,
        'errorMessage': errorMessage,
        'screen': screen,
        'userRole': currentRole,
        'username': currentUser,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
        'additionalData': additionalData,
      };

      // Add stack trace if available
      if (stackTrace != null) {
        errorData['stackTrace'] = stackTrace.toString();
      }

      // Add original error if available
      if (error != null) {
        errorData['originalError'] = error.toString();
      }

      // Save to Firestore
      await _firestore.collection('errors').add(errorData);

      // Track in analytics
      await AnalyticsService.trackError(
        errorType: errorType,
        errorMessage: errorMessage,
        screen: screen,
        userRole: currentRole,
        stackTrace: stackTrace?.toString(),
      );

      print('✅ Error reported: $errorType - $errorMessage');
    } catch (e) {
      print('❌ Failed to report error: $e');
    }
  }

  /// Handle Firestore errors gracefully
  static Future<T?> handleFirestoreError<T>({
    required Future<T> Function() operation,
    required String operationName,
    String? screen,
    String? userRole,
    T? defaultValue,
  }) async {
    try {
      return await operation();
    } on FirebaseException catch (e) {
      await reportError(
        errorType: 'firestore_error',
        errorMessage: '${operationName}: ${e.message}',
        screen: screen,
        userRole: userRole,
        error: e,
        additionalData: {
          'operation': operationName,
          'firestoreCode': e.code,
        },
      );
      return defaultValue;
    } catch (e, stackTrace) {
      await reportError(
        errorType: 'general_error',
        errorMessage: '${operationName}: ${e.toString()}',
        screen: screen,
        userRole: userRole,
        error: e,
        stackTrace: stackTrace,
        additionalData: {
          'operation': operationName,
        },
      );
      return defaultValue;
    }
  }

  /// Handle network errors
  static Future<T?> handleNetworkError<T>({
    required Future<T> Function() operation,
    required String operationName,
    String? screen,
    String? userRole,
    T? defaultValue,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      final errorMessage = e.toString().toLowerCase();
      final isNetworkError = errorMessage.contains('network') ||
          errorMessage.contains('connection') ||
          errorMessage.contains('timeout') ||
          errorMessage.contains('internet');

      await reportError(
        errorType: isNetworkError ? 'network_error' : 'general_error',
        errorMessage: '${operationName}: ${e.toString()}',
        screen: screen,
        userRole: userRole,
        error: e,
        stackTrace: stackTrace,
        additionalData: {
          'operation': operationName,
          'isNetworkError': isNetworkError,
        },
      );
      return defaultValue;
    }
  }

  /// Show user-friendly error dialog
  static void showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
          if (actionText != null && onAction != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onAction();
              },
              child: Text(actionText),
            ),
        ],
      ),
    );
  }

  /// Show user-friendly error snackbar
  static void showErrorSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: duration,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Handle authentication errors
  static Future<bool> handleAuthError({
    required String operation,
    required dynamic error,
    String? screen,
    String? userRole,
  }) async {
    final errorMessage = error.toString().toLowerCase();
    
    String errorType = 'auth_error';
    String userMessage = 'Authentication failed. Please try again.';

    if (errorMessage.contains('invalid') || errorMessage.contains('wrong')) {
      errorType = 'invalid_credentials';
      userMessage = 'Invalid username or password.';
    } else if (errorMessage.contains('network') || errorMessage.contains('connection')) {
      errorType = 'network_error';
      userMessage = 'Network error. Please check your connection.';
    } else if (errorMessage.contains('already exists') || errorMessage.contains('taken')) {
      errorType = 'user_exists';
      userMessage = 'Username already taken.';
    }

    await reportError(
      errorType: errorType,
      errorMessage: '${operation}: ${error.toString()}',
      screen: screen,
      userRole: userRole,
      error: error,
    );

    return false;
  }

  /// Handle payment errors
  static Future<bool> handlePaymentError({
    required String operation,
    required dynamic error,
    required String orderId,
    String? screen,
    String? userRole,
  }) async {
    final errorMessage = error.toString().toLowerCase();
    
    String errorType = 'payment_error';
    String userMessage = 'Payment failed. Please try again.';

    if (errorMessage.contains('insufficient') || errorMessage.contains('balance')) {
      errorType = 'insufficient_funds';
      userMessage = 'Insufficient funds. Please check your balance.';
    } else if (errorMessage.contains('network') || errorMessage.contains('connection')) {
      errorType = 'network_error';
      userMessage = 'Network error. Please check your connection.';
    } else if (errorMessage.contains('timeout')) {
      errorType = 'timeout_error';
      userMessage = 'Payment timeout. Please try again.';
    }

    await reportError(
      errorType: errorType,
      errorMessage: '${operation}: ${error.toString()}',
      screen: screen,
      userRole: userRole,
      error: error,
      additionalData: {
        'orderId': orderId,
        'operation': operation,
      },
    );

    return false;
  }

  /// Get error statistics for admin dashboard
  static Future<Map<String, dynamic>> getErrorStatistics() async {
    try {
      final now = DateTime.now();
      final last7Days = now.subtract(Duration(days: 7));
      final last30Days = now.subtract(Duration(days: 30));

      // Get recent errors
      final recentErrors = await _firestore
          .collection('errors')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(last7Days))
          .get();

      // Count by error type
      final errorTypeCounts = <String, int>{};
      final screenErrorCounts = <String, int>{};

      for (var doc in recentErrors.docs) {
        final data = doc.data();
        final errorType = data['errorType'] ?? 'unknown';
        final screen = data['screen'] ?? 'unknown';

        errorTypeCounts[errorType] = (errorTypeCounts[errorType] ?? 0) + 1;
        screenErrorCounts[screen] = (screenErrorCounts[screen] ?? 0) + 1;
      }

      return {
        'totalErrors': recentErrors.docs.length,
        'errorTypeCounts': errorTypeCounts,
        'screenErrorCounts': screenErrorCounts,
        'period': '7_days',
      };
    } catch (e) {
      print('❌ Failed to get error statistics: $e');
      return {
        'totalErrors': 0,
        'errorTypeCounts': {},
        'screenErrorCounts': {},
        'period': '7_days',
        'error': e.toString(),
      };
    }
  }

  /// Clear old error logs (admin function)
  static Future<void> clearOldErrors({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      final oldErrors = await _firestore
          .collection('errors')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (var doc in oldErrors.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('✅ Cleared ${oldErrors.docs.length} old error logs');
    } catch (e) {
      print('❌ Failed to clear old errors: $e');
    }
  }

  /// Report authentication error (legacy method)
  static Future<void> reportAuthError(
    String action,
    String errorMessage, {
    Map<String, dynamic>? authData,
  }) async {
    try {
      await reportError(
        errorType: 'auth_error',
        errorMessage: '$action: $errorMessage',
        additionalData: authData,
      );
    } catch (e) {
      print('❌ Failed to report auth error: $e');
    }
  }
} 