Umusare - Fish Ordering Mobile App

Student Registration Number: 22RP01823
App Name: Umusare - Fish Ordering Mobile App
Academic Year: 2024-2025
Module Title: Mobile Application Development (ITLMA701)
Date: July 13, 2025

App Overview
Umusare is a mobile application developed using Flutter and Firebase, designed to solve the challenge of fish access and distribution in Rwanda. It connects fish vendors and consumers in a simplified, digital, and user-friendly manner.

Problem Statement
Many Rwandan communities, especially in urban centers, face difficulty in accessing fresh, smoked, or dried fish reliably and affordably. Middlemen often inflate prices and create logistical barriers.

Target Audience

* Urban consumers
* Restaurants and food vendors
* Fish wholesalers and retailers
* Farmers and cooperatives

Market Research & Unique Selling Proposition (USP)
Existing solutions are limited to local vendors and traditional markets. Umusare stands out by:

* Digitizing the fish ordering process
* Supporting multiple order types (smoked, dried, fresh)
* Integrating delivery tracking and Firebase notifications
* Offering seller profiles and customer ratings

Monetization Strategy
We adopted a Freemium + Commission-based model:

* Freemium: Basic app usage is free
* Commission: 2% charged per order to vendors
* Future additions:

  * Vendor premium listings
  * Subscription plans for bulk buyers
  * Google AdMob for ads

Analytics & Tracking
Firebase Analytics is integrated to track:

* Daily Active Users
* Purchase flow and conversion rates
* Bounce rate and cart abandonment

Sustainability Plan

* Continuous Feedback: Feedback forms, app rating prompts
* Low CAC Strategies:

  * Referral programs
  * Word-of-mouth and social media promotion
* Retention:

  * Push notifications
  * Loyalty points system (future release)
  * Frequent product offers

Key Features Implemented

* Firebase Authentication (Email)
* Product listing with categories (dried, smoked, fresh fish)
* Shopping cart system
* Order history per user
* Push notifications for order confirmation
* Role-based logic for sellers and buyers

Scalability, Performance & Security

* Scalability: Firestore backend with indexed queries and lazy loading of products
* Performance: Optimized images, efficient state management using Provider
* Security:

  * Secure authentication using Firebase
  * Data validation before write
  * Firebase rules for read/write access

Folder Structure (Partial)

├── main.dart
├── screens/
│   ├── home.dart
│   ├── login.dart
│   ├── register.dart
│   ├── product\_detail.dart
│   └── cart.dart
├── services/
│   ├── auth\_service.dart
│   └── database\_service.dart
├── models/
├── widgets/
└── constants/

Reliability & Testing

* Manual testing performed on:

  * Android 8 (Oreo) to Android 13
  * Different screen sizes
* UI responsiveness verified on both emulators and physical devices

APK and AAB Files

* Generated using:

  * flutter build apk --release
  * flutter build appbundle --release
* Files are zipped and named: 22RP01823\_AppFiles.zip

How to Install and Run

1. Download the APK file from the shared zip
2. Enable Install from Unknown Sources in Android settings
3. Tap the APK and install
4. Launch the app and register an account

GitHub Repository Info

* Repository: [https://github.com/PickerIb/mobileAppdevExam2025](https://github.com/PickerIb/mobileAppdevExam2025)
* Folder: 22RP01823
* Pull Request: Created and merged with description

Developer Information

* Name: Bienvenue Izukondi
* Contact: +250790561952
