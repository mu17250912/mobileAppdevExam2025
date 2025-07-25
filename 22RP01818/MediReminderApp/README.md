# Mediremind

## App Name: Mediremind  
**Student Registration Number:** 22RP01818

---

## 1. Problem Statement & Market Fit

**Problem:**  
Many people, especially the elderly and those with chronic illnesses, forget to take their medication on time, leading to health complications. Mediremind solves this by providing reliable, customizable reminders and medication tracking.

**Target Audience:**  
- Elderly individuals
- Patients with chronic illnesses
- Caregivers
- Busy professionals

**Unique Selling Proposition:**  
- Simple, intuitive interface
- Customizable reminders
- Medication tracking
- Freemium model (premium features: analytics, export, ad-free)
- Accessibility and offline support

---

## 2. App Overview & Core Features

- **Cross-platform Flutter app** (Android, iOS, Web)
- **Authentication:** Secure email/password sign-up and sign-in (Firebase Auth)
- **Profile Management:** View and upgrade to premium
- **Medication Management:** Add, edit, delete medications
- **Reminders & Notifications:** Customizable, with snooze and mark-as-read
- **Snoozed Notifications:** Access via notification icon, manage snoozed reminders
- **Premium Upgrade:** Simulated payment for unlocking advanced features
- **Offline Support:** Core features work without internet

---

## 3. Monetization & Analytics

- **Freemium Model:**  
  - Free: Basic reminders and tracking  
  - Premium: Advanced analytics, export, ad-free
- **AdMob Integration:** Ads for free users (not on web)
- **Simulated Payment:** For premium upgrade (no real transactions)
- **Analytics:**  
  - Tracks sign-ups, feature usage, premium upgrades, and more (Firebase Analytics)
  - Events are logged in code (see `profile_screen.dart`, `my_meds_screen.dart`)

---

## 4. Security & Reliability

- **Authentication:** Firebase Auth
- **Data Privacy:** No sensitive data shared with third parties
- **Compliance:** GDPR/local awareness
- **Reliability:**  
  - Tested on multiple devices
  - Error handling and crash reporting (Firebase Crashlytics)
  - Widget and integration tests

---

## 5. Installation & Usage

### To Install the APK:
1. Download the APK from the provided link or `22RP01818_AppFiles.zip`.
2. Transfer to your Android device.
3. Enable installation from unknown sources.
4. Tap the APK to install and open the app.

### To Run from Source:
1. Clone the repository and open in VS Code or Android Studio.
2. Run `flutter pub get` to install dependencies.
3. Add your Firebase config files (`google-services.json` for Android, `GoogleService-Info.plist` for iOS).
4. Connect a device or start an emulator.
5. Run `flutter run`.

---

## 6. How the App Works

- **Welcome Screen:** Choose to log in or register.
- **Login/Register:** Secure authentication with Firebase.
- **Home Screen:**  
  - See app overview and premium status.
  - Notification icon in the top-right shows snoozed reminders (with badge if unread).
- **My Meds:**  
  - Add, edit, or delete medications.
  - Tap a medication to see and manage reminders.
- **Reminders:**  
  - Get notified when it’s time to take medication.
  - Snooze or mark reminders as read.
- **Snoozed Notifications:**  
  - Access via notification icon.
  - Mark as read or delete notifications (deletes from database).
- **Profile:**  
  - View user info.
  - Upgrade to premium (simulated payment).
  - Logout.

---

## 7. Scalability & Sustainability

- Modular, maintainable codebase
- Designed for easy feature addition and scaling
- Focus on user privacy and secure data handling
- Regular updates and user engagement strategies

---

## 8. Simulated Payment Gateway

- Premium upgrade uses a simulated payment screen (no real transactions).
- Clearly labeled in UI and code.

---

## 9. Contact

- Student Registration Number: 22RP01818
- For any issues, contact: gislmusabyemariya@gmail.com



