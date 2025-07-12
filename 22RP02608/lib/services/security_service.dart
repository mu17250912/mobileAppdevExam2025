import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  static const String _keyName = 'encryption_key';
  static const String _ivName = 'encryption_iv';
  
  late Key _key;
  late IV _iv;
  late Encrypter _encrypter;

  // Initialize encryption
  Future<void> initialize() async {
    await _loadOrGenerateKeys();
    _encrypter = Encrypter(AES(_key));
  }

  // Load or generate encryption keys
  Future<void> _loadOrGenerateKeys() async {
    final prefs = await SharedPreferences.getInstance();
    
    String? keyString = prefs.getString(_keyName);
    String? ivString = prefs.getString(_ivName);

    if (keyString == null || ivString == null) {
      // Generate new keys
      final random = Random.secure();
      final keyBytes = Uint8List.fromList(List<int>.generate(32, (i) => random.nextInt(256)));
      final ivBytes = Uint8List.fromList(List<int>.generate(16, (i) => random.nextInt(256)));
      
      _key = Key(keyBytes);
      _iv = IV(ivBytes);
      
      // Save keys
      await prefs.setString(_keyName, base64Encode(keyBytes));
      await prefs.setString(_ivName, base64Encode(ivBytes));
    } else {
      // Load existing keys
      _key = Key(base64Decode(keyString));
      _iv = IV(base64Decode(ivString));
    }
  }

  // Encrypt data
  String encrypt(String data) {
    try {
      final encrypted = _encrypter.encrypt(data, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      print('Encryption error: $e');
      return data; // Return original data if encryption fails
    }
  }

  // Decrypt data
  String decrypt(String encryptedData) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedData);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      print('Decryption error: $e');
      return encryptedData; // Return original data if decryption fails
    }
  }

  // Hash password
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Verify password
  bool verifyPassword(String password, String hashedPassword) {
    return hashPassword(password) == hashedPassword;
  }

  // Secure storage methods
  Future<void> secureStore(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedValue = encrypt(value);
    await prefs.setString(key, encryptedValue);
  }

  Future<String?> secureRetrieve(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedValue = prefs.getString(key);
    if (encryptedValue != null) {
      return decrypt(encryptedValue);
    }
    return null;
  }

  Future<void> secureRemove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  // Generate secure token
  String generateSecureToken() {
    final random = Random.secure();
    final tokenBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(tokenBytes);
  }

  // Validate email format
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Validate password strength
  bool isStrongPassword(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$');
    return passwordRegex.hasMatch(password);
  }

  // Sanitize user input
  String sanitizeInput(String input) {
    // Remove potentially dangerous characters
    return input
      .replaceAll('<', '')
      .replaceAll('>', '')
      .replaceAll('"', '')
      .replaceAll("'", '');
  }

  // Generate user ID
  String generateUserId() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomBytes = List<int>.generate(8, (i) => random.nextInt(256));
    return 'user_${timestamp}_${base64Encode(randomBytes).substring(0, 8)}';
  }

  // Encrypt sensitive data for transmission
  Map<String, String> encryptSensitiveData(Map<String, dynamic> data) {
    final encryptedData = <String, String>{};
    
    for (final entry in data.entries) {
      if (entry.value is String) {
        encryptedData[entry.key] = encrypt(entry.value as String);
      } else {
        encryptedData[entry.key] = encrypt(jsonEncode(entry.value));
      }
    }
    
    return encryptedData;
  }

  // Decrypt sensitive data
  Map<String, dynamic> decryptSensitiveData(Map<String, String> encryptedData) {
    final decryptedData = <String, dynamic>{};
    
    for (final entry in encryptedData.entries) {
      try {
        final decrypted = decrypt(entry.value);
        // Try to parse as JSON, if it fails, use as string
        try {
          decryptedData[entry.key] = jsonDecode(decrypted);
        } catch (e) {
          decryptedData[entry.key] = decrypted;
        }
      } catch (e) {
        print('Error decrypting data for key ${entry.key}: $e');
        decryptedData[entry.key] = entry.value; // Return encrypted value if decryption fails
      }
    }
    
    return decryptedData;
  }

  // Clear all secure data
  Future<void> clearAllSecureData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Check if device is secure
  bool isDeviceSecure() {
    // Basic security checks
    // In a real app, you might check for:
    // - Root/Jailbreak detection
    // - Emulator detection
    // - Screen lock status
    // - Biometric availability
    return true; // Placeholder
  }

  // Log security event
  void logSecurityEvent(String event, {Map<String, dynamic>? details}) {
    final timestamp = DateTime.now().toIso8601String();
    print('Security Event [$timestamp]: $event');
    if (details != null) {
      print('Details: $details');
    }
  }
} 