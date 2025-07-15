# eSoma Library

**Student Registration Number:** 22RP02601

## App Name
**eSoma Library**

## Brief Description
A mobile application for students and the community to discover, read, and buy books online. eSoma Library provides easy access to a wide range of books, supports borrowing, favorites, and offers premium features via subscription.

## Problem Statement
Many students and community members lack easy access to quality educational and leisure books. eSoma Library solves this by providing a digital platform to read and purchase books anytime, anywhere.

## Unique Selling Proposition (USP)
- Localized content for the community
- Affordable subscription model
- Easy-to-use interface and fast search
- Integrated notifications and favorites

## Target Audience
- Students
- General public interested in reading and buying books online

## Monetization Strategy
- **Subscription Model:** Users can subscribe for premium access (simulated MoMo payment). Free users can browse and read a limited number of books; subscribers get unlimited access and premium features.

## Key Features
- Email/password registration and login (Firebase Auth)
- Browse, search, and read books from Firestore
- Add/remove favorites
- Borrowed books tracking
- Notifications for new books and updates
- Subscription screen with simulated payment
- Responsive and accessible UI

## APK/AAB Install Instructions
1. Download the provided `.apk` or `.aab` file from the submission zip.
2. For APK: Transfer to your Android device and install (enable "Install from unknown sources").
3. For AAB: Use Google Play Console or bundletool to install on a device.

## Scalability & Performance
- Modular code structure for easy feature expansion
- Efficient Firestore queries and client-side filtering for performance
- Lazy loading for book lists
- Optimized image loading

## Sustainability Plan
- Regular updates based on user feedback
- Push notifications for engagement
- Referral and loyalty programs to reduce customer acquisition cost
- Plans for organic growth via social sharing and community partnerships

## Security & Privacy
- Secure authentication using Firebase Auth
- Firestore rules restrict access to authenticated users (see below)
- No sensitive data stored on device or in code
- Awareness of GDPR/local data protection

## Analytics & Tracking
- (Optional) Integrate Firebase Analytics (see below for setup)
- Track events such as book borrow, subscription start, and favorites

## Testing & Reliability
- Tested on multiple Android emulators and real devices
- Responsive design for various screen sizes
- Manual and widget tests included in `/test`

## Firestore Security Rules (Example)
```
service cloud.firestore {
  match /databases/{database}/documents {
    match /Categories/{book} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == 'ADMIN_UID';
    }
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    // Add further rules as needed
  }
}
```

## Firebase Analytics Integration (Optional)
1. Add `firebase_analytics` to `pubspec.yaml`.
2. Initialize in `main.dart`:
   ```dart
   import 'package:firebase_analytics/firebase_analytics.dart';
   FirebaseAnalytics analytics = FirebaseAnalytics.instance;
   ```
3. Log events, e.g. when a book is borrowed:
   ```dart
   analytics.logEvent(name: 'borrow_book', parameters: {'book_title': book['title']});
   ```



