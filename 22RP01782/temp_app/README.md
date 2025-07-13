# Campus Gigs & Income Tracker

A professional, cross-platform Flutter app for students to find gigs, track income, and unlock premium features for advanced analytics and productivity. Built with Firebase, modern UI, and robust architecture.

---

## 🚀 Features

- **Push Notifications**: Get alerts for new gigs, chat messages, and updates (Android, iOS, Windows)
- **In-App Calendar**: Track gig dates, deadlines, and payments
- **Search & Filter**: Find gigs by category, pay, or keywords
- **User Profiles**: Add a profile photo, bio, and skills
- **Gig Application Tracking**: Mark gigs as applied, in progress, or completed
- **Income Analytics**: Visualize your earnings over time and by category
- **Dark Mode**: Toggle between light and dark themes
- **Feedback & Ratings**: Rate gigs and leave feedback
- **Export Data**: Download your gig and income data as CSV
- **Help/FAQ**: In-app help and support
- **Ad Banner**: Monetization via AdMob (Android/iOS)

## 🌟 Premium Features

- **Ad-Free Experience**
- **Premium Purchase Flow**: Upgrade via in-app purchase or simulated payment
- **Advanced Analytics**: Monthly/weekly breakdowns, projections, and custom date range filters
- **Priority Gig Listings**: Sort jobs by pay, newest, or all
- **Resume Builder**: Generate a PDF resume from your profile and completed gigs
- **Custom Notifications**: Set gig alert preferences (category, minimum pay)
- **Premium Support**: Contact a dedicated support channel
- **Quick Stats Widget**: See this month’s income and gigs completed at a glance

---

## 🖥️ Main Screens

- **SplashScreen**: Animated app launch
- **SignInScreen**: Email/Google sign-in
- **HomeScreen**: Dashboard, quick stats, navigation
- **JobListingsScreen**: Browse, search, and apply for gigs
- **GigDetailScreen**: Gig info, apply, chat
- **MyGigsScreen**: Track your applications and completed gigs
- **IncomeDashboardScreen**: Charts, analytics, export
- **CalendarScreen**: Visualize gigs and income by date
- **ProfileScreen**: Edit profile, resume builder
- **PremiumScreen**: Upgrade and manage premium
- **SimulatedPaymentScreen**: Test premium purchase
- **HelpFaqScreen**: In-app help and FAQ
- **ChatScreen**: In-app messaging for gigs

---

## 🏗️ Project Structure

```
lib/
  main.dart                # App entry, routing, theme
  firebase_options.dart    # Firebase config
  screens/                 # All main app screens
  widgets/                 # Reusable widgets (e.g., ad_banner.dart)
assets/
  images/                  # App icons, logos
android/                   # Android platform code (with google-services.json)
ios/                       # iOS platform code
windows/                   # Windows platform code
macos/                     # macOS platform code
web/                       # Web platform code
```

---

## ⚙️ Getting Started

1. **Clone the repo:**
   ```bash
   git clone <your-repo-url>
   cd temp_app
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Firebase Setup:**
   - Android: Place your `google-services.json` in `android/app/`
   - iOS: Place your `GoogleService-Info.plist` in `ios/Runner/`
   - Set up Firestore, Authentication, and (optionally) Cloud Messaging in your Firebase console
4. **Run the app:**
   ```bash
   flutter run
   ```
   - For Windows: Make sure you have Visual Studio with Desktop C++ workload
   - For web: `flutter run -d chrome`

---

## 🖥️ Supported Platforms
- Android
- iOS
- Windows
- Web
- macOS (experimental)
- Linux (experimental)

---

## 📦 Key Dependencies
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_analytics`, `firebase_messaging`, `firebase_storage`
- `google_sign_in`, `google_mobile_ads`, `in_app_purchase`
- `provider`, `shared_preferences`, `fl_chart`, `table_calendar`, `flutter_local_notifications`, `pdf`, `printing`, `csv`, `image_picker`, `url_launcher`, `file_picker`, `intl`, `timezone`

---

## 🧪 Testing
- Example widget test in `test/widget_test.dart`
- Add your own tests for screens, widgets, and business logic

---

## 📱 App Highlights
- Modern, responsive UI
- Secure authentication
- Cloud sync with Firestore
- Monetization via AdMob and in-app purchases
- Works on Android, iOS, Windows, and Web

---
## system usage
 -register account valid email and password
 - verify email on your Gmail and check link in Spam emails
 -login with valid   email and password
 - to allow extra features, go to premium


## 📧 Contact
- General Support: [support@campusgigs.com](mailto:support@campusgigs.com)
- Premium Support: [premium-support@campusgigs.com](mailto:premium-support@campusgigs.com)

---

**Enjoy tracking your gigs and income like a pro!**
