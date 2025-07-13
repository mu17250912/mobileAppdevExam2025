# mobileAppdevExam2025

# 📱 SmartCare – Medical Link Rwanda

**👨‍🎓 Student Registration Number:** 22RP03920  
**📱 App Name:** SmartCare - Medical Link Rwanda  
**📦 Version:** 1.0.0  
**🖥️ Platform:** Android (Flutter)  
**📅 Academic Year:** 2024–2025  
**📘 Module Title:** Mobile Application Development  
**📗 Module Code:** ITLMA701  
**🏛️ Department:** ICT – Option: IT  
**📆 Semester:** Year 3, Semester 1


FOR ACCESS APPLICATION USE THIS CREDENTIAL 
================================================================
🔐 Credential of admin: us@gmail.com  password: 1234567890
                        user: patient@gmail.com  password: 123456
=================================================================

## 🔍 Project Overview

### 🚨 Problem Statement

Rwanda's healthcare system faces challenges such as:
- Difficulty accessing qualified doctors
- Inefficient appointment scheduling
- Lack of remote consultations
- Insecure storage of health records
- Barriers to mobile payment options

### 🎯 Target Audience

- **Primary:** Patients (18–65) in Rwanda using smartphones
- **Secondary:**  doctors, and hospitals
- **Location:** Urban & semi-urban Rwanda, scalable to East Africa

### 💎 Unique Selling Proposition (USP)

- 🇷🇼 Rwanda-focused platform with local regulations in mind  
- 📲 Integrated booking, record keeping, and payment  
- 💬 Multiple consultation modes: in-person
- 🛠️ Full patient-doctor ecosystem in one app

## 🚀 Core Features Implemented

### 1. 🎨 User-Centric Design
- Intuitive bottom navigation bar
- Fast-loading optimized interface
- Fully responsive across Android screen sizes
- Accessible font sizes and contrast

### 2. 🔐 Authentication & Profiles
- Email, Google Sign-In, or phone authentication (Firebase)
- Verified secure sign-in 
- Role-based user interfaces (Admin And users )
- Full user profile management


### 3. 🧩 Key Functionalities
- Doctor search & discovery
- Real-time appointment booking
- Personal health record access
- Push notifications for bookings & reminders
- Secure payment through Stripe 

---

## 💰 Monetization Strategy

### 📊 Freemium + Commission Model

**Free Tier:**  
- Book doctors, view records, basic features

**Premium Tier:**  
- Advanced health analytics, faster bookings

**Commission-Based Services:**  
- 5–10% per successful appointment  
- Featured placements for doctors and clinics

**In-App Purchases:**  
- Pay-per-video consult  
- Premium health packages

## 💵 Payment Integration

- **Global:** Stripe integration (secure & PCI-compliant)  
- **Currency Support:** RWF and USD  
- **Security:** Encrypted payments and validation checks

## 📊 Analytics & Tracking

**Firebase Analytics** integrated:
- Screen views, behavior tracking, session duration  
- Conversion funnels and retention metrics  
- App performance tracking (e.g., crashes, slow loads)  
- A/B testing for feature changes

## 🔒 Security & Reliability

- HTTPS APIs and Firebase token validation  
- Secure storage of medical records (Hive + Firebase)  
- Offline support for appointments and local records  
- GDPR-awareness and user data privacy compliance  
- Local & cloud backups with encryption  
- Rigorous testing across devices and Android versions

---

## ⚙️ Technical Implementation

### 🔧 Technology Stack

- **Frontend:** Flutter 3.32.6  
- **Backend:** Firebase (Firestore, Authentication, Analytics)  
- **Storage:** Hive (local), Firestore (cloud)  
- **Payments:** Stripe, MTN Mobile Money, Airtel Money  
- **State Management:** Provider Pattern  
- **Ads:** Google Mobile Ads SDK (AdMob)



### 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── providers/               # State management
├── screens/                 # UI screens
│   ├── auth/               # Login/Register
│   ├── home/               # Home dashboard
│   ├── booking/            # Appointment screens
│   ├── payment/            # Payment handling
│   ├── doctors/            # Doctor listings
│   ├── my_bookings/        # User bookings
│   ├── admin/              # Admin controls
│   └── error_screen.dart   # Error handling
└── services/               # App logic
    ├── auth_service.dart
    ├── firestore_service.dart
    └── notification_service.dart
```

---

## 📈 Business Model & Growth Strategy

### 📊 Market Overview
- Rwanda healthcare market: ~$1.2 Billion
- 70% smartphone penetration in urban areas
- Limited direct competitors in mobile health apps

### 💵 Revenue Projections
- **Year 1:** 10,000 users – $50,000
- **Year 2:** 50,000 users – $250,000
- **Year 3:** 100,000 users – $500,000

### 🪴 Growth Phases
- **Phase 1:** Kigali and urban clinics
- **Phase 2:** Expand across Rwanda
- **Phase 3:** Enter Uganda, Kenya, Tanzania

---

## 🔮 Future Roadmap

### 🟢 Short-Term (0–6 months)
- Video consultation
- Insurance integration
- Prescription sharing
- Lab test booking

### 🟡 Mid-Term (6–12 months)
- AI symptom checker
- Real-time doctor status
- Analytics for patients
- Multi-language: Kinyarwanda, English, French

### 🔵 Long-Term (1–2 years)
- IoT & Smart device integration
- East African market expansion
- Marketplace for clinics, pharmacies

---

## 🔁 Sustainability Plan

- 📆 Monthly feature updates
- 🚑 Hotfixes and performance patches
- 📢 Push notifications for retention
- 🎮 Gamification with loyalty points
- 💬 Feedback channels & health education blog
- 👥 Referral and incentive programs to reduce CAC

---

## 📦 Installation & Setup

### ✅ Prerequisites
- Android phone (Android 5.0 or higher)
- Internet connection for full features
- Enable "Install from Unknown Sources"

### 📲 How to Install APK
1. Download the APK file from the release folder
2. Tap the file to install
3. Allow permissions as requested
4. Register your account and complete profile
5. Start booking or managing appointments

### 🔧 Development Setup
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase credentials
4. Run `flutter run` to start the development server


