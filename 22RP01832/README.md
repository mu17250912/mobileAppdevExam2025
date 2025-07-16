# 📚 BookSwap

![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue?logo=flutter) ![Firebase](https://img.shields.io/badge/Firebase-Cloud-yellow?logo=firebase) ![License](https://img.shields.io/badge/License-Academic-green)

> **Student Registration Number:** `22RP01832`  
> **Module:** MOBILE APPLICATION DEVELOPMENT (ITLMA701)  
> **Academic Year:** 2024-2025  
> **App Type:** Android (Flutter)

---

---

## 📝 App Overview

**BookSwap** is a modern, cross-platform mobile app for buying, selling, and exchanging books within academic communities. It features real-time listings, live MTN MoMo payment integration, and a robust admin dashboard for platform management.

---

## ❓ Problem Statement

> Many students struggle to access affordable textbooks and academic materials. New books are costly, and there is no trusted, easy-to-use platform for exchanging or selling used books within their community.

---

## 🎯 Target Audience

- University and college students
- Book lovers and academic staff
- Academic institutions and libraries

---

## 💡 Unique Selling Proposition

- **Community Focus:** Connects users within the same institution for trusted exchanges.
- **Verified Users:** Secure authentication and role-based access (admin/user).
- **Live Mobile Money Payments:** Real MTN MoMo API for secure, real-world transactions.
- **Sustainability:** Promotes book reuse and reduces waste.

---

## 📊 Market Fit

- Existing solutions are generic and lack student focus or secure payment.
- BookSwap is tailored for academic communities, with features and security designed for students and staff.
- The live payment and admin management features set it apart from competitors.

---

## 🚀 Core Features

- **User Authentication & Profile Management**

  - Email/password registration and login (Firebase Auth)
  - Role-based navigation (user/admin)
  - Profile management: update name, profile picture, password
  - View history of books listed and purchased

- **Book Listing, Buying, and Selling**

  - Any user can list books for sale and purchase books from others
  - List books with image and PDF upload (Cloudinary)
  - Browse/search/filter books by title, subject, or user
  - Buy books using live MTN MoMo payment integration
  - Download purchased books (PDF)
  - Track purchases and sales history

- **Notifications**
  - Real-time, per-user notifications (Firestore)
  - Notifications for purchases, sales, and key events
  - Unread notifications tracked and marked as read

---

## 🛡️ Admin Features

| Feature   | Description                                              |
| --------- | -------------------------------------------------------- |
| Dashboard | Overview of platform stats and quick navigation          |
| Finance   | View commission earnings and sales statistics            |
| Reports   | View sales by month, top users, and subject distribution |



---

## 💸 Monetization

BookSwap generates revenue through two core mechanisms:

### 1. Commission on Book Sales

- **10% commission** is deducted from every book sale. The remaining 90% is credited to the user who listed the book.
- All commission and payout transactions are recorded in Firestore and visible in the admin dashboard.

### 2. Live MTN MoMo Payments

- All book purchases are processed using a live integration with the MTN Mobile Money (MoMo) API
- Buyers enter their MoMo-enabled phone number and receive a real-time payment prompt.
- Payment status is polled and updated in real time.



---

## 📱 MoMo Payment Testing

> **You must have a real MTN Mobile Money-enabled phone number.**
>
> 1. Initiate a payment in the app (e.g., to buy a book).
> 2. You will receive a popup prompt on your phone to approve the payment.
> 3. Follow the instructions on your phone to complete the transaction.

_Note: This is a live integration, not a simulation. Real transactions will be processed._

---

## 📈 Analytics & Reporting

- **Admin Reports:** Sales by month, top users, and subject distribution (admin dashboard)
- **Finance:** Commission and payout tracking for all sales
- **User Activity:** Purchases, sales, and notifications tracked in Firestore

---

## 🌱 Sustainability

- **Continuous Updates:** Regular feature releases and bug fixes
- **User Retention:** Push notifications, loyalty rewards, and referral bonuses
- **Low CAC:** Organic growth via campus ambassadors, social media, and referral programs
- **Feedback Loops:** In-app feedback forms and community polls
- **Long-Term Engagement:** Gamification, seasonal campaigns, and partnerships

---

## 🔒 Security & Reliability

- **Role-based Access:** Admin/user roles enforced at login and navigation
- **Firestore Security:** Data access via authenticated users
- **API Security:** HTTPS for all external API calls
- **Input Validation:** Forms validated before submission
- **Testing:** Manual and widget tests, error handling, and user feedback

---

## ⚡ Scalability & Performance

- **Modular Codebase:** Separation of concerns (models, providers, screens, utils)
- **Efficient Data Handling:** Lazy loading for book lists, optimized queries
- **Cloud-Ready:** Backend can be scaled to support more users and data
- **Optimized for Low Bandwidth:** Minimal image sizes, caching, and offline support

---

## 🛠️ Technologies Used

| Technology        | Purpose                               |
| ----------------- | ------------------------------------- |
| Flutter (Dart)    | Cross-platform mobile development     |
| Firebase          | Auth, Firestore, Storage              |
| Provider          | State management                      |
| HTTP, Dio         | REST API calls, file download         |
| Cloudinary        | Image/PDF uploads                     |
| MTN MoMo API      | Live mobile money payments (HDEV API) |
| Flutter Spinkit   | Loading indicators                    |
| Fluttertoast      | User feedback                         |
| Image/File Picker | Media selection                       |
| Intl              | Date formatting                       |

---

## 📦 Installation & Usage

1. **Download the APK:**
   - https://drive.google.com/file/d/1xQV4U1C8wUvNtVB9KyDr9kS-ibr1_Uzk/view
2. **Download the AAB:**
   - https://drive.google.com/file/d/1xQV4U1C8wUvNtVB9KyDr9kS-ibr1_Uzk/view
3. **Install on Android Device:**
   - Enable "Install from Unknown Sources" in device settings.
   - Transfer the APK to your device and open it to install.
4. **Run the App:**
   - Sign up or log in.
   - Start browsing, listing, buying, or selling books!

---

## 🗃️ Project Structure

```text
lib/
  models/         # Data models (e.g., Book)
  providers/      # State management
  screens/        # UI screens (auth, home, admin, etc.)
  utils/          # Utility functions
  main.dart       # App entry point
assets/           # Images and icons
```

---

---

## 📣 Contact

For any queries, contact:  
**mbonimpatheogene15@gmail.com**  
or open an issue in the repository.

---

> **Thank you for reviewing my project!**
