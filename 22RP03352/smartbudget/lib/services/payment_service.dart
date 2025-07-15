import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  static const List<String> _paymentMethods = [
    'Credit Card', 
    'Debit Card', 
    'PayPal', 
    'Apple Pay',
    'MTN Mobile Money',
    'Airtel Money',
    'M-Pesa',
    'Orange Money'
  ];
  static const List<String> _cardTypes = ['Visa', 'Mastercard', 'American Express', 'Discover'];
  
  // Store successful transactions in Firestore
  static Future<void> _saveTransactionToFirestore(PaymentTransaction transaction) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(transaction.id)
          .set({
        'id': transaction.id,
        'amount': transaction.amount,
        'status': transaction.status,
        'date': transaction.date,
        'paymentMethod': transaction.paymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving transaction to Firestore: $e');
    }
  }
  
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
    final timestamp = DateTime.now();
    
    // Create transaction object
    final transaction = PaymentTransaction(
      id: transactionId,
      amount: amount,
      status: 'completed',
      date: timestamp,
      paymentMethod: paymentMethod,
    );
    
    // Save successful transaction to Firestore
    await _saveTransactionToFirestore(transaction);
    
    return PaymentResult(
      success: true,
      errorMessage: null,
      transactionId: transactionId,
      amount: amount,
      paymentMethod: paymentMethod,
      timestamp: timestamp,
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

  /// Get payment history from Firestore - only successful transactions
  static Future<List<PaymentTransaction>> getPaymentHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('date', descending: true)
          .get();
      
      final transactions = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return PaymentTransaction(
          id: data['id'] ?? '',
          amount: (data['amount'] ?? 0.0).toDouble(),
          status: data['status'] ?? 'completed',
          date: (data['date'] as Timestamp).toDate(),
          paymentMethod: data['paymentMethod'] ?? '',
        );
      }).toList();
      
      // Clear any existing sample data (for users who had sample data before)
      final clearedTransactions = await _clearSampleDataIfExists(user.uid, transactions);
      
      return clearedTransactions ?? transactions;
    } catch (e) {
      print('Error fetching transactions from Firestore: $e');
      return [];
    }
  }
  
  /// Clear any existing sample data from previous versions
  static Future<List<PaymentTransaction>?> _clearSampleDataIfExists(String userId, List<PaymentTransaction> transactions) async {
    try {
      // Check if there are any sample transactions (old sample data)
      final sampleTransactions = transactions.where((t) => 
        t.id.contains('_001') || 
        t.id.contains('_002') || 
        t.id.contains('_003') ||
        (t.amount == 4.99 && t.paymentMethod == 'Credit Card') ||
        (t.amount == 4.99 && t.paymentMethod == 'PayPal') ||
        (t.amount == 4.99 && t.paymentMethod == 'MTN Mobile Money')
      ).toList();
      
      if (sampleTransactions.isNotEmpty) {
        print('Found sample transactions, clearing them...');
        final batch = FirebaseFirestore.instance.batch();
        
        for (final transaction in sampleTransactions) {
          final docRef = FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('transactions')
              .doc(transaction.id);
          batch.delete(docRef);
        }
        
        await batch.commit();
        print('Sample transactions cleared successfully');
        
        // Return empty list after clearing sample data
        return [];
      }
    } catch (e) {
      print('Error clearing sample data: $e');
    }
    return null; // Return null if no sample data was found or error occurred
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