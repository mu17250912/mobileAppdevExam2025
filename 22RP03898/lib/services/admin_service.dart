import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../models/ride_model.dart';
import '../models/booking_model.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  // Analytics Data
  Map<String, dynamic> _analyticsData = {};
  bool _isAnalyticsLoaded = false;

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        return false;
      }

      final userData = userDoc.data()!;
      return userData['userType'] == 'admin';
    } catch (e) {
      _logger.e('Error checking admin status: $e');
      return false;
    }
  }

  /// Load comprehensive analytics data
  Future<Map<String, dynamic>> loadAnalytics() async {
    if (_isAnalyticsLoaded) {
      return _analyticsData;
    }

    try {
      _logger.i('Loading admin analytics...');

      // Load all collections
      final usersSnapshot = await _firestore.collection('users').get();
      final ridesSnapshot = await _firestore.collection('rides').get();
      final bookingsSnapshot = await _firestore.collection('bookings').get();

      // Calculate user statistics
      final totalUsers = usersSnapshot.docs.length;
      final drivers = usersSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['userType'] == 'driver';
      }).length;
      final passengers = usersSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['userType'] == 'passenger';
      }).length;
      final bannedUsers = usersSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['isBanned'] == true;
      }).length;

      // Calculate ride statistics
      final totalRides = ridesSnapshot.docs.length;
      final activeRides = ridesSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['status'] == 'scheduled';
      }).length;
      final completedRides = ridesSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['status'] == 'completed';
      }).length;
      final cancelledRides = ridesSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['status'] == 'cancelled';
      }).length;

      // Calculate booking statistics
      final totalBookings = bookingsSnapshot.docs.length;
      final pendingBookings = bookingsSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['status'] == 'pending';
      }).length;
      final confirmedBookings = bookingsSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['status'] == 'confirmed';
      }).length;
      final completedBookings = bookingsSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['status'] == 'completed';
      }).length;

      // Calculate revenue
      double totalRevenue = 0;
      double monthlyRevenue = 0;
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      for (var doc in bookingsSnapshot.docs) {
        final booking = doc.data();
        if (booking['status'] == 'completed' &&
            booking['paymentStatus'] == 'paid') {
          final amount = (booking['totalAmount'] ?? 0).toDouble();
          totalRevenue += amount;

          final bookingTime = (booking['bookingTime'] as Timestamp).toDate();
          if (bookingTime.isAfter(monthStart)) {
            monthlyRevenue += amount;
          }
        }
      }

      // Calculate growth rates
      final lastMonthUsers = await _getLastMonthUsers();
      final userGrowthRate = totalUsers > 0
          ? ((totalUsers - lastMonthUsers) / lastMonthUsers * 100)
          : 0;

      _analyticsData = {
        'users': {
          'total': totalUsers,
          'drivers': drivers,
          'passengers': passengers,
          'banned': bannedUsers,
          'growthRate': userGrowthRate,
        },
        'rides': {
          'total': totalRides,
          'active': activeRides,
          'completed': completedRides,
          'cancelled': cancelledRides,
        },
        'bookings': {
          'total': totalBookings,
          'pending': pendingBookings,
          'confirmed': confirmedBookings,
          'completed': completedBookings,
        },
        'revenue': {
          'total': totalRevenue,
          'monthly': monthlyRevenue,
        },
        'system': {
          'lastUpdated': DateTime.now(),
        },
      };

      _isAnalyticsLoaded = true;
      _logger.i('Analytics loaded successfully');
      return _analyticsData;
    } catch (e) {
      _logger.e('Error loading analytics: $e');
      return {};
    }
  }

  /// Get users count from last month
  Future<int> _getLastMonthUsers() async {
    try {
      final lastMonth = DateTime.now().subtract(const Duration(days: 30));
      final snapshot = await _firestore
          .collection('users')
          .where('createdAt', isLessThan: Timestamp.fromDate(lastMonth))
          .get();
      return snapshot.docs.length;
    } catch (e) {
      _logger.e('Error getting last month users: $e');
      return 0;
    }
  }

  /// Get all users with pagination
  Future<List<UserModel>> getUsers(
      {int limit = 20, DocumentSnapshot? lastDocument}) async {
    try {
      Query query =
          _firestore.collection('users').orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);
      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) =>
              UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      _logger.e('Error getting users: $e');
      return [];
    }
  }

  /// Get all rides with pagination
  Future<List<RideModel>> getRides(
      {int limit = 20, DocumentSnapshot? lastDocument}) async {
    try {
      Query query =
          _firestore.collection('rides').orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);
      final snapshot = await query.get();

      return snapshot.docs.map((doc) => RideModel.fromDoc(doc)).toList();
    } catch (e) {
      _logger.e('Error getting rides: $e');
      return [];
    }
  }

  /// Get all bookings with pagination
  Future<List<BookingModel>> getBookings(
      {int limit = 20, DocumentSnapshot? lastDocument}) async {
    try {
      Query query = _firestore
          .collection('bookings')
          .orderBy('bookingTime', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);
      final snapshot = await query.get();

      return snapshot.docs.map((doc) => BookingModel.fromDoc(doc)).toList();
    } catch (e) {
      _logger.e('Error getting bookings: $e');
      return [];
    }
  }

  /// Ban/Unban a user
  Future<bool> toggleUserBan(String userId, bool ban) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isBanned': ban,
        'status': ban ? 'suspended' : 'active',
        'updatedAt': Timestamp.now(),
      });

      _logger.i('User ${ban ? 'banned' : 'unbanned'}: $userId');
      return true;
    } catch (e) {
      _logger.e('Error toggling user ban: $e');
      return false;
    }
  }

  /// Delete a user
  Future<bool> deleteUser(String userId) async {
    try {
      // Check if user has active bookings
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('passengerId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'confirmed']).get();

      if (bookingsSnapshot.docs.isNotEmpty) {
        throw Exception('Cannot delete user with active bookings');
      }

      // Delete user's rides if they are a driver
      final ridesSnapshot = await _firestore
          .collection('rides')
          .where('driverId', isEqualTo: userId)
          .where('status', whereIn: ['scheduled', 'inProgress']).get();

      if (ridesSnapshot.docs.isNotEmpty) {
        throw Exception('Cannot delete driver with active rides');
      }

      // Delete user document
      await _firestore.collection('users').doc(userId).delete();

      _logger.i('User deleted: $userId');
      return true;
    } catch (e) {
      _logger.e('Error deleting user: $e');
      return false;
    }
  }

  /// Cancel a ride
  Future<bool> cancelRide(String rideId) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
      });

      // Notify all passengers
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('rideId', isEqualTo: rideId)
          .where('status', whereIn: ['pending', 'confirmed']).get();

      for (var doc in bookingsSnapshot.docs) {
        await _firestore.collection('bookings').doc(doc.id).update({
          'status': 'cancelled',
          'cancellationReason': 'Ride cancelled by admin',
          'cancellationTime': Timestamp.now(),
        });
      }

      _logger.i('Ride cancelled: $rideId');
      return true;
    } catch (e) {
      _logger.e('Error cancelling ride: $e');
      return false;
    }
  }

  /// Generate user report
  Future<Map<String, dynamic>> generateUserReport() async {
    try {
      final analytics = await loadAnalytics();
      final users = await getUsers(limit: 1000);

      // Calculate user demographics
      final userAges = <String, int>{};
      final userLocations = <String, int>{};
      final userTypes = <String, int>{};

      for (var user in users) {
        // Age groups (if age data is available)
        final age = user.preferences['age'] ?? 0;
        if (age < 25) {
          userAges['18-24'] = (userAges['18-24'] ?? 0) + 1;
        } else if (age < 35) {
          userAges['25-34'] = (userAges['25-34'] ?? 0) + 1;
        } else if (age < 45) {
          userAges['35-44'] = (userAges['35-44'] ?? 0) + 1;
        } else {
          userAges['45+'] = (userAges['45+'] ?? 0) + 1;
        }

        // User types
        userTypes[user.userType.name] =
            (userTypes[user.userType.name] ?? 0) + 1;
      }

      return {
        'summary': analytics['users'],
        'demographics': {
          'ageGroups': userAges,
          'userTypes': userTypes,
          'locations': userLocations,
        },
        'generatedAt': DateTime.now(),
      };
    } catch (e) {
      _logger.e('Error generating user report: $e');
      return {};
    }
  }

  /// Generate revenue report
  Future<Map<String, dynamic>> generateRevenueReport() async {
    try {
      final analytics = await loadAnalytics();
      final bookings = await getBookings(limit: 1000);

      // Calculate revenue by month
      final monthlyRevenue = <String, double>{};
      final paymentMethods = <String, int>{};

      for (var booking in bookings) {
        if (booking.status == BookingStatus.completed &&
            booking.paymentStatus == PaymentStatus.paid) {
          // Monthly revenue
          final month =
              '${booking.bookingTime.year}-${booking.bookingTime.month.toString().padLeft(2, '0')}';
          monthlyRevenue[month] =
              (monthlyRevenue[month] ?? 0) + booking.totalAmount;

          // Payment methods
          if (booking.paymentMethod != null) {
            final method = booking.paymentMethod!.name;
            paymentMethods[method] = (paymentMethods[method] ?? 0) + 1;
          }
        }
      }

      return {
        'summary': analytics['revenue'],
        'monthlyBreakdown': monthlyRevenue,
        'paymentMethods': paymentMethods,
        'generatedAt': DateTime.now(),
      };
    } catch (e) {
      _logger.e('Error generating revenue report: $e');
      return {};
    }
  }

  /// Generate ride performance report
  Future<Map<String, dynamic>> generateRideReport() async {
    try {
      final analytics = await loadAnalytics();
      final rides = await getRides(limit: 1000);

      // Calculate ride performance metrics
      final vehicleTypeStats = <String, Map<String, dynamic>>{};
      final routeStats = <String, int>{};

      for (var ride in rides) {
        // Vehicle type statistics
        final vehicleType = ride.vehicleType.name;
        if (!vehicleTypeStats.containsKey(vehicleType)) {
          vehicleTypeStats[vehicleType] = {
            'total': 0,
            'completed': 0,
            'cancelled': 0,
            'revenue': 0.0,
          };
        }

        vehicleTypeStats[vehicleType]!['total'] =
            (vehicleTypeStats[vehicleType]!['total'] as int) + 1;

        if (ride.status == RideStatus.completed) {
          vehicleTypeStats[vehicleType]!['completed'] =
              (vehicleTypeStats[vehicleType]!['completed'] as int) + 1;
        } else if (ride.status == RideStatus.cancelled) {
          vehicleTypeStats[vehicleType]!['cancelled'] =
              (vehicleTypeStats[vehicleType]!['cancelled'] as int) + 1;
        }

        // Route statistics
        final route = '${ride.origin.name} → ${ride.destination.name}';
        routeStats[route] = (routeStats[route] ?? 0) + 1;
      }

      return {
        'summary': analytics['rides'],
        'vehicleTypeStats': vehicleTypeStats,
        'popularRoutes': routeStats,
        'generatedAt': DateTime.now(),
      };
    } catch (e) {
      _logger.e('Error generating ride report: $e');
      return {};
    }
  }

  /// Get system health metrics
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final now = DateTime.now();
      final last24Hours = now.subtract(const Duration(hours: 24));

      // Check recent activity
      final recentBookings = await _firestore
          .collection('bookings')
          .where('bookingTime', isGreaterThan: Timestamp.fromDate(last24Hours))
          .get();

      final recentRides = await _firestore
          .collection('rides')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(last24Hours))
          .get();

      final recentUsers = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(last24Hours))
          .get();

      // Check for errors (if error logging is implemented)
      final errorCount = 0; // This would come from error logging service

      return {
        'activity': {
          'bookings24h': recentBookings.docs.length,
          'rides24h': recentRides.docs.length,
          'newUsers24h': recentUsers.docs.length,
        },
        'errors': {
          'count24h': errorCount,
          'status': errorCount < 10 ? 'healthy' : 'warning',
        },
        'system': {
          'lastChecked': now,
          'status': 'operational',
        },
      };
    } catch (e) {
      _logger.e('Error getting system health: $e');
      return {};
    }
  }

  /// Update system settings
  Future<bool> updateSystemSettings(Map<String, dynamic> settings) async {
    try {
      await _firestore.collection('system').doc('settings').set({
        ...settings,
        'updatedAt': Timestamp.now(),
        'updatedBy': _auth.currentUser?.uid,
      });

      _logger.i('System settings updated');
      return true;
    } catch (e) {
      _logger.e('Error updating system settings: $e');
      return false;
    }
  }

  /// Get system settings
  Future<Map<String, dynamic>> getSystemSettings() async {
    try {
      final doc = await _firestore.collection('system').doc('settings').get();
      if (doc.exists) {
        return doc.data()!;
      }
      return {};
    } catch (e) {
      _logger.e('Error getting system settings: $e');
      return {};
    }
  }

  /// Clear analytics cache
  void clearAnalyticsCache() {
    _analyticsData = {};
    _isAnalyticsLoaded = false;
    _logger.i('Analytics cache cleared');
  }

  /// Send notification to all users
  Future<bool> sendNotificationToAllUsers(String title, String message) async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      int sentCount = 0;

      for (var doc in usersSnapshot.docs) {
        try {
          // This would integrate with your notification service
          // await NotificationService().sendNotificationToUser(
          //   userId: doc.id,
          //   title: title,
          //   body: message,
          // );
          sentCount++;
        } catch (e) {
          _logger.w('Failed to send notification to user ${doc.id}: $e');
        }
      }

      // Save notification record
      await _firestore.collection('notifications').add({
        'title': title,
        'message': message,
        'targetType': 'all',
        'sentCount': sentCount,
        'status': 'sent',
        'sentAt': Timestamp.now(),
        'sentBy': _auth.currentUser?.uid,
      });

      _logger.i('Notification sent to $sentCount users');
      return true;
    } catch (e) {
      _logger.e('Error sending notification to all users: $e');
      return false;
    }
  }

  /// Send notification to specific user types
  Future<bool> sendNotificationToUserType(
      String title, String message, String userType) async {
    try {
      final usersSnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: userType)
          .get();

      int sentCount = 0;

      for (var doc in usersSnapshot.docs) {
        try {
          // This would integrate with your notification service
          // await NotificationService().sendNotificationToUser(
          //   userId: doc.id,
          //   title: title,
          //   body: message,
          // );
          sentCount++;
        } catch (e) {
          _logger.w('Failed to send notification to user ${doc.id}: $e');
        }
      }

      // Save notification record
      await _firestore.collection('notifications').add({
        'title': title,
        'message': message,
        'targetType': userType,
        'sentCount': sentCount,
        'status': 'sent',
        'sentAt': Timestamp.now(),
        'sentBy': _auth.currentUser?.uid,
      });

      _logger.i('Notification sent to $sentCount $userType users');
      return true;
    } catch (e) {
      _logger.e('Error sending notification to $userType users: $e');
      return false;
    }
  }

  /// Get notification history
  Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .orderBy('sentAt', descending: true)
          .limit(100)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      _logger.e('Error getting notification history: $e');
      return [];
    }
  }

  /// Get notification templates
  Future<List<Map<String, dynamic>>> getNotificationTemplates() async {
    try {
      final snapshot = await _firestore
          .collection('notification_templates')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      _logger.e('Error getting notification templates: $e');
      return [];
    }
  }

  /// Create notification template
  Future<bool> createNotificationTemplate(
      String title, String message, String category) async {
    try {
      await _firestore.collection('notification_templates').add({
        'title': title,
        'message': message,
        'category': category,
        'createdAt': Timestamp.now(),
        'createdBy': _auth.currentUser?.uid,
      });

      _logger.i('Notification template created: $title');
      return true;
    } catch (e) {
      _logger.e('Error creating notification template: $e');
      return false;
    }
  }

  /// Get refund requests
  Future<List<Map<String, dynamic>>> getRefundRequests() async {
    try {
      final snapshot = await _firestore
          .collection('refund_requests')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      _logger.e('Error getting refund requests: $e');
      return [];
    }
  }

  /// Approve refund request
  Future<bool> approveRefund(String refundId) async {
    try {
      await _firestore.collection('refund_requests').doc(refundId).update({
        'status': 'approved',
        'approvedAt': Timestamp.now(),
        'approvedBy': _auth.currentUser?.uid,
      });

      _logger.i('Refund approved: $refundId');
      return true;
    } catch (e) {
      _logger.e('Error approving refund: $e');
      return false;
    }
  }

  /// Reject refund request
  Future<bool> rejectRefund(String refundId, String reason) async {
    try {
      await _firestore.collection('refund_requests').doc(refundId).update({
        'status': 'rejected',
        'rejectedAt': Timestamp.now(),
        'rejectedBy': _auth.currentUser?.uid,
        'rejectionReason': reason,
      });

      _logger.i('Refund rejected: $refundId');
      return true;
    } catch (e) {
      _logger.e('Error rejecting refund: $e');
      return false;
    }
  }

  /// Get transaction history
  Future<List<Map<String, dynamic>>> getTransactionHistory() async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      _logger.e('Error getting transaction history: $e');
      return [];
    }
  }

  /// Extend user premium subscription
  Future<bool> extendPremiumSubscription(String userId, int days) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      final currentExpiry = userData['premiumExpiry'] as Timestamp?;
      final newExpiry = currentExpiry != null
          ? currentExpiry.toDate().add(Duration(days: days))
          : DateTime.now().add(Duration(days: days));

      await _firestore.collection('users').doc(userId).update({
        'isPremium': true,
        'premiumExpiry': Timestamp.fromDate(newExpiry),
        'updatedAt': Timestamp.now(),
      });

      _logger.i('Premium subscription extended for user $userId by $days days');
      return true;
    } catch (e) {
      _logger.e('Error extending premium subscription: $e');
      return false;
    }
  }

  /// Cancel user premium subscription
  Future<bool> cancelPremiumSubscription(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isPremium': false,
        'premiumExpiry': null,
        'updatedAt': Timestamp.now(),
      });

      _logger.i('Premium subscription cancelled for user $userId');
      return true;
    } catch (e) {
      _logger.e('Error cancelling premium subscription: $e');
      return false;
    }
  }
}
