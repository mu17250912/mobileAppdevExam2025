import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MonetizationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Subscription Plans
  static const Map<String, Map<String, dynamic>> subscriptionPlans = {
    'seller_premium': {
      'name': 'Seller Premium',
      'price': 9.99,
      'billing_cycle': 'monthly',
      'features': [
        'Unlimited product listings',
        'Priority customer support',
        'Advanced analytics',
        'Featured product placement',
        'Reduced transaction fees',
      ],
    },
    'buyer_premium': {
      'name': 'Buyer Premium',
      'price': 4.99,
      'billing_cycle': 'monthly',
      'features': [
        'Free shipping on all orders',
        'Exclusive deals and discounts',
        'Priority customer support',
        'Early access to sales',
        'Double loyalty points',
      ],
    },
  };

  // Transaction Fees
  static const double platformFeePercentage = 0.15; // 15% platform fee
  static const double premiumSellerFeePercentage = 0.10; // 10% for premium sellers

  // Loyalty Points
  static const int pointsPerDollar = 1;
  static const int pointsPerReview = 50;
  static const int pointsPerReferral = 200;

  /// Process a purchase and update revenue tracking
  static Future<Map<String, dynamic>> processPurchase({
    required String productId,
    required String sellerId,
    required double amount,
    required String buyerId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Calculate fees
      final sellerDoc = await _firestore.collection('users').doc(sellerId).get();
      final isPremiumSeller = sellerDoc.data()?['isPremium'] ?? false;
      final feePercentage = isPremiumSeller ? premiumSellerFeePercentage : platformFeePercentage;
      final platformFee = amount * feePercentage;
      final sellerRevenue = amount - platformFee;

      // Create transaction record
      final transactionData = {
        'productId': productId,
        'sellerId': sellerId,
        'buyerId': buyerId,
        'amount': amount,
        'platformFee': platformFee,
        'sellerRevenue': sellerRevenue,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'completed',
      };

      final transactionRef = await _firestore.collection('transactions').add(transactionData);

      // Update seller revenue
      await _firestore.collection('users').doc(sellerId).update({
        'monthlyRevenue': FieldValue.increment(sellerRevenue),
        'totalSales': FieldValue.increment(1),
        'totalRevenue': FieldValue.increment(sellerRevenue),
      });

      // Update buyer stats
      await _firestore.collection('users').doc(buyerId).update({
        'totalSpent': FieldValue.increment(amount),
        'ordersPlaced': FieldValue.increment(1),
        'loyaltyPoints': FieldValue.increment((amount * pointsPerDollar).round()),
      });

      // Update product stats
      await _firestore.collection('products').doc(productId).update({
        'salesCount': FieldValue.increment(1),
        'totalRevenue': FieldValue.increment(amount),
      });

      return {
        'success': true,
        'transactionId': transactionRef.id,
        'platformFee': platformFee,
        'sellerRevenue': sellerRevenue,
        'loyaltyPointsEarned': (amount * pointsPerDollar).round(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Subscribe user to premium plan
  static Future<Map<String, dynamic>> subscribeToPremium({
    required String userId,
    required String planType,
  }) async {
    try {
      final plan = subscriptionPlans[planType];
      if (plan == null) throw Exception('Invalid plan type');

      // Create subscription record
      final subscriptionData = {
        'userId': userId,
        'planType': planType,
        'planName': plan['name'],
        'price': plan['price'],
        'billingCycle': plan['billing_cycle'],
        'startDate': FieldValue.serverTimestamp(),
        'status': 'active',
        'nextBillingDate': _getNextBillingDate(plan['billing_cycle']),
      };

      await _firestore.collection('subscriptions').add(subscriptionData);

      // Update user premium status
      await _firestore.collection('users').doc(userId).update({
        'isPremium': true,
        'premiumPlan': planType,
        'premiumStartDate': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'planName': plan['name'],
        'price': plan['price'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Cancel premium subscription
  static Future<Map<String, dynamic>> cancelSubscription({
    required String userId,
  }) async {
    try {
      // Find active subscription
      final subscriptionQuery = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      if (subscriptionQuery.docs.isNotEmpty) {
        await subscriptionQuery.docs.first.reference.update({
          'status': 'cancelled',
          'cancelledDate': FieldValue.serverTimestamp(),
        });
      }

      // Update user status
      await _firestore.collection('users').doc(userId).update({
        'isPremium': false,
        'premiumPlan': null,
      });

      return {
        'success': true,
        'message': 'Subscription cancelled successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Process withdrawal request
  static Future<Map<String, dynamic>> processWithdrawal({
    required String userId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      // Check if user has sufficient balance
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final currentBalance = userDoc.data()?['monthlyRevenue'] ?? 0.0;

      if (currentBalance < amount) {
        return {
          'success': false,
          'error': 'Insufficient balance',
        };
      }

      // Create withdrawal record
      final withdrawalData = {
        'userId': userId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'status': 'pending',
        'requestDate': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('withdrawals').add(withdrawalData);

      // Deduct from user balance
      await _firestore.collection('users').doc(userId).update({
        'monthlyRevenue': FieldValue.increment(-amount),
      });

      return {
        'success': true,
        'message': 'Withdrawal request submitted',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Award loyalty points
  static Future<Map<String, dynamic>> awardLoyaltyPoints({
    required String userId,
    required int points,
    required String reason,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'loyaltyPoints': FieldValue.increment(points),
      });

      // Log points transaction
      await _firestore.collection('loyalty_transactions').add({
        'userId': userId,
        'points': points,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'pointsAwarded': points,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Redeem loyalty points
  static Future<Map<String, dynamic>> redeemLoyaltyPoints({
    required String userId,
    required int points,
    required String reward,
  }) async {
    try {
      // Check if user has sufficient points
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final currentPoints = userDoc.data()?['loyaltyPoints'] ?? 0;

      if (currentPoints < points) {
        return {
          'success': false,
          'error': 'Insufficient loyalty points',
        };
      }

      // Deduct points
      await _firestore.collection('users').doc(userId).update({
        'loyaltyPoints': FieldValue.increment(-points),
      });

      // Log redemption
      await _firestore.collection('loyalty_redemptions').add({
        'userId': userId,
        'points': points,
        'reward': reward,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'reward': reward,
        'pointsRedeemed': points,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get revenue analytics for seller
  static Future<Map<String, dynamic>> getSellerAnalytics({
    required String sellerId,
    String? timeRange,
  }) async {
    try {
      final now = DateTime.now();
      DateTime startDate;

      switch (timeRange) {
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'year':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        default:
          startDate = DateTime(now.year, now.month - 1, now.day); // Default to last month
      }

      // Get transactions
      final transactionsQuery = await _firestore
          .collection('transactions')
          .where('sellerId', isEqualTo: sellerId)
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .get();

      double totalRevenue = 0;
      double totalFees = 0;
      int totalSales = 0;

      for (final doc in transactionsQuery.docs) {
        final data = doc.data();
        totalRevenue += data['sellerRevenue'] ?? 0;
        totalFees += data['platformFee'] ?? 0;
        totalSales++;
      }

      return {
        'success': true,
        'totalRevenue': totalRevenue,
        'totalFees': totalFees,
        'totalSales': totalSales,
        'netRevenue': totalRevenue - totalFees,
        'timeRange': timeRange ?? 'month',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get buyer analytics
  static Future<Map<String, dynamic>> getBuyerAnalytics({
    required String buyerId,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(buyerId).get();
      final userData = userDoc.data() ?? {};

      // Get recent transactions
      final transactionsQuery = await _firestore
          .collection('transactions')
          .where('buyerId', isEqualTo: buyerId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final recentTransactions = transactionsQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'amount': data['amount'],
          'timestamp': data['timestamp'],
          'productId': data['productId'],
        };
      }).toList();

      return {
        'success': true,
        'totalSpent': userData['totalSpent'] ?? 0.0,
        'ordersPlaced': userData['ordersPlaced'] ?? 0,
        'loyaltyPoints': userData['loyaltyPoints'] ?? 0,
        'isPremium': userData['isPremium'] ?? false,
        'recentTransactions': recentTransactions,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Calculate next billing date
  static DateTime _getNextBillingDate(String billingCycle) {
    final now = DateTime.now();
    switch (billingCycle) {
      case 'monthly':
        return DateTime(now.year, now.month + 1, now.day);
      case 'yearly':
        return DateTime(now.year + 1, now.month, now.day);
      default:
        return DateTime(now.year, now.month + 1, now.day);
    }
  }

  /// Get available rewards for loyalty points
  static List<Map<String, dynamic>> getAvailableRewards() {
    return [
      {
        'id': 'free_shipping',
        'name': 'Free Shipping',
        'points': 500,
        'description': 'Free shipping on next order',
        'icon': 'local_shipping',
      },
      {
        'id': 'discount_10',
        'name': '10% Discount',
        'points': 1000,
        'description': '10% off on any purchase',
        'icon': 'discount',
      },
      {
        'id': 'premium_trial',
        'name': 'Premium Trial',
        'points': 2000,
        'description': '1 month premium membership',
        'icon': 'star',
      },
      {
        'id': 'cash_back',
        'name': 'Cash Back',
        'points': 1000,
        'description': '\$10 cash back',
        'icon': 'attach_money',
      },
    ];
  }

  /// Get subscription plans
  static Map<String, Map<String, dynamic>> getSubscriptionPlans() {
    return subscriptionPlans;
  }

  /// Check if user can afford a reward
  static Future<bool> canAffordReward({
    required String userId,
    required int requiredPoints,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final currentPoints = userDoc.data()?['loyaltyPoints'] ?? 0;
      return currentPoints >= requiredPoints;
    } catch (e) {
      return false;
    }
  }
} 