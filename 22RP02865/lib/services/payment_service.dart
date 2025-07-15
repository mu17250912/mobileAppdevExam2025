import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final AnalyticsService _analytics = AnalyticsService();

  // Simulated payment methods
  static const List<String> _paymentMethods = [
    'Credit Card',
    'PayPal',
    'MTN Mobile Money',
    'Airtel Money',
    'Flutterwave',
  ];

  // Premium plans
  static const Map<String, Map<String, dynamic>> _premiumPlans = {
    'monthly': {
      'name': 'Monthly Premium',
      'price': 4.99,
      'currency': 'USD',
      'features': [
        'Unlimited tasks',
        'Advanced analytics',
        'Ad-free experience',
        'Priority support',
      ],
    },
    'yearly': {
      'name': 'Yearly Premium',
      'price': 39.99,
      'currency': 'USD',
      'features': [
        'All monthly features',
        '2 months free',
        'Exclusive themes',
        'Early access to features',
      ],
    },
    'lifetime': {
      'name': 'Lifetime Premium',
      'price': 99.99,
      'currency': 'USD',
      'features': [
        'All features forever',
        'One-time payment',
        'Lifetime updates',
        'VIP support',
      ],
    },
  };

  // Get available payment methods
  List<String> getPaymentMethods() {
    return _paymentMethods;
  }

  // Get premium plans
  Map<String, Map<String, dynamic>> getPremiumPlans() {
    return _premiumPlans;
  }

  // Simulate payment processing
  Future<PaymentResult> processPayment({
    required String planId,
    required String paymentMethod,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Simulate payment validation
    if (cardNumber.isEmpty || expiryDate.isEmpty || cvv.isEmpty) {
      return PaymentResult(
        success: false,
        message: 'Please fill in all payment details',
        transactionId: null,
      );
    }

    // Simulate card validation (basic check)
    if (cardNumber.length < 13 || cardNumber.length > 19) {
      return PaymentResult(
        success: false,
        message: 'Invalid card number',
        transactionId: null,
      );
    }

    if (cvv.length < 3 || cvv.length > 4) {
      return PaymentResult(
        success: false,
        message: 'Invalid CVV',
        transactionId: null,
      );
    }

    // Simulate successful payment (90% success rate for demo)
    final random = DateTime.now().millisecondsSinceEpoch % 10;
    if (random < 9) {
      final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';
      
      // Track successful payment
      await _analytics.trackPremiumUpgrade(planId);
      
      // Store payment record
      await _storePaymentRecord(planId, paymentMethod, transactionId);
      
      return PaymentResult(
        success: true,
        message: 'Payment successful! Welcome to Premium!',
        transactionId: transactionId,
      );
    } else {
      return PaymentResult(
        success: false,
        message: 'Payment failed. Please try again or use a different payment method.',
        transactionId: null,
      );
    }
  }

  // Store payment record locally
  Future<void> _storePaymentRecord(
    String planId,
    String paymentMethod,
    String transactionId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final paymentHistory = prefs.getStringList('payment_history') ?? [];
    
    final paymentRecord = {
      'planId': planId,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'date': DateTime.now().toIso8601String(),
      'amount': _premiumPlans[planId]?['price']?.toString() ?? '0',
      'currency': _premiumPlans[planId]?['currency'] ?? 'USD',
    };
    
    paymentHistory.add(paymentRecord.toString());
    await prefs.setStringList('payment_history', paymentHistory);
  }

  // Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final paymentHistory = prefs.getStringList('payment_history') ?? [];
    
    return paymentHistory.map((record) {
      // Parse the string representation back to map
      final cleanRecord = record.replaceAll('{', '').replaceAll('}', '');
      final pairs = cleanRecord.split(', ');
      final map = <String, dynamic>{};
      
      for (final pair in pairs) {
        final keyValue = pair.split(': ');
        if (keyValue.length == 2) {
          final key = keyValue[0].trim();
          final value = keyValue[1].trim();
          map[key] = value;
        }
      }
      
      return map;
    }).toList();
  }

  // Validate payment method
  bool validatePaymentMethod(String paymentMethod) {
    return _paymentMethods.contains(paymentMethod);
  }

  // Get plan details
  Map<String, dynamic>? getPlanDetails(String planId) {
    return _premiumPlans[planId];
  }
}

class PaymentResult {
  final bool success;
  final String message;
  final String? transactionId;

  PaymentResult({
    required this.success,
    required this.message,
    this.transactionId,
  });
} 