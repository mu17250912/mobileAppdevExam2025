RentMate

Student Registration Number: 22RP03693  
Name: MBAZUMUTIMA EDSON  
Email: edisonofficial250@gmail.com  
GitHub Fork: https://github.com/edsonmbaz/mobileAppdevExam2025

.

GETTING STARTED

To get a copy of this project, clone the repository using:

git clone https://github.com/edsonmbaz/mobileAppdevExam2025.git

Navigate to the 22RP03693 directory for all project files, documentation, and installation instructions.

.

FLUTTER SETUP & RUNNING THE APP

1. Install Flutter:
   - Follow the official guide: https://docs.flutter.dev/get-started/install
   - Ensure you have Android Studio or another IDE with Flutter and Dart plugins.

2. Fetch Dependencies:
   flutter pub get

3. Run the App:
   - Connect an Android device or start an emulator.
   - In the 22RP03693 directory, run:
     flutter run
   This will build and launch the app on your connected device or emulator.

4. Build APK/AAB (optional):
   - To generate a release APK:
     flutter build apk --release
   - To generate an Android App Bundle (AAB):
     flutter build appbundle --release

.

HOW TO RUN THE APP

Option 1: Using Flutter (Recommended for Developers)
1. Open a terminal and navigate to the 22RP03693 directory.
2. Connect your Android device via USB (enable USB debugging) or start an Android emulator.
3. Run:
   flutter run
   This will build and launch the app on your connected device or emulator.

Option 2: Installing the APK Directly (For Testers/Users)
1. Locate the RentMate.apk file provided in the release .zip.
2. Transfer the APK to your Android device (via USB, email, or cloud storage).
3. On your device, open the APK file and follow the prompts to install it.
   - You may need to enable "Install from unknown sources" in your device settings.
4. Once installed, open the RentMate app from your app drawer and tap "Get Started" to begin.

.

1. APP NAME & BRIEF DESCRIPTION

RentMate is a mobile application designed to streamline student housing management. It connects students seeking accommodation with landlords offering properties, providing a secure, user-friendly, and locally relevant platform. The app features role-based dashboards, secure authentication, mobile money payments, premium features for landlords, and a modern, animated UI.

.

2. THE PROBLEM RENTMATE SOLVES

Finding safe, affordable, and convenient student accommodation is a challenge for many students, while landlords struggle to manage listings, bookings, and payments efficiently. Existing solutions are often generic, lack local payment options, and do not address the unique needs of students and landlords in emerging markets.



3. TARGET AUDIENCE

Primary: University and college students seeking off-campus housing.
Secondary: Landlords and property managers offering student accommodation.


4. MARKET RESEARCH & UNIQUE SELLING PROPOSITION (USP)

Existing Solutions
Generic rental apps (e.g., Airbnb, local classifieds)
University notice boards and social media groups

RentMate’s USP
Student-focused: Tailored for student needs (affordability, proximity, safety).
Local Payment Integration: Supports MTN and Airtel mobile money.
Role-based Experience: Separate dashboards and features for students and landlords.
Premium Landlord Features: Monetization via premium listings and analytics.
Modern, Intuitive UI: Fast, accessible, and mobile-first design.



5. MONETIZATION STRATEGY

Model: Freemium + In-App Purchases  
Free for students: Browsing, searching, and booking are free.
Landlord Premium Upgrade: Landlords can upgrade to premium (via mobile money) to unlock featured listings, advanced analytics, and priority support.

Justification:  
Landlords are incentivized to pay for increased visibility and management tools, while students benefit from a free, high-quality service. This aligns with local market realities and maximizes adoption.



6. KEY FEATURES IMPLEMENTED

Animated Splash Screen: Modern, branded entry with animated logo, particles, shimmer effect, and a centered "Get Started" button.
Role Selection: Users choose to continue as Student or Landlord.
Role-Based Authentication: Separate login flows for students and landlords with email/password validation, loading spinner, and double-tap prevention.
Student Dashboard: Search properties, book accommodation, view booking/payment history, manage profile, access help/support, and notifications.
Landlord Dashboard: Add/manage properties, view bookings, upgrade to premium, access analytics, and manage payments.
Premium Upgrade: Landlords can pay (simulated MTN/Airtel mobile money) to unlock premium features. Includes phone number input, validation (10 digits, starts with "07"), error messages, and confirmation dialogs.
Payment Validation: Professional validation for phone numbers and payment flows, with clear error and success feedback.
Dynamic Analytics: Real-time revenue and booking stats for premium landlords, using actual payment data (PaymentRecord model).
Notifications: In-app notifications for bookings, payments, and updates, with notification icon in the app bar.
Accessibility: Centered content, large tap targets, responsive design, and accessible navigation.
Security: Secure authentication, input validation, simulated secure payment flow, and structure ready for secure API integration.
UI/UX Improvements: Material and InkWell for better tap areas, improved button feedback, and professional validation for all forms.
Dashboard Design: Student and landlord dashboards are structurally similar for consistency but functionally distinct.
Testing: Basic widget test included in /test/widget_test.dart.



USER PORTALS & THEIR FUNCTIONS

Student Portal
Browse & Search Properties: Students can search for available accommodation tailored to their needs.
Book Accommodation: Securely book properties and view booking history.
Profile Management: Edit and manage personal details and preferences.
Payment History: View all past payments and booking transactions.
Notifications: Receive updates about bookings, payments, and property status.
Help & Support: Access help resources and support channels.

Landlord Portal
Add & Manage Properties: List new properties, edit details, and manage availability.
View Bookings: See all current and past bookings for their properties.
Upgrade to Premium: Access premium features (featured listings, analytics) via mobile money payment.
Analytics Dashboard: View real-time revenue and booking statistics.
Payment Management: Track payments received from student bookings.
Notifications: Get notified about new bookings, payments, and important updates.
Profile Management: Update landlord profile and contact information.



7. DEVELOPMENT PROCESS & IMPROVEMENTS

Implemented a modern splash screen with advanced animations and centered content.
Created a role selection screen to direct users to student or landlord login.
Developed separate login screens with robust validation and improved tap areas.
Made the landlord premium upgrade button functional, simulating mobile money payments with validation and confirmation.
Integrated phone number validation for mobile money payments (10 digits, starts with "07").
Added error messages and loading indicators for all critical actions.
Improved analytics to use real payment data, not static values.
Moved notification icon to the app bar and added a back button to the premium screen.
Ensured dashboards for students and landlords are consistent in design but distinct in features.
Addressed all user feedback promptly, including UI/UX, validation, and feature requests.



8. PAYMENT INTEGRATION (SIMULATED)

Mobile Money (MTN, Airtel):  
Landlords can upgrade to premium using a simulated mobile money payment flow. The app validates phone numbers (must be 10 digits, start with "07") and provides user feedback for errors and successful payments.  
Note: This is a simulation for demonstration purposes; no real transactions occur.



9. ANALYTICS & TRACKING

Firebase Analytics Ready: Codebase structured for easy integration of Firebase Analytics.
Firebase Project Name: rentmate
User Behavior Tracking: (Planned) Track logins, bookings, payments, and feature usage.
Revenue Tracking: Premium upgrades and payment flows are logged for analytics.
Demo: Analytics dashboard for landlords shows real-time revenue and bookings.



10. SCALABILITY, PERFORMANCE & SUSTAINABILITY

Scalability
Modular codebase: clear separation of models, providers, services, and screens
Provider pattern: efficient state management for scalable user/data growth
Lazy loading: data and images loaded as needed
Cloud-ready: designed for easy backend/API integration

Performance
Optimized UI: fast loading, minimal memory usage, smooth animations
Low-bandwidth friendly: efficient data handling and caching

Sustainability Plan
Continuous updates: regular feature improvements and bug fixes
User feedback loops: in-app feedback and support channels
Low CAC strategies: organic growth via student referrals, campus partnerships, social media
Retention features: push notifications, loyalty rewards, gamified engagement
Monetization evolution: ability to add ads, subscriptions, or commission models as the user base grows



11. SECURITY & RELIABILITY

Security Measures
Secure authentication: email/password login with validation
Data privacy: user data handled securely; ready for GDPR/local compliance
Input validation: all user inputs (email, password, phone) are validated
Simulated secure payments: payment flows mimic real mobile money security steps
API security ready: structure supports secure API integration (tokens, HTTPS)

Reliability & Testing
Cross-device testing: app tested on multiple Android screen sizes and emulators
Error handling: user-friendly error messages and loading indicators
Minimal downtime: robust state management and UI feedback for failed actions
Automated widget tests: basic widget test included in /test/widget_test.dart



12. HOW TO INSTALL AND RUN THE APK

1. Download the APK:  
   Extract the provided .zip file containing RentMate.apk and RentMate.aab.
2. Install on Android Device:  
   Transfer RentMate.apk to your device.  
   Open the file and follow prompts to install (enable "Install from unknown sources" if needed).
3. Run the App:  
   Launch RentMate from your app drawer.  
   Use the "Get Started" button to begin.



13. SUBMISSION CHECKLIST

Forked repository: https://github.com/edsonmbaz/mobileAppdevExam2025
Directory created: 22RP03693/
All project files inside directory
README.md (this file)
APK & AAB files in compressed .zip
Pull request to main repository
Email sent with required details



14. CONTACT

Name: MBAZUMUTIMA EDSON
Student Registration Number: 22RP03693
Email: edisonofficial250@gmail.com
GitHub Repo: https://github.com/edsonmbaz/mobileAppdevExam2025



Thank you for assessing RentMate!



This README reflects all implemented features, improvements, and the development process for RentMate as required by the assessment. 