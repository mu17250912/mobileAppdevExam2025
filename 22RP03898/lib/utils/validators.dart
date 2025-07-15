/// Form validation utilities for SafeRide app
class Validators {
  /// Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // Email regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    // Optional: Add more password strength requirements
    // if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
    //   return 'Password must contain uppercase, lowercase, and number';
    // }

    return null;
  }

  /// Confirm password validation
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Name validation
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Phone number validation
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    // Check for valid phone number length (7-15 digits)
    if (digitsOnly.length < 7 || digitsOnly.length > 15) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Required field validation
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Minimum length validation
  static String? minLength(String? value, int minLength, String fieldName) {
    if (value == null || value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  /// Maximum length validation
  static String? maxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }
    return null;
  }

  /// Number validation
  static String? number(String? value) {
    if (value == null || value.isEmpty) {
      return 'Number is required';
    }

    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }

    return null;
  }

  /// Positive number validation
  static String? positiveNumber(String? value) {
    final numberError = number(value);
    if (numberError != null) {
      return numberError;
    }

    final numValue = double.parse(value!);
    if (numValue <= 0) {
      return 'Please enter a positive number';
    }

    return null;
  }

  /// URL validation
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional
    }

    try {
      Uri.parse(value);
      return null;
    } catch (e) {
      return 'Please enter a valid URL';
    }
  }

  /// Date validation
  static String? date(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }

    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }

  /// Future date validation
  static String? futureDate(String? value) {
    final dateError = date(value);
    if (dateError != null) {
      return dateError;
    }

    final dateValue = DateTime.parse(value!);
    final now = DateTime.now();

    if (dateValue.isBefore(now)) {
      return 'Date must be in the future';
    }

    return null;
  }

  /// Vehicle number validation
  static String? vehicleNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vehicle number is required';
    }

    // Basic vehicle number validation (can be customized based on country)
    if (value.length < 3 || value.length > 20) {
      return 'Vehicle number must be between 3 and 20 characters';
    }

    return null;
  }

  /// License number validation
  static String? licenseNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'License number is required';
    }

    // Basic license number validation (can be customized based on country)
    if (value.length < 5 || value.length > 20) {
      return 'License number must be between 5 and 20 characters';
    }

    return null;
  }

  /// Price validation
  static String? price(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }

    final price = double.tryParse(value);
    if (price == null) {
      return 'Please enter a valid price';
    }

    if (price < 0) {
      return 'Price cannot be negative';
    }

    if (price > 1000000) {
      return 'Price seems too high';
    }

    return null;
  }

  /// Seats validation
  static String? seats(String? value) {
    if (value == null || value.isEmpty) {
      return 'Number of seats is required';
    }

    final seats = int.tryParse(value);
    if (seats == null) {
      return 'Please enter a valid number of seats';
    }

    if (seats < 1) {
      return 'Must have at least 1 seat';
    }

    if (seats > 50) {
      return 'Cannot have more than 50 seats';
    }

    return null;
  }

  /// Description validation
  static String? description(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Description is optional
    }

    if (value.length > 500) {
      return 'Description must be less than 500 characters';
    }

    return null;
  }
}
