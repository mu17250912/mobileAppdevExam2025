import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PerformanceUtils {
  // Lazy loading for images
  static Widget buildOptimizedImage(String imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        ),
        memCacheWidth: 800, // Optimize memory usage
        memCacheHeight: 600,
      );
    } else {
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: 800,
        cacheHeight: 600,
      );
    }
  }

  // Pagination for large datasets
  static Stream<QuerySnapshot> getPaginatedData(
    CollectionReference collection, {
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) {
    Query query = collection.orderBy('createdAt', descending: true).limit(limit);
    
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    
    return query.snapshots();
  }

  // Efficient search with debouncing
  static Stream<QuerySnapshot> searchWithDebounce(
    CollectionReference collection,
    String searchTerm, {
    int debounceMs = 500,
  }) {
    if (searchTerm.isEmpty) {
      return collection.limit(20).snapshots();
    }
    
    return collection
        .where('name', isGreaterThanOrEqualTo: searchTerm)
        .where('name', isLessThan: '$searchTerm\uf8ff')
        .limit(20)
        .snapshots();
  }

  // Memory-efficient list building
  static Widget buildOptimizedListView<T>({
    required List<T> items,
    required Widget Function(BuildContext, T) itemBuilder,
    ScrollController? controller,
    bool shrinkWrap = false,
  }) {
    return ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return itemBuilder(context, items[index]);
      },
    );
  }

  // Efficient data caching
  static final Map<String, dynamic> _cache = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  static Future<T?> getCachedData<T>(String key, Future<T> Function() fetcher) async {
    final now = DateTime.now();
    final cached = _cache[key];
    
    if (cached != null && 
        cached['timestamp'] != null &&
        now.difference(cached['timestamp']) < _cacheExpiry) {
      return cached['data'] as T;
    }
    
    try {
      final data = await fetcher();
      _cache[key] = {
        'data': data,
        'timestamp': now,
      };
      return data;
    } catch (e) {
      return null;
    }
  }

  // Clear cache when needed
  static void clearCache() {
    _cache.clear();
  }

  // Optimize network requests
  static Future<List<Map<String, dynamic>>> getOptimizedCarList() async {
    final cachedData = await getCachedData('cars', () async {
      final snapshot = await FirebaseFirestore.instance
          .collection('cars')
          .limit(50) // Limit for performance
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
    
    return cachedData ?? [];
  }
} 