import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'analytics_service.dart';
import 'error_reporting_service.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  // Lazy initialization to avoid Firebase initialization issues
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Cache keys
  static const String _productsCacheKey = 'cached_products';
  static const String _ordersCacheKey = 'cached_orders';
  static const String _userDataCacheKey = 'cached_user_data';
  static const String _pendingActionsKey = 'pending_actions';
  static const String _lastSyncKey = 'last_sync_timestamp';

  // Cache expiration time (24 hours)
  static const Duration _cacheExpiration = Duration(hours: 24);

  /// Check if data is available offline
  Future<bool> isDataAvailableOffline(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(cacheKey);
      if (cachedData == null) return false;

      final data = jsonDecode(cachedData);
      final timestamp = DateTime.parse(data['timestamp']);
      final now = DateTime.now();

      return now.difference(timestamp) < _cacheExpiration;
    } catch (e) {
      print('❌ Offline: Error checking cache availability: $e');
      return false;
    }
  }

  /// Cache data locally
  Future<void> cacheData(String cacheKey, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(cacheKey, jsonEncode(cacheData));
      print('✅ Offline: Data cached for $cacheKey');
    } catch (e) {
      print('❌ Offline: Failed to cache data: $e');
      await ErrorReportingService.reportError(
        errorType: 'cache_error',
        errorMessage: 'Failed to cache data for $cacheKey',
        error: e,
      );
    }
  }

  /// Get cached data
  Future<dynamic> getCachedData(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(cacheKey);
      if (cachedData == null) return null;

      final data = jsonDecode(cachedData);
      final timestamp = DateTime.parse(data['timestamp']);
      final now = DateTime.now();

      if (now.difference(timestamp) > _cacheExpiration) {
        // Cache expired, remove it
        await prefs.remove(cacheKey);
        return null;
      }

      return data['data'];
    } catch (e) {
      print('❌ Offline: Error getting cached data: $e');
      return null;
    }
  }

  /// Cache products for offline use
  Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    await cacheData(_productsCacheKey, products);
  }

  /// Get cached products
  Future<List<Map<String, dynamic>>> getCachedProducts() async {
    final data = await getCachedData(_productsCacheKey);
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Cache orders for offline use
  Future<void> cacheOrders(List<Map<String, dynamic>> orders) async {
    await cacheData(_ordersCacheKey, orders);
  }

  /// Get cached orders
  Future<List<Map<String, dynamic>>> getCachedOrders() async {
    final data = await getCachedData(_ordersCacheKey);
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Cache user data
  Future<void> cacheUserData(Map<String, dynamic> userData) async {
    await cacheData(_userDataCacheKey, userData);
  }

  /// Get cached user data
  Future<Map<String, dynamic>?> getCachedUserData() async {
    final data = await getCachedData(_userDataCacheKey);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return null;
  }

  /// Add pending action for later sync
  Future<void> addPendingAction({
    required String action,
    required Map<String, dynamic> data,
    String? userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingActions = await getPendingActions();
      
      pendingActions.add({
        'action': action,
        'data': data,
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      await prefs.setString(_pendingActionsKey, jsonEncode(pendingActions));
      print('✅ Offline: Pending action added: $action');
    } catch (e) {
      print('❌ Offline: Failed to add pending action: $e');
    }
  }

  /// Get pending actions
  Future<List<Map<String, dynamic>>> getPendingActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_pendingActionsKey);
      if (data != null) {
        final actions = jsonDecode(data) as List;
        return actions.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('❌ Offline: Error getting pending actions: $e');
    }
    return [];
  }

  /// Sync pending actions with server
  Future<void> syncPendingActions() async {
    try {
      final pendingActions = await getPendingActions();
      if (pendingActions.isEmpty) return;

      print('🔄 Offline: Syncing ${pendingActions.length} pending actions...');

      final batch = _firestore.batch();
      final successfulActions = <String>[];

      for (final action in pendingActions) {
        try {
          switch (action['action']) {
            case 'add_order':
              await _syncAddOrder(action['data']);
              successfulActions.add(action['id']);
              break;
            case 'update_order':
              await _syncUpdateOrder(action['data']);
              successfulActions.add(action['id']);
              break;
            case 'add_product':
              await _syncAddProduct(action['data']);
              successfulActions.add(action['id']);
              break;
            case 'update_product':
              await _syncUpdateProduct(action['data']);
              successfulActions.add(action['id']);
              break;
            default:
              print('⚠️ Offline: Unknown action type: ${action['action']}');
          }
        } catch (e) {
          print('❌ Offline: Failed to sync action ${action['id']}: $e');
        }
      }

      // Remove successful actions from pending list
      if (successfulActions.isNotEmpty) {
        final remainingActions = pendingActions
            .where((action) => !successfulActions.contains(action['id']))
            .toList();
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_pendingActionsKey, jsonEncode(remainingActions));
        
        print('✅ Offline: Synced ${successfulActions.length} actions successfully');
        print('⚠️ Offline: ${remainingActions.length} actions still pending');
      }

      // Update last sync timestamp
      await _updateLastSyncTimestamp();
    } catch (e) {
      print('❌ Offline: Sync failed: $e');
      await ErrorReportingService.reportError(
        errorType: 'sync_error',
        errorMessage: 'Failed to sync pending actions',
        error: e,
      );
    }
  }

  /// Sync add order action
  Future<void> _syncAddOrder(Map<String, dynamic> orderData) async {
    await _firestore.collection('orders').add(orderData);
          await AnalyticsService.trackFeatureUsage(
        feature: 'offline_order_synced',
        userRole: orderData['buyerRole'] ?? 'unknown',
      );
  }

  /// Sync update order action
  Future<void> _syncUpdateOrder(Map<String, dynamic> orderData) async {
    final orderId = orderData['id'];
    if (orderId != null) {
      await _firestore.collection('orders').doc(orderId).update(orderData);
    }
  }

  /// Sync add product action
  Future<void> _syncAddProduct(Map<String, dynamic> productData) async {
    await _firestore.collection('products').add(productData);
    await AnalyticsService.trackFeatureUsage(
      feature: 'offline_product_synced',
      userRole: productData['dealer'] ?? 'unknown',
    );
  }

  /// Sync update product action
  Future<void> _syncUpdateProduct(Map<String, dynamic> productData) async {
    final productId = productData['id'];
    if (productId != null) {
      final docRef = _firestore.collection('products').doc(productId);
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        await docRef.update(productData);
      } else {
        await docRef.set(productData);
      }
    }
  }

  /// Update last sync timestamp
  Future<void> _updateLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_lastSyncKey);
      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
    } catch (e) {
      print('❌ Offline: Error getting last sync timestamp: $e');
    }
    return null;
  }

  /// Check if sync is needed
  Future<bool> isSyncNeeded() async {
    final lastSync = await getLastSyncTimestamp();
    if (lastSync == null) return true;

    final pendingActions = await getPendingActions();
    if (pendingActions.isNotEmpty) return true;

    final timeSinceLastSync = DateTime.now().difference(lastSync);
    return timeSinceLastSync > Duration(hours: 1); // Sync every hour
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_productsCacheKey);
      await prefs.remove(_ordersCacheKey);
      await prefs.remove(_userDataCacheKey);
      await prefs.remove(_pendingActionsKey);
      await prefs.remove(_lastSyncKey);
      print('✅ Offline: Cache cleared');
    } catch (e) {
      print('❌ Offline: Failed to clear cache: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingActions = await getPendingActions();
      final lastSync = await getLastSyncTimestamp();

      return {
        'pendingActions': pendingActions.length,
        'lastSync': lastSync?.toIso8601String(),
        'productsCached': await isDataAvailableOffline(_productsCacheKey),
        'ordersCached': await isDataAvailableOffline(_ordersCacheKey),
        'userDataCached': await isDataAvailableOffline(_userDataCacheKey),
      };
    } catch (e) {
      print('❌ Offline: Error getting cache stats: $e');
      return {};
    }
  }

  /// Show offline status indicator
  Widget buildOfflineIndicator({
    required bool isOnline,
    required VoidCallback onRetry,
  }) {
    if (isOnline) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.orange,
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'You\'re offline. Some features may be limited.',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle offline data operations
  Future<T?> handleOfflineOperation<T>({
    required Future<T> Function() onlineOperation,
    required Future<T?> Function() offlineOperation,
    required String operationName,
    Map<String, dynamic>? pendingData,
  }) async {
    try {
      // Try online operation first
      return await onlineOperation();
    } catch (e) {
      print('⚠️ Offline: Online operation failed, trying offline: $e');
      
      // If there's pending data, add it to pending actions
      if (pendingData != null) {
        await addPendingAction(
          action: operationName,
          data: pendingData,
        );
      }

      // Try offline operation
      try {
        return await offlineOperation();
      } catch (offlineError) {
        print('❌ Offline: Offline operation also failed: $offlineError');
        await ErrorReportingService.reportError(
          errorType: 'offline_operation_failed',
          errorMessage: 'Both online and offline operations failed for $operationName',
          error: offlineError,
        );
        return null;
      }
    }
  }
} 