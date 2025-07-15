# InternLink App

**Student Registration Number:** 22RP02314  
**Full Name:** Samuel Kamanzi  



## App Name & Description

**App Name:** InternLink  

**Description:**  
InternLink is a mobile application built to connect students with verified internship opportunities. It helps students easily search, apply for, and track internships, while providing companies a convenient platform to recruit and manage student interns.


## Problem Statement

Many students face challenges accessing relevant internships, while companies struggle to identify and recruit qualified student interns. InternLink solves this by providing a centralized platform tailored to internship discovery, application tracking, and certificate generation.



## Monetization Strategy

- **Freemium Model:**  
  - Free access to internship listings and basic features  
  - Paid access to premium features like exclusive internships, CV editing tools, and certificate tracking  

- **Ad Integration:**  
  - Displays banner ads (via Google AdMob) for free users  

- **Subscription Model:**  
  - Monthly or yearly premium subscriptions for enhanced user experience and career tools


## Key Features Implemented

- Firebase Authentication with role-based access (Student / Company)  
- Internship listing and detailed view  
- Student profile and CV upload  
- Internship application tracking system  
- Company dashboard to post and manage opportunities  
- Simulated internship certificate viewer  
- Firebase Analytics tracking user actions  
- Google AdMob banner ads (on non-premium views)  
- Push notification simulation for internship alerts  
- Simulated premium upgrade flow  

---

## Installation Instructions

You can install InternLink using the `.apk` file (recommended for testing) or publish the `.aab` via Google Play Console.

### For APK Installation (Recommended)

1. Download the `app-release.apk` file from the ZIP archive.  
2. Transfer the APK to your Android device.  
3. On your device, enable **"Install from Unknown Sources"** in the Settings > Security section.  
4. Tap the APK file to install the app.  
5. Launch InternLink and use the test account below or register as a new user.

### For AAB File (Advanced / Play Store)

- The `app-release.aab` is intended for uploading to the Google Play Store.  
- You can use this file via the Google Play Console or bundletool for internal testing.  
- Not suitable for direct device installation.

---

## Test User Accounts

### Student Account
- **Email:** kamanzi@gmail.com  
- **Password:** 1234567890

### Company Account
- **Email:** lanari@gmail.com  
- **Password:** 1234567890

---

## Scalability, Sustainability & Security Overview

- **Scalability:**  
  InternLink uses a modular Flutter architecture connected to Firebase. It supports multi-role access and is structured for future expansion (more users, universities, and features).

- **Sustainability:**  
  The project is designed for long-term impact through regular updates, partnerships with institutions, referral incentives, and a feedback loop for continuous improvement.

- **Security:**  
  User data is secured using Firebase Authentication and Firestore access rules. The app follows secure data handling practices and aligns with data protection principles (e.g., GDPR awareness).

---
