# BudgetWise

**Student Registration Number:** 22RP03352

## App Name
BudgetWise

## Brief Description
BudgetWise is a smart financial management app designed to help users efficiently track their budgets and expenses. The app provides intuitive tools for setting monthly budgets, logging expenses, and visualizing spending by category, empowering users to make informed financial decisions. Built with Flutter for cross-platform compatibility, it offers both free and premium features to cater to different user needs.

## The Problem Your App Solves
Many individuals struggle to manage their finances, leading to overspending and financial stress. Existing solutions are often complex or lack local relevance. BudgetWise addresses this by offering a simple, user-friendly platform for budget tracking, expense management, and financial awareness, tailored for everyday users with both free and premium options.

## Target Audience
- Young professionals, students, and families seeking to manage personal or household budgets.
- Users who want a simple, mobile-first solution for tracking expenses and staying within budget.
- Power users who need advanced analytics and ad-free experience (Premium users).

## Unique Selling Proposition (USP) & Competitive Advantage
- **Intuitive UI/UX:** Clean, easy-to-navigate interface with fast loading times.
- **Real-time Tracking:** Instantly updates budgets and expenses, with visual feedback.
- **Cross-Platform:** Works seamlessly on Android, iOS, Web, and Desktop.
- **Freemium Model:** Free core features with premium upgrades for advanced users.
- **Profile Customization:** Upload profile pictures and customize display names.
- **Firebase Integration:** Secure authentication and real-time data sync.
- **Advanced Analytics:** Premium users get detailed spending insights and reports.

## Monetization Strategy

### Freemium Model
**Free Features:**
- Basic budget and expense tracking
- Monthly spending summaries
- Category-based expense organization
- Ad-supported experience

**Premium Features (In-App Purchase):**
- **Ad Removal:** Distraction-free experience
- **Advanced Analytics & Reports:** Detailed spending trends, charts, and export options
- **Unlimited Budgets:** No restrictions on budget categories
- **Priority Support:** Enhanced customer service

### Ad Integration (Google AdMob)
- Banner ads displayed for free users
- Non-intrusive ad placement
- Revenue generation while maintaining user experience

## Key Features Implemented

### Core Features
- **User Authentication:** Secure sign-up/sign-in with email and password (Firebase Auth)
- **User Profile Management:** 
  - Customizable display names
  - Profile picture upload (supports both web and mobile)
  - Real-time profile updates
- **Budget Management:** Set monthly budgets by category with unlimited categories
- **Expense Tracking:** Add, edit, and categorize expenses with warnings for budget overruns
- **Dashboard:** Visual summary of spending, remaining budget, and category breakdowns
- **Cross-Platform Support:** Works on Android, iOS, Web, and Desktop

### Premium Features
- **Ad-Free Experience:** Remove all banner and interstitial ads
- **Advanced Analytics Screen:** Access to detailed spending reports and trends
- **Enhanced User Experience:** Cleaner interface without ad distractions

### Technical Features
- **Responsive Design:** Works on various screen sizes and orientations
- **Accessibility:** Large buttons, clear fonts, and color contrast for usability
- **Real-time Sync:** Firebase Firestore integration for instant data updates
- **Image Upload:** Cross-platform profile picture upload with Firebase Storage
- **State Management:** Efficient state handling for immediate UI updates

## Analytics & Tracking
- **Firebase Analytics** integration for user behavior tracking
- **Premium Feature Usage:** Track which premium features are most popular
- **User Engagement:** Monitor app usage patterns and feature adoption
- **Revenue Analytics:** Track in-app purchase conversions and ad revenue

## Scalability, Sustainability, and Security Considerations

### Scalability
- Built with Firebase for real-time, scalable backend
- Modular code structure for easy feature expansion
- Efficient data handling and lazy loading for performance
- Cross-platform architecture reduces development overhead

### Sustainability Plan
- **Freemium Revenue Model:** Multiple revenue streams (ads + premium subscriptions)
- **Continuous Updates:** Plan to add new features based on user feedback
- **User Engagement:** Premium features encourage long-term usage
- **Low CAC:** Organic growth via referrals and social sharing
- **Feedback Loops:** In-app feedback and analytics to guide improvements

### Security
- **Authentication:** Secure Firebase Auth for user sign-in
- **Data Privacy:** User data is isolated and protected in Firestore
- **Image Security:** Profile images stored securely in Firebase Storage
- **Best Practices:** No sensitive data stored on device; all API keys secured
- **Compliance:** Awareness of GDPR/local data protection; no unnecessary data collection

### Reliability
- Tested on multiple platforms (Android, iOS, Web, Desktop)
- Error handling for network and authentication issues
- Cross-platform image upload with platform-specific optimizations
- Regular code reviews and bug fixes

## Instructions: How to Install and Run

### Mobile (Android/iOS)
1. Download the APK file from the provided link or the compressed .zip archive
2. Transfer the APK to your Android device
3. On your device, enable installation from unknown sources (Settings > Security)
4. Tap the APK file to install
5. Open the app and sign up or log in to start managing your budget

### Web
1. Access the web version through the provided URL
2. Sign up or log in with your credentials
3. Start managing your budget directly in the browser

### Development Setup
1. Clone the repository
2. Install Flutter dependencies: `flutter pub get`
3. Configure Firebase project and add configuration files
4. Run the app: `flutter run`

## Project Structure

```
22RP03352/
  └── smartbudget/
      ├── lib/
      │   ├── main.dart                 # App entry point with premium service
      │   ├── firebase_options.dart     # Firebase configuration
      │   ├── screens/
      │   │   ├── home_screen.dart      # Main dashboard with premium features
      │   │   ├── auth_screen.dart      # Login/signup screen
      │   │   ├── budget_screen.dart    # Budget management
      │   │   ├── add_expense.dart      # Expense tracking
      │   │   ├── settings_screen.dart  # Profile and app settings
      │   │   ├── analytics_screen.dart # Premium analytics (premium only)
      │   │   ├── upgrade_screen.dart   # Premium upgrade flow
      │   │   └── premium_service.dart  # Premium status management
      │   └── assets/
      │       └── images/               # App icons and assets
      ├── android/                      # Android-specific configuration
      ├── ios/                          # iOS-specific configuration
      ├── web/                          # Web-specific configuration
      ├── pubspec.yaml                  # Dependencies and app configuration
      └── README.md                     # This file
```

## Dependencies

### Core Dependencies
- `flutter`: ^3.0.0
- `firebase_core`: ^2.0.0
- `firebase_auth`: ^4.0.0
- `cloud_firestore`: ^4.0.0
- `firebase_storage`: ^11.5.2
- `google_mobile_ads`: ^3.0.0
- `in_app_purchase`: ^3.1.7
- `image_picker`: ^1.0.7
- `shared_preferences`: ^2.2.2
- `intl`: ^0.18.0
- `url_launcher`: ^6.2.5

## Features Roadmap

### Completed ✅
- User authentication and profile management
- Budget and expense tracking
- Freemium model implementation
- Cross-platform support
- Profile image upload
- Advanced analytics (premium)
- Ad integration

### Planned 🚀
- Export functionality (CSV/PDF)
- Push notifications
- Budget templates
- Financial goals tracking
- Social sharing features
- Dark mode theme
- Multi-currency support

## Submission Details

- **APK & AAB:** Provided in the compressed .zip file
- **Web Version:** Available for cross-platform testing
- **Pull Request:** Submitted to the main repository with this directory
- **Contact:** For any issues, contact via the email provided in the assessment brief

## Technical Notes

### Cross-Platform Image Upload
The app supports profile image upload on both web and mobile platforms:
- **Web:** Uses `putData()` with image bytes
- **Mobile:** Uses `putFile()` with File objects
- **Storage:** Images stored in Firebase Storage with user-specific paths

### Premium Feature Implementation
- Premium status stored locally using SharedPreferences
- Feature gating implemented throughout the app
- In-app purchase integration ready for store deployment

### Performance Optimizations
- Lazy loading for large datasets
- Efficient state management
- Platform-specific optimizations
- Minimal network requests with real-time sync
