/// Professional App Configuration for SafeRide
///
/// This file contains all app-wide configurations, constants, and settings
/// to ensure consistent behavior across the application.
library;

import 'package:flutter/material.dart';

class AppConfig {
  // App Information
  static const String appName = 'SafeRide';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Professional Transportation Booking Platform';

  // Company Information
  static const String companyName = 'SafeRide Ltd';
  static const String companyEmail = 'support@saferide.com';
  static const String companyPhone = '+250 123 456 789';
  static const String companyAddress = 'Kigali, Rwanda';

  // API Configuration
  static const String apiBaseUrl = 'https://api.saferide.com';
  static const int apiTimeout = 30000; // 30 seconds

  // Firebase Configuration
  static const String firebaseProjectId = 'saferide-app';
  static const String firebaseMessagingToken = 'your-messaging-token';

  // Payment Configuration
  static const String currency = 'FRW';
  static const String currencySymbol = '₣';
  static const double minimumFare = 500.0;
  static const double maximumFare = 50000.0;

  // Location Configuration
  static const double defaultLatitude = -1.9441; // Kigali
  static const double defaultLongitude = 30.0619;
  static const double searchRadius = 50.0; // km

  // Booking Configuration
  static const int maxSeatsPerRide = 20;
  static const int minSeatsPerRide = 1;
  static const int bookingTimeout = 300; // 5 minutes
  static const int cancellationWindow = 3600; // 1 hour

  // User Configuration
  static const int maxBookingsPerUser = 5;
  static const int maxRidesPerDriver = 10;
  static const double minimumRating = 1.0;
  static const double maximumRating = 5.0;

  // Notification Configuration
  static const int notificationTimeout = 5000; // 5 seconds
  static const bool enablePushNotifications = true;
  static const bool enableEmailNotifications = true;
  static const bool enableSMSNotifications = false;

  // Cache Configuration
  static const int cacheTimeout = 300; // 5 minutes
  static const int maxCacheSize = 100; // MB

  // Security Configuration
  static const String adminCode = 'ADMIN2024';
  static const int maxLoginAttempts = 5;
  static const int lockoutDuration = 900; // 15 minutes

  // Feature Flags
  static const bool enablePremiumFeatures = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePerformanceMonitoring = true;

  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  // Colors
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color secondaryColor = Color(0xFF42A5F5);
  static const Color accentColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color infoColor = Color(0xFF2196F3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFF44336), Color(0xFFEF5350)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1976D2),
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Color(0xFF424242),
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Color(0xFF424242),
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Color(0xFF757575),
  );

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Sizes
  static const double buttonHeight = 56.0;
  static const double inputHeight = 48.0;
  static const double cardRadius = 12.0;
  static const double avatarSize = 40.0;

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Validation Rules
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int minPhoneLength = 10;
  static const int maxPhoneLength = 15;

  // Error Messages
  static const String networkErrorMessage =
      'Network error. Please check your internet connection.';
  static const String serverErrorMessage =
      'Server error. Please try again later.';
  static const String timeoutErrorMessage =
      'Request timeout. Please try again.';
  static const String unknownErrorMessage =
      'An unknown error occurred. Please try again.';

  // Success Messages
  static const String loginSuccessMessage = 'Welcome back!';
  static const String registrationSuccessMessage =
      'Account created successfully!';
  static const String bookingSuccessMessage = 'Booking confirmed!';
  static const String ridePostedMessage = 'Ride posted successfully!';
  static const String profileUpdatedMessage = 'Profile updated successfully!';

  // Loading Messages
  static const String loadingMessage = 'Please wait...';
  static const String processingMessage = 'Processing...';
  static const String savingMessage = 'Saving...';
  static const String uploadingMessage = 'Uploading...';

  // Default Values
  static const String defaultUserImage = 'assets/images/default_avatar.png';
  static const String defaultVehicleImage = 'assets/images/default_vehicle.png';
  static const String defaultRideImage = 'assets/images/default_ride.png';

  // File Upload Limits
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxDocumentSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx'];

  // Cache Keys
  static const String userCacheKey = 'user_data';
  static const String settingsCacheKey = 'app_settings';
  static const String ridesCacheKey = 'rides_data';
  static const String bookingsCacheKey = 'bookings_data';

  // Route Names
  static const String homeRoute = '/home';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String profileRoute = '/profile';
  static const String dashboardRoute = '/dashboard';
  static const String bookingRoute = '/booking';
  static const String rideRoute = '/ride';
  static const String chatRoute = '/chat';
  static const String supportRoute = '/support';
  static const String settingsRoute = '/settings';

  // Feature Toggles
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static bool get isDevelopment => !isProduction;
  static bool get enableDebugMode => isDevelopment;
  static bool get enableLogging => isDevelopment;

  // Performance Settings
  static const int maxConcurrentRequests = 5;
  static const int requestRetryCount = 3;
  static const int requestRetryDelay = 1000; // 1 second

  // Analytics Events
  static const String loginEvent = 'user_login';
  static const String registrationEvent = 'user_registration';
  static const String bookingEvent = 'ride_booking';
  static const String ridePostEvent = 'ride_posted';
  static const String paymentEvent = 'payment_completed';

  // Error Codes
  static const String networkErrorCode = 'NETWORK_ERROR';
  static const String authErrorCode = 'AUTH_ERROR';
  static const String validationErrorCode = 'VALIDATION_ERROR';
  static const String serverErrorCode = 'SERVER_ERROR';
  static const String unknownErrorCode = 'UNKNOWN_ERROR';
}
