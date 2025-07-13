# EduMate

**Student Registration Number:** 22RP02247  
**Name:** Pascal NYIRIMBIBI

## App Name
**EduMate**

## App Description
EduMate is an offline study companion designed to help students review and test themselves without needing internet. It allows users to turn their class notes into flashcards, take self-quizzes, and track their study progress — all in one place. With EduMate, studying becomes simpler, more consistent, and more accessible for students everywhere.

---

## Problem Statement
Many students, especially in areas with limited internet access, struggle to revise their notes effectively. Existing tools like Quizlet or Google Drive require a constant internet connection and are not optimized for offline environments. EduMate fills this gap by providing an offline, mobile-first solution for note revision, flashcards, and self-quizzing.

## Monetization Strategy
EduMate uses AdMob banner ads for monetization. Ads are shown on the dashboard and can be expanded to other screens. This approach is chosen because it allows the app to remain free for students, especially in regions where paid apps or in-app purchases are not feasible.

## Key Features
- **User Authentication:** Secure sign up/sign in with Firebase Auth
- **Note to Flashcard Generator:** Convert notes into Q/A flashcards
- **Offline Quiz:** Quiz yourself using your flashcards, no internet required
- **Progress Tracker:** Track quizzes taken, correct answers, and study streaks
- **Study Streaks & Rewards:** Gamification to encourage daily study
- **AdMob Integration:** Banner ads for income generation
- **Firebase Analytics:** Track user engagement and app usage

## Installation & Usage
1. **Install APK:**
   - Copy the APK file to your Android device and open it to install.
   - You may need to allow installation from unknown sources.
2. **Run from Source:**
   - Clone the repository and run `flutter pub get`.
   - Add your `google-services.json` to `android/app/`.
   - Run `flutter run` on a connected device or emulator.

## Scalability, Sustainability, and Security
- **Scalability:** Modular code structure, use of providers, and local storage for offline use. Easy to add new features (e.g., more quiz types, cloud sync).
- **Sustainability:**
  - Feedback loop: Users can suggest improvements via email or in-app feedback (future feature).
  - Low CAC: Organic growth via word of mouth and school partnerships.
  - User retention: Study streaks, gamification, and motivational rewards.
- **Security:**
  - Firebase Auth for secure login
  - No sensitive data stored in plain text
  - Data privacy: Only essential permissions requested

## Analytics & Tracking
- **Firebase Analytics** is integrated to track:
  - Logins
  - Quizzes taken
  - Ad views
- Data is used to improve user experience and app performance.

## Testing & Reliability
- Tested on multiple Android devices and emulators
- Responsive design for different screen sizes
- Minimal bugs and smooth performance

## APK & AAB Files
- Both files are included in the `22RP02247_AppFiles.zip` archive for submission.

---

**Thank you for assessing EduMate!**
