class AppConstants {
  // App Info
  static const String appName = 'EventEase';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Plan and manage events with ease';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String eventsCollection = 'events';
  static const String attendanceCollection = 'attendance';
  
  // Event Categories
  static const List<String> eventCategories = [
    'Study Group',
    'Meeting',
    'Social',
    'Workshop',
    'Seminar',
    'Party',
    'Sports',
    'Other',
  ];
  
  // Event Status
  static const String statusUpcoming = 'upcoming';
  static const String statusOngoing = 'ongoing';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  
  // Attendance Status
  static const String attendancePending = 'pending';
  static const String attendanceConfirmed = 'confirmed';
  static const String attendanceDeclined = 'declined';
  static const String attendanceCheckedIn = 'checked-in';
  static const String attendanceCheckedOut = 'checked-out';
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxEventTitleLength = 100;
  static const int maxEventDescriptionLength = 500;
  static const int maxEventLocationLength = 200;
  static const int maxParticipants = 100;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Error Messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorAuth = 'Authentication failed. Please try again.';
  static const String errorEventNotFound = 'Event not found.';
  static const String errorUserNotFound = 'User not found.';
  
  // Success Messages
  static const String successLogin = 'Welcome back! Login successful.';
  static const String successRegister = 'Account created successfully! Welcome to EventEase.';
  static const String successEventCreated = 'Event created successfully!';
  static const String successEventUpdated = 'Event updated successfully!';
  static const String successEventDeleted = 'Event deleted successfully!';
  static const String successJoinedEvent = 'Successfully joined the event!';
  static const String successLeftEvent = 'Successfully left the event.';
  static const String successProfileUpdated = 'Profile updated successfully!';
  
  // Placeholder Text
  static const String placeholderEventTitle = 'Enter event title';
  static const String placeholderEventDescription = 'Enter event description';
  static const String placeholderEventLocation = 'Enter event location';
  static const String placeholderSearch = 'Search events...';
  static const String placeholderEmail = 'Enter your email';
  static const String placeholderPassword = 'Enter your password';
  static const String placeholderName = 'Enter your name';
  
  // Premium Features
  static const List<String> premiumFeatures = [
    'Unlimited events',
    'Advanced analytics',
    'Custom branding',
    'Priority support',
    'No ads',
    'Export data',
  ];
  
  // Default Values
  static const int defaultMaxParticipants = 20;
  static const bool defaultIsPrivate = false;
  static const List<String> defaultCategories = ['Other'];
} 