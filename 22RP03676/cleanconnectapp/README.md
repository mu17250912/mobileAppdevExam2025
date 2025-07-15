## Student Registration number: 22RP03676
## App Name: CleanConnect 


**CleanConnect** is a cross-platform mobile and web app that connects managers and professional cleaners for job opportunities. Managers can easily post jobs, review applicants, and assign cleaners, while cleaners can browse and apply for jobs that match their skills. The app features secure authentication, real-time notifications, and a premium subscription model for advanced features. Built with Flutter and Firebase, CleanConnect streamlines the process of finding and managing cleaning jobs for both businesses and workers.

## Problem Statement
Many businesses and property managers struggle to find reliable, vetted cleaners for one-time or recurring jobs, while cleaners face challenges in finding consistent, well-matched work opportunities. Existing solutions are fragmented, lack transparency, and often do not provide a seamless way to manage job postings, applications, and payments in one place.

## Solution
CleanConnect provides a unified, easy-to-use platform that directly connects managers and cleaners. Managers can post jobs, review applicants, and assign work with just a few clicks, while cleaners can easily find and apply for jobs that match their skills and availability. The app ensures secure authentication, real-time notifications, and transparent communication between both parties. Premium features, such as unlimited job postings for managers and unlimited applications for cleaners, are available through a secure subscription system. This approach streamlines the hiring process, increases job reliability, and helps both managers and cleaners save time and effort.

## Target Audience
- **Managers:** Hotels, offices, property managers, and businesses needing cleaning services.
- **Cleaners:** Professional cleaners and cleaning companies seeking more job opportunities and reliable income.

## Unique Selling Proposition (USP) & Competitive Advantage
- **All-in-one platform:** CleanConnect connects managers and cleaners in a single, easy-to-use app.
- **Verified users:** Both managers and cleaners are authenticated, reducing fraud and no-shows.
- **Premium features:** Monetization through premium subscriptions for advanced features (e.g., unlimited job posts, unlimited applications).
- **Seamless payments:** Stripe integration for secure, in-app premium subscriptions.
- **Real-time notifications:** Keep users engaged and informed about job status and opportunities.
- **Scalable and cross-platform:** Built with Flutter and Firebase for fast, reliable performance on Android, iOS, and web.

## Business Model
- **Freemium:** Basic features are free. Managers and cleaners can upgrade to premium for unlimited job posts/applications and other advanced features.
- **Subscription-based:** Recurring revenue through monthly/annual premium plans.

## Features
- **User Roles:** Manager and Cleaner
- **Authentication:** Secure login and registration (Firebase Auth)
- **Job Management:**
  - Managers can post, edit, and delete jobs
  - Cleaners can browse and apply for jobs
  - Managers can review applicants and assign jobs
- **Premium Subscription:**
  - Managers: Post unlimited jobs (non-premium limited to 3 per month)
  - Cleaners: Apply for jobs (premium only)
  - Stripe payment integration for subscriptions
- **Notifications:** Real-time job and assignment notifications (Firebase Cloud Messaging)
- **Profile Management:** Edit profile, change password
- **Security:** Firebase security rules, secure API handling
- **Analytics:** Firebase Analytics integration for user engagement and feature tracking

## Monetization
- **Premium Subscription:**
  - Cleaners must subscribe to apply for jobs
  - Managers must subscribe to post more than 3 jobs per month
  - Stripe integration for secure payments

## Analytics & Tracking
- **Firebase Analytics** is integrated to track:
  - User signups/logins
  - Job postings and applications
  - Subscription events
- Data insights are used to improve user experience and retention

## Scalability & Performance
- Modular code structure using Provider for state management
- Designed for easy feature expansion and high performance across devices

## Security & Reliability
- **Security:**
  - Firebase Auth for secure login
  - Firestore security rules to protect user data
  - Secure handling of API keys and payment data
- **Reliability:**
  - Thorough testing on multiple devices
  - Minimal bugs and consistent performance

## Sustainability Plan
- Regular updates planned for new features and bug fixes
- Focus on user retention through notifications and premium features
- Cost-effective user acquisition strategies (CAC)

## Setup & Build Instructions
1. **Clone the repository:**
   ```sh
   git clone <repo-url>
   cd cleanconnectapp
   ```
2. **Install dependencies:**
   ```sh
   flutter pub get
   ```
3. **Configure Firebase:**
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective folders
4. **Run the app:**
   ```sh
   flutter run
   ```
5. **Build APK:**
   ```sh
   flutter build apk --release
   ```
6. **Build AAB:**
   ```sh
   flutter build appbundle --release
   ```

## Submission
- **APK & AAB:** Both files are generated and tested
- **Pull Request:** Please see the PR for a summary of changes and features
- **Documentation:** This README provides all required information

## Contact&Support
For any questions or support please contact:
**Email:** leebae0n@gmail.com
**Phone:** +250792417575

## Notes for the Assessor
- Please use the provided APK or AAB to install and test the app on your device or emulator.
- You can register as both a manager and a cleaner to experience both user flows.
- To test premium features:
  - As a manager, try to post more than 3 jobs in a month to see the paywall.
  - As a cleaner, try to apply for a job to see the premium paywall if not subscribed.
- The subscription flow is simulated with Stripe integration; you can use Stripe test cards if needed.
- All core features (job posting, application, assignment, notifications, premium, etc.) are implemented and tested.
- If you encounter any issues, please contact the support email provided below.

Prepared by Christine ABIZERA