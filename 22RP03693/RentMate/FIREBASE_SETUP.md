# Firebase Setup Guide for RentMate

This guide will help you set up Firebase for the RentMate application.

## Prerequisites

1. A Google account
2. Flutter SDK installed
3. Android Studio or VS Code

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter a project name (e.g., "rentmate-app")
4. Choose whether to enable Google Analytics (optional)
5. Click "Create project"

## Step 2: Add Android App

1. In your Firebase project, click the Android icon to add an Android app
2. Enter your package name: `com.example.mobile_exam_22rp03693`
3. Enter app nickname: "RentMate"
4. Click "Register app"
5. Download the `google-services.json` file
6. Place the `google-services.json` file in the `android/app/` directory

## Step 3: Add iOS App (if needed)

1. In your Firebase project, click the iOS icon to add an iOS app
2. Enter your bundle ID: `com.example.mobileExam22rp03693`
3. Enter app nickname: "RentMate"
4. Click "Register app"
5. Download the `GoogleService-Info.plist` file
6. Place the `GoogleService-Info.plist` file in the `ios/Runner/` directory

## Step 4: Enable Authentication

1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Email/Password" authentication
5. Click "Save"

## Step 5: Set up Firestore Database

1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location for your database
5. Click "Done"

## Step 6: Set up Firestore Security Rules

1. In Firestore Database, go to "Rules" tab
2. Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read and write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Anyone can read properties
    match /properties/{propertyId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Users can read and write their own bookings
    match /bookings/{bookingId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         resource.data.landlordId == request.auth.uid);
    }
    
    // Users can read and write their own payments
    match /payments/{paymentId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
  }
}
```

3. Click "Publish"

## Step 7: Update Firebase Configuration

1. Replace the placeholder values in `lib/firebase_options.dart` with your actual Firebase configuration
2. You can find these values in your Firebase project settings

## Step 8: Install Dependencies

Run the following command to install Firebase dependencies:

```bash
flutter pub get
```

## Step 9: Test the Setup

1. Run the app: `flutter run`
2. Try to register a new user
3. Check if the user appears in Firebase Authentication
4. Check if user data appears in Firestore Database

## Troubleshooting

### Common Issues:

1. **"Firebase not initialized" error**
   - Make sure you've added the `google-services.json` file to `android/app/`
   - Make sure you've updated `firebase_options.dart` with correct values

2. **"Permission denied" error**
   - Check your Firestore security rules
   - Make sure authentication is enabled

3. **"Network error"**
   - Check your internet connection
   - Make sure Firebase project is in the correct region

## Security Notes

- The current security rules allow read access to properties for everyone
- Users can only access their own bookings and payments
- In production, you should implement more restrictive rules based on your requirements

## Next Steps

1. Set up Firebase Storage for image uploads
2. Configure Firebase Analytics
3. Set up Firebase Cloud Messaging for push notifications
4. Implement proper error handling for Firebase operations

## Support

If you encounter issues:
1. Check the Firebase Console for error messages
2. Review the Flutter Firebase documentation
3. Check the Firebase status page for service issues 