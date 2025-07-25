import 'dart:developer' as developer;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  static const String _tag = 'LocalLink';
  static const int _maxLogFiles = 5;
  static const int _maxLogFileSize = 5 * 1024 * 1024; // 5MB

  late Directory _logDirectory;
  late File _currentLogFile;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      _logDirectory = Directory('${appDir.path}/logs');
      
      if (!await _logDirectory.exists()) {
        await _logDirectory.create(recursive: true);
      }

      _currentLogFile = File('${_logDirectory.path}/app_${_getDateString()}.log');
      _isInitialized = true;

      info('Logger initialized successfully');
      _cleanupOldLogs();
    } catch (e) {
      developer.log('Failed to initialize logger: $e', name: _tag);
    }
  }

  void debug(String message, [String? tag]) {
    _log(LogLevel.debug, message, tag);
  }

  void info(String message, [String? tag]) {
    _log(LogLevel.info, message, tag);
  }

  void warning(String message, [String? tag]) {
    _log(LogLevel.warning, message, tag);
  }

  void error(String message, [String? tag, Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, tag, error, stackTrace);
  }

  void fatal(String message, [String? tag, Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.fatal, message, tag, error, stackTrace);
  }

  void _log(LogLevel level, String message, [String? tag, Object? error, StackTrace? stackTrace]) {
    final timestamp = DateTime.now();
    final logTag = tag ?? _tag;
    final levelString = level.name.toUpperCase();
    
    // Console logging
    final consoleMessage = '[$levelString] $logTag: $message';
    developer.log(consoleMessage, name: _tag, level: _getLogLevel(level));

    if (error != null) {
      developer.log('Error: $error', name: _tag, level: _getLogLevel(level));
    }

    if (stackTrace != null) {
      developer.log('StackTrace: $stackTrace', name: _tag, level: _getLogLevel(level));
    }

    // File logging
    _writeToFile(levelString, logTag, message, timestamp, error, stackTrace);
  }

  int _getLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.fatal:
        return 1200;
    }
  }

  Future<void> _writeToFile(String level, String tag, String message, DateTime timestamp, Object? error, StackTrace? stackTrace) async {
    if (!_isInitialized) return;

    try {
      final timestampStr = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(timestamp);
      final logEntry = StringBuffer();
      
      logEntry.writeln('[$timestampStr] [$level] $tag: $message');
      
      if (error != null) {
        logEntry.writeln('Error: $error');
      }
      
      if (stackTrace != null) {
        logEntry.writeln('StackTrace: $stackTrace');
      }
      
      logEntry.writeln('---');

      await _currentLogFile.writeAsString(logEntry.toString(), mode: FileMode.append);
      
      // Check file size and rotate if necessary
      final fileSize = await _currentLogFile.length();
      if (fileSize > _maxLogFileSize) {
        await _rotateLogFile();
      }
    } catch (e) {
      developer.log('Failed to write to log file: $e', name: _tag);
    }
  }

  Future<void> _rotateLogFile() async {
    try {
      final timestamp = _getDateString();
      final newLogFile = File('${_logDirectory.path}/app_${timestamp}_${DateTime.now().millisecondsSinceEpoch}.log');
      await _currentLogFile.rename(newLogFile.path);
      _currentLogFile = File('${_logDirectory.path}/app_${_getDateString()}.log');
    } catch (e) {
      developer.log('Failed to rotate log file: $e', name: _tag);
    }
  }

  Future<void> _cleanupOldLogs() async {
    try {
      final files = _logDirectory.listSync().whereType<File>().toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      if (files.length > _maxLogFiles) {
        for (int i = _maxLogFiles; i < files.length; i++) {
          await files[i].delete();
        }
      }
    } catch (e) {
      developer.log('Failed to cleanup old logs: $e', name: _tag);
    }
  }

  String _getDateString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<List<String>> getLogFiles() async {
    if (!_isInitialized) return [];

    try {
      final files = _logDirectory.listSync().whereType<File>().toList();
      return files.map((file) => file.path).toList();
    } catch (e) {
      developer.log('Failed to get log files: $e', name: _tag);
      return [];
    }
  }

  Future<String> getLogContent(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return 'Log file not found';
    } catch (e) {
      return 'Error reading log file: $e';
    }
  }

  Future<void> clearLogs() async {
    if (!_isInitialized) return;

    try {
      final files = _logDirectory.listSync().whereType<File>().toList();
      for (final file in files) {
        await file.delete();
      }
      info('All logs cleared');
    } catch (e) {
      developer.log('Failed to clear logs: $e', name: _tag);
    }
  }
}

// Global logger instance
final logger = LoggerService(); 