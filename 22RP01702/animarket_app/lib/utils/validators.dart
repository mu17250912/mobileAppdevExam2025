class Validators {
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Enter your phone number';
    if (!RegExp(r'^\d{10,15}$').hasMatch(value)) return 'Enter a valid phone number';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) return 'Enter your name';
    return null;
  }

  static String? validateLocation(String? value) {
    if (value == null || value.isEmpty) return 'Enter your location';
    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) return 'Enter price';
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) return 'Enter valid price';
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) return 'Enter description';
    return null;
  }
}