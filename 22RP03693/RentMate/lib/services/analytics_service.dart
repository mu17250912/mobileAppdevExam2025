import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Track user activity
  Future<void> trackUserActivity(String userId, String activity) async {
    try {
      await _firestore.collection('analytics').add({
        'userId': userId,
        'activity': activity,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error tracking user activity: $e');
    }
  }

  // Track property views
  Future<void> trackPropertyView(String propertyId, String userId) async {
    try {
      await _firestore.collection('analytics').add({
        'type': 'property_view',
        'propertyId': propertyId,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error tracking property view: $e');
    }
  }

  // Track booking events
  Future<void> trackBookingEvent(String bookingId, String event, String userId) async {
    try {
      await _firestore.collection('analytics').add({
        'type': 'booking_event',
        'bookingId': bookingId,
        'event': event,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error tracking booking event: $e');
    }
  }

  // Get analytics for landlord
  Future<Map<String, dynamic>> getLandlordAnalytics(String landlordId) async {
    try {
      // Get property views
      final viewsSnapshot = await _firestore
          .collection('analytics')
          .where('type', isEqualTo: 'property_view')
          .where('propertyId', whereIn: await _getPropertyIds(landlordId))
          .get();

      // Get booking events
      final bookingsSnapshot = await _firestore
          .collection('analytics')
          .where('type', isEqualTo: 'booking_event')
          .get();

      return {
        'totalViews': viewsSnapshot.docs.length,
        'totalBookings': bookingsSnapshot.docs.length,
        'recentActivity': viewsSnapshot.docs.length + bookingsSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting landlord analytics: $e');
      return {
        'totalViews': 0,
        'totalBookings': 0,
        'recentActivity': 0,
      };
    }
  }

  // Helper method to get property IDs for a landlord
  Future<List<String>> _getPropertyIds(String landlordId) async {
    try {
      final propertiesSnapshot = await _firestore
          .collection('properties')
          .where('landlordId', isEqualTo: landlordId)
          .get();

      return propertiesSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting property IDs: $e');
      return [];
    }
  }
} 