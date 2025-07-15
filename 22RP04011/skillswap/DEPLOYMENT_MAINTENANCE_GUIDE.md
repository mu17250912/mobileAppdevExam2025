# SkillSwap Deployment & Maintenance Guide

## Table of Contents
1. [Initial Setup](#initial-setup)
2. [Firebase Configuration](#firebase-configuration)
3. [Development Environment](#development-environment)
4. [Build Process](#build-process)
5. [Deployment Process](#deployment-process)
6. [Monitoring & Analytics](#monitoring--analytics)
7. [Performance Optimization](#performance-optimization)
8. [Security Maintenance](#security-maintenance)
9. [Backup & Recovery](#backup--recovery)
10. [Troubleshooting](#troubleshooting)

---

## Initial Setup

### Prerequisites Installation

#### 1. Development Tools
```bash
# Install Flutter SDK
git clone https://github.com/flutter/flutter.git
export PATH="$PATH:`pwd`/flutter/bin"

# Verify Flutter installation
flutter doctor

# Install Android Studio or VS Code
# Install Flutter and Dart extensions

# Install Firebase CLI
npm install -g firebase-tools

# Install Git
# Download from https://git-scm.com/
```

#### 2. Platform-Specific Setup

##### Android Setup
```bash
# Install Android SDK
# Download Android Studio and install SDK

# Set ANDROID_HOME environment variable
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# Accept Android licenses
flutter doctor --android-licenses
```

##### iOS Setup (macOS only)
```bash
# Install Xcode from App Store
# Install Xcode Command Line Tools
xcode-select --install

# Accept Xcode licenses
sudo xcodebuild -license accept
```

### Project Setup

#### 1. Clone Repository
```bash
# Clone the project
git clone https://github.com/your-username/skillswap.git
cd skillswap

# Install dependencies
flutter pub get
```

#### 2. Environment Configuration
```bash
# Create environment configuration
cp .env.example .env

# Edit environment variables
nano .env
```

#### 3. Firebase Project Setup
```bash
# Login to Firebase
firebase login

# Initialize Firebase project
firebase init

# Select services:
# - Firestore
# - Storage
# - Functions (optional)
# - Hosting (optional)
```

---

## Firebase Configuration

### Firebase Project Creation

#### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: "skillswap"
4. Enable Google Analytics (recommended)
5. Choose analytics account or create new
6. Click "Create project"

#### 2. Add Firebase to Flutter App
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your app
flutterfire configure

# Select your Firebase project
# Choose platforms (Android, iOS, Web)
```

### Firebase Services Configuration

#### 1. Authentication Setup
```javascript
// Firebase Console > Authentication > Sign-in method
// Enable providers:
// - Email/Password
// - Google Sign-in
// - Phone (optional)

// Configure OAuth consent screen for Google Sign-in
// Add authorized domains
```

#### 2. Firestore Database Setup
```javascript
// Firebase Console > Firestore Database
// Create database in production mode
// Choose location closest to your users

// Security rules (firestore.rules)
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Your security rules here
  }
}
```

#### 3. Storage Setup
```javascript
// Firebase Console > Storage
// Create storage bucket
// Choose location

// Security rules (storage.rules)
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }
  }
}
```

#### 4. Cloud Messaging Setup
```javascript
// Firebase Console > Cloud Messaging
// Generate server key for push notifications
// Configure Android and iOS apps
```

### Firebase Configuration Files

#### 1. Android Configuration
```xml
<!-- android/app/google-services.json -->
<!-- Download from Firebase Console > Project Settings > Your Apps -->
```

#### 2. iOS Configuration
```xml
<!-- ios/Runner/GoogleService-Info.plist -->
<!-- Download from Firebase Console > Project Settings > Your Apps -->
```

#### 3. Web Configuration
```javascript
// web/index.html
// Add Firebase SDK scripts
```

---

## Development Environment

### IDE Configuration

#### 1. VS Code Setup
```json
// .vscode/settings.json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.lineLength": 80,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  }
}
```

#### 2. Android Studio Setup
```xml
<!-- .idea/codeStyles/Project.xml -->
<!-- Configure code style settings -->
```

### Development Workflow

#### 1. Git Workflow
```bash
# Create feature branch
git checkout -b feature/new-feature

# Make changes and commit
git add .
git commit -m "Add new feature"

# Push to remote
git push origin feature/new-feature

# Create pull request
# Merge after review
```

#### 2. Code Quality Tools
```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - avoid_empty_else
    - avoid_print
    - prefer_const_constructors
    - prefer_final_fields
    - prefer_single_quotes
```

#### 3. Testing Setup
```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run with coverage
flutter test --coverage
```

---

## Build Process

### Build Configuration

#### 1. Android Build Configuration
```gradle
// android/app/build.gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.example.skillswap"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
        
        // Enable multidex
        multiDexEnabled true
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    
    // Enable R8 optimization
    buildTypes {
        release {
            minifyEnabled true
            useProguard false
        }
    }
}
```

#### 2. iOS Build Configuration
```xml
<!-- ios/Runner/Info.plist -->
<key>CFBundleDisplayName</key>
<string>SkillSwap</string>
<key>CFBundleVersion</key>
<string>1.0.0</string>
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take profile pictures</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select profile pictures</string>
```

### Build Commands

#### 1. Development Builds
```bash
# Debug build for testing
flutter build apk --debug

# Profile build for performance testing
flutter build apk --profile

# Debug build for iOS
flutter build ios --debug
```

#### 2. Production Builds
```bash
# Android APK
flutter build apk --release

# Android App Bundle (recommended for Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release
```

#### 3. Web Build
```bash
# Web build
flutter build web --release

# Web build with base href
flutter build web --release --base-href "/skillswap/"
```

### Build Optimization

#### 1. Code Optimization
```dart
// Enable tree shaking
// Use const constructors where possible
// Minimize widget rebuilds
// Use proper state management
```

#### 2. Asset Optimization
```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
  
  fonts:
    - family: CustomFont
      fonts:
        - asset: assets/fonts/CustomFont-Regular.ttf
        - asset: assets/fonts/CustomFont-Bold.ttf
          weight: 700
```

#### 3. Performance Optimization
```dart
// Use const widgets
// Implement proper caching
// Optimize images
// Minimize network requests
```

---

## Deployment Process

### Firebase Deployment

#### 1. Deploy Security Rules
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage

# Deploy all rules
firebase deploy --only firestore:rules,storage
```

#### 2. Deploy Functions (if applicable)
```bash
# Deploy Cloud Functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:functionName
```

#### 3. Deploy Hosting (if applicable)
```bash
# Deploy web app to Firebase Hosting
firebase deploy --only hosting

# Deploy to specific site
firebase deploy --only hosting:siteName
```

### App Store Deployment

#### 1. Google Play Store

##### Prepare Release
```bash
# Build app bundle
flutter build appbundle --release

# Sign the bundle (if not using upload signing)
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
  -keystore ~/upload-keystore.jks \
  build/app/outputs/bundle/release/app-release.aab \
  upload
```

##### Upload to Play Console
1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Go to "Release" > "Production"
4. Create new release
5. Upload the AAB file
6. Add release notes
7. Review and roll out

#### 2. Apple App Store

##### Prepare Release
```bash
# Build iOS app
flutter build ios --release

# Open in Xcode
open ios/Runner.xcworkspace
```

##### Archive and Upload
1. In Xcode, select "Any iOS Device" as target
2. Go to Product > Archive
3. Click "Distribute App"
4. Select "App Store Connect"
5. Choose "Upload"
6. Follow the upload process

##### Submit for Review
1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Select your app
3. Go to "App Store" > "Prepare for Submission"
4. Fill in app information
5. Upload screenshots and metadata
6. Submit for review

### Continuous Deployment

#### 1. GitHub Actions Setup
```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Run tests
      run: flutter test
    
    - name: Build APK
      run: flutter build apk --release
    
    - name: Upload APK
      uses: actions/upload-artifact@v2
      with:
        name: app-release
        path: build/app/outputs/flutter-apk/app-release.apk
```

#### 2. Firebase CI/CD
```yaml
# firebase.json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ]
  }
}
```

---

## Monitoring & Analytics

### Firebase Analytics

#### 1. Analytics Setup
```dart
// lib/services/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  static Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }
  
  static Future<void> setUserProperties({
    required String userId,
    required String userType,
  }) async {
    await _analytics.setUserId(id: userId);
    await _analytics.setUserProperty(name: 'user_type', value: userType);
  }
}
```

#### 2. Custom Events
```dart
// Track user actions
await AnalyticsService.logEvent(
  name: 'skill_added',
  parameters: {
    'skill_name': skillName,
    'category': category,
    'difficulty': difficulty,
  },
);

await AnalyticsService.logEvent(
  name: 'session_requested',
  parameters: {
    'skill_id': skillId,
    'partner_id': partnerId,
    'session_type': sessionType,
  },
);
```

### Performance Monitoring

#### 1. Firebase Performance
```dart
// lib/services/performance_service.dart
import 'package:firebase_performance/firebase_performance.dart';

class PerformanceService {
  static final FirebasePerformance _performance = FirebasePerformance.instance;
  
  static Future<void> startTrace(String traceName) async {
    final trace = _performance.newTrace(traceName);
    await trace.start();
    return trace;
  }
  
  static Future<void> stopTrace(Trace trace) async {
    await trace.stop();
  }
}
```

#### 2. Custom Traces
```dart
// Monitor app performance
final trace = await PerformanceService.startTrace('app_startup');
// ... app initialization code
await PerformanceService.stopTrace(trace);

// Monitor network requests
final networkTrace = await PerformanceService.startTrace('api_request');
// ... API call
await PerformanceService.stopTrace(networkTrace);
```

### Error Monitoring

#### 1. Crashlytics Setup
```dart
// lib/services/error_service.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class ErrorService {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  
  static Future<void> initialize() async {
    // Enable crash reporting
    FlutterError.onError = _crashlytics.recordFlutterError;
    
    // Enable native crash reporting
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }
  
  static Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(error, stackTrace, fatal: fatal);
  }
}
```

#### 2. Custom Error Logging
```dart
// Log custom errors
try {
  // Risky operation
} catch (e, stackTrace) {
  await ErrorService.logError(e, stackTrace);
  // Handle error gracefully
}
```

---

## Performance Optimization

### Database Optimization

#### 1. Query Optimization
```dart
// Use proper indexes
// Limit query results
// Use pagination
// Cache frequently accessed data

static Future<List<Skill>> getSkillsByCategory(String category) async {
  final querySnapshot = await _firestore
      .collection('skills')
      .where('category', isEqualTo: category)
      .where('isActive', isEqualTo: true)
      .orderBy('rating', descending: true)
      .limit(20) // Limit results
      .get();
  
  return querySnapshot.docs.map((doc) => Skill.fromFirestore(doc)).toList();
}
```

#### 2. Index Management
```json
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "skills",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "rating", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "sessions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

### App Performance

#### 1. Widget Optimization
```dart
// Use const constructors
const SkillCard({required this.skill});

// Minimize rebuilds
class OptimizedWidget extends StatelessWidget {
  final String data;
  
  const OptimizedWidget({required this.data});
  
  @override
  Widget build(BuildContext context) {
    return Text(data); // Only rebuilds when data changes
  }
}
```

#### 2. Image Optimization
```dart
// Use cached network images
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  fit: BoxFit.cover,
  width: 100,
  height: 100,
)
```

#### 3. Memory Management
```dart
// Proper disposal of controllers
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late ScrollController _scrollController;
  late StreamSubscription _subscription;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _subscription = stream.listen((data) {
      // Handle data
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    _subscription.cancel();
    super.dispose();
  }
}
```

---

## Security Maintenance

### Security Audits

#### 1. Dependency Security
```bash
# Check for security vulnerabilities
flutter pub deps

# Update dependencies regularly
flutter pub upgrade

# Use security scanning tools
# - Snyk
# - GitHub Security Advisories
# - npm audit (for Node.js dependencies)
```

#### 2. Code Security
```dart
// Input validation
String sanitizeInput(String input) {
  return input.trim().replaceAll(RegExp(r'[<>]'), '');
}

// Secure data storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
await storage.write(key: 'api_key', value: apiKey);
```

#### 3. Firebase Security
```javascript
// Regular security rule reviews
// Monitor access patterns
// Update rules as needed
// Test security rules thoroughly
```

### Access Control

#### 1. User Authentication
```dart
// Verify user authentication
Future<bool> isUserAuthenticated() async {
  final user = FirebaseAuth.instance.currentUser;
  return user != null;
}

// Check user permissions
Future<bool> hasPermission(String permission) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  
  final permissions = userDoc.data()?['permissions'] ?? [];
  return permissions.contains(permission);
}
```

#### 2. Data Access Control
```dart
// Validate data ownership
Future<bool> canAccessData(String dataId, String userId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  
  // Check if user owns the data or has permission
  return user.uid == userId || await hasPermission('admin');
}
```

---

## Backup & Recovery

### Data Backup

#### 1. Firestore Backup
```bash
# Export Firestore data
gcloud firestore export gs://your-backup-bucket/skillswap-backup

# Import Firestore data
gcloud firestore import gs://your-backup-bucket/skillswap-backup
```

#### 2. Storage Backup
```bash
# Backup Firebase Storage
gsutil -m cp -r gs://your-project-id.appspot.com gs://your-backup-bucket/storage-backup

# Restore Firebase Storage
gsutil -m cp -r gs://your-backup-bucket/storage-backup gs://your-project-id.appspot.com
```

#### 3. Configuration Backup
```bash
# Backup configuration files
tar -czf config-backup.tar.gz \
  firebase.json \
  firestore.rules \
  firestore.indexes.json \
  storage.rules \
  .env
```

### Recovery Procedures

#### 1. Data Recovery
```bash
# Restore Firestore data
gcloud firestore import gs://your-backup-bucket/skillswap-backup

# Restore Storage data
gsutil -m cp -r gs://your-backup-bucket/storage-backup gs://your-project-id.appspot.com
```

#### 2. App Recovery
```bash
# Rollback to previous version
git checkout previous-version-tag
flutter build apk --release
flutter build appbundle --release
```

#### 3. Configuration Recovery
```bash
# Restore configuration
tar -xzf config-backup.tar.gz
firebase deploy --only firestore:rules,storage
```

---

## Troubleshooting

### Common Issues

#### 1. Build Issues
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release

# Check Flutter doctor
flutter doctor

# Update Flutter
flutter upgrade
```

#### 2. Firebase Issues
```bash
# Check Firebase CLI
firebase --version

# Re-login to Firebase
firebase logout
firebase login

# Check project configuration
firebase projects:list
firebase use your-project-id
```

#### 3. Permission Issues
```bash
# Check file permissions
chmod +x android/gradlew

# Check Android SDK permissions
flutter doctor --android-licenses
```

### Debug Tools

#### 1. Flutter Inspector
```bash
# Enable Flutter Inspector
flutter run --debug

# Use Flutter Inspector in IDE
# - VS Code: Flutter Inspector extension
# - Android Studio: Flutter Inspector tool
```

#### 2. Firebase Console
- **Firestore**: Monitor database operations
- **Authentication**: Monitor user authentication
- **Storage**: Monitor file uploads/downloads
- **Analytics**: Monitor user behavior
- **Crashlytics**: Monitor app crashes

#### 3. Performance Monitoring
```dart
// Enable performance monitoring
FirebasePerformance.instance.setPerformanceCollectionEnabled(true);

// Monitor specific operations
final trace = FirebasePerformance.instance.newTrace('custom_trace');
await trace.start();
// ... operation
await trace.stop();
```

### Error Resolution

#### 1. Common Error Messages
```dart
// Permission denied error
if (e.code == 'permission-denied') {
  // Check Firebase security rules
  // Verify user authentication
  // Check data ownership
}

// Network error
if (e.code == 'network-request-failed') {
  // Check internet connection
  // Retry with exponential backoff
  // Show offline mode
}

// Quota exceeded error
if (e.code == 'quota-exceeded') {
  // Implement rate limiting
  // Use caching
  // Optimize queries
}
```

#### 2. Debug Logging
```dart
// Enable debug logging
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable debug mode
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Enable debug logging
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  runApp(const SkillSwapApp());
}
```

---

## Conclusion

This deployment and maintenance guide provides comprehensive instructions for deploying and maintaining the SkillSwap app. Key points to remember:

### Deployment Checklist
- [ ] Firebase project configured
- [ ] Security rules deployed
- [ ] App built and tested
- [ ] App store deployment completed
- [ ] Monitoring tools configured

### Maintenance Schedule
- **Daily**: Monitor app performance and errors
- **Weekly**: Review analytics and user feedback
- **Monthly**: Update dependencies and security patches
- **Quarterly**: Performance optimization and feature updates

### Best Practices
- **Automation**: Use CI/CD pipelines for deployment
- **Monitoring**: Implement comprehensive monitoring
- **Backup**: Regular data and configuration backups
- **Security**: Regular security audits and updates
- **Documentation**: Keep documentation updated

Following this guide ensures a robust, secure, and maintainable SkillSwap application that provides an excellent user experience while being easy to manage and update. 