# CarRent App

## Student Registration Number
Reg_No:22RP03844
Names: Emmanuel NIYONKURU

## App Name and Description
**CarRent** is a cross-platform mobile app for renting cars, designed for both users and administrators. It streamlines the car rental process, allowing users to browse, book, and manage car rentals, while providing admins with tools to manage bookings, cars, and revenue.

## Problem Statement
Finding, booking, and managing car rentals is often inconvenient, fragmented, and lacks transparency. CarRent solves this by providing a unified, user-friendly platform for both customers and rental agencies.

## Target Audience
- Individuals seeking to rent cars for personal or business use.
- Car rental agencies/administrators managing fleets and bookings.

## Existing Solutions & Unique Selling Proposition (USP)
- Competing apps: Turo, Getaround, local rental agency apps.
- **USP:** CarRent offers a simple, intuitive UI, real-time booking management, and a dual dashboard (admin/user) in a single app. Premium users can book without availability checks, and admins have instant revenue insights.

## How CarRent Solves the Problem
- Centralizes car rental listings and booking management.
- Provides instant booking confirmation and digital receipts.
- Allows users to manage their bookings and profiles.
- Admins can track revenue and manage cars/bookings efficiently.

## Monetization Strategy
- **Freemium Model:** Basic features are free. Premium users can book cars without availability checks and may access exclusive cars or discounts (simulated in-app upgrade).
- **Commission-based:** Admin dashboard tracks revenue from confirmed bookings, simulating a commission model.

## Key Features Implemented
- **User-Centric Design:**
  - Intuitive, modern UI with easy navigation.
  - Fast loading and responsive layouts.
  - Accessible design (large buttons, readable fonts, color contrast).
- **Authentication & User Profiles:**
  - Email/password and Google sign-in.
  - Secure profile management for users and admins.
- **Booking Management:**
  - Users can browse, book, and (if eligible) delete bookings.
  - Premium users can book anytime.
  - Booking summary and digital receipt generation.
- **Admin Dashboard:**
  - View total revenue from confirmed bookings.
  - Manage cars and bookings.
- **Monetization:**
  - Freemium logic for premium users (simulated upgrade).
  - Revenue tracking for commission-based model.
- **Performance & Scalability:**
  - Efficient Firestore queries and lazy loading.
  - Defensive coding for low-bandwidth and error scenarios.
- **Security:**
  - Firebase Authentication for secure sign-in.
  - Firestore security rules (enforced via backend).
  - No sensitive data stored on device.
- **Reliability:**
  - Tested on multiple Android devices/emulators.
  - Defensive error handling and user feedback (SnackBars, dialogs).

## Installation & Running the APK
1. Download the APK or AAB file from the `build/app/outputs/bundle/release/` directory.
2. Transfer the file to your Android device.
3. Enable installation from unknown sources in device settings.
4. Tap the file to install and follow on-screen instructions.

## Scalability, Sustainability, and Security Overview
- **Scalability:**
  - Uses Firestore for scalable, real-time data storage.
  - Modular code structure for easy feature expansion.
- **Sustainability:**
  - Designed for easy updates and maintenance.
  - User feedback can be collected via in-app forms or support email.
  - Potential for organic growth via referral incentives (future work).
- **Security:**
  - Secure authentication (Firebase Auth, Google sign-in).
  - Data privacy: No sensitive data stored locally; all sensitive operations handled server-side.
  - GDPR/local compliance awareness (no unnecessary data collection).

## Analytics & Tracking
- **Firebase Analytics** can be integrated to track user behavior and revenue (not implemented in this version, but code structure allows easy addition).

## Sustainability Plan
- Regular updates based on user feedback.
- Maintenance of backend and security rules.
- User engagement via push notifications and loyalty features (future work).



