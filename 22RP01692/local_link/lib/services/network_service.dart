import 'dart:io';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'logger_service.dart';
import 'cache_service.dart';

/// Network service for handling connectivity and optimized requests
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  final http.Client _httpClient = http.Client();
  
  bool _isInitialized = false;
  bool _isOnline = true;
  Timer? _connectivityTimer;
  
  // Request queue for offline operations
  final List<Map<String, dynamic>> _offlineQueue = [];
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();

  /// Initialize network service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize cache service
      await cacheService.initialize();
      
      // Check initial connectivity
      await _checkConnectivity();
      
      // Start connectivity monitoring
      _startConnectivityMonitoring();
      
      _isInitialized = true;
      logger.info('Network service initialized successfully', 'NetworkService');
    } catch (e) {
      logger.error('Failed to initialize network service', 'NetworkService', e);
    }
  }

  /// Get connectivity stream
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Check if device is online
  bool get isOnline => _isOnline;

  /// Check connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final wasOnline = _isOnline;
      _isOnline = connectivityResult != ConnectivityResult.none;
      
      if (wasOnline != _isOnline) {
        _connectivityController.add(_isOnline);
        logger.info('Connectivity changed: ${_isOnline ? 'Online' : 'Offline'}', 'NetworkService');
        
        if (_isOnline) {
          await _processOfflineQueue();
        }
      }
    } catch (e) {
      logger.error('Failed to check connectivity', 'NetworkService', e);
    }
  }

  /// Start connectivity monitoring
  void _startConnectivityMonitoring() {
    _connectivityTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkConnectivity();
    });
  }

  /// Optimized GET request with caching and offline support
  Future<http.Response?> get(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? cacheParameters,
    Duration? cacheExpiry,
    bool forceRefresh = false,
  }) async {
    if (!_isInitialized) return null;

    final cacheKey = 'GET_$url';
    
    // Try cache first if not forcing refresh
    if (!forceRefresh) {
      final cachedResponse = await cacheService.get<Map<String, dynamic>>(
        cacheKey,
        parameters: cacheParameters,
      );
      
      if (cachedResponse != null) {
        logger.debug('Cache hit for GET: $url', 'NetworkService');
        return _createResponseFromCache(cachedResponse);
      }
    }

    // Check if offline
    if (!_isOnline) {
      logger.warning('Offline: Cannot fetch $url', 'NetworkService');
      return null;
    }

    try {
      logger.debug('Making GET request: $url', 'NetworkService');
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: headers,
      );

      // Cache successful responses
      if (response.statusCode == 200) {
        await cacheService.set(
          cacheKey,
          {
            'statusCode': response.statusCode,
            'headers': response.headers,
            'body': response.body,
            'timestamp': DateTime.now().toIso8601String(),
          },
          parameters: cacheParameters,
          expiry: cacheExpiry,
        );
      }

      return response;
    } catch (e) {
      logger.error('GET request failed: $url', 'NetworkService', e);
      return null;
    }
  }

  /// Optimized POST request with offline queue support
  Future<http.Response?> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? offlineData,
  }) async {
    if (!_isInitialized) return null;

    // Check if offline
    if (!_isOnline) {
      if (offlineData != null) {
        _addToOfflineQueue('POST', url, headers, body, offlineData);
        logger.info('Request queued for offline processing: POST $url', 'NetworkService');
      }
      return null;
    }

    try {
      logger.debug('Making POST request: $url', 'NetworkService');
      return await _httpClient.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
    } catch (e) {
      logger.error('POST request failed: $url', 'NetworkService', e);
      
      // Queue for retry if offline data provided
      if (offlineData != null) {
        _addToOfflineQueue('POST', url, headers, body, offlineData);
      }
      
      return null;
    }
  }

  /// Add request to offline queue
  void _addToOfflineQueue(
    String method,
    String url,
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic> offlineData,
  ) {
    _offlineQueue.add({
      'method': method,
      'url': url,
      'headers': headers,
      'body': body,
      'offlineData': offlineData,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    logger.debug('Added to offline queue: $method $url', 'NetworkService');
  }

  /// Process offline queue when back online
  Future<void> _processOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;

    logger.info('Processing ${_offlineQueue.length} queued requests', 'NetworkService');
    
    final queue = List<Map<String, dynamic>>.from(_offlineQueue);
    _offlineQueue.clear();

    for (final request in queue) {
      try {
        final method = request['method'] as String;
        final url = request['url'] as String;
        final headers = request['headers'] as Map<String, String>?;
        final body = request['body'];

        http.Response? response;
        
        switch (method) {
          case 'POST':
            response = await _httpClient.post(
              Uri.parse(url),
              headers: headers,
              body: body,
            );
            break;
          case 'PUT':
            response = await _httpClient.put(
              Uri.parse(url),
              headers: headers,
              body: body,
            );
            break;
          case 'DELETE':
            response = await _httpClient.delete(
              Uri.parse(url),
              headers: headers,
              body: body,
            );
            break;
        }

        if (response?.statusCode == 200 || response?.statusCode == 201) {
          logger.info('Queued request successful: $method $url', 'NetworkService');
        } else {
          // Re-queue failed requests
          _offlineQueue.add(request);
          logger.warning('Queued request failed, re-queued: $method $url', 'NetworkService');
        }
      } catch (e) {
        // Re-queue failed requests
        _offlineQueue.add(request);
        logger.error('Queued request error, re-queued: ${request['method']} ${request['url']}', 'NetworkService', e);
      }
    }
  }

  /// Create response from cached data
  http.Response _createResponseFromCache(Map<String, dynamic> cachedData) {
    return http.Response(
      cachedData['body'] as String,
      cachedData['statusCode'] as int,
      headers: Map<String, String>.from(cachedData['headers'] as Map),
    );
  }

  /// Get offline queue status
  Map<String, dynamic> getOfflineQueueStatus() {
    return {
      'queueLength': _offlineQueue.length,
      'isOnline': _isOnline,
      'pendingRequests': _offlineQueue.map((req) => {
        'method': req['method'],
        'url': req['url'],
        'timestamp': req['timestamp'],
      }).toList(),
    };
  }

  /// Clear offline queue
  void clearOfflineQueue() {
    _offlineQueue.clear();
    logger.info('Offline queue cleared', 'NetworkService');
  }

  /// Test network connectivity
  Future<bool> testConnectivity() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('https://www.google.com'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get network statistics
  Future<Map<String, dynamic>> getNetworkStats() async {
    final cacheStats = await cacheService.getStats();
    final queueStatus = getOfflineQueueStatus();
    
    return {
      'isOnline': _isOnline,
      'cacheStats': cacheStats,
      'offlineQueue': queueStatus,
    };
  }

  /// Dispose resources
  void dispose() {
    _connectivityTimer?.cancel();
    _httpClient.close();
    _connectivityController.close();
    logger.info('Network service disposed', 'NetworkService');
  }
}

// Global network instance
final networkService = NetworkService(); 