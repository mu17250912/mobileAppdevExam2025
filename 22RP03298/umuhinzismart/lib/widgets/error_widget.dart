import 'package:flutter/material.dart';

class CustomErrorWidget extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final IconData? icon;
  final Color? color;

  const CustomErrorWidget({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: color ?? Colors.red[400],
            ),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color ?? Colors.red[400],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color ?? Colors.red[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const NetworkErrorWidget({
    super.key,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      title: 'Connection Error',
      message: customMessage ?? 'Please check your internet connection and try again.',
      icon: Icons.wifi_off,
      color: Colors.orange[600],
      onRetry: onRetry,
    );
  }
}

class ServerErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const ServerErrorWidget({
    super.key,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      title: 'Server Error',
      message: customMessage ?? 'Something went wrong on our end. Please try again later.',
      icon: Icons.cloud_off,
      color: Colors.red[600],
      onRetry: onRetry,
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? title;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionText;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionText!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmText;
  final VoidCallback? onConfirm;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[400],
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.red[400],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (onConfirm != null)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm!();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText ?? 'OK'),
          ),
      ],
    );
  }
}

class ErrorSnackBar extends StatelessWidget {
  final String message;
  final Duration duration;
  final VoidCallback? onAction;
  final String? actionText;

  const ErrorSnackBar({
    super.key,
    required this.message,
    this.duration = const Duration(seconds: 4),
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return SnackBar(
      content: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message),
          ),
        ],
      ),
      backgroundColor: Colors.red[600],
      duration: duration,
      action: onAction != null && actionText != null
          ? SnackBarAction(
              label: actionText!,
              textColor: Colors.white,
              onPressed: onAction!,
            )
          : null,
    );
  }
}

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(String error)? errorBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ??
          CustomErrorWidget(
            title: 'Something went wrong',
            message: _error!,
            onRetry: () {
              setState(() {
                _error = null;
              });
            },
          );
    }

    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    // Set up error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      setState(() {
        _error = details.exception.toString();
      });
    };
  }
} 