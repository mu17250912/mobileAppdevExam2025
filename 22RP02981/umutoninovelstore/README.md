# 📚 Umutoni Novels Store

A modern Flutter mobile application for the UMUTONI NOVELS STORE assessment project. This app provides a comprehensive digital platform for browsing, managing, and accessing novels with Firebase backend integration.

## 🎯 Features

### 🔐 Authentication
- **Google Sign-In**: Seamless authentication using Google accounts
- **Firebase Auth**: Secure user authentication and session management
- **Profile Management**: Update display name and profile picture

### 📖 Novel Management
- **Browse Novels**: View available novels with cover images and details
- **Novel Categories**: Organized by genres (Crime, Romance, etc.)
- **Search & Filter**: Find novels quickly with search functionality
- **Novel Details**: Comprehensive information about each novel

### 🎨 User Interface
- **Modern Design**: Clean, intuitive Material Design interface
- **Dark Green Theme**: Consistent branding with #145A32 color scheme
- **Responsive Layout**: Optimized for various screen sizes
- **Custom App Icon**: Professional book-themed launcher icon

### 🔧 Technical Features
- **Firebase Integration**: Cloud Firestore for data storage
- **Image Storage**: Firebase Storage for novel covers and profile pictures
- **Cross-Platform**: Support for Android, iOS, Web, Windows, and macOS
- **State Management**: Provider pattern for efficient state management

## 📱 Screenshots

*Screenshots will be added here showing the app's interface*

## 🛠️ Technology Stack

- **Framework**: Flutter 3.32.2
- **Language**: Dart
- **Backend**: Firebase
  - Authentication
  - Cloud Firestore
  - Storage
- **State Management**: Provider
- **UI**: Material Design
- **Platforms**: Android, iOS, Web, Windows, macOS

## 📋 Prerequisites

Before running this project, make sure you have:

- **Flutter SDK**: Version 3.32.2 or higher
- **Dart SDK**: Compatible with Flutter version
- **Android Studio**: For Android development
- **Xcode**: For iOS development (macOS only)
- **Firebase Project**: Configured with Authentication, Firestore, and Storage
- **Google Services**: `google-services.json` for Android

## 🚀 Installation & Setup

### 1. Clone the Repository
```bash
git clone <repository-url>
cd 22RP02981
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Configuration

#### Android Setup
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/`
3. Ensure Firebase project is configured with:
   - Authentication (Google Sign-In enabled)
   - Cloud Firestore database
   - Storage bucket

#### iOS Setup (if developing for iOS)
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place it in `ios/Runner/`
3. Add to Xcode project

### 4. Run the Application

#### Development Mode
```bash
flutter run
```

#### Build Release APK
```bash
flutter build apk --release
```

#### Build for Other Platforms
```bash
# iOS
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/                  # UI screens
│   ├── login_screen.dart     # Authentication screen
│   ├── home_screen.dart      # Main dashboard
│   ├── profile_screen.dart   # User profile management
│   └── novel_details_screen.dart # Novel information
├── models/                   # Data models
├── services/                 # Business logic
├── widgets/                  # Reusable UI components
└── utils/                    # Utility functions

assets/
├── images/                   # App images and novel covers
└── icon.png                  # App launcher icon

android/                      # Android-specific configuration
ios/                         # iOS-specific configuration
web/                         # Web-specific configuration
```

## 🔧 Configuration

### App Icon
The app uses a custom launcher icon generated with `flutter_launcher_icons`:
- **Icon Path**: `assets/icon.png`
- **Theme Color**: #145A32 (Dark Green)
- **Background Color**: #145A32

### Firebase Configuration
- **Authentication**: Google Sign-In enabled
- **Firestore**: Collections for novels and user data
- **Storage**: Bucket for profile pictures and novel covers

## 📊 Dependencies

### Core Dependencies
- `flutter`: UI framework
- `provider`: State management
- `firebase_core`: Firebase initialization
- `firebase_auth`: User authentication
- `cloud_firestore`: Database operations
- `firebase_storage`: File storage
- `google_sign_in`: Google authentication
- `image_picker`: Image selection
- `shared_preferences`: Local storage
- `http`: Network requests
- `url_launcher`: External link handling

### Development Dependencies
- `flutter_test`: Testing framework
- `flutter_lints`: Code linting
- `flutter_launcher_icons`: App icon generation

## 🧪 Testing

Run tests with:
```bash
flutter test
```

## 📦 Building for Production

### Android APK
```bash
flutter build apk --release
```
The APK will be generated at: `build/app/outputs/flutter-apk/app-release.apk`

### App Bundle (Recommended for Play Store)
```bash
flutter build appbundle --release
```

## 🔒 Security Considerations

- Firebase Security Rules configured for data protection
- User authentication required for profile features
- Secure file upload with Firebase Storage
- Input validation and sanitization

## 🐛 Troubleshooting

### Common Issues

1. **Firebase Configuration**
   - Ensure `google-services.json` is properly placed
   - Verify Firebase project settings
   - Check Authentication providers are enabled

2. **Build Issues**
   - Run `flutter clean` and `flutter pub get`
   - Ensure all dependencies are compatible
   - Check Android SDK and NDK versions

3. **Authentication Issues**
   - Verify Google Sign-In is enabled in Firebase Console
   - Check SHA-1 fingerprint for Android
   - Ensure proper OAuth configuration

## 📄 License

This project is created for educational assessment purposes.

## 👨‍💻 Developer

**Project**: UMUTONI NOVELS STORE Assessment  
**Student ID**: 22RP02981  
**Framework**: Flutter  
**Backend**: Firebase

## 🔄 Version History

- **v1.0.0**: Initial release with core features
  - User authentication
  - Novel browsing
  - Profile management
  - Firebase integration
  - Custom app icon

---

*This README will be updated as the project evolves with new features and improvements.* 
