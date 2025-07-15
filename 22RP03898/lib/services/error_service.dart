import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class ErrorService {
  static final ErrorService _instance = ErrorService._internal();
  factory ErrorService() => _instance;
  ErrorService._internal();

  final Logger _logger = Logger();
  final FirebaseCrashlytics? _crashlytics =
      kIsWeb ? null : FirebaseCrashlytics.instance;

  Future<void> initialize() async {
    try {
      if (_crashlytics != null) {
        // Pass all uncaught errors to Crashlytics (only on non-web platforms)
        FlutterError.onError = _crashlytics.recordFlutterFatalError;

        // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
        PlatformDispatcher.instance.onError = (error, stack) {
          _crashlytics.recordError(error, stack, fatal: true);
          return true;
        };
      }
    } catch (e) {
      _logger.e('Error initializing error service', error: e);
    }
  }

  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    try {
      _logger.e(message, error: error, stackTrace: stackTrace);

      // Only record to Crashlytics if it's properly initialized and not web
      if (_crashlytics != null) {
        try {
          _crashlytics.recordError(error ?? message, stackTrace);
        } catch (crashlyticsError) {
          _logger.e('Crashlytics error', error: crashlyticsError);
        }
      }
    } catch (e) {
      _logger.e('Error logging error', error: e);
    }
  }

  void logInfo(String message) {
    try {
      _logger.i(message);
    } catch (e) {
      _logger.e('Error logging info', error: e);
    }
  }

  void logWarning(String message, [dynamic error, StackTrace? stackTrace]) {
    try {
      _logger.w(message, error: error, stackTrace: stackTrace);
    } catch (e) {
      _logger.e('Error logging warning', error: e);
    }
  }

  void logDebug(String message) {
    try {
      _logger.d(message);
    } catch (e) {
      _logger.e('Error logging debug', error: e);
    }
  }

  String getUserFriendlyErrorMessage(dynamic error) {
    if (error is String) {
      return error;
    }

    if (error.toString().contains('network')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    if (error.toString().contains('permission')) {
      return 'Permission denied. Please grant the required permissions to continue.';
    }

    if (error.toString().contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (error.toString().contains('not found')) {
      return 'The requested resource was not found.';
    }

    if (error.toString().contains('unauthorized')) {
      return 'You are not authorized to perform this action.';
    }

    if (error.toString().contains('validation')) {
      return 'Please check your input and try again.';
    }

    // Default error message
    return 'An unexpected error occurred. Please try again.';
  }

  String getAuthErrorMessage(dynamic error) {
    if (error.toString().contains('user-not-found')) {
      return 'No account found with this email address.';
    }

    if (error.toString().contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    }

    if (error.toString().contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }

    if (error.toString().contains('weak-password')) {
      return 'Password is too weak. Please choose a stronger password.';
    }

    if (error.toString().contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }

    if (error.toString().contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later.';
    }

    if (error.toString().contains('user-disabled')) {
      return 'This account has been disabled.';
    }

    if (error.toString().contains('operation-not-allowed')) {
      return 'This operation is not allowed.';
    }

    return 'Authentication failed. Please try again.';
  }

  String getBookingErrorMessage(dynamic error) {
    if (error.toString().contains('not available')) {
      return 'This ride is no longer available.';
    }

    if (error.toString().contains('not enough seats')) {
      return 'Not enough seats available for this ride.';
    }

    if (error.toString().contains('already booked')) {
      return 'You have already booked this ride.';
    }

    if (error.toString().contains('payment failed')) {
      return 'Payment failed. Please try again.';
    }

    if (error.toString().contains('cancelled')) {
      return 'This booking has been cancelled.';
    }

    return 'Booking failed. Please try again.';
  }

  String getRideErrorMessage(dynamic error) {
    if (error.toString().contains('not found')) {
      return 'Ride not found.';
    }

    if (error.toString().contains('not authorized')) {
      return 'You are not authorized to perform this action.';
    }

    if (error.toString().contains('already exists')) {
      return 'A ride with these details already exists.';
    }

    if (error.toString().contains('invalid time')) {
      return 'Please select a valid departure time.';
    }

    if (error.toString().contains('invalid location')) {
      return 'Please enter valid locations.';
    }

    return 'Ride operation failed. Please try again.';
  }

  String getLocationErrorMessage(dynamic error) {
    if (error.toString().contains('permission denied')) {
      return 'Location permission is required to use this feature.';
    }

    if (error.toString().contains('location services disabled')) {
      return 'Please enable location services to use this feature.';
    }

    if (error.toString().contains('timeout')) {
      return 'Location request timed out. Please try again.';
    }

    if (error.toString().contains('unavailable')) {
      return 'Location service is currently unavailable.';
    }

    return 'Location error. Please try again.';
  }

  String getNetworkErrorMessage(dynamic error) {
    if (error.toString().contains('no internet')) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (error.toString().contains('timeout')) {
      return 'Request timed out. Please check your connection and try again.';
    }

    if (error.toString().contains('server error')) {
      return 'Server error. Please try again later.';
    }

    if (error.toString().contains('connection refused')) {
      return 'Unable to connect to server. Please try again.';
    }

    return 'Network error. Please check your connection and try again.';
  }

  void setUserIdentifier(String userId) {
    try {
      if (_crashlytics != null) {
        _crashlytics.setUserIdentifier(userId);
      }
    } catch (e) {
      _logger.e('Error setting user identifier', error: e);
    }
  }

  void setCustomKey(String key, dynamic value) {
    try {
      if (_crashlytics != null) {
        _crashlytics.setCustomKey(key, value);
      }
    } catch (e) {
      _logger.e('Error setting custom key', error: e);
    }
  }

  void log(String message) {
    try {
      if (_crashlytics != null) {
        _crashlytics.log(message);
      }
      _logger.i(message);
    } catch (e) {
      _logger.e('Error logging message', error: e);
    }
  }

  Future<void> recordError(dynamic error, StackTrace? stackTrace,
      {bool fatal = false}) async {
    try {
      if (_crashlytics != null) {
        await _crashlytics.recordError(error, stackTrace, fatal: fatal);
      }
      _logger.e('Error recorded', error: error, stackTrace: stackTrace);
    } catch (e) {
      _logger.e('Error recording error', error: e);
    }
  }

  void logNavigation(String screenName) {
    try {
      if (_crashlytics != null) {
        _crashlytics.log('Navigated to: $screenName');
      }
      _logger.i('Navigation: $screenName');
    } catch (e) {
      _logger.e('Error logging navigation', error: e);
    }
  }

  void logUserAction(String action, {Map<String, dynamic>? parameters}) {
    try {
      String message = 'User action: $action';
      if (parameters != null) {
        message += ' - Parameters: $parameters';
      }
      if (_crashlytics != null) {
        _crashlytics.log(message);
      }
      _logger.i(message);
    } catch (e) {
      _logger.e('Error logging user action', error: e);
    }
  }

  void logPerformance(String operation, Duration duration) {
    try {
      if (_crashlytics != null) {
        _crashlytics
            .log('Performance: $operation took ${duration.inMilliseconds}ms');
      }
      _logger.i('Performance: $operation - ${duration.inMilliseconds}ms');
    } catch (e) {
      _logger.e('Error logging performance', error: e);
    }
  }
}
