import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiTest {
  static Future<void> testPaymentApi() async {
    print('=== Testing Payment API ===');

    // Test the payment proxy endpoint
    final url = Uri.parse('https://www.lanari.rw/pay/lnpay/pay_proxy.php');
    final payload = {
      'amount': 100,
      'phone': '0712345678',
      'network': 'mtn',
      'apiKey':
          '6949156a26cafc9d148b0e36158bb005af91b67160f892ed9592cc595eaa818c',
    };

    try {
      print('Sending request to: $url');
      print('Payload: $payload');

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

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ API is working! Status 200 received');

        // Try to parse the response
        try {
          final decoded = jsonDecode(response.body);
          print('✅ Response is valid JSON: $decoded');
        } catch (e) {
          print('⚠️ Response is not JSON: ${response.body}');
        }
      } else {
        print('❌ API returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ API test failed: $e');
    }
  }

  static Future<void> testVerifyApi() async {
    print('=== Testing Verify API ===');

    final url = Uri.parse('https://www.lanari.rw/pay/lnpay/verify_payment.php');
    final payload = {
      'phone': '0712345678',
      'amount': 10000,
      'network': 'mtn',
      'apiKey':
          '6949156a26cafc9d148b0e36158bb005af91b67160f892ed9592cc595eaa818c',
    };

    try {
      print('Sending verify request to: $url');
      print('Payload: $payload');

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

      print('Verify response status: ${response.statusCode}');
      print('Verify response body: ${response.body}');
    } catch (e) {
      print('❌ Verify API test failed: $e');
    }
  }
}
