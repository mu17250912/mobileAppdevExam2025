# GoalTracker

**Student Registration Number:** 22RP01605

## App Name
**GoalTracker**

## Brief Description
GoalTracker is a modern, user-friendly mobile app designed to help users set, track, and achieve their personal and professional goals. The app provides a visually appealing and customizable experience, allowing users to monitor their progress, receive motivational insights, and upgrade to premium features for enhanced productivity.

## Problem Solved
Many individuals struggle to stay organized and motivated when pursuing their goals. GoalTracker addresses this by providing a structured platform for goal management, progress tracking, and motivational support, making it easier for users to achieve their ambitions and build productive habits.

## Monetization Strategy
- **Freemium Model:** Users can use the app for free with a limit of 3 active goals.
- **Premium Upgrade:** Users can upgrade to a premium account via mobile payment (MTN/Airtel) to unlock unlimited goals and additional features.
- **Ad Integration:** Banner ads are displayed for free users, providing an additional revenue stream.

## Key Features Implemented
- **User Authentication:** Secure sign-up, sign-in, and email verification.
- **Profile Management:** Edit profile, track XP, referral system, and premium status.
- **Goal Management:** Add, edit, delete, and track goals and subgoals with deadlines.
- **Analytics Dashboard:** Visual analytics for completed, in-progress, and canceled goals, with progress charts and motivational insights.
- **Motivational Quotes:** Daily motivational notifications and quotes.
- **Customizable Themes:** Users can choose from Elegant Purple, Modern Blue, or Fresh Green templates, with real-time theming across the app.
- **Mobile Payments:** Integrated payment system for premium upgrades, with real-time status tracking and troubleshooting.
- **Ad Support:** Banner ads for monetization (removable with premium upgrade).
- **Responsive UI:** Consistent, accessible, and visually appealing design across all screens.

## Installation & Running the APK
1. **Clone the Repository:**
   ```
   git clone <your-repo-url>
   ```
2. **Open in Android Studio or VS Code.**
3. **Install Dependencies:**
   ```
   flutter pub get
   ```
4. **Run on Emulator or Device:**
   ```
   flutter run
   ```
5. **Build APK:**
   ```
   flutter build apk --release
   ```
6. **Install APK on Device:**
   - Transfer the APK from `build/app/outputs/flutter-apk/app-release.apk` to your Android device and open it to install.

## Scalability, Sustainability, and Security Considerations
- **Scalability:**
  - Uses Firebase for authentication and Firestore for scalable, real-time data storage.
  - Modular codebase and service-oriented architecture for easy feature expansion.
- **Sustainability:**
  - Freemium and ad-based monetization ensure ongoing revenue.
  - Clean, maintainable code and documentation for future development.
  - Theming and UI consistency for long-term user engagement.
- **Security:**
  - Firebase Authentication for secure user management.
  - Firestore security rules to protect user data.
  - Input validation and error handling throughout the app.
  - No sensitive data stored on device; all payments and upgrades are securely processed.

---

**Developed by:** 22RP01605
