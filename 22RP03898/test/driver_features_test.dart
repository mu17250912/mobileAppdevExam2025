import 'package:flutter_test/flutter_test.dart';
import 'package:saferide/services/role_service.dart';
import 'package:saferide/models/user_model.dart';

void main() {
  group('Driver Features Tests', () {
    test('Driver features list should contain 9 features', () {
      final roleService = RoleService();
      final driverFeatures = roleService.getDriverFeatures();

      expect(driverFeatures.length, equals(9));
      expect(
          driverFeatures,
          contains(
              '🔐 Register/Login - Sign up with phone/email and select "Driver" role'));
      expect(
          driverFeatures,
          contains(
              '📤 Post Rides - Enter route, departure time, available seats, and price'));
      expect(
          driverFeatures,
          contains(
              '✏️ Edit/Delete Rides - Change ride info or cancel if unavailable'));
      expect(
          driverFeatures,
          contains(
              '📋 View Bookings - See list of passengers who booked their ride'));
      expect(
          driverFeatures,
          contains(
              '📞 Contact Passengers - Call or chat with booked users for confirmation'));
      expect(
          driverFeatures,
          contains(
              '📈 Upgrade to Premium - Pay monthly/weekly to appear at the top of results'));
      expect(
          driverFeatures,
          contains(
              '💰 Receive Bookings - Get payments or booking fees from passengers'));
      expect(
          driverFeatures,
          contains(
              '💬 Get Reviews - Read feedback from passengers after trips'));
      expect(
          driverFeatures,
          contains(
              '📊 Track Performance - See how many bookings/views their rides got'));
    });

    test('Driver permissions should be comprehensive', () {
      final roleService = RoleService();
      final permissions = roleService.getRolePermissions();
      final driverPermissions = permissions['driver'] ?? [];

      expect(driverPermissions.length, greaterThan(5));
      expect(driverPermissions, contains('post_rides'));
      expect(driverPermissions, contains('view_own_rides'));
      expect(driverPermissions, contains('manage_bookings'));
      expect(driverPermissions, contains('view_earnings'));
      expect(driverPermissions, contains('contact_passengers'));
      expect(driverPermissions, contains('update_ride_status'));
      expect(driverPermissions, contains('view_driver_analytics'));
    });

    test('Driver role display name should be correct', () {
      final roleService = RoleService();
      final displayName = roleService.getRoleDisplayName(UserType.driver);

      expect(displayName, equals('Driver'));
    });

    test('Driver role description should be correct', () {
      final roleService = RoleService();
      final description = roleService.getRoleDescription(UserType.driver);

      expect(description, equals('Can post rides and transport passengers'));
    });

    test('UserType.driver should be correctly defined', () {
      expect(UserType.driver, isNotNull);
      expect(UserType.driver.toString(), contains('driver'));
    });
  });
}
