# 💪 Fitinity Fitness App

**Student Registration Number:** 22RP03196     **NSENGIYUMVA THEOPHILE**


---

## 📱 Project Overview

Fitinity is a cross-platform fitness app designed to empower users to reach their fitness goals through personalized workout plans, progress tracking, premium features, and trainer bookings. The app blends freemium, subscription, and commission-based models to ensure both user value and business sustainability.

---

## 1. 💡 Idea Generation & Market Fit

### 🎯 Unique Value Proposition

- Guided structured workouts.
- Real-time progress tracking.
- Optional premium upgrades.
- Admin dashboard for user and payment management.
- Commission-based trainer booking.

### 🧍 Target Audience

- Health-conscious individuals.
- Users looking for structured and motivational fitness solutions.
- Affordable access to personal trainers.

### 📈 Market Fit

The app mixes essential fitness functionalities with multiple revenue models—freemium access, subscriptions, and trainer commissions—making it suitable for wide adoption and scalability.

---

## 2. 🛠 App Development & Implementation

### 🔑 Core Features

- Responsive UI with bottom navigation.
- Firebase Email/Password authentication.
- Personalized workout plans with daily tracking.
- Premium upgrade flow (simulated payment).
- Admin dashboard for managing users and payments.
- Trainer booking with automatic commission tracking.
- Google AdMob integration.

---

## 3. 👥 User Role Management

In **Fitinity Fitness App**, both **admin** and **regular users** access the same app installation (APK or AAB). Role-based access control ensures tailored user experiences.

### 🔄 How It Works

#### ✅ Single App, Multiple Roles
- One installation for both roles.
- After login, user role is fetched from Firestore (`role: 'admin'` or `role: 'user'`).

#### 🔐 Login Process
1. Users log in via Firebase Auth.
2. User document is fetched from Firestore.
3. Role is checked:
   - `role: 'admin'` → Admin dashboard.
   - `role: 'user'` → Standard workout features.

#### 🧭 Role-Based Navigation

| Role   | Features                                                 |
|--------|----------------------------------------------------------|
| Admin  | Manage workouts, track users, view revenue reports       |
| User   | Access workouts, view progress, book trainers            |




##############👤 Admin Login Access###################

If you want to log in as an admin user, you can use the pre-created admin credentials:


Email:    theophile@gmail.com  
Password: 123theo@1

##############🛠️ Alternatively#############


You can create your own account via the Sign Up screen in the app, then:

Go to your Firebase Console.

Open the users collection in Firestore.

Locate your newly created user document.

Manually change the field:


"role": "admin"


This will grant admin access to your custom account.




  ################   MY CONTACT ###############

  Tel  +2507808888084
  Email: nsengiyumvatheophile08@gmail.com
