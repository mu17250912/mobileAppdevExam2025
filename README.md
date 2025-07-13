# mobileAppdevExam2025
Student Registration Number: 22RP03793

📱 App Name: TechBuy
<img width="449" height="406" alt="image" src="https://github.com/user-attachments/assets/fbee0bfc-9f92-4148-a1ae-5e968d2fc13a" />

📝 Description:
TechBuy is a mobile application built with Flutter that allows users to **buy and sell electronic devices** easily and securely. It features a dual-panel system for Sellers and Buyers, with Firebase as the backend.


❓ Problem Solved:
The app solves the problem of **limited access to online marketplaces for electronics**, especially in emerging regions. It provides a secure, user-friendly platform for individuals and businesses to **list, browse, and purchase tech products** like phones, laptops, and accessories.


💰 Monetization Strategy:
TechBuy uses the **Freemium + Ad Integration** model:
- **Freemium**: Basic browsing and buying is free. Sellers can upgrade to a premium listing plan.
- **Ad Integration**: Google Mobile Ads are displayed to free users (toggle available for ad-free experience).
  <img width="463" height="387" alt="image" src="https://github.com/user-attachments/assets/2c83d42e-534d-4652-9bdc-c6ddb95f5f83" />



🚀 Key Features:
- 🔐 Firebase Authentication (Email/Password + Google Sign-In)
- 🛍️ Buyer & Seller dashboards
- 📸 Add product with image URL & live preview
- 🔍 Search and filter functionality
- 💳 Simulated payment flow
- 🔒 Firebase Security Rules for Firestore & Storage
- 📦 Product management: add, edit, delete (for sellers)
- 🧾 Order history and favorites (for buyers)



## 📦 How to Install & Run the APK:

1. **Download the APK** from the `TechBuy_APK_AAB.zip` archive.
2. **Transfer it to your Android phone**.
3. Go to **Settings > Security > Allow unknown sources**.
4. Tap the APK file and follow the prompts to install.
5. Launch the app and choose either **Buyer** or **Seller** role after login.



 🌱 Scalability, Sustainability & Security Overview:

🔄 Scalability:
- Firebase Firestore and Storage allow for real-time updates and horizontal scaling.
- Lazy loading and pagination improve performance.

🔐 Security:
- Firebase Auth ensures secure sign-in.
- Firebase Firestore rules restrict read/write access by role (buyer/seller).
- Image uploads restricted to authenticated users.

 ♻️ Sustainability:
- Codebase is modular for future updates.
- Feedback mechanism can be added via Firestore.
- Monetization via ads + freemium will support long-term growth.
- Future plans include referral system and seller rating to increase trust.



🛠️ Developer Notes:
- Built with **Flutter 3.22+**
- Firebase SDK used: **firebase_auth, firebase_core, cloud_firestore, firebase_storage**
- State management: `Provider`
- Build tools: Android SDK, Gradle 7.6, NDK 27.0.12077973


> Developed by: Tuyizere Janvier  
> Student Reg. No: 22RP03793
