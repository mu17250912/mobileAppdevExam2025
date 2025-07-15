# 📚 StudySync Mobile App

*Student Registration Number:* 22RP04075 &nbsp;&nbsp;&nbsp;&nbsp; *UWIMBABAZI Clemence*

---

## 📱 Project Overview

**StudySync** is a cross-platform mobile application designed to help students plan smarter and study harder. It enables users to find and connect with compatible study partners, schedule and manage study sessions, receive reminders, and upgrade for premium features. The app is built using Flutter and Firebase, with scalability, monetization, and performance in mind.

---

## 1. 💡 Idea Generation & Market Fit

### 🎯 Unique Value Proposition

- Real-time partner matchmaking and session tracking.
- Study stats and personal dashboard.
- Premium upgrade (simulated PayPal).
- Notification reminders for active sessions.
- Engaging UI for learners to focus and collaborate.

### 🧍 Target Audience

- University and high school students.
- Remote learners and online collaborators.
- Peer-to-peer learning enthusiasts.

### 📈 Market Fit

While many apps offer self-study tools, **StudySync** focuses on **collaborative learning**. With built-in monetization, personalization, and reminders, it offers a unique blend of accountability and peer support.

---

## 2. 🛠 App Development & Implementation

### 🔑 Core Features

- Firebase Email/Password and Google Authentication
- Study session creation, joining, and management
- Real-time updates using Cloud Firestore
- Partner matchmaking system
- Notification system for upcoming sessions
- Profile management with session stats and avatars
- Premium features and upgrade simulation
- Responsive UI compatible across Android, iOS, and Web

---

## 3. 💰 Monetization Features

- Freemium model: Free users access core features.
- Premium upgrade: Unlock custom avatars and additional filters.
- Simulated PayPal integration for upgrade flow.


---

## 4. 🔒 User Role Management

**StudySync** is a single-app solution with a flexible UI. While all users follow the same flow, premium users enjoy additional features unlocked upon payment.

### 🔐 Login Flow

1. User signs in using Firebase Authentication.
2. User document is fetched from Firestore.
3. Premium status (`isPremium: true`) unlocks extra features.

| User Type     | Features                                      |
|---------------|-----------------------------------------------|
| Free User     | Join sessions, edit profile, find partners    |
| Premium User  | All free features + avatar customizer, filters|

---

## 5. 🧪 APK & AAB Builds

Generate your release files using the following:

```bash
flutter build apk --release
flutter build appbundle --release

##CONTACT##

Tel: +250792362209





