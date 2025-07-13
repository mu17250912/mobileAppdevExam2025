# Firebase Setup Guide for Ireme Girl Safe

This guide will help you set up Firebase for the Ireme Girl Safe app.

## 🔥 Firebase Project Setup

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `ireme-girl-safe`
4. Enable Google Analytics (recommended)
5. Choose your Analytics account or create a new one
6. Click "Create project"

### 2. Add Apps to Firebase Project

#### Android App
1. In Firebase Console, click "Add app" → "Android"
2. Package name: `com.example.safegirl`
3. App nickname: `Ireme Girl Safe Android`
4. Download `google-services.json` and replace the placeholder file in `android/app/`

#### iOS App
1. In Firebase Console, click "Add app" → "iOS"
2. Bundle ID: `com.example.safegirl`
3. App nickname: `GirlSafe iOS`
4. Download `GoogleService-Info.plist` and replace the placeholder file in `ios/Runner/`

#### Web App
1. In Firebase Console, click "Add app" → "Web"
2. App nickname: `GirlSafe Web`
3. Copy the Firebase config and update `web/firebase-config.js`

### 3. Enable Firebase Services

#### Authentication
1. Go to Authentication → Sign-in method
2. Enable "Email/Password"
3. Configure additional providers if needed (Google, Facebook, etc.)

#### Firestore Database
1. Go to Firestore Database
2. Click "Create database"
3. Choose "Start in test mode" for development
4. Select a location close to your users

#### Storage
1. Go to Storage
2. Click "Get started"
3. Choose "Start in test mode" for development
4. Select a location

#### Cloud Messaging
1. Go to Project Settings → Cloud Messaging
2. Note the Sender ID for FCM configuration

### 4. Security Rules

#### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public articles and videos
    match /articles/{articleId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
    
    match /videos/{videoId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
    
    // Chat messages
    match /chat_messages/{messageId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         resource.data.counselorId == request.auth.uid);
    }
    
    // Reminders
    match /reminders/{reminderId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
  }
}
```

#### Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /public/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
  }
}
```

### 5. Update Configuration Files

#### Replace Placeholder Values
1. **Android**: Update `android/app/google-services.json` with your actual Firebase config
2. **iOS**: Update `ios/Runner/GoogleService-Info.plist` with your actual Firebase config
3. **Web**: Update `web/firebase-config.js` with your actual Firebase config

#### Example Configuration Values
```javascript
// Replace these with your actual Firebase project values
const firebaseConfig = {
  apiKey: "your-actual-api-key",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "your-sender-id",
  appId: "your-app-id",
  measurementId: "your-measurement-id"
};
```

### 6. Test Firebase Integration

#### Test Authentication
1. Run the app
2. Try to register a new account
3. Try to login with the created account
4. Check Firebase Console → Authentication → Users

#### Test Firestore
1. Navigate to Info Hub in the app
2. Check if articles/videos load from Firestore
3. Check Firebase Console → Firestore Database

#### Test Storage
1. Try uploading a file (if implemented)
2. Check Firebase Console → Storage

#### Test Analytics
1. Use the app for a few minutes
2. Check Firebase Console → Analytics

### 7. Production Setup

#### Security Rules
1. Update Firestore rules for production
2. Update Storage rules for production
3. Enable proper authentication methods

#### Environment Variables
1. Store sensitive config in environment variables
2. Use different Firebase projects for dev/staging/prod

#### Monitoring
1. Set up Firebase Crashlytics
2. Configure Performance Monitoring
3. Set up alerts and notifications

## 🚀 Deployment Checklist

- [ ] Firebase project created
- [ ] All apps added to Firebase project
- [ ] Authentication enabled
- [ ] Firestore database created
- [ ] Storage bucket created
- [ ] Security rules configured
- [ ] Configuration files updated
- [ ] All services tested
- [ ] Production environment configured

## 📱 Platform-Specific Setup

### Android
- Google Services plugin added to build.gradle
- google-services.json in app directory
- Firebase dependencies added

### iOS
- GoogleService-Info.plist in Runner directory
- Firebase pods will be added automatically

### Web
- Firebase SDK scripts in index.html
- firebase-config.js with proper configuration

## 🔧 Troubleshooting

### Common Issues
1. **Authentication not working**: Check if Email/Password is enabled in Firebase Console
2. **Database access denied**: Check Firestore security rules
3. **Storage upload failed**: Check Storage security rules
4. **Analytics not showing**: Wait 24-48 hours for data to appear

### Debug Tips
1. Check Firebase Console logs
2. Use Firebase CLI for local testing
3. Enable debug mode in Firebase services
4. Check network connectivity

## 📞 Support

For Firebase-specific issues:
- [Firebase Documentation](https://firebase.google.com/docs)
- [Firebase Support](https://firebase.google.com/support)
- [Flutter Firebase Plugin](https://firebase.flutter.dev/)

For app-specific issues:
- Check the app logs
- Review the service implementations
- Test with Firebase Emulator Suite 