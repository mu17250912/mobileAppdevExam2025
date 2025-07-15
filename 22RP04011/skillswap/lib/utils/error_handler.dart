import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ErrorHandler {
  /// Handle Firebase Auth errors
  static String handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'weak-password':
          return 'Password is too weak. Please choose a stronger password.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return 'Authentication error: ${error.message}';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Handle Firestore errors
  static String handleFirestoreError(dynamic error) {
    if (error.toString().contains('permission-denied')) {
      return 'Access denied. Please check your permissions.';
    } else if (error.toString().contains('unavailable')) {
      return 'Service temporarily unavailable. Please try again.';
    } else if (error.toString().contains('not-found')) {
      return 'The requested data was not found.';
    } else if (error.toString().contains('already-exists')) {
      return 'This item already exists.';
    } else if (error.toString().contains('resource-exhausted')) {
      return 'Service quota exceeded. Please try again later.';
    } else if (error.toString().contains('failed-precondition')) {
      return 'Operation failed due to a precondition.';
    } else if (error.toString().contains('aborted')) {
      return 'Operation was aborted. Please try again.';
    } else if (error.toString().contains('out-of-range')) {
      return 'Operation is out of valid range.';
    } else if (error.toString().contains('unimplemented')) {
      return 'This operation is not implemented.';
    } else if (error.toString().contains('internal')) {
      return 'Internal server error. Please try again.';
    } else if (error.toString().contains('data-loss')) {
      return 'Data loss occurred. Please try again.';
    } else if (error.toString().contains('unauthenticated')) {
      return 'Please log in to continue.';
    }
    return 'Database error: ${error.toString()}';
  }

  /// Handle FCM errors
  static String handleFCMError(dynamic error) {
    if (error.toString().contains('permission-blocked')) {
      return 'Notification permission was denied. You can enable it in settings.';
    } else if (error.toString().contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else if (error.toString().contains('token')) {
      return 'Failed to get notification token.';
    }
    return 'Notification error: ${error.toString()}';
  }

  /// Log error with context
  static void logError(String context, dynamic error,
      [StackTrace? stackTrace]) {
    debugPrint('Error in $context: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Check if error is network related
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('unavailable');
  }

  /// Check if error is permission related
  static bool isPermissionError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('permission') ||
        errorString.contains('denied') ||
        errorString.contains('unauthorized');
  }

  /// Get user-friendly error message
  static String getUserFriendlyMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return handleAuthError(error);
    } else if (error.toString().contains('firebase_messaging')) {
      return handleFCMError(error);
    } else if (isNetworkError(error)) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (isPermissionError(error)) {
      return 'Permission denied. Please check your settings and try again.';
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Retry operation with exponential backoff
  static Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int retries = 0;
    Duration delay = initialDelay;

    while (retries < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        retries++;
        if (retries >= maxRetries) {
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(delay);
        delay = Duration(milliseconds: delay.inMilliseconds * 2);
      }
    }

    throw Exception('Operation failed after $maxRetries retries');
  }
}
 