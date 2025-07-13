import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class SearchAnalyticsService {
  static final SearchAnalyticsService _instance = SearchAnalyticsService._internal();
  factory SearchAnalyticsService() => _instance;
  SearchAnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Track search event
  Future<void> trackSearch({
    required String query,
    required Map<String, dynamic> filters,
    required int resultCount,
    required String searchType,
  }) async {
    try {
      final user = _auth.currentUser;
      final searchData = {
        'userId': user?.uid,
        'query': query,
        'filters': filters,
        'resultCount': resultCount,
        'searchType': searchType, // 'text', 'map', 'filter'
        'timestamp': FieldValue.serverTimestamp(),
        'userAgent': 'flutter_app',
      };

      // Save to Firestore
      await _firestore.collection('search_analytics').add(searchData);

      // Track with Firebase Analytics
      await _analytics.logEvent(
        name: 'property_search',
        parameters: {
          'search_query': query,
          'result_count': resultCount,
          'search_type': searchType,
          'has_filters': filters.isNotEmpty,
          'filter_count': filters.length,
        },
      );
    } catch (e) {
      print('Error tracking search: $e');
    }
  }

  // Track filter usage
  Future<void> trackFilterUsage({
    required String filterType,
    required String filterValue,
    required bool isApplied,
  }) async {
    try {
      final user = _auth.currentUser;
      final filterData = {
        'userId': user?.uid,
        'filterType': filterType,
        'filterValue': filterValue,
        'isApplied': isApplied,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('filter_analytics').add(filterData);

      await _analytics.logEvent(
        name: 'filter_used',
        parameters: {
          'filter_type': filterType,
          'filter_value': filterValue,
          'is_applied': isApplied,
        },
      );
    } catch (e) {
      print('Error tracking filter usage: $e');
    }
  }

  // Track saved search
  Future<void> trackSavedSearch({
    required String searchName,
    required Map<String, dynamic> filters,
  }) async {
    try {
      final user = _auth.currentUser;
      final savedSearchData = {
        'userId': user?.uid,
        'searchName': searchName,
        'filters': filters,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('saved_search_analytics').add(savedSearchData);

      await _analytics.logEvent(
        name: 'search_saved',
        parameters: {
          'search_name': searchName,
          'filter_count': filters.length,
        },
      );
    } catch (e) {
      print('Error tracking saved search: $e');
    }
  }

  // Track property view from search
  Future<void> trackPropertyViewFromSearch({
    required String propertyId,
    required String searchQuery,
    required Map<String, dynamic> searchFilters,
    required int searchResultPosition,
  }) async {
    try {
      final user = _auth.currentUser;
      final viewData = {
        'userId': user?.uid,
        'propertyId': propertyId,
        'searchQuery': searchQuery,
        'searchFilters': searchFilters,
        'searchResultPosition': searchResultPosition,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('search_property_views').add(viewData);

      await _analytics.logEvent(
        name: 'property_viewed_from_search',
        parameters: {
          'property_id': propertyId,
          'search_query': searchQuery,
          'result_position': searchResultPosition,
        },
      );
    } catch (e) {
      print('Error tracking property view from search: $e');
    }
  }

  // Track search performance
  Future<void> trackSearchPerformance({
    required String searchType,
    required int resultCount,
    required int searchTimeMs,
    required bool isSuccessful,
  }) async {
    try {
      final performanceData = {
        'searchType': searchType,
        'resultCount': resultCount,
        'searchTimeMs': searchTimeMs,
        'isSuccessful': isSuccessful,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('search_performance').add(performanceData);

      await _analytics.logEvent(
        name: 'search_performance',
        parameters: {
          'search_type': searchType,
          'result_count': resultCount,
          'search_time_ms': searchTimeMs,
          'is_successful': isSuccessful,
        },
      );
    } catch (e) {
      print('Error tracking search performance: $e');
    }
  }

  // Get popular searches
  Future<List<Map<String, dynamic>>> getPopularSearches({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('search_analytics')
          .where('query', isNotEqualTo: '')
          .orderBy('query')
          .limit(limit)
          .get();

      final Map<String, int> searchCounts = {};
      for (final doc in snapshot.docs) {
        final query = doc.data()['query'] as String;
        searchCounts[query] = (searchCounts[query] ?? 0) + 1;
      }

      final sortedSearches = searchCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedSearches.take(limit).map((entry) => {
        'query': entry.key,
        'count': entry.value,
      }).toList();
    } catch (e) {
      print('Error getting popular searches: $e');
      return [];
    }
  }

  // Get search insights for admin
  Future<Map<String, dynamic>> getSearchInsights() async {
    try {
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));
      final lastMonth = now.subtract(const Duration(days: 30));

      // Get search counts
      final weeklySearches = await _firestore
          .collection('search_analytics')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(lastWeek))
          .get();

      final monthlySearches = await _firestore
          .collection('search_analytics')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(lastMonth))
          .get();

      // Get filter usage
      final filterUsage = await _firestore
          .collection('filter_analytics')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(lastWeek))
          .get();

      // Calculate insights
      final Map<String, int> filterCounts = {};
      for (final doc in filterUsage.docs) {
        final filterType = doc.data()['filterType'] as String;
        filterCounts[filterType] = (filterCounts[filterType] ?? 0) + 1;
      }

      return {
        'weeklySearches': weeklySearches.docs.length,
        'monthlySearches': monthlySearches.docs.length,
        'popularFilters': filterCounts,
        'averageResultsPerSearch': _calculateAverageResults(weeklySearches.docs),
        'searchSuccessRate': _calculateSuccessRate(weeklySearches.docs),
      };
    } catch (e) {
      print('Error getting search insights: $e');
      return {};
    }
  }

  double _calculateAverageResults(List<QueryDocumentSnapshot> searches) {
    if (searches.isEmpty) return 0;
    
    final totalResults = searches.fold<int>(0, (sum, doc) {
      return sum + (doc.data()['resultCount'] as int? ?? 0);
    });
    
    return totalResults / searches.length;
  }

  double _calculateSuccessRate(List<QueryDocumentSnapshot> searches) {
    if (searches.isEmpty) return 0;
    
    final successfulSearches = searches.where((doc) {
      final resultCount = doc.data()['resultCount'] as int? ?? 0;
      return resultCount > 0;
    }).length;
    
    return successfulSearches / searches.length;
  }

  // Track search abandonment
  Future<void> trackSearchAbandonment({
    required String searchQuery,
    required Map<String, dynamic> filters,
    required int resultCount,
    required String reason,
  }) async {
    try {
      final user = _auth.currentUser;
      final abandonmentData = {
        'userId': user?.uid,
        'searchQuery': searchQuery,
        'filters': filters,
        'resultCount': resultCount,
        'reason': reason, // 'no_results', 'too_many_results', 'user_cancelled'
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('search_abandonment').add(abandonmentData);

      await _analytics.logEvent(
        name: 'search_abandoned',
        parameters: {
          'search_query': searchQuery,
          'result_count': resultCount,
          'abandonment_reason': reason,
        },
      );
    } catch (e) {
      print('Error tracking search abandonment: $e');
    }
  }
} 