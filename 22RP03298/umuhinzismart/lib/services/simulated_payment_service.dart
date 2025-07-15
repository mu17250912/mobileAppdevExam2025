import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class SimulatedPaymentService {
  static const String _baseUrl = 'https://api.simulated-payment.com';
  
  // Simulated API credentials for demo purposes
  static const String _apiKey = 'demo_api_key_12345';
  static const String _apiSecret = 'demo_api_secret_67890';
  static const String _subscriptionKey = 'demo_subscription_key';

  /// Initialize simulated payment service
  static Future<void> initialize() async {
    // Simulate initialization delay
    await Future.delayed(const Duration(milliseconds: 500));
    print('Simulated Payment Service initialized successfully');
  }

  /// Generate unique reference ID
  static String _generateReferenceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1000000).toString().padLeft(6, '0');
    return 'UMUHINZI_$timestamp$random';
  }

  /// Simulate payment request
  static Future<Map<String, dynamic>> requestPayment({
    required String phoneNumber,
    required double amount,
    required String orderId,
    required String description,
  }) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));
      
      final referenceId = _generateReferenceId();
      
      // Simulate payment processing
      final success = _simulatePaymentSuccess(phoneNumber, amount);
      
      if (success) {
        // Simulate successful payment
        final result = {
          'status': 'success',
          'referenceId': referenceId,
          'paymentStatus': 'SUCCESSFUL',
          'amount': amount,
          'currency': 'RWF',
          'payerMessage': description,
          'payeeNote': 'Payment for $description',
          'transactionId': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
          'timestamp': DateTime.now().toIso8601String(),
        };

        // Save transaction locally
        await _saveTransaction(result);
        
        return result;
      } else {
        // Simulate failed payment
        throw Exception('Payment failed: Insufficient funds or network error');
      }
    } catch (e) {
      throw Exception('Payment request failed: ${e.toString()}');
    }
  }

  /// Simulate payment success based on phone number and amount
  static bool _simulatePaymentSuccess(String phoneNumber, double amount) {
    // Simulate different scenarios based on phone number and amount
    final random = Random();
    
    // Higher success rate for demo purposes
    if (phoneNumber.contains('demo') || phoneNumber.contains('test')) {
      return true; // Always succeed for demo/test numbers
    }
    
    // Simulate success rate based on amount
    if (amount < 1000) {
      return random.nextDouble() > 0.1; // 90% success for small amounts
    } else if (amount < 10000) {
      return random.nextDouble() > 0.2; // 80% success for medium amounts
    } else {
      return random.nextDouble() > 0.3; // 70% success for large amounts
    }
  }

  /// Check payment status
  static Future<Map<String, dynamic>> checkPaymentStatus(String referenceId) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Get saved transaction
      final transactions = await getTransactionHistory();
      final transaction = transactions.firstWhere(
        (t) => t['referenceId'] == referenceId,
        orElse: () => throw Exception('Transaction not found'),
      );
      
      return transaction;
    } catch (e) {
      throw Exception('Failed to check payment status: ${e.toString()}');
    }
  }

  /// Validate phone number format (Rwanda MTN format)
  static bool isValidPhoneNumber(String phoneNumber) {
    // Rwanda MTN phone number format: +2507XXXXXXXX
    final regex = RegExp(r'^\+2507\d{8}$');
    return regex.hasMatch(phoneNumber);
  }

  /// Format phone number for payment API
  static String formatPhoneNumber(String phoneNumber) {
    // Remove spaces and dashes
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-]'), '');
    
    // Add country code if missing
    if (cleaned.startsWith('07')) {
      cleaned = '+250$cleaned';
    } else if (cleaned.startsWith('7')) {
      cleaned = '+250$cleaned';
    } else if (!cleaned.startsWith('+250')) {
      cleaned = '+250$cleaned';
    }
    
    return cleaned;
  }

  /// Save payment transaction locally
  static Future<void> _saveTransaction(Map<String, dynamic> transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = prefs.getStringList('simulated_transactions') ?? [];
    transactions.add(json.encode(transaction));
    await prefs.setStringList('simulated_transactions', transactions);
  }

  /// Get local transaction history
  static Future<List<Map<String, dynamic>>> getTransactionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = prefs.getStringList('simulated_transactions') ?? [];
    return transactions.map((t) => json.decode(t) as Map<String, dynamic>).toList();
  }

  /// Clear transaction history
  static Future<void> clearTransactionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('simulated_transactions');
  }

  /// Simulate payment verification
  static Future<bool> verifyPayment(String referenceId) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulate verification process
      final random = Random();
      return random.nextDouble() > 0.1; // 90% verification success
    } catch (e) {
      return false;
    }
  }

  /// Get payment statistics for demo purposes
  static Future<Map<String, dynamic>> getPaymentStatistics() async {
    final transactions = await getTransactionHistory();
    
    double totalAmount = 0;
    int successfulPayments = 0;
    int failedPayments = 0;
    
    for (final transaction in transactions) {
      final amount = transaction['amount'] ?? 0.0;
      final status = transaction['paymentStatus'] ?? 'UNKNOWN';
      
      totalAmount += amount;
      
      if (status == 'SUCCESSFUL') {
        successfulPayments++;
      } else {
        failedPayments++;
      }
    }
    
    return {
      'totalTransactions': transactions.length,
      'successfulPayments': successfulPayments,
      'failedPayments': failedPayments,
      'totalAmount': totalAmount,
      'successRate': transactions.isNotEmpty ? (successfulPayments / transactions.length) * 100 : 0,
    };
  }

  /// Simulate refund process
  static Future<Map<String, dynamic>> processRefund({
    required String referenceId,
    required double amount,
    required String reason,
  }) async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      
      final refundId = 'REFUND_${DateTime.now().millisecondsSinceEpoch}';
      
      final refund = {
        'status': 'success',
        'refundId': refundId,
        'originalReferenceId': referenceId,
        'amount': amount,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Save refund transaction
      final prefs = await SharedPreferences.getInstance();
      final refunds = prefs.getStringList('simulated_refunds') ?? [];
      refunds.add(json.encode(refund));
      await prefs.setStringList('simulated_refunds', refunds);
      
      return refund;
    } catch (e) {
      throw Exception('Refund failed: ${e.toString()}');
    }
  }

  /// Get demo phone numbers for testing
  static List<String> getDemoPhoneNumbers() {
    return [
      '+250700000001',
      '+250700000002',
      '+250700000003',
      '+250700000004',
      '+250700000005',
    ];
  }

  /// Simulate network connectivity check
  static Future<bool> checkNetworkConnectivity() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true; // Simulate always connected for demo
  }

  /// Simulate API health check
  static Future<Map<String, dynamic>> healthCheck() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return {
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'service': 'Simulated Payment Gateway',
      'uptime': '99.9%',
    };
  }
}

/// Payment status enum
enum PaymentStatus {
  pending,
  successful,
  failed,
  cancelled,
  expired,
  refunded,
}

/// Payment result model
class PaymentResult {
  final bool success;
  final String? referenceId;
  final PaymentStatus status;
  final String? message;
  final double? amount;
  final String? currency;
  final String? transactionId;

  PaymentResult({
    required this.success,
    this.referenceId,
    required this.status,
    this.message,
    this.amount,
    this.currency,
    this.transactionId,
  });

  factory PaymentResult.fromMap(Map<String, dynamic> map) {
    return PaymentResult(
      success: map['status'] == 'success',
      referenceId: map['referenceId'],
      status: _parseStatus(map['paymentStatus']),
      message: map['payerMessage'],
      amount: double.tryParse(map['amount']?.toString() ?? '0'),
      currency: map['currency'],
      transactionId: map['transactionId'],
    );
  }

  static PaymentStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'successful':
        return PaymentStatus.successful;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'expired':
        return PaymentStatus.expired;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }
}

/// Payment simulation configuration
class PaymentSimulationConfig {
  static bool enableRealisticDelays = true;
  static bool enableRandomFailures = true;
  static double successRate = 0.85; // 85% success rate
  static Duration minDelay = const Duration(milliseconds: 500);
  static Duration maxDelay = const Duration(seconds: 3);
  
  static Duration getRandomDelay() {
    if (!enableRealisticDelays) return Duration.zero;
    
    final random = Random();
    final delayMs = minDelay.inMilliseconds + 
        random.nextInt(maxDelay.inMilliseconds - minDelay.inMilliseconds);
    return Duration(milliseconds: delayMs);
  }
} 