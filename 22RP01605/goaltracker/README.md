# GoalTracker: Personal Goal Tracking and Motivation App

**Student Registration:** 22RP01605  
**App Name:** GoalTracker  
**Problem Solved:** Poor goal tracking and lack of motivation for personal development

## Overview

GoalTracker is a modern, gamified goal-tracking app designed to help users set, track, and achieve their personal goals. Built with Flutter and Firebase, it provides a seamless cross-platform experience with real-time synchronization and motivational features.

## Features

### Core Features
- **Goal Management**: Create, edit, and delete personal goals with subgoals
- **Daily Check-ins**: Track progress with streak calculations
- **Analytics Dashboard**: Monitor goal progress with visual charts
- **Motivational System**: Daily quotes and push notifications
- **User Profiles**: XP-based leveling system with avatars
### Monetization
- **Freemium Model**: Free users limited to 3 goals, premium unlocks unlimited goals
- **Ad Integration**: Non-intrusive banner ads and occasional interstitial ads
- **Premium Upgrade**: Simulated PayPal payment for premium features

### Technical Features
- **Firebase Integration**: Real-time Firestore database and authentication
- **Cross-platform**: Works on Android, iOS, and web
- **Offline Support**: Caching with shared_preferences
- **Accessibility**: WCAG compliant with semantic labels and tooltips

## Installation Guide

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / VS Code
- Firebase project setup

### Setup Steps
1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd goaltracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Enable Authentication and Firestore

4. **Run the app**
   ```bash
   flutter run
   ```

### APK Installation
1. Download the APK file from the releases
2. Enable "Install from unknown sources" on your device
3. Install the APK file
4. Open GoalTracker and sign up/login

## Architecture

### Feature-based Structure
```
lib/
├── auth/          # Authentication services and screens
├── goals/         # Goal management and CRUD operations
├── profile/       # User profile and settings
├── analytics/     # Progress tracking and statistics
├── motivation/    # Quotes and notifications
├── ads/          # AdMob integration
└── shared/       # Common utilities and widgets
```

### Technology Stack
- **Frontend**: Flutter with Material 3 design
- **Backend**: Firebase Firestore for real-time data
- **Authentication**: Firebase Auth
- **Analytics**: Firebase Analytics
- **Ads**: Google AdMob
- **Notifications**: Firebase Cloud Messaging

## Sustainability Strategy

### User Retention
- **Gamification**: XP levels and streak badges
- **Personalization**: Custom avatars and motivational quotes
- **Progress Tracking**: Visual analytics and milestone celebrations

### Growth Tactics
- **Referral System**: Share achievements and invite friends
- **Social Features**: Share milestones on social media
- **Feedback Loop**: In-app feedback form for continuous improvement

### Revenue Streams
- **Freemium Conversion**: Premium features for power users
- **Ad Revenue**: Non-intrusive banner and interstitial ads
- **Future Plans**: Premium templates and advanced analytics

## Security & Privacy

### Data Protection
- **Firebase Security Rules**: User data isolation
- **GDPR Compliance**: Data protection and user consent
- **Local Encryption**: Secure storage for sensitive data

### Authentication
- **Email/Password**: Secure Firebase authentication
- **User Profiles**: Isolated data per user
- **Premium Status**: Secure premium feature access

## Testing

### Widget Tests
```bash
flutter test
```

### Manual Testing
- Test on Android 10-14 devices
- Verify Firebase connectivity
- Test premium upgrade flow
- Validate ad integration

## Performance

### Optimization
- **Lazy Loading**: Efficient list rendering
- **Caching**: Offline support with shared_preferences
- **Real-time Sync**: Firestore for live updates
- **Minimal Data Usage**: Optimized network requests

## Future Roadmap

### Planned Features
- **Advanced Analytics**: Detailed progress insights
- **Goal Templates**: Pre-built templates for common goals
- **Social Features**: Goal sharing and community
- **AI Integration**: Smart goal recommendations

### Technical Improvements
- **Performance**: Further optimization for large datasets
- **Accessibility**: Enhanced screen reader support
- **Testing**: Comprehensive unit and integration tests

## Support

For issues, feedback, or questions:
- Use the in-app feedback form
- Check the help sections in each screen
- Review the analytics for usage patterns

---

**Built with ❤️ using Flutter and Firebase**
