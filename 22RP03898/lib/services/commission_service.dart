/// Commission Service for SafeRide
///
/// Handles commission-based monetization where the platform takes a percentage
/// of each booking transaction. This service manages revenue sharing between
/// drivers and the platform.
///
/// Features:
/// - Dynamic commission rates based on driver tier
/// - Platform fee calculation
/// - Revenue sharing distribution
/// - Commission analytics and reporting
/// - Driver earnings tracking
/// - Payment processing for driver payouts
///
/// Commission Structure:
/// - Free drivers: 15% platform fee
/// - Basic subscribers: 12% platform fee
/// - Premium drivers: 10% platform fee
/// - Driver Premium: 8% platform fee
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class CommissionTransaction {
  final String id;
  final String bookingId;
  final String driverId;
  final String passengerId;
  final double bookingAmount;
  final double platformFee;
  final double driverEarnings;
  final String currency;
  final DateTime createdAt;
  final String status;
  final Map<String, dynamic> metadata;

  CommissionTransaction({
    required this.id,
    required this.bookingId,
    required this.driverId,
    required this.passengerId,
    required this.bookingAmount,
    required this.platformFee,
    required this.driverEarnings,
    required this.currency,
    required this.createdAt,
    required this.status,
    required this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'driverId': driverId,
      'passengerId': passengerId,
      'bookingAmount': bookingAmount,
      'platformFee': platformFee,
      'driverEarnings': driverEarnings,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'metadata': metadata,
    };
  }

  factory CommissionTransaction.fromMap(Map<String, dynamic> map) {
    return CommissionTransaction(
      id: map['id'] ?? '',
      bookingId: map['bookingId'] ?? '',
      driverId: map['driverId'] ?? '',
      passengerId: map['passengerId'] ?? '',
      bookingAmount: map['bookingAmount']?.toDouble() ?? 0.0,
      platformFee: map['platformFee']?.toDouble() ?? 0.0,
      driverEarnings: map['driverEarnings']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'FRW',
      createdAt:
          DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      status: map['status'] ?? 'pending',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}

class DriverEarnings {
  final String driverId;
  final double totalEarnings;
  final double pendingEarnings;
  final double paidEarnings;
  final int totalRides;
  final int completedRides;
  final double averageEarningsPerRide;
  final DateTime lastPayoutDate;
  final String currency;

  DriverEarnings({
    required this.driverId,
    required this.totalEarnings,
    required this.pendingEarnings,
    required this.paidEarnings,
    required this.totalRides,
    required this.completedRides,
    required this.averageEarningsPerRide,
    required this.lastPayoutDate,
    required this.currency,
  });

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'totalEarnings': totalEarnings,
      'pendingEarnings': pendingEarnings,
      'paidEarnings': paidEarnings,
      'totalRides': totalRides,
      'completedRides': completedRides,
      'averageEarningsPerRide': averageEarningsPerRide,
      'lastPayoutDate': lastPayoutDate.toIso8601String(),
      'currency': currency,
    };
  }

  factory DriverEarnings.fromMap(Map<String, dynamic> map) {
    return DriverEarnings(
      driverId: map['driverId'] ?? '',
      totalEarnings: map['totalEarnings']?.toDouble() ?? 0.0,
      pendingEarnings: map['pendingEarnings']?.toDouble() ?? 0.0,
      paidEarnings: map['paidEarnings']?.toDouble() ?? 0.0,
      totalRides: map['totalRides'] ?? 0,
      completedRides: map['completedRides'] ?? 0,
      averageEarningsPerRide: map['averageEarningsPerRide']?.toDouble() ?? 0.0,
      lastPayoutDate: DateTime.parse(
          map['lastPayoutDate'] ?? DateTime.now().toIso8601String()),
      currency: map['currency'] ?? 'FRW',
    );
  }
}

class CommissionService {
  static final CommissionService _instance = CommissionService._internal();
  factory CommissionService() => _instance;
  CommissionService._internal();

  final Logger _logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Commission rates by driver tier
  static const Map<String, double> commissionRates = {
    'free': 0.15, // 15% platform fee
    'basic': 0.12, // 12% platform fee
    'premium': 0.10, // 10% platform fee
    'driverPremium': 0.08, // 8% platform fee
  };

  // Minimum payout threshold
  static const double minimumPayoutThreshold = 5000.0; // 5,000 FRW

  /// Calculate commission for a booking
  Future<CommissionTransaction> calculateCommission({
    required String bookingId,
    required String driverId,
    required String passengerId,
    required double bookingAmount,
    required String currency,
  }) async {
    try {
      // Get driver's subscription tier
      final driverDoc =
          await _firestore.collection('users').doc(driverId).get();
      final driverData = driverDoc.data() ?? {};
      final driverTier = driverData['subscriptionTier'] ?? 'free';

      // Calculate commission
      final commissionRate =
          commissionRates[driverTier] ?? commissionRates['free']!;
      final platformFee = bookingAmount * commissionRate;
      final driverEarnings = bookingAmount - platformFee;

      final transaction = CommissionTransaction(
        id: 'comm_${DateTime.now().millisecondsSinceEpoch}',
        bookingId: bookingId,
        driverId: driverId,
        passengerId: passengerId,
        bookingAmount: bookingAmount,
        platformFee: platformFee,
        driverEarnings: driverEarnings,
        currency: currency,
        createdAt: DateTime.now(),
        status: 'pending',
        metadata: {
          'driverTier': driverTier,
          'commissionRate': commissionRate,
          'bookingCompleted': false,
        },
      );

      // Save commission transaction
      await _firestore
          .collection('commission_transactions')
          .add(transaction.toMap());

      _logger.i(
          'Commission calculated for booking $bookingId: Platform fee ${platformFee.toStringAsFixed(0)} $currency');

      return transaction;
    } catch (e) {
      _logger.e('Error calculating commission: $e');
      rethrow;
    }
  }

  /// Mark booking as completed and release driver earnings
  Future<void> completeBookingCommission(String bookingId) async {
    try {
      final commissionDoc = await _firestore
          .collection('commission_transactions')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (commissionDoc.docs.isEmpty) {
        _logger.w('No commission transaction found for booking $bookingId');
        return;
      }

      final doc = commissionDoc.docs.first;
      final transaction = CommissionTransaction.fromMap({
        ...doc.data(),
        'id': doc.id,
      });

      // Update commission transaction status
      await _firestore
          .collection('commission_transactions')
          .doc(doc.id)
          .update({
        'status': 'completed',
        'metadata.bookingCompleted': true,
        'completedAt': DateTime.now().toIso8601String(),
      });

      // Update driver earnings
      await _updateDriverEarnings(
          transaction.driverId, transaction.driverEarnings);

      _logger.i('Commission completed for booking $bookingId');
    } catch (e) {
      _logger.e('Error completing commission: $e');
      rethrow;
    }
  }

  /// Get driver earnings summary
  Future<DriverEarnings> getDriverEarnings(String driverId) async {
    try {
      final earningsDoc =
          await _firestore.collection('driver_earnings').doc(driverId).get();

      if (earningsDoc.exists) {
        return DriverEarnings.fromMap({
          ...earningsDoc.data()!,
          'driverId': driverId,
        });
      }

      // Create new earnings record if doesn't exist
      final defaultEarnings = DriverEarnings(
        driverId: driverId,
        totalEarnings: 0.0,
        pendingEarnings: 0.0,
        paidEarnings: 0.0,
        totalRides: 0,
        completedRides: 0,
        averageEarningsPerRide: 0.0,
        lastPayoutDate: DateTime.now(),
        currency: 'FRW',
      );

      await _firestore
          .collection('driver_earnings')
          .doc(driverId)
          .set(defaultEarnings.toMap());

      return defaultEarnings;
    } catch (e) {
      _logger.e('Error getting driver earnings: $e');
      rethrow;
    }
  }

  /// Request payout for driver
  Future<Map<String, dynamic>> requestPayout({
    required String driverId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      final earnings = await getDriverEarnings(driverId);

      if (amount > earnings.pendingEarnings) {
        throw Exception('Insufficient pending earnings');
      }

      if (amount < minimumPayoutThreshold) {
        throw Exception(
            'Minimum payout amount is ${minimumPayoutThreshold.toStringAsFixed(0)} FRW');
      }

      // Create payout request
      final payoutId = 'payout_${DateTime.now().millisecondsSinceEpoch}';
      await _firestore.collection('payout_requests').add({
        'id': payoutId,
        'driverId': driverId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'status': 'pending',
        'requestedAt': DateTime.now().toIso8601String(),
        'currency': 'FRW',
      });

      // Update driver earnings
      await _firestore.collection('driver_earnings').doc(driverId).update({
        'pendingEarnings': earnings.pendingEarnings - amount,
        'paidEarnings': earnings.paidEarnings + amount,
        'lastPayoutDate': DateTime.now().toIso8601String(),
      });

      _logger.i(
          'Payout request created for driver $driverId: ${amount.toStringAsFixed(0)} FRW');

      return {
        'success': true,
        'payoutId': payoutId,
        'amount': amount,
        'status': 'pending',
      };
    } catch (e) {
      _logger.e('Error requesting payout: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get platform revenue analytics
  Future<Map<String, dynamic>> getPlatformRevenueAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final snapshot = await _firestore
          .collection('commission_transactions')
          .where('createdAt', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('createdAt', isLessThanOrEqualTo: end.toIso8601String())
          .get();

      double totalRevenue = 0.0;
      double totalBookings = 0.0;
      Map<String, double> revenueByTier = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final platformFee = (data['platformFee'] ?? 0).toDouble();
        final bookingAmount = (data['bookingAmount'] ?? 0).toDouble();
        final driverTier = data['metadata']?['driverTier'] ?? 'free';

        totalRevenue += platformFee;
        totalBookings += bookingAmount;
        revenueByTier[driverTier] =
            (revenueByTier[driverTier] ?? 0) + platformFee;
      }

      return {
        'totalRevenue': totalRevenue,
        'totalBookings': totalBookings,
        'averageCommissionRate':
            totalBookings > 0 ? (totalRevenue / totalBookings) : 0.0,
        'revenueByTier': revenueByTier,
        'period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      };
    } catch (e) {
      _logger.e('Error getting revenue analytics: $e');
      return {};
    }
  }

  /// Update driver earnings when commission is completed
  Future<void> _updateDriverEarnings(String driverId, double earnings) async {
    try {
      final earningsRef =
          _firestore.collection('driver_earnings').doc(driverId);

      await _firestore.runTransaction((transaction) async {
        final earningsDoc = await transaction.get(earningsRef);

        if (earningsDoc.exists) {
          final currentData = earningsDoc.data()!;
          final currentPending =
              (currentData['pendingEarnings'] ?? 0).toDouble();
          final currentTotal = (currentData['totalEarnings'] ?? 0).toDouble();
          final currentCompleted = (currentData['completedRides'] ?? 0) + 1;

          transaction.update(earningsRef, {
            'pendingEarnings': currentPending + earnings,
            'totalEarnings': currentTotal + earnings,
            'completedRides': currentCompleted,
            'averageEarningsPerRide':
                (currentTotal + earnings) / currentCompleted,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        } else {
          transaction.set(earningsRef, {
            'driverId': driverId,
            'pendingEarnings': earnings,
            'totalEarnings': earnings,
            'paidEarnings': 0.0,
            'totalRides': 0,
            'completedRides': 1,
            'averageEarningsPerRide': earnings,
            'lastPayoutDate': DateTime.now().toIso8601String(),
            'currency': 'FRW',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      });
    } catch (e) {
      _logger.e('Error updating driver earnings: $e');
      rethrow;
    }
  }
}
