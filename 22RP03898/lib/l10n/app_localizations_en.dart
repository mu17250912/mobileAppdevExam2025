// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SafeRide';

  @override
  String get welcome => 'Welcome to SafeRide!';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get signup => 'Sign Up';

  @override
  String get bookRide => 'Book a Ride';

  @override
  String get profile => 'Profile';

  @override
  String get driver => 'Driver';

  @override
  String get rideDetails => 'Ride Details';

  @override
  String get home => 'Home';

  @override
  String get onboardingTitle => 'Get Started with SafeRide';

  @override
  String get onboardingDescription => 'Book safe, affordable rides in your community.';

  @override
  String get premiumUpgrade => 'Upgrade to Premium';

  @override
  String get payNow => 'Pay Now';

  @override
  String get cancel => 'Cancel';

  @override
  String get errorOccurred => 'An error occurred. Please try again.';

  @override
  String get networkError => 'No internet connection.';
}
