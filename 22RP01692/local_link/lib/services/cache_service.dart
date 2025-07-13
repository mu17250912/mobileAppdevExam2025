import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'logger_service.dart';

/// Cache service for offline support and performance optimization
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _cacheDir = 'app_cache';
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB
  static const Duration _defaultExpiry = Duration(hours: 24);
  
  late Directory _cacheDirectory;
  bool _isInitialized = false;

  /// Initialize cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = Directory('${appDir.path}/$_cacheDir');
      
      if (!await _cacheDirectory.exists()) {
        await _cacheDirectory.create(recursive: true);
      }

      _isInitialized = true;
      logger.info('Cache service initialized successfully', 'CacheService');
      
      // Clean expired cache entries
      await _cleanExpiredCache();
    } catch (e) {
      logger.error('Failed to initialize cache service', 'CacheService', e);
    }
  }

  /// Generate cache key from data
  String _generateCacheKey(String key, Map<String, dynamic>? parameters) {
    final data = parameters != null ? json.encode(parameters) : '';
    final combined = '$key$data';
    return sha256.convert(utf8.encode(combined)).toString();
  }

  /// Cache data with expiry
  Future<void> set(String key, dynamic data, {
    Map<String, dynamic>? parameters,
    Duration? expiry,
  }) async {
    if (!_isInitialized) return;

    try {
      final cacheKey = _generateCacheKey(key, parameters);
      final cacheFile = File('${_cacheDirectory.path}/$cacheKey.json');
      
      final cacheData = {
        'key': key,
        'parameters': parameters,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'expiry': expiry?.inMilliseconds ?? _defaultExpiry.inMilliseconds,
      };

      await cacheFile.writeAsString(json.encode(cacheData));
      logger.debug('Data cached: $key', 'CacheService');
      
      // Check cache size and clean if necessary
      await _manageCacheSize();
    } catch (e) {
      logger.error('Failed to cache data: $key', 'CacheService', e);
    }
  }

  /// Get cached data
  Future<T?> get<T>(String key, {
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized) return null;

    try {
      final cacheKey = _generateCacheKey(key, parameters);
      final cacheFile = File('${_cacheDirectory.path}/$cacheKey.json');
      
      if (!await cacheFile.exists()) {
        return null;
      }

      final cacheData = json.decode(await cacheFile.readAsString());
      final timestamp = DateTime.parse(cacheData['timestamp']);
      final expiry = Duration(milliseconds: cacheData['expiry']);
      
      if (DateTime.now().isAfter(timestamp.add(expiry))) {
        await cacheFile.delete();
        logger.debug('Cache expired: $key', 'CacheService');
        return null;
      }

      logger.debug('Cache hit: $key', 'CacheService');
      return cacheData['data'] as T?;
    } catch (e) {
      logger.error('Failed to get cached data: $key', 'CacheService', e);
      return null;
    }
  }

  /// Check if data is cached and not expired
  Future<bool> has(String key, {Map<String, dynamic>? parameters}) async {
    if (!_isInitialized) return false;

    try {
      final cacheKey = _generateCacheKey(key, parameters);
      final cacheFile = File('${_cacheDirectory.path}/$cacheKey.json');
      
      if (!await cacheFile.exists()) return false;

      final cacheData = json.decode(await cacheFile.readAsString());
      final timestamp = DateTime.parse(cacheData['timestamp']);
      final expiry = Duration(milliseconds: cacheData['expiry']);
      
      return !DateTime.now().isAfter(timestamp.add(expiry));
    } catch (e) {
      return false;
    }
  }

  /// Remove specific cache entry
  Future<void> remove(String key, {Map<String, dynamic>? parameters}) async {
    if (!_isInitialized) return;

    try {
      final cacheKey = _generateCacheKey(key, parameters);
      final cacheFile = File('${_cacheDirectory.path}/$cacheKey.json');
      
      if (await cacheFile.exists()) {
        await cacheFile.delete();
        logger.debug('Cache removed: $key', 'CacheService');
      }
    } catch (e) {
      logger.error('Failed to remove cache: $key', 'CacheService', e);
    }
  }

  /// Clear all cache
  Future<void> clear() async {
    if (!_isInitialized) return;

    try {
      final files = _cacheDirectory.listSync().whereType<File>();
      for (final file in files) {
        await file.delete();
      }
      logger.info('All cache cleared', 'CacheService');
    } catch (e) {
      logger.error('Failed to clear cache', 'CacheService', e);
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    if (!_isInitialized) return {};

    try {
      final files = _cacheDirectory.listSync().whereType<File>();
      int totalSize = 0;
      int validEntries = 0;
      int expiredEntries = 0;

      for (final file in files) {
        try {
          final cacheData = json.decode(await file.readAsString());
          final timestamp = DateTime.parse(cacheData['timestamp']);
          final expiry = Duration(milliseconds: cacheData['expiry']);
          
          totalSize += await file.length();
          
          if (DateTime.now().isAfter(timestamp.add(expiry))) {
            expiredEntries++;
          } else {
            validEntries++;
          }
        } catch (e) {
          // Invalid cache file
          expiredEntries++;
        }
      }

      return {
        'totalSize': totalSize,
        'validEntries': validEntries,
        'expiredEntries': expiredEntries,
        'totalEntries': validEntries + expiredEntries,
      };
    } catch (e) {
      logger.error('Failed to get cache stats', 'CacheService', e);
      return {};
    }
  }

  /// Clean expired cache entries
  Future<void> _cleanExpiredCache() async {
    try {
      final files = _cacheDirectory.listSync().whereType<File>();
      int cleanedCount = 0;

      for (final file in files) {
        try {
          final cacheData = json.decode(await file.readAsString());
          final timestamp = DateTime.parse(cacheData['timestamp']);
          final expiry = Duration(milliseconds: cacheData['expiry']);
          
          if (DateTime.now().isAfter(timestamp.add(expiry))) {
            await file.delete();
            cleanedCount++;
          }
        } catch (e) {
          // Invalid cache file, delete it
          await file.delete();
          cleanedCount++;
        }
      }

      if (cleanedCount > 0) {
        logger.info('Cleaned $cleanedCount expired cache entries', 'CacheService');
      }
    } catch (e) {
      logger.error('Failed to clean expired cache', 'CacheService', e);
    }
  }

  /// Manage cache size to prevent excessive storage usage
  Future<void> _manageCacheSize() async {
    try {
      final stats = await getStats();
      final totalSize = stats['totalSize'] ?? 0;

      if (totalSize > _maxCacheSize) {
        // Get all cache files with their timestamps
        final files = _cacheDirectory.listSync().whereType<File>();
        final fileInfos = <Map<String, dynamic>>[];

        for (final file in files) {
          try {
            final cacheData = json.decode(await file.readAsString());
            final timestamp = DateTime.parse(cacheData['timestamp']);
            fileInfos.add({
              'file': file,
              'timestamp': timestamp,
              'size': await file.length(),
            });
          } catch (e) {
            // Skip invalid files
          }
        }

        // Sort by timestamp (oldest first)
        fileInfos.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

        // Remove oldest files until we're under the limit
        int currentSize = totalSize;
        for (final fileInfo in fileInfos) {
          if (currentSize <= _maxCacheSize) break;
          
          await fileInfo['file'].delete();
          currentSize -= (fileInfo['size'] as int);
        }

        logger.info('Cache size managed: ${totalSize ~/ 1024}KB -> ${currentSize ~/ 1024}KB', 'CacheService');
      }
    } catch (e) {
      logger.error('Failed to manage cache size', 'CacheService', e);
    }
  }
}

// Global cache instance
final cacheService = CacheService(); 