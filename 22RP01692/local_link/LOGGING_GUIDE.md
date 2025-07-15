# Android Logging System Guide

This guide explains how to use the comprehensive logging system implemented in your Local Link Android app.

## Overview

The logging system provides:
- **Console logging** - Visible in Android Studio's debug console
- **File logging** - Persistent logs stored on the device
- **Log levels** - Different severity levels for better organization
- **Log viewer** - Built-in UI to view and manage logs
- **Automatic log rotation** - Prevents logs from consuming too much storage

## Log Levels

The system supports 5 log levels:

1. **DEBUG** - Detailed information for debugging
2. **INFO** - General information about app flow
3. **WARNING** - Potential issues that don't break functionality
4. **ERROR** - Errors that affect functionality but don't crash the app
5. **FATAL** - Critical errors that may cause app crashes

## Basic Usage

### Import the Logger

```dart
import 'services/logger_service.dart';
```

### Using the Global Logger Instance

```dart
// Debug level - for detailed debugging information
logger.debug('This is a debug message', 'MyComponent');

// Info level - for general information
logger.info('User logged in successfully', 'AuthService');

// Warning level - for potential issues
logger.warning('Network connection is slow', 'NetworkService');

// Error level - for errors with exception details
try {
  // Some operation that might fail
} catch (e, stackTrace) {
  logger.error('Operation failed', 'MyService', e, stackTrace);
}

// Fatal level - for critical errors
logger.fatal('App is about to crash', 'CrashHandler', error, stackTrace);
```

## Log Viewer

### Accessing the Log Viewer

1. Open the app
2. Go to **Profile** screen
3. Scroll down to find the **Debug Tools** section (only visible in debug builds)
4. Tap **"View Logs"**

### Log Viewer Features

- **View all log files** - Browse through different log files by date
- **Read log content** - View detailed log entries with timestamps
- **Refresh logs** - Update the log list
- **Clear logs** - Delete all log files
- **Share logs** - Prepare logs for sharing (you can implement actual sharing)

### Testing the Logger

1. Go to **Profile** screen
2. Tap **"Test Logging"** in the Debug Tools section
3. This will add sample log entries at different levels
4. Open the Log Viewer to see the test logs

## Log File Management

### Automatic Features

- **Log rotation**: When a log file exceeds 5MB, it's automatically rotated
- **File cleanup**: Only the 5 most recent log files are kept
- **Daily files**: New log files are created daily

### Log File Location

Log files are stored in the app's documents directory:
```
/data/data/com.example.local_link/app_flutter/logs/
```

### Log File Format

Each log entry includes:
- Timestamp (YYYY-MM-DD HH:mm:ss.SSS)
- Log level (DEBUG, INFO, WARNING, ERROR, FATAL)
- Component tag
- Message
- Error details (if applicable)
- Stack trace (if applicable)

Example:
```
[2024-01-15 14:30:25.123] [INFO] AuthService: Login successful for user: user@example.com with role: user
[2024-01-15 14:30:26.456] [ERROR] NetworkService: Failed to fetch data
Error: SocketException: Connection refused
StackTrace: #0 _rootRunUnary (dart:async/zone.dart:1362:47)
---
```

## Best Practices

### 1. Use Appropriate Log Levels

```dart
// Good - Use debug for detailed information
logger.debug('Processing user data: ${userData.toString()}', 'UserService');

// Good - Use info for important events
logger.info('User completed booking: ${booking.id}', 'BookingService');

// Good - Use warning for potential issues
logger.warning('API response time exceeded 5 seconds', 'APIService');

// Good - Use error for actual errors
logger.error('Failed to save user data', 'UserService', exception, stackTrace);
```

### 2. Include Meaningful Tags

```dart
// Good - Specific component tag
logger.info('Payment processed', 'PaymentService');

// Avoid - Generic tag
logger.info('Payment processed', 'Service');
```

### 3. Include Context in Messages

```dart
// Good - Include relevant context
logger.info('User ${user.id} updated profile: ${changedFields.join(', ')}', 'UserService');

// Avoid - Vague messages
logger.info('Profile updated', 'UserService');
```

### 4. Handle Exceptions Properly

```dart
try {
  await someAsyncOperation();
} catch (e, stackTrace) {
  logger.error('Operation failed with specific context', 'ServiceName', e, stackTrace);
  // Handle the error appropriately
}
```

## Integration Examples

### Authentication Service

```dart
class AuthService {
  Future<UserCredential?> login(String email, String password) async {
    logger.info('Login attempt for: $email', 'AuthService');
    
    try {
      final result = await _auth.signInWithEmailAndPassword(email, password);
      logger.info('Login successful for: $email', 'AuthService');
      return result;
    } catch (e) {
      logger.error('Login failed for: $email', 'AuthService', e);
      rethrow;
    }
  }
}
```

### Network Service

```dart
class NetworkService {
  Future<Response> get(String url) async {
    logger.debug('Making GET request to: $url', 'NetworkService');
    
    try {
      final response = await http.get(Uri.parse(url));
      logger.debug('Response received: ${response.statusCode}', 'NetworkService');
      return response;
    } catch (e) {
      logger.error('GET request failed: $url', 'NetworkService', e);
      rethrow;
    }
  }
}
```

### UI Components

```dart
class MyWidget extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    logger.debug('MyWidget initialized', 'MyWidget');
  }
  
  void _handleButtonPress() {
    logger.info('Button pressed in MyWidget', 'MyWidget');
    // Handle button press
  }
}
```

## Debug vs Release

The logging system behaves differently in debug and release builds:

### Debug Build
- All log levels are recorded
- Debug tools are visible in the UI
- Console logging is verbose

### Release Build
- Only INFO, WARNING, ERROR, and FATAL levels are recorded
- Debug tools are hidden
- Console logging is minimal

## Troubleshooting

### Logs Not Appearing

1. Check if the logger is initialized in `main.dart`
2. Verify the app has storage permissions
3. Check if the log directory exists

### Log Viewer Not Working

1. Ensure you're running in debug mode
2. Check if the debug tools section is visible in Profile screen
3. Verify the log files exist in the app's documents directory

### Performance Issues

1. Avoid logging in tight loops
2. Use debug level sparingly in production
3. Consider log file size limits

## Advanced Usage

### Custom Log Tags

You can create custom log tags for better organization:

```dart
class PaymentService {
  static const String _tag = 'PaymentService';
  
  Future<void> processPayment() async {
    logger.info('Processing payment', _tag);
    // Payment logic
  }
}
```

### Conditional Logging

```dart
if (kDebugMode) {
  logger.debug('Debug-only information', 'MyService');
}
```

### Log Filtering

You can filter logs by level or tag in the log viewer by implementing search functionality.

## Security Considerations

- Logs may contain sensitive information
- Consider what data you log in production
- Implement log encryption if needed
- Clear logs when users logout

## Support

For issues with the logging system:
1. Check the console output for initialization errors
2. Verify file permissions
3. Test with the built-in test logging feature
4. Check log file sizes and rotation 