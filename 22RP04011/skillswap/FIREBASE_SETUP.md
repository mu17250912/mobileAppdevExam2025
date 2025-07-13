# Firebase Setup Guide for SkillSwap

## Issues Fixed

1. **Firestore Permission Denied Errors**: Added proper security rules
2. **Authentication Checks**: Added user authentication validation
3. **Error Handling**: Improved error handling across all screens
4. **Performance**: Added timeouts and better state management

## Required Setup Steps

### 1. Deploy Firestore Security Rules

You need to deploy the security rules to fix the permission denied errors. Run these commands in your terminal:

```bash
# Install Firebase CLI if you haven't already
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project (if not already done)
firebase init firestore

# Deploy the security rules
firebase deploy --only firestore:rules
```

### 2. Update Firebase Security Rules

The `firestore.rules` file contains the security rules that allow:
- Authenticated users to read and write their own profile data
- Authenticated users to read other users' profiles for matching
- Authenticated users to access sessions and connections

### 3. Verify Firebase Configuration

Make sure your `google-services.json` file is properly configured and up to date.

### 4. Test the App

After deploying the security rules:
1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter run`

## Error Resolution

### If you still see permission denied errors:

1. **Check Firebase Console**: Go to Firebase Console > Firestore Database > Rules
2. **Verify Rules**: Make sure the rules from `firestore.rules` are deployed
3. **Test Authentication**: Ensure users are properly authenticated before accessing Firestore

### If you see Google Play Services errors:

These are warnings and won't affect the app functionality. They're related to:
- Google Play Services not being available on the test device
- Missing OAuth client configuration (not required for basic functionality)

### Performance Issues:

The app now includes:
- Timeout handling for Firestore operations
- Better error states with retry buttons
- Authentication checks before Firestore operations

## Firebase Security Rules Explanation

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      // Users can read other profiles for matching
      allow read: if request.auth != null;
    }
    
    // Authenticated users can access sessions and connections
    match /sessions/{sessionId} {
      allow read, write: if request.auth != null;
    }
    
    match /connections/{connectionId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Testing

1. **Register a new user** - Should work without errors
2. **Login** - Should navigate to home screen
3. **View Profile** - Should show user data or appropriate error message
4. **Find Partners** - Should show all users or appropriate error message
5. **Schedule Session** - Should work without Firestore errors

## Troubleshooting

If you continue to see errors:

1. **Check Firebase Console** for any configuration issues
2. **Verify the project ID** in `firebase_options.dart` matches your Firebase project
3. **Ensure Firestore is enabled** in your Firebase project
4. **Check authentication** is working properly

## Support

If you need help with Firebase setup, refer to the official Firebase documentation or contact your Firebase project administrator. 