# GenZ'd  Flutter App

**Student Registration Number:** 22RP03335

A modern Flutter app for discovering, booking, and genearating comedy event tickets, featuring comedian profiles, comedy shorts, and real-world monetization. Built with Firebase for authentication, data storage, and notifications. using DART Language

---

## App Overview
This app connects users with the best comedy events and comedians. Users can:
- Browse upcoming comedy events
- View comedian profiles and bios
- Book tickets and receive digital tickets
- Share and download tickets
- Watch comedy shorts (YouTube links)
- Receive notifications for bookings
- Personalize their experience (profile, theme and change password)

---

## Problem Solved
**Problem:** Comedy fans often struggle to discover, book, and share tickets for live events, and comedians lack a centralized platform to promote their shows and connect with fans.

**Solution:** This app provides a seamless, user-friendly platform for discovering comedy events, booking tickets, and sharing them digitally. It also gives comedians a space to showcase their profiles and content, increasing their reach and engagement.

**Target Audience:**
- Comedy fans seeking events and easy ticketing
- Comedians and event organizers
- Young adults and students interested in entertainment

**Market Fit & USP:**
- Combines event discovery, ticketing, and social sharing in one app
- Monetization through ticket sales (by commision) and partner banners
- Real-time notifications and digital ticketing
- Modern, accessible, and scalable design

---

## Monetization Strategy

- **Commission-based ticket sales:** Each ticket booking includes a commission, providing direct revenue.

- **Partner banners:** Static ad banners (e.g., Facebook Audience Network, Alibaba) are shown on the dashboard and comedy shorts screens.

- **Future-ready:** Easily extendable for AdMob, in-app purchases, donations, affiliate links, sponsored content, and merchandise.

**Justification:// on how i will gain income from this application**

- Comedy fans are willing to pay for event access and exclusive content.

- Partner banners and future ad integration provide additional revenue streams.

- Commission model aligns with event-based monetization and is sustainable as the user base grows.

---

## Analytics & Tracking

- **Firebase Analytics** (recommended): Track user sign-ups, ticket bookings, and engagement with events and comedians.

- **Usage:** Integrate Firebase Analytics to monitor:
  - Active users
  - Ticket sales and revenue
  - Most viewed comedians/events
  - Feature usage (e.g., sharing, downloads)

- **Data Insights:** Use analytics to optimize event recommendations, ad placements, and user engagement strategies.

---

## Sustainability Plan

- **Continuous Updates:** Regularly add new events, comedians, and features based on user feedback.

- **User Engagement:**

  - Push notifications for new events and booking confirmations
  - Loyalty features (e.g., rewards for frequent bookings)
  - Social sharing to drive organic growth

- **Low CAC Strategies:**

  - Referral programs (invite friends, get discounts)
  - Social media integration for viral growth

- **Feedback Loops:**

  - In-app feedback forms
  - Monitor reviews and analytics for improvement

- **Scalability:**

  - Built with Firebase for easy scaling
  - Efficient data handling and lazy loading for low-bandwidth environments
  - Modular code structure for adding new features

---

## Security & Reliability

- **Security Measures:**

  - Secure authentication (Firebase Auth, Google Sign-In)
  - Data privacy: User data stored securely in Firestore, profile pictures in Firebase Storage
  - Awareness of GDPR/local data protection (no sensitive data stored insecurely)
  - Secure API handling (all backend via Firebase)

- **Reliability:**

  - Tested on multiple screen sizes and Android versions
  - Error handling for all network and file operations
  - Minimal downtime due to Firebase’s managed infrastructure

---

## Key Features

- Intuitive, accessible UI/UX
- Fast loading and cross-platform (Android, Web)
- Secure sign-up/sign-in (email, Google)
- User profile management (picture, theme, language)
- Event discovery and comedian profiles
- Ticket booking with commission and payment simulation
- Digital ticket with code, notifications, and sharing/downloading
- Comedy shorts (YouTube links)
- Partner ad banners for monetization
- Real-time notifications (per user)

---

4. **Build AAB:**
   ```sh
   flutter build appbundle
   ```
5. **Run on mobile:**
   ```sh
   flutter run
   ```
6. **Run on web:**
   ```sh
   flutter run -d chrome
   ```
7. **Install APK:**

   - Transfer the APK to your Android device and open it to install.
8. **Install AAB:**
   - Upload the AAB to Google Play Console for distribution.

---

## Scalability, Sustainability & Security Overview

- **Scalability:** Firebase backend, modular code, efficient data handling, and lazy loading.
- **Sustainability:** Regular updates, user feedback, referral programs, and loyalty features.
- **Security:** Secure authentication, data privacy, error handling, and compliance awareness.

---

## Project Info

- **Student Registration Number:** 22RP03335
- **App Name:** Comedy Events Flutter App
- **Module:** MOBILE APPLICATION DEVELOPMENT (ITLMA701)
- **Academic Year:** 2024-2025


---

**Enjoy discovering and sharing comedy events!**

---

## **How to Fix**

1. **Add the badges package to your `pubspec.yaml`:**
   ```yaml
   dependencies:
     badges: ^3.1.1
   ```
   (You can use the latest version if a newer one is available.)

2. **Install the package:**
   ```sh
   flutter pub get
   ```

3. **Rebuild your app:**
   ```sh
   flutter run
   ```

---

## **Summary**

 For testing it you can create your own account and start to enjoy this important application in rwandan society especialy in intertainment


