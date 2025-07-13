import 'dart:convert';
import 'package:http/http.dart' as http;

class LnPay {
  final String apiKey;
  final String baseUrl;

  LnPay(this.apiKey, {this.baseUrl = 'https://www.lanari.rw/pay/lnpay/api'});

  Future<Map<String, dynamic>> requestPayment(
    int amount,
    String phone, {
      
    String network = 'mtn',
  }) async {
    // Use the same endpoint as the working proxy
    final url = Uri.parse('https://www.lanari.rw/pay/lnpay/pay_proxy.php');
    final payload = {
      'amount': amount,
      'phone': phone,
      'network': network,
      'apiKey': apiKey,
    };

    try {
      print('[LnPay] Requesting payment: $payload');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      print('[LnPay] Response status: ${response.statusCode}');
      print('[LnPay] Response body: ${response.body}');

      return _parseResponse(response);
    } catch (e) {
      print('[LnPay] Network error: $e');
      return {'status': -1, 'response': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> checkPaymentStatus(
    String transactionId, {
    required String phone,
  }) async {
    // For now, use a simple verification since the API might not support status checking
    final url = Uri.parse('https://www.lanari.rw/pay/lnpay/verify_payment.php');
    final payload = {
      'transactionId': transactionId,
      'phone': phone,
      'apiKey': apiKey,
    };

    try {
      print('[LnPay] Checking payment status: $payload');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      print('[LnPay] Status check response: ${response.body}');
      return _parseResponse(response);
    } catch (e) {
      print('[LnPay] Status check error: $e');
      return {'status': -1, 'response': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyPayment(
    String phone,
    int amount, {
    String network = 'mtn',
  }) async {
    final url = Uri.parse('$baseUrl/verify_payment.php?key=$apiKey');
    final payload = {'phone': phone, 'amount': amount, 'network': network};

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      return _parseResponse(response);
    } catch (e) {
      return {'status': -1, 'response': 'Network error: $e'};
    }
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = response.body;
    }

    return {'status': response.statusCode, 'response': body};
  }
}
