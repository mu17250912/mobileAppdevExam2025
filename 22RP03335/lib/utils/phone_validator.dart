class PhoneValidator {
  // Rwandan country code
  static const String rwandaCode = '+250';
  
  // MTN Rwanda number patterns - MTN numbers start with 078 or 079
  static final List<String> mtnPatterns = [
    '07[8-9][0-9]{7}', // 078XXXXXXX or 079XXXXXXX (10 digits starting with 078 or 079)
    '2507[8-9][0-9]{7}', // 25078XXXXXXX or 25079XXXXXXX (12 digits starting with 25078 or 25079)
    '\\+2507[8-9][0-9]{7}', // +25078XXXXXXX or +25079XXXXXXX (13 digits starting with +25078 or +25079)
  ];
  
  // Airtel Rwanda number patterns - Airtel numbers start with 072 or 073
  static final List<String> airtelPatterns = [
    '07[2-3][0-9]{7}', // 072XXXXXXX or 073XXXXXXX (10 digits starting with 072 or 073)
    '2507[2-3][0-9]{7}', // 25072XXXXXXX or 25073XXXXXXX (12 digits starting with 25072 or 25073)
    '\\+2507[2-3][0-9]{7}', // +25072XXXXXXX or +25073XXXXXXX (13 digits starting with +25072 or +25073)
  ];

  /// Validates if a phone number is a valid MTN Rwanda number
  static bool isValidMtnNumber(String phoneNumber) {
    // Remove all spaces, dashes, and parentheses
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check against MTN patterns
    for (String pattern in mtnPatterns) {
      if (RegExp('^$pattern\$').hasMatch(cleanNumber)) {
        return true;
      }
    }
    return false;
  }

  /// Validates if a phone number is a valid Airtel Rwanda number
  static bool isValidAirtelNumber(String phoneNumber) {
    // Remove all spaces, dashes, and parentheses
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check against Airtel patterns
    for (String pattern in airtelPatterns) {
      if (RegExp('^$pattern\$').hasMatch(cleanNumber)) {
        return true;
      }
    }
    return false;
  }

  /// Validates phone number based on provider
  static bool isValidPhoneNumber(String phoneNumber, String provider) {
    switch (provider.toUpperCase()) {
      case 'MTN':
        return isValidMtnNumber(phoneNumber);
      case 'AIRTEL':
        return isValidAirtelNumber(phoneNumber);
      default:
        return false;
    }
  }

  /// Validates email format
  static bool isValidEmail(String email) {
    // Basic email validation with @ and .com requirement
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.com$').hasMatch(email);
  }

  /// Formats phone number to standard format (+250XXXXXXXXX)
  static String formatPhoneNumber(String phoneNumber) {
    // Remove all spaces, dashes, and parentheses
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // If it starts with 0, replace with +250
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '+250${cleanNumber.substring(1)}';
    }
    // If it starts with 250 but no +, add +
    else if (cleanNumber.startsWith('250') && !cleanNumber.startsWith('+')) {
      cleanNumber = '+$cleanNumber';
    }
    // If it doesn't start with +250, add it
    else if (!cleanNumber.startsWith('+250')) {
      cleanNumber = '+250$cleanNumber';
    }
    
    return cleanNumber;
  }

  /// Gets validation error message for phone number
  static String getValidationMessage(String phoneNumber, String provider) {
    if (phoneNumber.isEmpty) {
      return 'Please enter a phone number';
    }
    
    switch (provider.toUpperCase()) {
      case 'MTN':
        if (!isValidMtnNumber(phoneNumber)) {
          return 'Invalid MTN number. Please enter a valid MTN Rwanda number (e.g., 0781234567 or +250781234567)';
        }
        break;
      case 'AIRTEL':
        if (!isValidAirtelNumber(phoneNumber)) {
          return 'Invalid Airtel number. Please enter a valid Airtel Rwanda number (e.g., 0721234567 or +250721234567)';
        }
        break;
    }
    
    return '';
  }

  /// Gets validation error message for email
  static String getEmailValidationMessage(String email) {
    if (email.isEmpty) {
      return 'Please enter an email address';
    }
    
    if (!isValidEmail(email)) {
      return 'Invalid email. Please enter a valid email address ending with .com (e.g., user@example.com)';
    }
    
    return '';
  }

  /// Gets provider from phone number
  static String? getProviderFromNumber(String phoneNumber) {
    if (isValidMtnNumber(phoneNumber)) {
      return 'MTN';
    } else if (isValidAirtelNumber(phoneNumber)) {
      return 'Airtel';
    }
    return null;
  }
} 