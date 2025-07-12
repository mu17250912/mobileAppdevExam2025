import 'package:flutter_test/flutter_test.dart';
import 'payment_tracker.dart';
import 'lnpay_service.dart';

void main() {
  group('Payment System Tests', () {
    test('LnPay service should handle payment requests', () async {
      final lnPay = LnPay('test-api-key');

      // Test payment request
      final result = await lnPay.requestPayment(10000, '0712345678');

      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('status'), isTrue);
      expect(result.containsKey('response'), isTrue);
    });

    test('LnPay service should handle payment verification', () async {
      final lnPay = LnPay('test-api-key');

      // Test payment verification
      final result = await lnPay.verifyPayment('0712345678', 10000);

      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('status'), isTrue);
      expect(result.containsKey('response'), isTrue);
    });

    test('LnPay service should handle payment status check', () async {
      final lnPay = LnPay('test-api-key');

      // Test payment status check
      final result = await lnPay.checkPaymentStatus(
        'test-transaction-id',
        phone: '0712345678',
      );

      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('status'), isTrue);
      expect(result.containsKey('response'), isTrue);
    });
  });
}
