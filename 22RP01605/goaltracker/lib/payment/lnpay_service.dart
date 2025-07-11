import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class LnPay {
  final String apiKey;
  final String baseUrl;

  LnPay(this.apiKey, {this.baseUrl = 'https://www.lanari.rw/pay/lnpay/api/'});

  Future<Map<String, dynamic>> requestPayment({
    required int amount,
    required String phone,
    String network = 'mtn',
  }) async {
    String base = baseUrl;
    if (kIsWeb) {
      base = 'https://cors-anywhere.herokuapp.com/' + baseUrl;
    }
    final url = Uri.parse('${base}request_payment.php?key=$apiKey');
    final data = {'amount': amount, 'phone': phone, 'network': network};
    return await _makeRequest(url, data);
  }

  Future<Map<String, dynamic>> withdraw({
    required int amount,
    required String phone,
    String network = 'mtn',
  }) async {
    String base = baseUrl;
    if (kIsWeb) {
      base = 'https://cors-anywhere.herokuapp.com/' + baseUrl;
    }
    final url = Uri.parse('${base}withdraw.php?key=$apiKey');
    final data = {'amount': amount, 'phone': phone, 'network': network};
    return await _makeRequest(url, data);
  }

  Future<Map<String, dynamic>> _makeRequest(
    Uri url,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    try {
      return {
        'status': response.statusCode,
        'response': jsonDecode(response.body),
      };
    } catch (e) {
      // Return the raw response for debugging
      return {
        'status': response.statusCode,
        'response': response.body,
        'error': 'Invalid JSON: $e',
      };
    }
  }
}
