# VetMeds

Student Registration Number: 22RP02166 
Module: ITLMA701 – Mobile Application Development  
Academic Year: 2024–2025  
Project: Summative Assessment – VetMeds App

 App Overview

VetMeds is a cross-platform mobile application built using Flutter for browsing, purchasing, and managing veterinary medicines in Rwanda. It empowers farmers, livestock owners, and veterinarians to access affordable animal medicine and services directly from their phones.
 Problem Solved

Many livestock owners in rural Rwanda face difficulty accessing quality veterinary medicine due to limited stock in local shops, distance, or lack of digital platforms. VetMeds bridges this gap by offering a digital medicine catalog with convenient ordering and delivery features.

Target Audience

- Rural and urban livestock owners in Rwanda  
- Veterinary service providers  
- Agrovet sellers and distributors  
- Smallholder farmers needing remote vet access

Unique Selling Proposition (USP)

- Built-in Google Sign-In and MTN MoMo mobile payments  
- In-app subscription model for premium access  
- Local push notifications and Firebase messaging  
- Runs on Android, iOS, Web, and Desktop  
- Accessible UI for both literate and semi-literate users

Monetization Strategy

 Subscription Model
- Basic (Free): Limited product access, view-only
- Premium (RWF 1,000/month): Add-to-cart, order history, priority support
- MTN MoMo is used for real payments (simulated in dev mode)

In-App Purchase Support
- Premium content unlocked using Flutter’s in-app purchase APIs
Ads (Optional Future Feature)
- Google AdMob integration for banner ads (not in current version)

Analytics & Tracking

- Firebase Analytics is used to track:
  - Active users
  - Most-viewed products
  - Conversion rates on subscriptions
- Data is visualized through Firebase Console and exported for business reports

 Sustainability Plan

User Feedback Loop: In-app surveys and review prompts after orders
- Organic Growth: Referral codes for new user discounts
- Engagement Features: Notifications for product restocks, cart reminders
- Continuous Updates: Monthly content and performance releases via GitHub
- Loyalty & Gamification: Points system for returning users (planned)

 Security Measures

- Firebase Auth handles secure login (OAuth 2.0 for Google)
- Firestore rules enforce read/write access by user roles
- Sensitive user data encrypted and never stored locally
- GDPR/Data Protection-compliant structure for user privacy

 Reliability & Testing

- Tested on:
  - Android phones (Pixel, Samsung)
  - Android emulator
  - Web (Chrome/Edge)
- Screens optimized for various sizes and screen densities
- Bugs tracked using Firebase Crashlytics (optional setup)

 Key Features Implemented

- Firebase Authentication (Email + Google)
- Product catalog with search
- Cart and checkout simulation
- Subscription gatekeeping for cart access
- MTN MoMo payment integration (simulated)
- Push + local notifications
- Clean, responsive UI

 

