# CookMate

---

## Student Registration Number

**22RP02518**

## Name

**Gloria Ineza**

## Email

gloriaineza1@gmail.com

---

## App Name

**CookMate**

---

## Brief Description

CookMate is a modern mobile application designed for chefs and food enthusiasts to share, discover, and monetize recipes. The app empowers chefs to post special (premium) recipes that can be unlocked for a fee, creating a direct income stream and fostering professional networking within the culinary community.

---

## Problem Statement

Many talented chefs and home cooks lack a dedicated platform to share their unique recipes and earn income from their culinary creations. Existing recipe apps rarely offer direct monetization or chef-to-chef networking opportunities. CookMate addresses this gap by providing a platform for both sharing and earning.

---

## Target Audience

- Professional chefs
- Home cooks
- Food enthusiasts seeking unique, premium recipes

---

## Market Research & Unique Selling Proposition (USP)

- **Competitors:** Tasty, Yummly, AllRecipes
- **USP:**
  - Direct chef-to-chef recipe monetization (paywall for special recipes)
  - In-app chef networking (contact requests and feedback)
  - Simple, accessible UI for all skill levels

---

## How CookMate Solves the Problem

- Enables chefs to earn from their best recipes
- Connects chefs for collaboration and networking
- Provides food lovers with exclusive, high-quality recipes
- Offers a clear monetization path for culinary creators

---

## Monetization Strategy

- **Freemium Model:**
  - Chefs pay a one-time (simulated) fee to post a special (premium) recipe.
  - Users and other chefs pay a one-time (simulated) fee to unlock and view each special recipe.
  - Payment is simulated in-app for demonstration purposes.
- **Justification:**
  - Incentivizes chefs to create high-quality, exclusive content.
  - Provides a revenue stream for both the app and participating chefs.
  - Users and chefs gain access to unique, premium recipes not available elsewhere.

---

## Core Features

- Secure user authentication (sign up/sign in with email and Google)
- User profiles with chef/user roles
- Add, edit, delete, and view recipes
- Mark recipes as special (premium)
- Paywall for special recipes (income generation)
- Chef-to-chef contact requests and approval workflow
- Search for recipes and chefs
- Analytics dashboard for chefs (recipe views, contact requests)
- Favorites system for users and chefs
- Responsive, accessible UI for Android

---

## Simulated Payment Gateway (Bonus)

- When a user or chef tries to view a special recipe, a payment dialog appears (PayPal, Stripe, Flutterwave, MTN Mobile Money).
- On confirmation, the recipe is unlocked for that user/chef (tracked in Firestore).
- Chefs pay once to unlock the ability to post special recipes.
- This simulates an in-app purchase for demonstration purposes.

---

## Analytics & Tracking

- **Recipe views** are tracked in Firestore and displayed in the chef's analytics dashboard.
- **Contact requests** and approvals are tracked and shown in real time.
- (Optional) Firebase Analytics can be integrated for deeper insights (user engagement, feature usage).

---

## Sustainability Plan

- Regular updates based on user feedback
- Gamification and loyalty rewards for active users
- Referral program to encourage organic growth
- Push notifications for new recipes and chef connections (future work)
- Firebase backend for scalable, persistent data storage
- Modular codebase for easy maintenance and feature expansion

---

## Security & Reliability

- Secure authentication and role-based access (Firebase Auth)
- No sensitive data stored on device
- Simulated payments (no real transactions)
- Firestore security rules for data protection
- Manual testing on multiple Android devices/emulators
- Code structured for maintainability and future upgrades

---

## Scalability & Performance

- Modular codebase (models, services, views)
- Uses Firebase for real-time, scalable backend
- Efficient data handling and UI updates (StreamBuilder, lazy loading)
- Optimized for low-bandwidth environments

---

## Installation & Running the App

1. Clone the repository and navigate to your student directory (`22RP02518/`).
2. Run `flutter pub get` to install dependencies.
3. Build the APK: `flutter build apk --release`
4. Build the AAB: `flutter build appbundle --release`
5. Install the APK on your Android device or emulator (see instructions above).

---

## APK & AAB Submission

- Both APK and AAB files are generated and included in the submission `.zip` file as required.

---

## Pull Request

- A pull request has been created from my `22RP02518` directory to the main branch of the exam repository, with a clear and concise description.

---

## Project Documentation

- This README includes:
  - Student registration number
  - Name and contact email
  - App name and description
  - Problem statement and solution
  - Monetization strategy
  - Key features
  - Installation and running instructions
  - Scalability, sustainability, and security considerations

---

## Contact

For any questions, please contact: **gloriaineza1@gmail.com**

---

*All information above is tailored for the 2024-2025 Mobile Application Development summative assessment.*

