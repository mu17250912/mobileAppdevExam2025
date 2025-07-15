/// Payment Service for SafeRide
///
/// Handles all payment-related operations including subscription management,
/// payment processing, and integration with payment gateways. This service
/// manages the monetization aspects of the SafeRide platform.
///
/// Features:
/// - Premium subscription management
/// - Payment gateway integration
/// - Payment processing and verification
/// - Refund handling
/// - Payment analytics and reporting
/// - Multi-currency support (FRW, USD)
///
/// TODO: Future Enhancements:
/// - Integration with MTN Mobile Money
/// - Integration with Airtel Money
/// - Integration with M-Pesa
/// - Credit card payment support
/// - Automated billing and invoicing
/// - Payment dispute resolution
/// - Advanced payment analytics
/// - Subscription management dashboard
/// - Payment security and fraud detection
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
}

enum PaymentMethod {
  mtnMobileMoney,
  airtelMoney,
  mpesa,
  card,
  bankTransfer,
}

class PaymentTransaction {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final PaymentMethod paymentMethod;
  final String description;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic> metadata;
  final String? errorMessage;
  final String? transactionId;

  PaymentTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.description,
    required this.status,
    required this.createdAt,
    this.completedAt,
    required this.metadata,
    this.errorMessage,
    this.transactionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod.name,
      'description': description,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'metadata': metadata,
      'errorMessage': errorMessage,
      'transactionId': transactionId,
    };
  }

  factory PaymentTransaction.fromMap(Map<String, dynamic> map) {
    return PaymentTransaction(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'FRW',
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.mtnMobileMoney,
      ),
      description: map['description'] ?? '',
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      createdAt:
          DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      errorMessage: map['errorMessage'],
      transactionId: map['transactionId'],
    );
  }
}

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final Logger _logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;
  bool _isTestMode = true;

  /// Getter for initialization status
  bool get isInitialized => _isInitialized;

  /// Getter for test mode status
  bool get isTestMode => _isTestMode;

  /// Payment methods
  static const List<String> supportedPaymentMethods = [
    'mtn_mobile_money',
    'airtel_money',
    'mpesa',
    'card',
    'bank_transfer',
  ];

  /// Premium subscription plans in FRW and USD
  static const Map<String, Map<String, dynamic>> subscriptionPlans = {
    'basic': {
      'name': 'Basic',
      'price': 5000.0, // 5,000 FRW
      'currency': 'FRW',
      'price_usd': 5.0, // $5 USD
      'features': ['Unlimited bookings', 'Basic support'],
    },
    'premium': {
      'name': 'Premium',
      'price': 10000.0, // 10,000 FRW
      'currency': 'FRW',
      'price_usd': 10.0, // $10 USD
      'features': [
        'Unlimited bookings',
        'Priority booking',
        'Advanced analytics',
        'Premium support',
        'No ads',
      ],
    },
    'driver_premium': {
      'name': 'Driver Premium',
      'price': 15000.0, // 15,000 FRW
      'currency': 'FRW',
      'price_usd': 15.0, // $15 USD
      'features': [
        'Featured listings',
        'Higher commission rates',
        'Advanced driver analytics',
        'Priority support',
        'No ads',
      ],
    },
  };

  /// Initialize the payment service
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      // TODO: Initialize payment gateway connections
      // - MTN Mobile Money API
      // - Airtel Money API
      // - M-Pesa API
      // - Stripe/PayPal for international payments

      _logger.i('Payment service initialized successfully');
      _isInitialized = true;
    } catch (e) {
      _logger.e('Failed to initialize payment service: $e');
      _isInitialized = false;
    }
  }

  /// Process a payment
  Future<Map<String, dynamic>> processPayment({
    required String userId,
    required double amount,
    required String currency,
    required String paymentMethod,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _logger.i('Processing payment: $amount $currency via $paymentMethod');

      // Create transaction record
      final transactionId = 'txn_${DateTime.now().millisecondsSinceEpoch}';
      final paymentTransaction = PaymentTransaction(
        id: transactionId,
        userId: userId,
        amount: amount,
        currency: currency,
        paymentMethod: _getPaymentMethodFromString(paymentMethod),
        description: description,
        status: PaymentStatus.processing,
        createdAt: DateTime.now(),
        metadata: metadata ?? {},
      );

      // Save to Firestore
      await _saveTransaction(paymentTransaction);

      // TODO: Implement actual payment gateway integration
      // This is a mock implementation
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      // Simulate payment success/failure
      final isSuccess = _isTestMode || _simulatePaymentSuccess(paymentMethod);

      if (isSuccess) {
        // Update transaction status
        final updatedTransaction = PaymentTransaction(
          id: transactionId,
          userId: userId,
          amount: amount,
          currency: currency,
          paymentMethod: _getPaymentMethodFromString(paymentMethod),
          description: description,
          status: PaymentStatus.completed,
          createdAt: paymentTransaction.createdAt,
          completedAt: DateTime.now(),
          metadata: metadata ?? {},
          transactionId: transactionId,
        );

        await _updateTransaction(updatedTransaction);

        final result = {
          'success': true,
          'transactionId': transactionId,
          'amount': amount,
          'currency': currency,
          'paymentMethod': paymentMethod,
          'timestamp': DateTime.now().toIso8601String(),
          'status': 'completed',
        };

        _logger.i('Payment processed successfully: $transactionId');
        return result;
      } else {
        // Update transaction status to failed
        final failedTransaction = PaymentTransaction(
          id: transactionId,
          userId: userId,
          amount: amount,
          currency: currency,
          paymentMethod: _getPaymentMethodFromString(paymentMethod),
          description: description,
          status: PaymentStatus.failed,
          createdAt: paymentTransaction.createdAt,
          completedAt: DateTime.now(),
          metadata: metadata ?? {},
          errorMessage: 'Payment failed - insufficient funds',
        );

        await _updateTransaction(failedTransaction);

        throw Exception('Payment failed - insufficient funds');
      }
    } catch (e) {
      _logger.e('Payment processing failed: $e');
      throw Exception('Payment processing failed: $e');
    }
  }

  /// Get payment history for a user
  Future<List<PaymentTransaction>> getPaymentHistory({
    required String userId,
    int limit = 20,
    PaymentStatus? status,
  }) async {
    try {
      Query query = _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) =>
              PaymentTransaction.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' &&
          e.message != null &&
          e.message!.contains('index')) {
        _logger.w('Firestore index missing for payment history query: $e');
        return [];
      } else {
        _logger.e('Failed to get payment history: $e');
        return [];
      }
    } catch (e) {
      _logger.e('Failed to get payment history: $e');
      return [];
    }
  }

  /// Get transaction by ID
  Future<PaymentTransaction?> getTransaction(String transactionId) async {
    try {
      final doc =
          await _firestore.collection('payments').doc(transactionId).get();
      if (doc.exists) {
        return PaymentTransaction.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      _logger.e('Failed to get transaction: $e');
      return null;
    }
  }

  /// Cancel a payment
  Future<bool> cancelPayment(String transactionId) async {
    try {
      final transaction = await getTransaction(transactionId);
      if (transaction == null) {
        throw Exception('Transaction not found');
      }

      if (transaction.status != PaymentStatus.pending &&
          transaction.status != PaymentStatus.processing) {
        throw Exception(
            'Cannot cancel payment in ${transaction.status.name} status');
      }

      final cancelledTransaction = PaymentTransaction(
        id: transaction.id,
        userId: transaction.userId,
        amount: transaction.amount,
        currency: transaction.currency,
        paymentMethod: transaction.paymentMethod,
        description: transaction.description,
        status: PaymentStatus.cancelled,
        createdAt: transaction.createdAt,
        completedAt: DateTime.now(),
        metadata: transaction.metadata,
        errorMessage: 'Payment cancelled by user',
      );

      await _updateTransaction(cancelledTransaction);
      return true;
    } catch (e) {
      _logger.e('Failed to cancel payment: $e');
      return false;
    }
  }

  /// Request a refund
  Future<bool> requestRefund({
    required String transactionId,
    required String reason,
    double? amount,
  }) async {
    try {
      final transaction = await getTransaction(transactionId);
      if (transaction == null) {
        throw Exception('Transaction not found');
      }

      if (transaction.status != PaymentStatus.completed) {
        throw Exception(
            'Cannot refund payment in ${transaction.status.name} status');
      }

      final refundAmount = amount ?? transaction.amount;
      if (refundAmount > transaction.amount) {
        throw Exception('Refund amount cannot exceed original payment');
      }

      // Create refund transaction
      final refundTransaction = PaymentTransaction(
        id: 'refund_${DateTime.now().millisecondsSinceEpoch}',
        userId: transaction.userId,
        amount: refundAmount,
        currency: transaction.currency,
        paymentMethod: transaction.paymentMethod,
        description: 'Refund: ${transaction.description}',
        status: PaymentStatus.refunded,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        metadata: {
          ...transaction.metadata,
          'originalTransactionId': transactionId,
          'refundReason': reason,
          'refundAmount': refundAmount,
        },
        transactionId: 'refund_${transaction.transactionId}',
      );

      await _saveTransaction(refundTransaction);

      // TODO: Process actual refund through payment gateway
      await Future.delayed(
          const Duration(seconds: 1)); // Simulate refund processing

      return true;
    } catch (e) {
      _logger.e('Failed to request refund: $e');
      return false;
    }
  }

  /// Get payment statistics
  Future<Map<String, dynamic>> getPaymentStatistics({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: PaymentStatus.completed.name);

      if (startDate != null) {
        query = query.where('createdAt',
            isGreaterThanOrEqualTo: startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.where('createdAt',
            isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final querySnapshot = await query.get();
      final transactions = querySnapshot.docs
          .map((doc) =>
              PaymentTransaction.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      double totalAmount = 0;
      final paymentMethodCounts = <String, int>{};
      final currencyTotals = <String, double>{};

      for (final transaction in transactions) {
        totalAmount += transaction.amount;
        paymentMethodCounts[transaction.paymentMethod.name] =
            (paymentMethodCounts[transaction.paymentMethod.name] ?? 0) + 1;
        currencyTotals[transaction.currency] =
            (currencyTotals[transaction.currency] ?? 0) + transaction.amount;
      }

      return {
        'totalTransactions': transactions.length,
        'totalAmount': totalAmount,
        'averageAmount':
            transactions.isNotEmpty ? totalAmount / transactions.length : 0,
        'paymentMethodBreakdown': paymentMethodCounts,
        'currencyBreakdown': currencyTotals,
        'period': {
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        },
      };
    } catch (e) {
      _logger.e('Failed to get payment statistics: $e');
      return {};
    }
  }

  /// Subscribe user to a premium plan
  Future<Map<String, dynamic>> subscribeToPlan({
    required String userId,
    required String planId,
    required String paymentMethod,
    String currency = 'FRW',
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final plan = subscriptionPlans[planId];
      if (plan == null) {
        throw Exception('Invalid plan ID: $planId');
      }

      final amount = currency == 'USD' ? plan['price_usd'] : plan['price'];

      _logger.i('Processing subscription: $planId for user $userId');

      // Process the payment
      final paymentResult = await processPayment(
        userId: userId,
        amount: amount.toDouble(),
        currency: currency,
        paymentMethod: paymentMethod,
        description: 'SafeRide ${plan['name']} Subscription',
        metadata: {
          'planId': planId,
          'planName': plan['name'],
          'features': plan['features'],
          'subscriptionType': 'premium',
        },
      );

      if (paymentResult['success']) {
        // TODO: Update user's premium status in database
        // TODO: Set up recurring billing if applicable

        _logger.i('Subscription successful: ${paymentResult['transactionId']}');
        return {
          'success': true,
          'subscriptionId': 'sub_${DateTime.now().millisecondsSinceEpoch}',
          'transactionId': paymentResult['transactionId'],
          'planId': planId,
          'planName': plan['name'],
          'paymentResult': paymentResult,
          'expiresAt':
              DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        };
      } else {
        throw Exception('Payment failed');
      }
    } catch (e) {
      _logger.e('Subscription failed: $e');
      throw Exception('Subscription failed: $e');
    }
  }

  /// Save transaction to Firestore
  Future<void> _saveTransaction(PaymentTransaction transaction) async {
    try {
      await _firestore
          .collection('payments')
          .doc(transaction.id)
          .set(transaction.toMap());
    } catch (e) {
      _logger.e('Failed to save transaction: $e');
      throw Exception('Failed to save transaction: $e');
    }
  }

  /// Update transaction in Firestore
  Future<void> _updateTransaction(PaymentTransaction transaction) async {
    try {
      await _firestore
          .collection('payments')
          .doc(transaction.id)
          .update(transaction.toMap());
    } catch (e) {
      _logger.e('Failed to update transaction: $e');
      throw Exception('Failed to update transaction: $e');
    }
  }

  /// Convert string payment method to enum
  PaymentMethod _getPaymentMethodFromString(String method) {
    switch (method) {
      case 'mtn_mobile_money':
        return PaymentMethod.mtnMobileMoney;
      case 'airtel_money':
        return PaymentMethod.airtelMoney;
      case 'mpesa':
        return PaymentMethod.mpesa;
      case 'card':
        return PaymentMethod.card;
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      default:
        return PaymentMethod.mtnMobileMoney;
    }
  }

  /// Simulate payment success/failure for testing
  bool _simulatePaymentSuccess(String paymentMethod) {
    // Simulate different success rates for different payment methods
    switch (paymentMethod) {
      case 'mtn_mobile_money':
        return DateTime.now().millisecondsSinceEpoch % 10 < 8; // 80% success
      case 'airtel_money':
        return DateTime.now().millisecondsSinceEpoch % 10 < 7; // 70% success
      case 'mpesa':
        return DateTime.now().millisecondsSinceEpoch % 10 < 9; // 90% success
      case 'card':
        return DateTime.now().millisecondsSinceEpoch % 10 < 6; // 60% success
      default:
        return DateTime.now().millisecondsSinceEpoch % 10 < 5; // 50% success
    }
  }
}
