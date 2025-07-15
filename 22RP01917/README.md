# Shop Management App

**Student Registration Number:** [22RP01917]

A modern Flutter app for small shop owners and customers, designed for the Rwandan and East African market.  
**Features:** Inventory management, product booking, admin dashboard, feedback, referrals, analytics, and more.

---

## 🚀 Idea Generation & Market Fit

### Problem Statement
Small retail shop owners, especially in rural or semi-urban areas, struggle with manual inventory and booking management. This leads to errors, lost sales, and poor customer tracking.

### Target Audience
- Small shop owners
- Boutique retailers
- General store managers
- Young entrepreneurs in Rwanda and East Africa

### Unique Selling Proposition (USP)
- **Simple, lightweight, and offline-first** Flutter app
- **Integrated booking and payment tracking**
- **Admin dashboard** for real-time inventory and booking management
- **Referral and feedback system** for organic growth and quality improvement
- **Freemium model:** Core features free, premium unlocks extra value

---

## 🛠️ Core Features

- **Admin:**
  - Product CRUD (add, edit, delete, list)
  - Booking management (view, update status, see payment/commission)
  - Dashboard with inventory, booking, and commission stats
  - Send announcements to users
  - View feedback and referral stats

- **User:**
  - Product catalog and booking
  - Simulated PayPal payment flow
  - View own bookings and booking status
  - Submit feedback and see referral code/profile
  - Receive in-app notifications for booking status changes
  - **Upgrade to Premium:** Unlocks gold badge, highlighted products, and exclusive tips

- **Other:**
  - Firebase Analytics for key events
  - Simulated AdMob banner (real ads on Android/iOS, hidden on web)
  - Robust error handling and loading indicators

---

## 💰 Monetization Strategy & Sustainability

- **Ad Integration:** AdMob banner is shown on Android/iOS, providing advertising revenue.
- **Freemium Model:** Users can upgrade to “Premium” via a simulated in-app purchase. Premium users see a gold badge, highlighted product cards, and exclusive “Premium Tips.”
- **Commission:** 5% per booking, visible to admin (simulated for demo)
- **Referral program:** Users can invite others and track referrals

**Why This Model:**
- Shop owners are willing to pay a small commission for successful bookings.
- Ads and premium upgrades provide additional revenue streams.
- Referral program drives organic growth and reduces acquisition costs.

**Sustainability Plan:**  
- Regular updates based on user feedback  
- Focus on user retention via referral, feedback, and announcements  
- Cost-effective user acquisition through referrals and organic growth

---

## 📊 Analytics & Tracking

- **Firebase Analytics** integrated for:
  - `booking_made`: When a user books a product (logs product, quantity, user, total)
  - `premium_upgrade`: When a user upgrades to premium (logs user and timestamp)
- **Admin dashboard** shows real-time stats for bookings, commission, and referrals

---

## 🏅 Premium Feature (Freemium Model)

- Users can upgrade to Premium (simulated in-app purchase)
- Premium users see a gold badge in the app bar, product cards with a gold border, and exclusive “Premium Tips” below each product
- Demonstrates a freemium model and adds value for users who upgrade

---

## 🔒 Security & Reliability

- **Authentication:** Firebase Auth (email/password)
- **Data:** Firestore with secure rules (users can only see their own bookings)
- **Error Handling:** All major flows have robust error dialogs and loading indicators
- **Testing:** App tested on web, Android emulator, and Windows desktop

---

## ♿ Accessibility & Scalability

- High-contrast Rwanda flag colors, readable fonts, and large tap targets
- Modular code structure, efficient data handling, and responsive UI
- Designed for low-bandwidth environments and future feature growth

---

## 📱 Screenshots

<!-- Add your screenshots here -->
<!-- Example: -->
<!-- ![Admin Dashboard](screenshots/admin_dashboard.png) -->
<!-- ![User Booking](screenshots/user_booking.png) -->

---

## 🏁 How to Run This Project

### 1. **Requirements**
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.x recommended)
- A Firebase project (Firestore, Auth, Analytics enabled)
- Internet connection for Firebase features

---

### 2. **Firebase Setup**
This app uses Firebase for authentication, Firestore, and analytics.

- The app is pre-configured for a demo Firebase project.
- If you want to use your own Firebase project:
  1. Go to [Firebase Console](https://console.firebase.google.com/).
  2. Create a new project.
  3. Enable **Firestore Database** and **Authentication (Email/Password)**.
  4. In your project settings, add a new **Web App** and copy the config.
  5. Replace the `FirebaseOptions` in `lib/main.dart` with your config.

---

### 3. **Running the App**

```sh
git clone https://github.com/yourusername/shop_management_app.git
cd shop_management_app
flutter pub get
flutter run
```

- When prompted, select your device (Windows, Chrome, Edge, Android, etc.).

---

### 4. **Admin Login Credentials**

> **Admin Username:** `billy`  
> **Admin Password:** `1234`

- Use these credentials to log in as an admin and access the admin dashboard.

---

### 5. **User Registration & Login**

- Users can sign up with any email and password.
- After signup, users can log in and access the product catalog, booking, and profile features.

---

### 6. **Firestore Security Rules (Recommended)**
To ensure users can only see their own bookings, use these Firestore rules:

```plaintext
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /bookings/{booking} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userUid;
    }
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /products/{productId} {
      allow read, write: if request.auth != null;
    }
    match /announcements/{docId} {
      allow read, write: if request.auth != null;
    }
    match /feedback/{docId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

### 7. **Simulated Features**
- **Payments:** The PayPal payment flow is simulated for demo purposes.
- **AdMob:** The banner is simulated; you can replace it with real AdMob integration if desired.
- **Premium Upgrade:** The premium upgrade is simulated for demo; in production, integrate with real in-app purchase APIs.

---

### 8. **Default Data**
- No default products or users are included. Add products via the admin dashboard after logging in.

---

## 📦 Submission

- **APK & AAB:** Both files generated and submitted
- **Pull Request:** Please see the PR for a summary of features and implementation
- **README:** This file provides all required information

---

## 🤝 Contributors

- [Your Name] (your.email@example.com)

---

## 📄 License

This project is licensed under the MIT License.

---

## 💡 Future Improvements

- Real payment gateway integration (Stripe, PayPal, etc.)
- Real AdMob integration
- Push notifications (Firebase Cloud Messaging)
- User profile editing and photo upload
- More advanced analytics and reporting

---

**Thank you for reviewing the Shop Management App!**
