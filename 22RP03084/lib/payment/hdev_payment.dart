import 'package:http/http.dart' as http;
import 'dart:convert';

/// Dart class for HDEV Payment Gateway API integration.
class HdevPayment {
  final String apiId;
  final String apiKey;

  HdevPayment({required this.apiId, required this.apiKey});

  /// Initiate a payment request
  Future<Map<String, dynamic>?> pay({
    required String tel,
    required String amount,
    required String transactionRef,
    String link = '',
  }) async {
    final url = 'https://payment.hdevtech.cloud/api_pay/api/$apiId/$apiKey';
    final response = await http.post(
      Uri.parse(url),
      body: {
        'ref': 'pay',
        'tel': tel,
        'tx_ref': transactionRef,
        'amount': amount,
        'link': link,
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  /// Check payment status
  Future<Map<String, dynamic>?> getPay({
    required String transactionRef,
  }) async {
    final url = 'https://payment.hdevtech.cloud/api_pay/api/$apiId/$apiKey';
    final response = await http.post(
      Uri.parse(url),
      body: {
        'ref': 'read',
        'tx_ref': transactionRef,
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }
}
