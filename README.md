Umusare Mobile Application - Project Documentation
Student Registration Number: 22RP01823
App Name: Umusare - Fish Ordering Mobile App
Academic Year: 2024-2025
Module Title: Mobile Application Development (ITLMA701)
Date: July 13, 2025

1. App Overview
Umusare is a mobile application developed using Flutter and Firebase, designed to solve the challenge of fish access and distribution in Rwanda. It connects fish vendors and consumers in a simplified, digital, and user-friendly manner.
2. Problem Statement
Many Rwandan communities, especially in urban centers, face difficulty in accessing fresh, smoked, or dried fish reliably and affordably. Middlemen often inflate prices and create logistical barriers.
3. Target Audience
•	Urban consumers
•	Restaurants and food vendors
•	Fish wholesalers and retailers
•	Farmers and cooperatives
4. Market Research & USP
Existing solutions are limited to local vendors and traditional markets. Umusare stands out by:
•	Digitizing the fish ordering process
•	Supporting multiple order types (smoked, dried, fresh)
•	Integrating delivery tracking and Firebase notifications
•	Offering seller profiles and customer ratings
5. Monetization Strategy
We adopted a Freemium + Commission-based model:
•	Freemium: Basic app usage is free
•	Commission: 2% charged per order to vendors
•	Future additions:
o	Vendor premium listings
o	Subscription plans for bulk buyers
o	Google AdMob for ads
6. Analytics & Tracking
•	Firebase Analytics is integrated to track:
o	Daily Active Users
o	Purchase flow and conversion rates
o	Bounce rate and cart abandonment
7. Sustainability Plan
•	Continuous Feedback: Feedback forms, app rating prompts
•	Low CAC Strategies:
o	Referral programs
o	Word-of-mouth and social media promotion
•	Retention:
o	Push notifications
o	Loyalty points system (future release)
o	Frequent product offers
8. Key Features Implemented
•	Firebase Authentication (Email)
•	Product listing with categories (dried, smoked, fresh fish)
•	Shopping cart system
•	Order history per user
•	Push notifications for order confirmation
•	Role based logic for sellers and buyers
9. Scalability, Performance & Security
Scalability:
•	Firestore as backend with indexed queries
•	Lazy loading of products
Performance:
•	Optimized images
•	Efficient state management (Provider)
Security:
•	Secure authentication using Firebase
•	Data validation before write
•	Firebase rules for read/write access

├── main.dart
├── screens/
│ ├── home.dart
│ ├── login.dart
│ ├── register.dart
│ ├── product_detail.dart
│ └── cart.dart
├── services/
│ ├── auth_service.dart
│ └── database_service.dart
├── models/
├── widgets/
└── constants/

10. Reliability & Testing
•	Manual testing on:
o	Android 8 (Oreo) to Android 13
o	Different screen sizes
•	UI responsiveness verified on emulators and physical devices
11. APK and AAB Files
•	APK and AAB generated using:
flutter build apk --release
flutter build appbundle --release
•	Files are zipped and named 22RP01823_AppFiles.zip
12. How to Install and Run
1.	Download the APK file from the shared zip
2.	Enable "Install from Unknown Sources" in Android settings
3.	Tap the APK and install
4.	Launch the app and register
13. GitHub Repository Info
•	Repository: https://github.com/PickerIb/mobileAppdevExam2025
•	Folder: 22RP01823
•	Pull Request Created and Merged with Description

Developer: Bienvenue Izukondi
Contact: +250790561952


