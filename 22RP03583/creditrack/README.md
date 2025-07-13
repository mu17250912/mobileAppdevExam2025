# CreditTrack

**Student Registration Number:** 22RP03583  
**Student Name:** MUKARUKUNDO Sophie

## App Overview

CreditTrack is a mobile application designed to help individuals and small businesses efficiently manage loans, payments, and borrowers. The app provides a user-friendly interface for tracking loan disbursements, repayments, and borrower information, with built-in analytics and a simulated payment gateway for demonstration of monetization.

---

## 1. Problem Statement & Market Fit

- **Problem:** Many individuals and small businesses struggle to keep track of multiple loans, repayments, and borrower details, leading to financial mismanagement and missed payments.
- **Target Audience:** Small business owners, individual lenders, and anyone who needs to manage multiple loans and repayments.
- **Existing Solutions:** Apps like Money Manager, Loan Calculator, and Excel sheets are commonly used, but often lack integrated analytics, easy payment tracking, and a simple user experience.
- **Unique Selling Proposition (USP):**  
  - Intuitive, modern UI/UX.
  - Integrated analytics dashboard.
  - Simulated payment gateway for monetization demonstration.
  - Google Sign-In for easy authentication.
- **Competitive Advantage:**  
  - Focused on simplicity and actionable insights.
  - Designed for both individual and small business use.
  - Scalable and ready for real payment integration.

---

## 2. Core Features

- **User Authentication:** Email/password and Google Sign-In.
- **User Profile:** View and (future) edit user info.
- **Loan Management:** Add, view, and manage loans and borrowers.
- **Payments:** Record and view payments, with a "Simulate Payment" gateway button.
- **Analytics:** Dashboard for total loaned, collected, and other key metrics.
- **Notifications:** Basic notification system for reminders and updates.
- **Modern UI/UX:** Responsive, accessible, and visually appealing design.

---

## 3. Monetization Strategy

- **Simulated Payment Gateway:**  
  - A "Simulate Payment" button demonstrates how a real payment gateway (e.g., Stripe, PayPal) could be integrated.
  - This feature is for demonstration only; no real money is processed.
- **Future Monetization Potential:**  
  - In-app purchases for premium analytics or features.
  - Subscription model for advanced reporting.
  - Ad integration (e.g., Google AdMob) for free users.

---

## 4. Analytics & Tracking

- **Strategy:**  
  - User actions (loan creation, payment, etc.) can be tracked for insights.
  - Firebase Analytics can be integrated for real-time user behavior and revenue tracking.
- **Demonstration:**  
  - (If integrated) Basic Firebase Analytics events are logged for key actions.
  - Data insights are shown in the Analytics dashboard.

---

## 5. Sustainability Plan

- **Continuous Updates:**  
  - Plan to add new features based on user feedback (e.g., more payment options, export to CSV).
- **User Retention & Engagement:**  
  - Push notifications for payment reminders.
  - Gamification (badges for on-time payments) in future updates.
- **Low CAC Strategies:**  
  - Organic growth via referrals and social sharing.
  - Focus on excellent user experience to drive word-of-mouth.
- **Cost-Effective Maintenance:**  
  - Modular codebase for easy updates.
  - Use of Firebase for scalable backend.

---

## 6. Scalability & Security

- **Scalability:**  
  - Uses Firebase for backend, which scales automatically with users and data.
  - Efficient data loading and lazy loading in lists.
- **Performance:**  
  - Optimized for fast loading and low bandwidth usage.
- **Security:**  
  - Secure authentication via Firebase Auth.
  - No sensitive data stored on device.
  - Awareness of GDPR/local data protection (no unnecessary data collection).
  - Secure API handling and error management.

---

## 7. Reliability & Testing

- **Reliability:**  
  - Tested on multiple Android devices and emulators.
  - Handles common error cases gracefully.
- **Testing:**  
  - Includes a basic widget test in `/test/widget_test.dart`.
  - Manual testing for all major features.

---

## 8. Installation & Usage

1. **Clone the repository** and navigate to your student directory:
   ```
   git clone https://github.com/[your-username]/mobileAppdevExam2025.git
   cd mobileAppdevExam2025/22RP03583
   ```
2. **Install dependencies:**
   ```
   flutter pub get
   ```
3. **Run the app:**
   ```
   flutter run
   ```
4. **Install APK:**  
   - Locate the APK file in the `/build/app/outputs/flutter-apk/` directory.
   - Transfer to your Android device and install.

---

## 9. APK & AAB Files

- Both APK and AAB files are included in the submission zip: `22RP03583_AppFiles.zip`

---

## 10. Project Structure

- All source code and assets are inside the `22RP03583` directory.

---

## 11. Contact

- **Student Name:** MUKARUKUNDO Sophie
- **Student Registration Number:** 22RP03583
- **Email:** mukaru2022@gmail.com

---

## 12. Notes

- The payment gateway is simulated for demonstration purposes only.
- For any questions or issues, please contact me at the email above.

---
