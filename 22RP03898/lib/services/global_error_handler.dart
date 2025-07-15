import 'package:flutter/material.dart';
import 'error_service.dart';

class GlobalErrorHandler {
  static final GlobalErrorHandler _instance = GlobalErrorHandler._internal();
  factory GlobalErrorHandler() => _instance;
  GlobalErrorHandler._internal();

  final ErrorService _errorService = ErrorService();

  void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      // Don't log overflow errors as they're not critical
      if (details.exception.toString().contains('RenderFlex overflowed')) {
        return;
      }

      // Don't log assertion failures from Crashlytics
      if (details.exception.toString().contains('Assertion failed')) {
        return;
      }

      _errorService.logError('Flutter Error', details.exception, details.stack);
    };
  }

  void handleError(dynamic error, StackTrace? stackTrace, {String? context}) {
    _errorService.logError(
      context ?? 'Unhandled Error',
      error,
      stackTrace,
    );
  }

  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
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

  void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
