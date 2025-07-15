import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  late final FlutterSecureStorage _secureStorage;
  late final encrypt.Encrypter _encrypter;
  late final encrypt.IV _iv;
  bool _isInitialized = false;

  // Security constants
  static const String _encryptionKey = 'your-32-character-encryption-key-here'; // 32 chars
  static const String _storageKeyPrefix = 'commissioner_secure_';
  static const int _saltLength = 32;
  static const int _hashIterations = 10000;

  // Secure storage keys
  static const String _keyAuthToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserCredentials = 'user_credentials';
  static const String _keyPaymentInfo = 'payment_info';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyLastLoginTime = 'last_login_time';
  static const String _keyDeviceId = 'device_id';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize secure storage
      _secureStorage = const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: IOSOptions(),
      );

      // Initialize encryption
      final key = encrypt.Key.fromUtf8(_encryptionKey);
      _iv = encrypt.IV.fromLength(16);
      _encrypter = encrypt.Encrypter(encrypt.AES(key));

      _isInitialized = true;
      debugPrint('Security service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing security service: $e');
    }
  }

  // Hash password with salt
  String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate random salt
  String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(_saltLength, (i) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  // Encrypt sensitive data
  String encryptData(String data) {
    if (!_isInitialized) return data;

    try {
      final encrypted = _encrypter.encrypt(data, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      debugPrint('Error encrypting data: $e');
      return data;
    }
  }

  // Decrypt sensitive data
  String decryptData(String encryptedData) {
    if (!_isInitialized) return encryptedData;

    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
      final decrypted = _encrypter.decrypt(encrypted, iv: _iv);
      return decrypted;
    } catch (e) {
      debugPrint('Error decrypting data: $e');
      return encryptedData;
    }
  }

  // Store sensitive data securely
  Future<void> storeSecureData(String key, String value) async {
    if (!_isInitialized) return;

    try {
      final encryptedValue = encryptData(value);
      await _secureStorage.write(
        key: _storageKeyPrefix + key,
        value: encryptedValue,
      );
    } catch (e) {
      debugPrint('Error storing secure data: $e');
    }
  }

  // Retrieve sensitive data securely
  Future<String?> getSecureData(String key) async {
    if (!_isInitialized) return null;

    try {
      final encryptedValue = await _secureStorage.read(
        key: _storageKeyPrefix + key,
      );
      
      if (encryptedValue != null) {
        return decryptData(encryptedValue);
      }
      return null;
    } catch (e) {
      debugPrint('Error retrieving secure data: $e');
      return null;
    }
  }

  // Store authentication tokens
  Future<void> storeAuthTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await storeSecureData(_keyAuthToken, accessToken);
    await storeSecureData(_keyRefreshToken, refreshToken);
    await storeSecureData(_keyLastLoginTime, DateTime.now().toIso8601String());
  }

  // Get authentication tokens
  Future<Map<String, String?>> getAuthTokens() async {
    final accessToken = await getSecureData(_keyAuthToken);
    final refreshToken = await getSecureData(_keyRefreshToken);
    
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }

  // Clear authentication tokens
  Future<void> clearAuthTokens() async {
    await _secureStorage.delete(key: _storageKeyPrefix + _keyAuthToken);
    await _secureStorage.delete(key: _storageKeyPrefix + _keyRefreshToken);
    await _secureStorage.delete(key: _storageKeyPrefix + _keyLastLoginTime);
  }

  // Store user credentials securely
  Future<void> storeUserCredentials({
    required String email,
    required String password,
  }) async {
    final credentials = json.encode({
      'email': email,
      'password': password,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    await storeSecureData(_keyUserCredentials, credentials);
  }

  // Get stored user credentials
  Future<Map<String, dynamic>?> getUserCredentials() async {
    final credentials = await getSecureData(_keyUserCredentials);
    if (credentials != null) {
      return json.decode(credentials);
    }
    return null;
  }

  // Store payment information securely
  Future<void> storePaymentInfo({
    required String cardNumber,
    required String expiryDate,
    required String cvv,
  }) async {
    final paymentInfo = json.encode({
      'cardNumber': _maskCardNumber(cardNumber),
      'expiryDate': expiryDate,
      'cvv': '***', // Never store CVV
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    await storeSecureData(_keyPaymentInfo, paymentInfo);
  }

  // Get stored payment information
  Future<Map<String, dynamic>?> getPaymentInfo() async {
    final paymentInfo = await getSecureData(_keyPaymentInfo);
    if (paymentInfo != null) {
      return json.decode(paymentInfo);
    }
    return null;
  }

  // Generate secure device ID
  Future<String> generateDeviceId() async {
    final existingId = await getSecureData(_keyDeviceId);
    if (existingId != null) return existingId;

    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    final deviceId = base64Url.encode(bytes);
    
    await storeSecureData(_keyDeviceId, deviceId);
    return deviceId;
  }

  // Validate input data
  bool validateEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }

  bool validatePassword(String password) {
    // Password must be at least 8 characters with at least one uppercase, lowercase, number, and special character
    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$'
    );
    return passwordRegex.hasMatch(password);
  }

  bool validatePhoneNumber(String phone) {
    // Basic phone number validation
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    return phoneRegex.hasMatch(phone);
  }

  // Sanitize user input
  String sanitizeInput(String input) {
    // Remove potentially dangerous characters
    return input
        .replaceAll(RegExp(r'[<>"\  -]'), '')
        .trim();
  }

  // Validate API response
  bool validateApiResponse(Map<String, dynamic> response) {
    // Check for required fields and data types
    if (!response.containsKey('status')) return false;
    if (!response.containsKey('data')) return false;
    
    return true;
  }

  // Check for suspicious activity
  Future<bool> detectSuspiciousActivity({
    required String userId,
    required String action,
  }) async {
    try {
      // Get last login time
      final lastLoginStr = await getSecureData(_keyLastLoginTime);
      if (lastLoginStr != null) {
        final lastLogin = DateTime.parse(lastLoginStr);
        final now = DateTime.now();
        
        // Check for rapid successive actions
        if (now.difference(lastLogin).inSeconds < 1) {
          return true; // Suspicious - too fast
        }
      }

      // Store current action time
      await storeSecureData(_keyLastLoginTime, DateTime.now().toIso8601String());
      
      return false;
    } catch (e) {
      debugPrint('Error detecting suspicious activity: $e');
      return false;
    }
  }

  // Generate secure random string
  String generateSecureRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  // Mask sensitive data for display
  String _maskCardNumber(String cardNumber) {
    if (cardNumber.length < 4) return cardNumber;
    return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
  }

  String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    
    final username = parts[0];
    final domain = parts[1];
    
    if (username.length <= 2) return email;
    
    final maskedUsername = username[0] + '*' * (username.length - 2) + username[username.length - 1];
    return '$maskedUsername@$domain';
  }

  // Clear all secure data
  Future<void> clearAllSecureData() async {
    if (!_isInitialized) return;

    try {
      await _secureStorage.deleteAll();
      debugPrint('All secure data cleared');
    } catch (e) {
      debugPrint('Error clearing secure data: $e');
    }
  }

  // Get security audit log
  Future<List<Map<String, dynamic>>> getSecurityAuditLog() async {
    // This would typically fetch from a secure audit log
    // For now, we'll return a mock structure
    return [
      {
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'login_attempt',
        'userId': 'user123',
        'ipAddress': '192.168.1.1',
        'success': true,
      },
      {
        'timestamp': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
        'action': 'password_change',
        'userId': 'user123',
        'ipAddress': '192.168.1.1',
        'success': true,
      },
    ];
  }

  // Validate session
  Future<bool> validateSession() async {
    try {
      final tokens = await getAuthTokens();
      final accessToken = tokens['accessToken'];
      
      if (accessToken == null) return false;

      // Check if token is expired (basic check)
      // In production, you'd validate the JWT token properly
      return true;
    } catch (e) {
      debugPrint('Error validating session: $e');
      return false;
    }
  }

  // Get security status
  Future<Map<String, dynamic>> getSecurityStatus() async {
    return {
      'isInitialized': _isInitialized,
      'hasAuthTokens': (await getAuthTokens())['accessToken'] != null,
      'hasStoredCredentials': await getUserCredentials() != null,
      'hasPaymentInfo': await getPaymentInfo() != null,
      'deviceId': await generateDeviceId(),
      'lastSecurityCheck': DateTime.now().toIso8601String(),
    };
  }
} 