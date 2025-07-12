import 'dart:async';
import 'dart:math';

class PaymentService {
  static const List<String> _paymentMethods = ['Credit Card', 'Debit Card', 'PayPal', 'Apple Pay'];
  static const List<String> _cardTypes = ['Visa', 'Mastercard', 'American Express', 'Discover'];
  
  /// Enhanced simulation with multiple payment methods and realistic scenarios
  static Future<PaymentResult> simulatePayment({
    required double amount,
    required String plan,
    String paymentMethod = 'Credit Card',
    String? cardNumber,
  }) async {
    // Validate payment method
    if (!_paymentMethods.contains(paymentMethod)) {
      return PaymentResult(
        success: false,
        errorMessage: 'Invalid payment method selected',
        transactionId: null,
      );
    }

    // Simulate card validation for card payments
    if (paymentMethod.contains('Card') && cardNumber != null) {
      if (!_isValidCardNumber(cardNumber)) {
        return PaymentResult(
          success: false,
          errorMessage: 'Invalid card number',
          transactionId: null,
        );
      }
    }

    // Simulate network delay (1-3 seconds)
    final delay = Duration(milliseconds: 1000 + Random().nextInt(2000));
    await Future.delayed(delay);

    // Simulate various failure scenarios (10% failure rate)
    final random = Random();
    final failureChance = random.nextDouble();
    
    if (failureChance < 0.1) {
      final failureReasons = [
        'Insufficient funds',
        'Card declined',
        'Network timeout',
        'Invalid security code',
        'Card expired',
      ];
      final randomFailure = failureReasons[random.nextInt(failureReasons.length)];
      
      return PaymentResult(
        success: false,
        errorMessage: randomFailure,
        transactionId: null,
      );
    }

    // Generate realistic transaction ID
    final transactionId = _generateTransactionId();
    
    return PaymentResult(
      success: true,
      errorMessage: null,
      transactionId: transactionId,
      amount: amount,
      paymentMethod: paymentMethod,
      timestamp: DateTime.now(),
    );
  }

  /// Simulate payment method validation
  static Future<List<String>> getAvailablePaymentMethods() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _paymentMethods;
  }

  /// Simulate card type detection
  static String? detectCardType(String cardNumber) {
    if (cardNumber.startsWith('4')) return 'Visa';
    if (cardNumber.startsWith('5')) return 'Mastercard';
    if (cardNumber.startsWith('3')) return 'American Express';
    if (cardNumber.startsWith('6')) return 'Discover';
    return null;
  }

  /// Validate card number (Luhn algorithm simulation)
  static bool _isValidCardNumber(String cardNumber) {
    if (cardNumber.length < 13 || cardNumber.length > 19) return false;
    
    // Simple validation - in real app, use proper Luhn algorithm
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 13) return false;
    
    // Simulate some invalid card numbers
    if (digits.startsWith('0000') || digits.startsWith('9999')) return false;
    
    return true;
  }

  /// Generate realistic transaction ID
  static String _generateTransactionId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = random.nextInt(999999);
    return 'TXN${timestamp}_${randomPart.toString().padLeft(6, '0')}';
  }

  /// Simulate payment history retrieval
  static Future<List<PaymentTransaction>> getPaymentHistory() async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    return [
      PaymentTransaction(
        id: 'TXN${DateTime.now().millisecondsSinceEpoch}_001',
        amount: 4.99,
        status: 'completed',
        date: DateTime.now().subtract(const Duration(days: 30)),
        paymentMethod: 'Credit Card',
      ),
      PaymentTransaction(
        id: 'TXN${DateTime.now().millisecondsSinceEpoch}_002',
        amount: 4.99,
        status: 'completed',
        date: DateTime.now().subtract(const Duration(days: 60)),
        paymentMethod: 'PayPal',
      ),
    ];
  }
}

class PaymentResult {
  final bool success;
  final String? errorMessage;
  final String? transactionId;
  final double? amount;
  final String? paymentMethod;
  final DateTime? timestamp;

  PaymentResult({
    required this.success,
    this.errorMessage,
    this.transactionId,
    this.amount,
    this.paymentMethod,
    this.timestamp,
  });
}

class PaymentTransaction {
  final String id;
  final double amount;
  final String status;
  final DateTime date;
  final String paymentMethod;

  PaymentTransaction({
    required this.id,
    required this.amount,
    required this.status,
    required this.date,
    required this.paymentMethod,
  });
} 