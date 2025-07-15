/// Role Service for SafeRide
///
/// Manages user roles and permissions throughout the application.
/// Defines what each user type (passenger, driver, admin) can do.
///
/// Passenger Features:
/// - Register/Login with phone/email
/// - Search for rides (filtered by location, date, time)
/// - Book a seat on available rides
/// - Cancel bookings if plans change
/// - View booking history (past and upcoming trips)
/// - Contact drivers (call or message)
/// - Rate drivers (optional feedback)
/// - Get notifications for booked rides, schedule changes
/// - View ads (free version)
///
/// TODO: Future Enhancements:
/// - Advanced permission management
/// - Role-based feature flags
/// - Permission inheritance
/// - Custom role creation
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class RoleService {
  static final RoleService _instance = RoleService._internal();
  factory RoleService() => _instance;
  RoleService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();

  /// Check if current user has a specific role
  Future<bool> hasRole(UserType role) async {
    try {
      final userModel = await _authService.getCurrentUserModel();
      if (userModel == null) return false;

      return userModel.userType == role;
    } catch (e) {
      _logger.e('Error checking user role: $e');
      return false;
    }
  }

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    return await hasRole(UserType.admin);
  }

  /// Check if current user is driver
  Future<bool> isDriver() async {
    return await hasRole(UserType.driver);
  }

  /// Check if current user is passenger
  Future<bool> isPassenger() async {
    return await hasRole(UserType.passenger);
  }

  /// Get current user's role
  Future<UserType?> getCurrentUserRole() async {
    try {
      final userModel = await _authService.getCurrentUserModel();
      return userModel?.userType;
    } catch (e) {
      _logger.e('Error getting current user role: $e');
      return null;
    }
  }

  /// Check if user can access admin features
  Future<bool> canAccessAdminFeatures() async {
    return await isAdmin();
  }

  /// Check if user can post rides (drivers only)
  Future<bool> canPostRides() async {
    return await isDriver();
  }

  /// Check if user can book rides (passengers only)
  Future<bool> canBookRides() async {
    return await isPassenger();
  }

  /// Check if user can view all rides (admin and drivers)
  Future<bool> canViewAllRides() async {
    final role = await getCurrentUserRole();
    return role == UserType.admin || role == UserType.driver;
  }

  /// Check if user can manage other users (admin only)
  Future<bool> canManageUsers() async {
    return await isAdmin();
  }

  /// Check if user can view analytics (admin only)
  Future<bool> canViewAnalytics() async {
    return await isAdmin();
  }

  /// Get all users by role
  Future<List<UserModel>> getUsersByRole(UserType role) async {
    try {
      // TODO: Implement user search by role
      // For now, return empty list
      return [];
    } catch (e) {
      _logger.e('Error getting users by role: $e');
      return [];
    }
  }

  /// Get all drivers
  Future<List<UserModel>> getAllDrivers() async {
    return await getUsersByRole(UserType.driver);
  }

  /// Get all passengers
  Future<List<UserModel>> getAllPassengers() async {
    return await getUsersByRole(UserType.passenger);
  }

  /// Get all admins
  Future<List<UserModel>> getAllAdmins() async {
    return await getUsersByRole(UserType.admin);
  }

  /// Update user role (admin only)
  Future<bool> updateUserRole(String userId, UserType newRole) async {
    try {
      // Check if current user is admin
      if (!await isAdmin()) {
        _logger.w('Non-admin user attempted to update user role');
        return false;
      }

      await _firestore.collection('users').doc(userId).update({
        'userType': newRole.name.toLowerCase(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      _logger.i('User role updated successfully: $userId -> ${newRole.name}');
      return true;
    } catch (e) {
      _logger.e('Error updating user role: $e');
      return false;
    }
  }

  /// Verify driver (admin only)
  Future<bool> verifyDriver(String driverId) async {
    try {
      // Check if current user is admin
      if (!await isAdmin()) {
        _logger.w('Non-admin user attempted to verify driver');
        return false;
      }

      await _firestore.collection('users').doc(driverId).update({
        'isVerified': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      _logger.i('Driver verified successfully: $driverId');
      return true;
    } catch (e) {
      _logger.e('Error verifying driver: $e');
      return false;
    }
  }

  /// Ban user (admin only)
  Future<bool> banUser(String userId) async {
    try {
      // Check if current user is admin
      if (!await isAdmin()) {
        _logger.w('Non-admin user attempted to ban user');
        return false;
      }

      await _firestore.collection('users').doc(userId).update({
        'isBanned': true,
        'status': UserStatus.suspended.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      _logger.i('User banned successfully: $userId');
      return true;
    } catch (e) {
      _logger.e('Error banning user: $e');
      return false;
    }
  }

  /// Unban user (admin only)
  Future<bool> unbanUser(String userId) async {
    try {
      // Check if current user is admin
      if (!await isAdmin()) {
        _logger.w('Non-admin user attempted to unban user');
        return false;
      }

      await _firestore.collection('users').doc(userId).update({
        'isBanned': false,
        'status': UserStatus.active.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      _logger.i('User unbanned successfully: $userId');
      return true;
    } catch (e) {
      _logger.e('Error unbanning user: $e');
      return false;
    }
  }

  /// Get admin-specific features
  List<String> getAdminFeatures() {
    return [
      '👥 Manage Users - Activate, suspend, or ban users and drivers',
      '🚫 Moderate Content - Remove fake or duplicate ride posts',
      '💳 Verify Payments - Approve premium subscriptions manually',
      '📈 View Analytics - Track bookings, users, and popular routes',
      '📬 Send Push Notifications - Announce features, updates, emergencies',
    ];
  }

  /// Get role permissions
  Map<String, List<String>> getRolePermissions() {
    return {
      'admin': [
        'manage_users',
        'activate_users',
        'suspend_users',
        'ban_users',
        'unban_users',
        'moderate_content',
        'remove_ride_posts',
        'verify_payments',
        'approve_premium',
        'view_analytics',
        'track_bookings',
        'track_active_users',
        'track_popular_routes',
        'send_notifications',
        'announce_features',
        'announce_updates',
        'announce_emergencies',
        'view_all_users',
        'view_all_rides',
        'update_user_roles',
        'manage_payments',
        'manage_notifications',
        'post_rides',
        'book_rides',
        'verify_drivers',
        'view_system_reports',
      ],
      'driver': [
        'post_rides',
        'view_own_rides',
        'view_passenger_profiles',
        'update_profile',
        'manage_bookings',
        'view_earnings',
        'contact_passengers',
        'update_ride_status',
        'view_driver_analytics',
      ],
      'passenger': [
        // Core booking features
        'book_rides',
        'view_available_rides',
        'search_rides',
        'filter_rides',
        'cancel_bookings',
        'view_booking_history',

        // Communication features
        'contact_driver',
        'message_driver',
        'call_driver',
        'view_driver_profiles',

        // Rating and feedback
        'rate_drivers',
        'leave_reviews',
        'view_driver_ratings',

        // Profile and preferences
        'update_profile',
        'manage_preferences',
        'view_personal_stats',

        // Notifications
        'receive_notifications',
        'manage_notification_settings',

        // Payment features
        'view_payment_history',
        'manage_payment_methods',
        'request_refunds',

        // Premium features
        'upgrade_to_premium',
        'view_premium_features',

        // Support
        'contact_support',
        'report_issues',
        'view_help_center',

        // Ads (free version)
        'view_ads',
        'skip_ads_premium',
      ],
    };
  }

  /// Check if user has specific permission
  Future<bool> hasPermission(String permission) async {
    try {
      final role = await getCurrentUserRole();
      if (role == null) return false;

      final permissions = getRolePermissions()[role.name];
      return permissions?.contains(permission) ?? false;
    } catch (e) {
      _logger.e('Error checking permission: $e');
      return false;
    }
  }

  /// Get user role display name
  String getRoleDisplayName(UserType role) {
    switch (role) {
      case UserType.admin:
        return 'Administrator';
      case UserType.driver:
        return 'Driver';
      case UserType.passenger:
        return 'Passenger';
    }
  }

  /// Get role description
  String getRoleDescription(UserType role) {
    switch (role) {
      case UserType.admin:
        return 'Full system access and user management';
      case UserType.driver:
        return 'Can post rides and transport passengers';
      case UserType.passenger:
        return 'Can book rides and travel with drivers';
    }
  }

  /// Get passenger-specific features
  List<String> getPassengerFeatures() {
    return [
      '🔐 Register/Login - Sign up with phone/email and log in securely',
      '🔍 Search for Rides - Browse available rides (filtered by location, date, time)',
      '📅 Book a Seat - Select a ride and reserve a seat',
      '📤 Cancel Booking - Cancel a booking if plans change',
      '🧾 View Booking History - See list of past and upcoming trips',
      '📞 Contact Driver - Call or message the driver for confirmation',
      '🌟 Rate Drivers - Give feedback to help improve quality',
      '🔔 Get Notifications - Receive alerts for booked rides, schedule changes, etc.',
      '💰 View Ads - Free version shows ads while browsing rides',
    ];
  }

  /// Get driver-specific features
  List<String> getDriverFeatures() {
    return [
      '🔐 Register/Login - Sign up with phone/email and select "Driver" role',
      '📤 Post Rides - Enter route, departure time, available seats, and price',
      '✏️ Edit/Delete Rides - Change ride info or cancel if unavailable',
      '📋 View Bookings - See list of passengers who booked their ride',
      '📞 Contact Passengers - Call or chat with booked users for confirmation',
      '📈 Upgrade to Premium - Pay monthly/weekly to appear at the top of results',
      '💰 Receive Bookings - Get payments or booking fees from passengers',
      '💬 Get Reviews - Read feedback from passengers after trips',
      '📊 Track Performance - See how many bookings/views their rides got',
    ];
  }

  /// Get feature access summary for current user
  Future<Map<String, bool>> getFeatureAccessSummary() async {
    final role = await getCurrentUserRole();
    if (role == null) return {};

    return {
      'can_book_rides': role == UserType.passenger || role == UserType.admin,
      'can_post_rides': role == UserType.driver || role == UserType.admin,
      'can_manage_users': role == UserType.admin,
      'can_view_analytics': role == UserType.admin,
      'can_contact_drivers':
          role == UserType.passenger || role == UserType.admin,
      'can_contact_passengers':
          role == UserType.driver || role == UserType.admin,
      'can_rate_users': role == UserType.passenger || role == UserType.admin,
      'can_view_earnings': role == UserType.driver || role == UserType.admin,
      'can_manage_bookings': role == UserType.driver || role == UserType.admin,
      'can_view_booking_history': true, // All users can view their own history
    };
  }
}
