import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    await _analytics.logEvent(
        name: name, parameters: _sanitizeParameters(parameters));
  }

  // Helper to convert bools to strings for analytics
  Map<String, dynamic>? _sanitizeParameters(Map<String, dynamic>? params) {
    if (params == null) return null;
    return params.map((key, value) {
      if (value is bool) {
        return MapEntry(key, value.toString());
      }
      return MapEntry(key, value);
    });
  }

  Future<void> logLogin({String? method}) async {
    await _analytics.logLogin(loginMethod: method ?? 'email');
  }

  Future<void> logSignUp({String? method}) async {
    await _analytics.logSignUp(signUpMethod: method ?? 'email');
  }

  Future<void> logLogout() async {
    await logEvent('logout');
  }

  Future<void> logPayment(
      {required double amount, required String method}) async {
    await logEvent('payment', parameters: {
      'amount': amount,
      'method': method,
    });
  }

  Future<void> logAdImpression({required String adType}) async {
    await logEvent('ad_impression', parameters: {'ad_type': adType});
  }

  Future<void> logBooking({required String rideId}) async {
    await logEvent('booking', parameters: {'ride_id': rideId});
  }

  Future<void> logRidePosted({required String rideId}) async {
    await logEvent('ride_posted', parameters: {'ride_id': rideId});
  }
}
