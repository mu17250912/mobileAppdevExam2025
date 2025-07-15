# QuickDocs

**Student Name:** SHEMA Parfait  
**Registration Number:** 22RP04131

---

## App Name

**QuickDocs**

## Brief Description

QuickDocs is a mobile-first document management and invoicing app designed for freelancers and small businesses. It enables users to create, manage, and export professional invoices and quotes, track document history, and upgrade to premium for advanced features—all from their Android device.

---

## Problem Solved

Freelancers and small business owners often struggle with managing invoices and business documents on the go. Existing solutions are often too complex, desktop-focused, or expensive. QuickDocs provides a simple, mobile, and affordable way to handle business documents, making professional invoicing accessible to everyone.

---

## Target Audience

- Freelancers
- Small business owners
- Self-employed professionals

---

## Unique Selling Proposition (USP)

- **Mobile-first:** Designed for Android, works on the go.
- **Freemium model:** Free tier with essential features, premium unlocks advanced capabilities.
- **Simple & Fast:** Intuitive UI, quick document creation, and export.
- **Instant PDF Export:** Share or download invoices/quotes instantly.

---

## Monetization Strategy

- **Freemium Model:**
  - Free users can create up to 10 documents and have a watermark on exported PDFs.
  - Premium users (one-time $5 upgrade via PayPal) can create unlimited documents and export watermark-free PDFs.
- **Upgrade Flow:**
  - Users tap "Upgrade to Premium" in Settings, pay via PayPal, and refresh their profile to unlock premium features.
- **(Bonus) Payment Integration:**
  - PayPal sandbox is used for demonstration. In production, real payment gateways (PayPal, Mobile Money, etc.) can be integrated.

---

## Key Features

- **User Authentication:** Email/password and Google Sign-In.
- **User Profile Management:** View and refresh profile, premium status badge.
- **Document Management:** Create, view, and manage invoices and quotes.
- **PDF Export:** Export documents as PDF, with/without watermark.
- **Document History:** Track and view past documents.
- **Premium Enforcement:** Document limits and watermark for free users.
- **About Page:** Explains app, tiers, and upgrade process.
- **Responsive UI:** Works on various Android devices and emulators.

---

## How to Install and Run the APK

1. Download the APK file from the provided zip archive.
2. Transfer the APK to your Android device (or use an emulator).
3. Open the APK file and follow prompts to install (you may need to allow installation from unknown sources).
4. Launch QuickDocs from your app drawer.

---

## App Workflow & Usage Examples

### 1. **Sign Up / Login**

- Open the app and sign up with your email/password or Google account.
- Existing users can log in directly.

### 2. **Dashboard**

- View your document stats and quick actions.
- Tap the "+" button to create a new document.

### 3. **Create Document**

- Choose document type (Invoice, Quote, Proforma Invoice).
- Fill in client info, items, and amounts.
- Save the document.

### 4. **Export & Share**

- Open any document from history.
- Tap "Export as PDF" to generate and share/download the PDF.
- Free users see a "Created with QuickDocs" watermark; premium users do not.

### 5. **Upgrade to Premium**

- Go to Settings > "Upgrade to Premium".
- Complete payment via PayPal (sandbox for demo).
- Tap "Refresh Profile" to update your premium status instantly.

### 6. **About & Help**

- Access the About page from Settings for app info, tier details, and upgrade instructions.

---

## Example Usage

- **Create and send an invoice to a client in under 2 minutes.**
- **Track all your sent documents in the history section.**
- **Upgrade to premium for unlimited, watermark-free PDF exports.**

- When a user pays for premium via the PayPal link, the payment goes to the app owner’s PayPal account (sandbox for demo, real account in production).
- The app owner (admin) checks PayPal for new payments and verifies the payer’s email or transaction ID.
- After confirming payment, the admin manually updates the user’s profile in Firebase Firestore to set `premium: true`.
- The user taps the “Refresh Profile” button in the app to instantly see their premium status.

### Instructions for Users

1. Tap “Upgrade to Premium” in the app and complete the PayPal payment.
2. After payment, email your account email or transaction ID to the app owner (see Contact section below).
3. Wait for confirmation (usually within 24 hours).
4. Open the app and tap “Refresh Profile” in Settings to activate premium features.

### Instructions for Admin (App Owner)

1. I Log in to your PayPal account and check for new payments.
2. Note the payer’s email or transaction ID.
3. Go to Firebase Console > Firestore Database > `users` collection.
4. Find the user’s document (by UID or email).
5. Set the `premium` field to `true` and save.
6. Notify the user (optional) that their premium status is active.

---

## Scalability, Sustainability, and Security

- **Scalability:**
  - Modular codebase, uses Provider for state management, ready for more features (e.g., more document types, analytics, push notifications).
  - Efficient Firestore usage and lazy loading for performance.
- **Sustainability:**
  - Plan for regular updates, user feedback via in-app prompts, and organic growth through referrals and user satisfaction.
  - User retention via premium features and potential loyalty programs.
- **Security:**
  - Secure authentication with Firebase Auth.
  - User data stored securely in Firestore.
  - No sensitive data stored on device.
  - Awareness of GDPR/local data protection (no unnecessary data collection).

---

## Analytics & Tracking

- (Optional) Firebase Analytics can be integrated to track user sign-ups, document creation, and premium upgrades.
- Data insights can be used to improve features and user experience.

---

## Contact

- **Student:** SHEMA Parfait
- **Reg No:** 22RP04131
- **Module:** ITLMA701 - Mobile Application Development

---

**Thank you for reviewing QuickDocs!**
