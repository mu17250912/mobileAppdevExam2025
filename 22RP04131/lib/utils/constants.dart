// App-wide constants and business logic
class AppConstants {
  // VAT Configuration
  static const double defaultVATRate = 0.18; // 18% for Rwanda
  static const String vatLabel = 'VAT (18%)';
  
  // Document Numbering
  static const String invoicePrefix = 'INV';
  static const String quotePrefix = 'QUO';
  static const String proformaPrefix = 'PRO';
  static const String deliveryNotePrefix = 'DEL';
  
  // Validation Rules
  static const int minPasswordLength = 6;
  static const int minClientNameLength = 2;
  static const double minItemPrice = 0.01;
  static const int minItemQuantity = 1;
  
  // Currency
  static const String currency = 'RWF';
  static const String currencySymbol = 'RWF ';
  
  // App Info
  static const String appName = 'QuickDocs';
  static const String appTagline = 'Documents Made Easy';
  static const String appVersion = '1.0.0';
  
  // Navigation Routes
  static const String splashRoute = '/';
  static const String onboardingRoute = '/onboarding';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String dashboardRoute = '/dashboard';
  static const String documentSelectionRoute = '/document-selection';
  static const String documentFormRoute = '/document-form';
  static const String documentPreviewRoute = '/document-preview';
  static const String documentHistoryRoute = '/document-history';
  static const String documentDetailRoute = '/document-detail';
  static const String settingsRoute = '/settings';
  static const String notificationsRoute = '/notifications';
  static const String formValidationErrorRoute = '/form-validation-error';
  static const String emptyStateRoute = '/empty-state';
}

// Validation messages
class ValidationMessages {
  static const String requiredField = 'This field is required';
  static const String invalidEmail = 'Please enter a valid email address';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  static const String invalidPrice = 'Price must be greater than 0';
  static const String invalidQuantity = 'Quantity must be at least 1';
  static const String clientNameTooShort = 'Client name must be at least 2 characters';
}

// Business logic helpers
class BusinessLogic {
  static double calculateVAT(double subtotal, double discountPercentage, bool vatEnabled) {
    if (!vatEnabled) return 0.0;
    double afterDiscount = subtotal - (subtotal * (discountPercentage / 100));
    return afterDiscount * AppConstants.defaultVATRate;
  }
  
  static double calculateTotal(double subtotal, double discountPercentage, bool vatEnabled) {
    double afterDiscount = subtotal - (subtotal * (discountPercentage / 100));
    double vat = calculateVAT(subtotal, discountPercentage, vatEnabled);
    return afterDiscount + vat;
  }
  
  static String generateDocumentNumber(String prefix, int sequenceNumber) {
    return '$prefix-${sequenceNumber.toString().padLeft(3, '0')}';
  }
} 