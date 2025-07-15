# RwandaQuickRide

**Student Registration Number:** 22RP02673

## App Name
RwandaQuickRide

## Brief Description
RwandaQuickRide is a ride-hailing app designed for Rwanda, connecting passengers with drivers for safe, affordable, and convenient transportation. The app supports real-time ride requests, driver management, trip history, earnings summary, notifications, and in-app chat.

## Problem Solved
The app addresses the challenge of finding reliable, safe, and affordable transportation in Rwanda. It streamlines the process of booking rides, improves driver-passenger communication, and provides transparency in trip history and earnings.

## Monetization Strategy
- **AdMob Integration:** Banner ads and rewarded interstitial ads are shown to users.
- **Premium Features:** Users can subscribe for premium features such as priority matching, ad-free experience, and advanced analytics.

## Key Features Implemented
- Driver and passenger registration and login
- Real-time ride requests and trip management
- Driver availability toggling
- Trip history and earnings summary for drivers
- Profile management and notifications
- WhatsApp chat integration between drivers and passengers
- Google AdMob banner and rewarded interstitial ads
- Premium feature support (priority, ad-free, etc.)
- Robust error handling and Firestore data consistency

## Installation and Running the APK
1. **Clone the repository:**
   ```
   git clone [https://github.com/charlybizima/mobileAppdevExam2025.git]
   cd ride
   ```
2. **Install dependencies:**
   ```
   flutter pub get
   ```
3. **Run the app (development):**
   ```
   flutter run -d chrome
   ```
4. **Build the APK:**
   ```
   flutter build apk --release
   ```
5. **Install the APK on your device:**
   - Transfer the generated APK from `build/app/outputs/flutter-apk/app-release.apk` to your Android device and install it.

## Scalability, Sustainability, and Security Overview
- **Scalability:**
  - Uses Google Firestore, which scales automatically with user growth.
  - Modular codebase allows for easy addition of new features and microservices.
- **Sustainability:**
  - Monetization through ads and premium features ensures ongoing revenue.
  - Cloud-based infrastructure reduces maintenance overhead.
- **Security:**
  - Firebase Authentication secures user accounts.
  - Firestore security rules restrict data access to authorized users.
  - Sensitive operations (e.g., payments, profile updates) are validated both client- and server-side.


