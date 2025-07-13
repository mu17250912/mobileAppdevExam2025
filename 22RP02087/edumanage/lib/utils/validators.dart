String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your email address';
  }
  // Simple but effective email regex
  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+');
  if (!emailRegex.hasMatch(value)) {
    return 'Enter a valid email address';
  }
  return null;
}

