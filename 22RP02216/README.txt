# 22RP02216 - BookMyTalent

**Student Registration Number:**

> **22RP02216**

## App Name
**BookMyTalent**

## Brief Description
BookMyTalent is a modern mobile application that connects clients with local talents (DJs, MCs, dancers, etc.) for event bookings and payments. The app features a professional, user-friendly interface, robust authentication, real-time notifications, and a real-world income generation strategy using live MTN Mobile Money (MoMo) payments.

## Problem Statement
Finding and booking reliable local talents for events is often difficult, time-consuming, and risky. Clients struggle to discover, compare, and securely pay talents, while talents lack a platform to showcase their skills and receive bookings with guaranteed payment.

## Target Audience
- **Clients:** Event organizers, individuals, and businesses seeking to book local talents for events.
- **Talents:** DJs, MCs, dancers, singers, and other performers looking to promote their services and receive secure bookings.

## Unique Selling Proposition (USP) & Competitive Advantage
- **Real MoMo Integration:** Unlike most demo apps, BookMyTalent uses a real MTN Mobile Money API. Payments are not simulated—clients must use their actual phone number, and real money is transferred (in small demo amounts).
- **Instant Booking & Secure Payment:** Clients can browse, book, and pay talents instantly, with all transactions recorded and notifications sent in real time.
- **Professional Portfolio:** Talents can upload a profile image and detailed portfolio, helping clients make informed decisions.
- **Commission-Based Revenue:** The platform automatically deducts a commission from each booking, ensuring a sustainable business model.

## How BookMyTalent Solves the Problem
**For Clients:**
- Browse a curated list of talents with photos, portfolios, and pricing.
- Book and pay instantly using MoMo, with clear commission breakdowns.
- Receive real-time notifications and booking confirmations.

**For Talents:**
- Create a professional profile with image and experience details.
- Receive bookings and payments directly to their account.
- Track income, commission paid, and booking history.

## Key Features Implemented
- **Modern, Responsive UI/UX:** Clean, accessible design with deepPurple branding, animated splash screen, and smooth navigation.
- **Authentication:** Secure email/password sign-up and login, with profile management for both clients and talents.
- **Talent Portfolio:** Talents can upload a profile image and detailed “More Information” section.
- **Talent Discovery:** Clients can browse/search talents, view details, and see real images and portfolios.
- **Booking & Payment:** Multi-step booking form with real MoMo payment integration (using your real phone number is required).
- **Commission Logic:** 10% commission is automatically deducted from each booking.
- **Notifications:** In-app notifications for bookings and payments, with read/unread status and pop-up banners.
- **Transaction History:** Both clients and talents can view their booking/payment history.
- **Scalability:** Efficient Firestore queries, lazy loading, and modular code structure for future growth.
- **Security:** Secure authentication, Firestore rules, and privacy best practices.

## Monetization Strategy
**Commission-Based Revenue (Real MoMo Integration):**
- The app charges a 10% commission on every booking.
- All payments are processed using the real MTN Mobile Money API.
- **This is not a simulation:** You must enter your actual phone number, and a real payment prompt will appear on your device.
- For demonstration, booking amounts are kept very small (e.g., 5–10 RWF) to minimize cost during testing.

**Why this strategy?**
- Commission-based models are proven and sustainable for service marketplaces.
- Using real payments builds trust and demonstrates technical capability.

## Analytics & Tracking
- **Firebase Analytics** is integrated to track user sign-ups, bookings, and payment events.
- This allows for monitoring user engagement, revenue, and app usage patterns.
- Data-driven insights will guide future improvements and marketing strategies.

## Sustainability Plan
- **Continuous Updates:** Modular codebase and clear documentation for easy maintenance and feature expansion.
- **User Retention:** In-app notifications, professional profiles, and booking history keep users engaged.
- **Low CAC:** Organic growth through word-of-mouth, social sharing, and referral incentives.
- **Feedback Loops:** Users can provide feedback for ongoing improvement.
- **Scalability:** Firestore and Flutter ensure the app can handle more users and data as it grows.
- **Security & Compliance:** Secure authentication, data privacy, and compliance with local regulations.

## Security & Reliability
- **Authentication:** Firebase Auth ensures secure sign-up and login.
- **Data Privacy:** User data is stored securely in Firestore with strict access rules.
- **API Security:** All payment and booking operations are validated and protected.
- **Testing:** The app is tested on multiple Android devices and screen sizes to ensure reliability and minimal bugs.

## How to Install and Run
1. Download the APK or AAB file from the provided zip archive.
2. Install the APK on your Android device (enable “Install from unknown sources” if prompted).
3. Open the app and register as a client or talent.
4. To test payments:
   - Use your real MTN phone number (required for MoMo payment prompt).
   - Booking amounts are very small for demo purposes.
5. Enjoy booking and managing talents!

## Technologies Used
- Flutter (cross-platform mobile framework)
- Firebase Auth & Firestore (authentication, data storage)
- Firebase Analytics (user tracking)
- MTN Mobile Money API (real payment integration)
- Cloudinary (profile image uploads)
- flutter_spinkit (loading animations)
- dropdown_search (modern dropdowns)
- another_flushbar (toast notifications)
- Modern UI/UX best practices

## Scalability, Sustainability, and Security
- Scalable architecture with modular screens and services.
- Efficient Firestore queries and lazy loading for performance.
- Continuous improvement plan with user feedback and analytics.
- Secure authentication and data privacy by design.

---

**Registration Number:**

> **22RP02216**

If you have any questions or need further details, please contact me via the submission email.

**Thank you for assessing my project!** 