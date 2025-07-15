class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String userDashboard = '/user-dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String eventDetails = '/event-details';
  static const String serviceProvider = '/service-provider';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String payments = '/payments';
}

class AppConstants {
  // App Info
  static const String appName = 'Faith';
  static const String appVersion = '1.0.0';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String eventsCollection = 'events';
  static const String servicesCollection = 'services';
  static const String bookingsCollection = 'bookings';
  static const String notificationsCollection = 'notifications';
  static const String paymentsCollection = 'payments';
  static const String chatsCollection = 'chats';
  static const String subscriptionsCollection = 'subscriptions';
  
  // User Types
  static const String userTypeAdmin = 'admin';
  static const String userTypeUser = 'user';
  static const String userTypeServiceProvider = 'service_provider';
  
  // Event Types
  static const String eventTypeWedding = 'wedding';
  static const String eventTypeCelebration = 'celebration';
  static const String eventTypeFaithBased = 'faith_based';
  
  // Service Categories
  static const String servicePhotographer = 'photographer';
  static const String serviceDancer = 'dancer';
  static const String serviceArtist = 'artist';
  static const String servicePreparator = 'preparator';
  
  // Payment Status
  static const String paymentPending = 'pending';
  static const String paymentCompleted = 'completed';
  static const String paymentFailed = 'failed';
  
  // Booking Status
  static const String bookingPending = 'pending';
  static const String bookingConfirmed = 'confirmed';
  static const String bookingCancelled = 'cancelled';
  static const String bookingCompleted = 'completed';
}

class AppColors {
  static const int primaryColor = 0xFF6B46C1;
  static const int secondaryColor = 0xFF9F7AEA;
  static const int accentColor = 0xFFE6FFFA;
  static const int backgroundColor = 0xFFF7FAFC;
  static const int textColor = 0xFF2D3748;
  static const int errorColor = 0xFFE53E3E;
  static const int successColor = 0xFF38A169;
  static const int warningColor = 0xFFD69E2E;
}

class AppStrings {
  // Welcome Messages
  static const String welcomeTitle = 'Welcome to Faith';
  static const String welcomeSubtitle = 'Your trusted partner for event planning in Rwanda';
  
  // Authentication
  static const String loginTitle = 'Sign In';
  static const String registerTitle = 'Create Account';
  static const String emailHint = 'Enter your email';
  static const String passwordHint = 'Enter your password';
  static const String confirmPasswordHint = 'Confirm your password';
  static const String forgotPassword = 'Forgot Password?';
  
  // Dashboard
  static const String userDashboardTitle = 'My Events';
  static const String adminDashboardTitle = 'Admin Dashboard';
  static const String upcomingEvents = 'Upcoming Events';
  static const String recentBookings = 'Recent Bookings';
  
  // Events
  static const String createEvent = 'Create Event';
  static const String editEvent = 'Edit Event';
  static const String eventTitle = 'Event Title';
  static const String eventDescription = 'Event Description';
  static const String eventDate = 'Event Date';
  static const String eventLocation = 'Event Location';
  
  // Services
  static const String findServices = 'Find Services';
  static const String serviceProviders = 'Service Providers';
  static const String bookService = 'Book Service';
  
  // Notifications
  static const String notifications = 'Notifications';
  static const String noNotifications = 'No notifications yet';
  
  // Profile
  static const String profile = 'Profile';
  static const String editProfile = 'Edit Profile';
  static const String settings = 'Settings';
  static const String logout = 'Logout';
  
  // Payments
  static const String payments = 'Payments';
  static const String paymentHistory = 'Payment History';
  static const String makePayment = 'Make Payment';
} 