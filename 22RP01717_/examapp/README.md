# Multiple Choice Exam Mobile App

**Student Registration Number:** 22RP01717  
**Name:** UWIMANA Anitha

---

## App Name
Multiple Choice Exam Mobile App

## Brief Description
A modern Android app to help users prepare for exams with categorized multiple-choice questions, mock tests, explanations, personalized learning, offline access, and a clean, user-friendly interface. Supports normal and premium users, with differentiated access and in-app purchases.

## Problem Statement
- Many students lack access to high-quality, interactive exam preparation tools.
- Existing solutions often do not adapt to individual learning needs or progress.
- There is a need for a scalable, gamified, and user-friendly platform for exam practice.
- Students require offline access and personalized feedback to improve their performance.
- Secure, role-based access and content management are needed for admins and trainers.

---

## Monetization Strategy & Sustainability

### Monetization Plan
- **Freemium Model:**
  - Basic categories and features are free.
  - Premium access unlocks all categories, removes ads, and provides exclusive features.
  - Premium can be purchased via in-app payment (integrated with HDEV Payment Gateway).
  - Some categories can also be unlocked by sharing the app on social platforms (organic growth incentive).
- **Justification:**
  - The target audience (students) is price-sensitive, so a freemium model lowers the barrier to entry.
  - Social sharing unlocks encourage organic growth and lower CAC.
  - Premium features are attractive for power users and those seeking a competitive edge.

### Analytics & Tracking
- **User Behavior Tracking:**
  - Integrated with Firebase Analytics to log key events (e.g., quiz attempts, purchases, category unlocks).
  - Tracks user engagement, retention, and revenue events.
- **Revenue Tracking:**
  - In-app purchase events and subscription status are logged in Firestore and can be tracked via Firebase Analytics.
- **Demonstration:**
  - Firebase Analytics is initialized in `main.dart` and can be extended to log custom events throughout the app.

### Sustainability Plan
- **Continuous Updates:**
  - Modular codebase allows for easy addition of new categories, questions, and features.
  - Admin panel enables content moderation and management without code changes.
- **Feedback Loops:**
  - Users can flag questions for review.
  - Trainers and admins can review flagged content and user progress.
- **Low CAC Strategies:**
  - Social sharing unlocks for categories.
  - Referral programs can be added to incentivize inviting friends.
- **User Retention & Engagement:**
  - Push notifications (can be added via Firebase Cloud Messaging).
  - Gamification: progress tracking, badges, and personalized quizzes.
  - Loyalty programs for consistent usage.

---

## Security & Reliability

### Security Measures
- **Authentication:**
  - Secure authentication via Firebase Auth (email/password).
  - Passwords are never stored in plaintext.
- **Data Privacy:**
  - User data is stored securely in Firestore with access rules.
  - Awareness of GDPR/local data protection; no sensitive data is collected unnecessarily.
- **API Security:**
  - All API calls are made over HTTPS.
  - Payment integration uses secure endpoints.

### Reliability
- **Testing:**
  - Manual and automated testing on multiple screen sizes and OS versions.
  - Error handling for network failures and offline fallback for questions.
- **Downtime Minimization:**
  - Firebase backend ensures high availability.
  - Local caching for offline access to questions.

---

## Submission & Documentation

### APK & AAB Files
- Both `app-release.apk` and `app-release.aab` are generated and 

### Pull Request
- Create a pull request to merge your directory (`22RP01717`) into the main branch of the forked repository.
- Ensure your pull request is well-described, mentioning key features, monetization, and security.

### Project Documentation
- **Student Registration Number:** 22RP01717
- **Name:** UWIMANA Anitha
- **App Name:** Multiple Choice Exam Mobile App
- **Description:** See above.
- **Problem Solved:** See above.
- **Monetization Strategy:** See above.
- **Key Features:**
  - Role-based dashboards (admin, trainer, user)
  - Practice and mock test modes
  - Premium unlock via payment or sharing
  - Trainer assignment and progress review
  - Admin content management
  - Analytics integration
  - Secure authentication and data handling
  - Offline fallback for questions
- **Install & Run:**
  1. Download the APK to your Android device and install.
  2. Or, upload the AAB to the Play Store for distribution.
  3. Requires internet for full functionality; some features work offline.
- **Scalability, Sustainability, Security:**
  - Modular codebase for easy updates
  - Admin panel for content management
  - Secure authentication and data storage
  - Analytics for ongoing improvement

---

## Test Credentials (for Internal Testing)

- **User:**
  - Email: anitha@gmail.com
  - Password: 123456
- **Trainer:**
  - Email: uwimana@gmail.com
  - Password: 12345678
- **Admin:**
  - Email: admin@gmail.com
  - Password: Admin@123

---

## MIT License