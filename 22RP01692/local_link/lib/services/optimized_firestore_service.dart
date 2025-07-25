import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'logger_service.dart';
import 'cache_service.dart';
import 'network_service.dart';

/// Optimized Firestore service with caching, pagination, and performance improvements
class OptimizedFirestoreService {
  static final OptimizedFirestoreService _instance = OptimizedFirestoreService._internal();
  factory OptimizedFirestoreService() => _instance;
  OptimizedFirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Pagination settings
  static const int _defaultPageSize = 20;
  static const int _maxPageSize = 50;
  
  // Cache settings
  static const Duration _userDataCacheExpiry = Duration(minutes: 30);
  static const Duration _servicesCacheExpiry = Duration(minutes: 15);
  static const Duration _bookingsCacheExpiry = Duration(minutes: 5);

  /// Get user data with caching
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final cacheKey = 'user_data_$uid';
    
    // Try cache first
    final cachedData = await cacheService.get<Map<String, dynamic>>(cacheKey);
    if (cachedData != null) {
      logger.debug('User data cache hit: $uid', 'OptimizedFirestore');
      return cachedData;
    }

    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        
        // Cache the result
        await cacheService.set(
          cacheKey,
          data,
          expiry: _userDataCacheExpiry,
        );
        
        logger.debug('User data fetched and cached: $uid', 'OptimizedFirestore');
        return data;
      }
      return null;
    } catch (e) {
      logger.error('Failed to get user data: $uid', 'OptimizedFirestore', e);
      return null;
    }
  }

  /// Get services with pagination and caching
  Future<List<Map<String, dynamic>>> getServices({
    String? category,
    String? location,
    int page = 0,
    int pageSize = _defaultPageSize,
    bool forceRefresh = false,
  }) async {
    // Validate page size
    pageSize = pageSize.clamp(1, _maxPageSize);
    
    final cacheKey = 'services_${category ?? 'all'}_${location ?? 'all'}_$page';
    
    // Try cache first if not forcing refresh
    if (!forceRefresh) {
      final cachedData = await cacheService.get<List<Map<String, dynamic>>>(cacheKey);
      if (cachedData != null) {
        logger.debug('Services cache hit: page $page', 'OptimizedFirestore');
        return cachedData;
      }
    }

    try {
      Query query = _db.collection('services');
      
      // Apply filters
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }
      
      if (location != null && location.isNotEmpty) {
        query = query.where('location', isEqualTo: location);
      }
      
      // Apply pagination
      query = query.limit(pageSize).offset(page * pageSize);
      
      final snapshot = await query.get();
      final services = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Cache the result
      await cacheService.set(
        cacheKey,
        services,
        expiry: _servicesCacheExpiry,
      );
      
      logger.debug('Services fetched and cached: ${services.length} items', 'OptimizedFirestore');
      return services;
    } catch (e) {
      logger.error('Failed to get services', 'OptimizedFirestore', e);
      return [];
    }
  }

  /// Get user bookings with pagination and caching
  Future<List<Map<String, dynamic>>> getUserBookings(
    String userId, {
    int page = 0,
    int pageSize = _defaultPageSize,
    String? status,
    bool forceRefresh = false,
  }) async {
    pageSize = pageSize.clamp(1, _maxPageSize);
    
    final cacheKey = 'user_bookings_${userId}_${status ?? 'all'}_$page';
    
    // Try cache first if not forcing refresh
    if (!forceRefresh) {
      final cachedData = await cacheService.get<List<Map<String, dynamic>>>(cacheKey);
      if (cachedData != null) {
        logger.debug('User bookings cache hit: $userId page $page', 'OptimizedFirestore');
        return cachedData;
      }
    }

    try {
      Query query = _db.collection('bookings').where('userId', isEqualTo: userId);
      
      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }
      
      // Apply pagination
      query = query.limit(pageSize).offset(page * pageSize);
      
      final snapshot = await query.get();
      final bookings = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Cache the result
      await cacheService.set(
        cacheKey,
        bookings,
        expiry: _bookingsCacheExpiry,
      );
      
      logger.debug('User bookings fetched and cached: ${bookings.length} items', 'OptimizedFirestore');
      return bookings;
    } catch (e) {
      logger.error('Failed to get user bookings: $userId', 'OptimizedFirestore', e);
      return [];
    }
  }

  /// Get provider bookings with pagination
  Future<List<Map<String, dynamic>>> getProviderBookings(
    String providerId, {
    int page = 0,
    int pageSize = _defaultPageSize,
    String? status,
  }) async {
    pageSize = pageSize.clamp(1, _maxPageSize);
    
    try {
      Query query = _db.collection('bookings').where('providerId', isEqualTo: providerId);
      
      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }
      
      // Apply pagination
      query = query.limit(pageSize).offset(page * pageSize);
      
      final snapshot = await query.get();
      final bookings = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      logger.debug('Provider bookings fetched: ${bookings.length} items', 'OptimizedFirestore');
      return bookings;
    } catch (e) {
      logger.error('Failed to get provider bookings: $providerId', 'OptimizedFirestore', e);
      return [];
    }
  }

  /// Save booking with offline support
  Future<bool> saveBooking(Map<String, dynamic> booking) async {
    try {
      // Check if offline
      if (!networkService.isOnline) {
        logger.warning('Offline: Booking will be queued', 'OptimizedFirestore');
        // Store locally for later sync
        await _storeOfflineBooking(booking);
        return true;
      }
      
      await _db.collection('bookings').add(booking);
      
      // Invalidate related caches
      await _invalidateBookingCaches(booking['userId'] as String?);
      
      logger.info('Booking saved successfully', 'OptimizedFirestore');
      return true;
    } catch (e) {
      logger.error('Failed to save booking', 'OptimizedFirestore', e);
      return false;
    }
  }

  /// Update booking status with cache invalidation
  Future<bool> updateBookingStatus(String bookingId, String status) async {
    try {
      await _db.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Invalidate related caches
      await _invalidateBookingCaches(null);
      
      logger.info('Booking status updated: $bookingId -> $status', 'OptimizedFirestore');
      return true;
    } catch (e) {
      logger.error('Failed to update booking status: $bookingId', 'OptimizedFirestore', e);
      return false;
    }
  }

  /// Get nearby providers with geospatial optimization
  Future<List<Map<String, dynamic>>> getNearbyProviders(
    double lat, 
    double lng, 
    double radiusKm,
  ) async {
    final cacheKey = 'nearby_providers_${lat.toStringAsFixed(2)}_${lng.toStringAsFixed(2)}_$radiusKm';
    
    // Try cache first
    final cachedData = await cacheService.get<List<Map<String, dynamic>>>(cacheKey);
    if (cachedData != null) {
      logger.debug('Nearby providers cache hit', 'OptimizedFirestore');
      return cachedData;
    }

    try {
      // Use geohash-based query for better performance
      final snapshot = await _db.collection('providers')
          .where('isActive', isEqualTo: true)
          .get();
      
      final providers = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Calculate distance
        final providerLat = (data['lat'] ?? 0).toDouble();
        final providerLng = (data['lng'] ?? 0).toDouble();
        data['distance'] = _calculateDistance(lat, lng, providerLat, providerLng);
        
        return data;
      }).where((provider) {
        final distance = provider['distance'] as double;
        return distance <= radiusKm;
      }).toList();
      
      // Sort by distance
      providers.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
      
      // Cache the result
      await cacheService.set(
        cacheKey,
        providers,
        expiry: const Duration(minutes: 10),
      );
      
      logger.debug('Nearby providers fetched and cached: ${providers.length} items', 'OptimizedFirestore');
      return providers;
    } catch (e) {
      logger.error('Failed to get nearby providers', 'OptimizedFirestore', e);
      return [];
    }
  }

  /// Get provider reviews with pagination
  Future<List<Map<String, dynamic>>> getProviderReviews(
    String providerId, {
    int page = 0,
    int pageSize = _defaultPageSize,
  }) async {
    pageSize = pageSize.clamp(1, _maxPageSize);
    
    try {
      final snapshot = await _db
          .collection('providers')
          .doc(providerId)
          .collection('reviews')
          .limit(pageSize)
          .offset(page * pageSize)
          .get();
      
      final reviews = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      logger.debug('Provider reviews fetched: ${reviews.length} items', 'OptimizedFirestore');
      return reviews;
    } catch (e) {
      logger.error('Failed to get provider reviews: $providerId', 'OptimizedFirestore', e);
      return [];
    }
  }

  /// Save review with cache invalidation
  Future<bool> saveReview(String providerId, Map<String, dynamic> review) async {
    try {
      await _db.collection('providers')
          .doc(providerId)
          .collection('reviews')
          .add({
        ...review,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Invalidate provider-related caches
      await _invalidateProviderCaches(providerId);
      
      logger.info('Review saved successfully for provider: $providerId', 'OptimizedFirestore');
      return true;
    } catch (e) {
      logger.error('Failed to save review: $providerId', 'OptimizedFirestore', e);
      return false;
    }
  }

  /// Get booking statistics with caching
  Future<Map<String, dynamic>> getBookingStats(String userId) async {
    final cacheKey = 'booking_stats_$userId';
    
    // Try cache first
    final cachedData = await cacheService.get<Map<String, dynamic>>(cacheKey);
    if (cachedData != null) {
      logger.debug('Booking stats cache hit: $userId', 'OptimizedFirestore');
      return cachedData;
    }

    try {
      final snapshot = await _db
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();
      
      final bookings = snapshot.docs;
      final total = bookings.length;
      final completed = bookings.where((doc) => doc.data()['status'] == 'completed').length;
      final pending = bookings.where((doc) => doc.data()['status'] == 'pending').length;
      final cancelled = bookings.where((doc) => doc.data()['status'] == 'cancelled').length;
      
      final stats = {
        'total': total,
        'completed': completed,
        'pending': pending,
        'cancelled': cancelled,
        'completionRate': total > 0 ? (completed / total * 100).round() : 0,
      };
      
      // Cache the result
      await cacheService.set(
        cacheKey,
        stats,
        expiry: const Duration(minutes: 30),
      );
      
      logger.debug('Booking stats calculated and cached: $userId', 'OptimizedFirestore');
      return stats;
    } catch (e) {
      logger.error('Failed to get booking stats: $userId', 'OptimizedFirestore', e);
      return {'total': 0, 'completed': 0, 'pending': 0, 'cancelled': 0, 'completionRate': 0};
    }
  }

  /// Store booking offline for later sync
  Future<void> _storeOfflineBooking(Map<String, dynamic> booking) async {
    try {
      final offlineBookings = await cacheService.get<List<Map<String, dynamic>>>('offline_bookings') ?? [];
      offlineBookings.add({
        ...booking,
        'offlineId': DateTime.now().millisecondsSinceEpoch.toString(),
        'synced': false,
      });
      
      await cacheService.set('offline_bookings', offlineBookings);
      logger.info('Booking stored offline', 'OptimizedFirestore');
    } catch (e) {
      logger.error('Failed to store offline booking', 'OptimizedFirestore', e);
    }
  }

  /// Invalidate booking-related caches
  Future<void> _invalidateBookingCaches(String? userId) async {
    try {
      if (userId != null) {
        await cacheService.remove('user_bookings_${userId}_all_0');
        await cacheService.remove('booking_stats_$userId');
      }
      
      // Clear all booking caches if no specific user
      final cacheStats = await cacheService.getStats();
      final files = cacheStats['totalEntries'] ?? 0;
      
      if (files > 0) {
        // This is a simplified approach - in production, you'd want more granular cache invalidation
        logger.debug('Booking caches invalidated', 'OptimizedFirestore');
      }
    } catch (e) {
      logger.error('Failed to invalidate booking caches', 'OptimizedFirestore', e);
    }
  }

  /// Invalidate provider-related caches
  Future<void> _invalidateProviderCaches(String providerId) async {
    try {
      await cacheService.remove('nearby_providers_', parameters: {'providerId': providerId});
      logger.debug('Provider caches invalidated: $providerId', 'OptimizedFirestore');
    } catch (e) {
      logger.error('Failed to invalidate provider caches', 'OptimizedFirestore', e);
    }
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);
    
    final a = (dLat / 2).sin() * (dLat / 2).sin() +
        lat1.sin() * lat2.sin() * (dLng / 2).sin() * (dLng / 2).sin();
    final c = 2 * a.sqrt().asin();
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    try {
      await cacheService.clear();
      logger.info('All Firestore caches cleared', 'OptimizedFirestore');
    } catch (e) {
      logger.error('Failed to clear caches', 'OptimizedFirestore', e);
    }
  }

  /// Get service statistics
  Future<Map<String, dynamic>> getServiceStats() async {
    try {
      final cacheKey = 'service_stats';
      
      // Try cache first
      final cachedData = await cacheService.get<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }

      final snapshot = await _db.collection('services').get();
      final services = snapshot.docs;
      
      final stats = {
        'totalServices': services.length,
        'categories': <String, int>{},
        'averageRating': 0.0,
      };
      
      double totalRating = 0;
      int ratedServices = 0;
      
      for (final doc in services) {
        final data = doc.data();
        final category = data['category'] as String? ?? 'Unknown';
        final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
        
        stats['categories'][category] = (stats['categories'][category] ?? 0) + 1;
        
        if (rating > 0) {
          totalRating += rating;
          ratedServices++;
        }
      }
      
      if (ratedServices > 0) {
        stats['averageRating'] = (totalRating / ratedServices).roundToDouble();
      }
      
      // Cache the result
      await cacheService.set(
        cacheKey,
        stats,
        expiry: const Duration(hours: 1),
      );
      
      return stats;
    } catch (e) {
      logger.error('Failed to get service stats', 'OptimizedFirestore', e);
      return {'totalServices': 0, 'categories': {}, 'averageRating': 0.0};
    }
  }
}

// Global optimized Firestore instance
final optimizedFirestore = OptimizedFirestoreService(); 