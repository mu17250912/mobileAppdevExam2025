CurrencyX - Multi-Currency Converter

A modern, feature-rich currency conversion application built with Flutter and Firebase. CurrencyX provides real-time exchange rates, user authentication, conversion history tracking, and premium features for an enhanced user experience.

FEATURES

Core Functionality
- Real-time currency conversion with live exchange rates
- Support for major world currencies including USD, EUR, GBP, JPY, CAD, AUD, CHF, CNY, RWF, and KES
- Intuitive currency selection with flag indicators
- Quick currency swap functionality
- Offline support with cached exchange rates

User Experience
- Clean, modern Material Design 3 interface
- Dark and light theme support
- Responsive design for various screen sizes
- Smooth animations and transitions
- User-friendly navigation with bottom navigation bar

Authentication & Data
- Firebase Authentication for secure user login and registration
- Cloud Firestore for data persistence
- Conversion history tracking and storage
- User profile management
- Secure data synchronization across devices

Premium Features
- Ad-free experience for premium users
- Unlimited currency conversions
- Priority customer support
- Early access to new features
- Enhanced conversion history with detailed analytics

TECHNOLOGY STACK

Frontend
- Flutter 3.8.1 - Cross-platform mobile development framework
- Dart - Programming language
- Material Design 3 - UI/UX framework
- Provider - State management
- Go Router - Navigation and routing

Backend & Services
- Firebase Core - Firebase initialization and configuration
- Firebase Authentication - User authentication and management
- Cloud Firestore - NoSQL cloud database
- HTTP package - API communication for exchange rates

Dependencies
- firebase_core: ^2.31.0
- firebase_auth: ^4.17.4
- cloud_firestore: ^4.15.4
- http: ^1.1.2
- provider: ^6.1.1
- shared_preferences: ^2.2.2
- intl: ^0.18.1
- go_router: ^13.2.0

INSTALLATION

Prerequisites
- Flutter SDK 3.8.1 or higher
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Firebase project setup

Setup Instructions

1. Clone the repository
   git clone https://github.com/muhirwa1mj/mobileAppdevExam2025.git
   cd currencyx

2. Install dependencies
   flutter pub get

3. Firebase Configuration
   - Create a new Firebase project
   - Enable Authentication and Firestore
   - Download google-services.json for Android
   - Configure iOS Firebase settings
   - Update firebase_options.dart with your project settings

4. Run the application
   flutter run

BUILD INSTRUCTIONS

Android
flutter build apk --release

iOS
flutter build ios --release

Web
flutter build web --release

PROJECT STRUCTURE

lib/
- main.dart - Application entry point and theme configuration
- firebase_options.dart - Firebase configuration
- screens/
  - auth_screen.dart - User authentication interface
  - home_screen.dart - Main conversion interface
  - history_screen.dart - Conversion history display
  - settings_screen.dart - User settings and preferences
  - splash_screen.dart - Application splash screen
- services/
  - auth_service.dart - Firebase authentication logic
  - currency_service.dart - Currency conversion and API integration

ARCHITECTURE

The application follows the Provider pattern for state management, ensuring clean separation of concerns and maintainable code structure. Key architectural components include:

- Service Layer: Handles business logic and external API communication
- UI Layer: Presentation components with Material Design 3
- Data Layer: Firebase integration for persistent storage
- Navigation: Go Router for declarative routing

API INTEGRATION

CurrencyX integrates with external currency exchange APIs to provide real-time exchange rates. The application supports multiple currency pairs and implements proper error handling for network failures.

SECURITY

- Firebase Authentication ensures secure user management
- Cloud Firestore rules protect user data
- HTTPS communication for all API calls
- Secure storage of user preferences

PERFORMANCE

- Efficient state management with Provider
- Optimized UI rendering with Flutter widgets
- Cached exchange rates for offline functionality
- Minimal network requests through intelligent caching

TESTING

Run tests with:
flutter test

CONTRIBUTING

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

LICENSE

This project is licensed under the MIT License. See LICENSE file for details.

SUPPORT

For support and questions:
- Create an issue on GitHub
- Contact the development team
- Check the documentation

VERSION HISTORY

Version 1.0.0
- Initial release
- Basic currency conversion functionality
- Firebase authentication
- Conversion history tracking
- Premium features implementation

ACKNOWLEDGMENTS

- Flutter team for the excellent framework
- Firebase for backend services
- Exchange Rate API for currency data
- Material Design team for UI guidelines
