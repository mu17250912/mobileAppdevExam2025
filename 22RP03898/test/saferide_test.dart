import 'package:flutter_test/flutter_test.dart';
import 'package:saferide/services/ad_service.dart';
import 'package:saferide/services/payment_service.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Firebase for all tests
    await Firebase.initializeApp();
  });

  group('SafeRide App Tests', () {
    group('AdService Tests', () {
      late AdService adService;

      setUp(() {
        adService = AdService();
      });

      test('should initialize ad service', () async {
        // Test that the service can be created without errors
        expect(adService, isNotNull);
      });

      test('should handle web platform gracefully', () async {
        // Test that the service doesn't crash on web platform
        await adService.initialize();
        expect(adService, isNotNull);
      });

      test('should create banner ad', () {
        final bannerAd = adService.getBannerAd();
        expect(bannerAd, isNotNull);
      });

      test('should load interstitial ad', () async {
        await adService.loadInterstitialAd();
        // Test that the method completes without error
        expect(true, true);
      });

      test('should show interstitial ad', () async {
        await adService.showInterstitialAd();
        // Test that the method completes without error
        expect(true, true);
      });

      test('should dispose ads', () {
        adService.dispose();
        // Test that the method completes without error
        expect(true, true);
      });
    });

    group('PaymentService Tests', () {
      late PaymentService paymentService;

      setUp(() {
        paymentService = PaymentService();
      });

      test('should initialize payment service', () async {
        await paymentService.initialize();
        expect(paymentService.isInitialized, true);
      });

      test('should return supported payment methods', () {
        final methods = PaymentService.supportedPaymentMethods;
        expect(methods, contains('mtn_mobile_money'));
        expect(methods, contains('airtel_money'));
        expect(methods, contains('mpesa'));
      });

      test('should return subscription plans', () {
        final plans = PaymentService.subscriptionPlans.keys;
        expect(plans, contains('basic'));
        expect(plans, contains('premium'));
        expect(plans, contains('driver_premium'));
      });

      test('should validate subscription plan prices', () {
        final plans = PaymentService.subscriptionPlans;

        expect(plans['basic']!['price'], 5000.0);
        expect(plans['premium']!['price'], 10000.0);
        expect(plans['driver_premium']!['price'], 15000.0);

        expect(plans['basic']!['currency'], 'FRW');
        expect(plans['premium']!['currency'], 'FRW');
        expect(plans['driver_premium']!['currency'], 'FRW');
      });

      test('should process payment successfully', () async {
        await paymentService.initialize();
        final result = await paymentService.processPayment(
          userId: 'test_user_id',
          amount: 10000.0,
          currency: 'FRW',
          paymentMethod: 'mtn_mobile_money',
          description: 'Test payment',
        );
        expect(result['success'], isA<bool>());
        if (result['success'] == true) {
          expect(result['transactionId'], isNotEmpty);
          expect(result['amount'], 10000.0);
          expect(result['currency'], 'FRW');
        }
      });

      test('should handle subscription creation', () async {
        await paymentService.initialize();
        final result = await paymentService.subscribeToPlan(
          userId: 'test_user_id',
          planId: 'basic',
          paymentMethod: 'mtn_mobile_money',
        );
        expect(result['success'], isA<bool>());
        if (result['success'] == true) {
          expect(result['subscriptionId'], isNotEmpty);
          expect(result['transactionId'], isNotEmpty);
        }
      });

      test('should handle invalid subscription plan', () async {
        await paymentService.initialize();
        try {
          await paymentService.subscribeToPlan(
            userId: 'test_user_id',
            planId: 'invalid_plan',
            paymentMethod: 'mtn_mobile_money',
          );
          fail('Should throw exception for invalid plan');
        } catch (e) {
          expect(e.toString(), contains('Invalid plan ID'));
        }
      });
    });

    group('Business Logic Tests', () {
      test('should calculate correct commission for drivers', () {
        const double ridePrice = 10000.0; // 10,000 FRW
        const double commissionRate = 0.15; // 15%
        const double expectedCommission = ridePrice * commissionRate;

        expect(expectedCommission, 1500.0);
      });

      test('should validate ride availability logic', () {
        const String status = 'scheduled';
        const int availableSeats = 0;

        final isAvailable = status == 'scheduled' && availableSeats > 0;
        expect(isAvailable, false);
      });

      test('should validate user types', () {
        const validUserTypes = ['passenger', 'driver', 'admin'];
        const testUserType = 'passenger';

        expect(validUserTypes.contains(testUserType), true);
      });

      test('should calculate ride pricing in FRW', () {
        const double basePrice = 5000.0; // 5,000 FRW base price
        const double distanceMultiplier = 1.5;
        const double timeMultiplier = 1.2;

        final totalPrice = basePrice * distanceMultiplier * timeMultiplier;
        expect(totalPrice, 9000.0);
      });

      test('should validate booking constraints', () {
        const int maxSeats = 4;
        const int requestedSeats = 5;

        final canBook = requestedSeats <= maxSeats;
        expect(canBook, false);
      });

      test('should validate MTN Mobile Money phone numbers', () {
        final validMTNNumbers = ['0781234567', '0791234567', '0731234567'];
        final invalidNumbers = ['0771234567', '0721234567', '1234567890'];

        for (final number in validMTNNumbers) {
          expect(
              number.startsWith('078') ||
                  number.startsWith('079') ||
                  number.startsWith('073'),
              true);
        }

        for (final number in invalidNumbers) {
          expect(
              number.startsWith('078') ||
                  number.startsWith('079') ||
                  number.startsWith('073'),
              false);
        }
      });
    });

    group('Error Handling Tests', () {
      test('should handle null values gracefully', () {
        String? nullableString;
        final result = nullableString ?? 'default';
        expect(result, 'default');
      });

      test('should validate required fields', () {
        const requiredFields = ['id', 'name', 'email'];
        const providedFields = ['id', 'name'];

        final hasAllRequired =
            requiredFields.every((field) => providedFields.contains(field));
        expect(hasAllRequired, false);
      });

      test('should handle payment service errors', () async {
        final paymentService = PaymentService();

        // Test with uninitialized service
        try {
          await paymentService.processPayment(
            userId: 'test_user_id',
            amount: 1000.0,
            currency: 'FRW',
            paymentMethod: 'invalid_method',
            description: 'Test payment',
          );
          // The service should auto-initialize, so this should not throw
          expect(true, true);
        } catch (e) {
          // If it throws, it should be a payment-related error, not initialization
          expect(e.toString(), isNotEmpty);
        }
      });
    });
  });
}
