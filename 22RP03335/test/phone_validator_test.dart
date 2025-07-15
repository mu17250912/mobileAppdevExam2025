import 'package:flutter_test/flutter_test.dart';
import 'package:exam_mobile/utils/phone_validator.dart';

void main() {
  group('PhoneValidator Tests', () {
    group('MTN Rwanda Numbers', () {
      test('should validate correct MTN numbers', () {
        expect(PhoneValidator.isValidMtnNumber('0781234567'), true);
        expect(PhoneValidator.isValidMtnNumber('0791234567'), true);
        expect(PhoneValidator.isValidMtnNumber('+250781234567'), true);
        expect(PhoneValidator.isValidMtnNumber('+250791234567'), true);
        expect(PhoneValidator.isValidMtnNumber('250781234567'), true);
        expect(PhoneValidator.isValidMtnNumber('250791234567'), true);
      });

      test('should reject invalid MTN numbers', () {
        expect(PhoneValidator.isValidMtnNumber('078123456'), false); // Too short
        expect(PhoneValidator.isValidMtnNumber('07812345678'), false); // Too long
        expect(PhoneValidator.isValidMtnNumber('0721234567'), false); // Airtel number
        expect(PhoneValidator.isValidMtnNumber('0731234567'), false); // Airtel number
        expect(PhoneValidator.isValidMtnNumber('0711234567'), false); // Invalid prefix
        expect(PhoneValidator.isValidMtnNumber('0701234567'), false); // Invalid prefix
      });
    });

    group('Airtel Rwanda Numbers', () {
      test('should validate correct Airtel numbers', () {
        expect(PhoneValidator.isValidAirtelNumber('0721234567'), true);
        expect(PhoneValidator.isValidAirtelNumber('0731234567'), true);
        expect(PhoneValidator.isValidAirtelNumber('+250721234567'), true);
        expect(PhoneValidator.isValidAirtelNumber('+250731234567'), true);
        expect(PhoneValidator.isValidAirtelNumber('250721234567'), true);
        expect(PhoneValidator.isValidAirtelNumber('250731234567'), true);
      });

      test('should reject invalid Airtel numbers', () {
        expect(PhoneValidator.isValidAirtelNumber('072123456'), false); // Too short
        expect(PhoneValidator.isValidAirtelNumber('07212345678'), false); // Too long
        expect(PhoneValidator.isValidAirtelNumber('0781234567'), false); // MTN number
        expect(PhoneValidator.isValidAirtelNumber('0791234567'), false); // MTN number
        expect(PhoneValidator.isValidAirtelNumber('0711234567'), false); // Invalid prefix
        expect(PhoneValidator.isValidAirtelNumber('0701234567'), false); // Invalid prefix
      });
    });

    group('Provider Detection', () {
      test('should detect MTN provider', () {
        expect(PhoneValidator.getProviderFromNumber('0781234567'), 'MTN');
        expect(PhoneValidator.getProviderFromNumber('0791234567'), 'MTN');
        expect(PhoneValidator.getProviderFromNumber('+250781234567'), 'MTN');
        expect(PhoneValidator.getProviderFromNumber('+250791234567'), 'MTN');
      });

      test('should detect Airtel provider', () {
        expect(PhoneValidator.getProviderFromNumber('0721234567'), 'Airtel');
        expect(PhoneValidator.getProviderFromNumber('0731234567'), 'Airtel');
        expect(PhoneValidator.getProviderFromNumber('+250721234567'), 'Airtel');
        expect(PhoneValidator.getProviderFromNumber('+250731234567'), 'Airtel');
      });

      test('should return null for invalid numbers', () {
        expect(PhoneValidator.getProviderFromNumber('123456789'), null);
        expect(PhoneValidator.getProviderFromNumber(''), null);
        expect(PhoneValidator.getProviderFromNumber('abc'), null);
        expect(PhoneValidator.getProviderFromNumber('0711234567'), null); // Invalid prefix
        expect(PhoneValidator.getProviderFromNumber('0701234567'), null); // Invalid prefix
      });
    });

    group('Email Validation', () {
      test('should validate correct email addresses', () {
        expect(PhoneValidator.isValidEmail('user@example.com'), true);
        expect(PhoneValidator.isValidEmail('test.user@domain.com'), true);
        expect(PhoneValidator.isValidEmail('user123@company.com'), true);
      });

      test('should reject invalid email addresses', () {
        expect(PhoneValidator.isValidEmail('user@example.org'), false); // Not .com
        expect(PhoneValidator.isValidEmail('user@example'), false); // No domain
        expect(PhoneValidator.isValidEmail('user.example.com'), false); // No @
        expect(PhoneValidator.isValidEmail('@example.com'), false); // No username
        expect(PhoneValidator.isValidEmail(''), false); // Empty
      });

      test('should return appropriate email validation messages', () {
        expect(PhoneValidator.getEmailValidationMessage(''), 'Please enter an email address');
        expect(PhoneValidator.getEmailValidationMessage('invalid'), contains('Invalid email'));
        expect(PhoneValidator.getEmailValidationMessage('user@example.com'), '');
      });
    });

    group('Phone Number Formatting', () {
      test('should format numbers correctly', () {
        expect(PhoneValidator.formatPhoneNumber('0781234567'), '+250781234567');
        expect(PhoneValidator.formatPhoneNumber('0721234567'), '+250721234567');
        expect(PhoneValidator.formatPhoneNumber('+250781234567'), '+250781234567');
        expect(PhoneValidator.formatPhoneNumber('250781234567'), '+250781234567');
      });
    });

    group('Validation Messages', () {
      test('should return appropriate error messages', () {
        expect(PhoneValidator.getValidationMessage('', 'MTN'), 'Please enter a phone number');
        expect(PhoneValidator.getValidationMessage('123', 'MTN'), contains('Invalid MTN number'));
        expect(PhoneValidator.getValidationMessage('0781234567', 'MTN'), '');
        expect(PhoneValidator.getValidationMessage('0791234567', 'MTN'), '');
        expect(PhoneValidator.getValidationMessage('0721234567', 'Airtel'), '');
        expect(PhoneValidator.getValidationMessage('0731234567', 'Airtel'), '');
        expect(PhoneValidator.getValidationMessage('0721234567', 'MTN'), contains('Invalid MTN number'));
        expect(PhoneValidator.getValidationMessage('0781234567', 'Airtel'), contains('Invalid Airtel number'));
      });
    });
  });
} 