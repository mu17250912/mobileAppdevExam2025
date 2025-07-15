 NeighborhoodAlert

Student Registration Number: 22RP03865
App Name:NeighborhoodAlert

 how run  my app
 In my application, when a user signs up, they are automatically assigned the "user" role by default. If you want to change their role, you go to Firebase and manually update it, assigning them either the "admin" role or keeping them as a "user".

 Admin credentials

Username:uwase@gmail.com

password:123456

user credentials

nkundatheogene098@gmail.com

password:12345678

role of Users: Receive alerts, view neighborhood updates, report issues, and possibly make payments (e.g., for community security services).

role of Admin: Manage alerts, verify reported issues, view user data, send announcements, and handle payment or subscription management.
 
*Brief Description
NeighborhoodAlert is a Flutter mobile application that empowers communities to report, view, and manage local safety alerts. It leverages Firebase for authentication, real-time data storage, and role-based access, allowing both regular users and admins to participate in neighborhood safety.

*Problem Statement
Many communities lack a centralized, real-time platform for reporting and responding to local emergencies, suspicious activities, or hazards. NeighborhoodAlert solves this by providing a collaborative space for residents and admins to share alerts, access emergency contacts, and stay informed, thereby improving neighborhood safety and response times.

*Monetization Strategy
The app implements a simulated payment gateway for demo purposes, allowing users to make donations or pay for premium features. In a production environment, this could be replaced with real payment integrations (e.g., Stripe, PayPal, Mobile Money) to support app sustainability and offer value-added services.

*Key Features
-Role-based Access: Admins can manage alerts, users, analytics, and emergency contacts; users can report incidents, view alerts, comment/react, receive notifications, and access premium features.
- Google Sign-In & Firebase Auth:Secure authentication and user management.
- Real-time Alerts:** Users can report incidents (with images), and all alerts are visible in real-time.
- emergency Contacts:Quick access to community emergency numbers, with call functionality.
- Simulated Payments:Users can donate or pay for premium features, with records saved in Firestore.
- SOS Button:Quick access for urgent help.
- Scalable Firestore Data Model:All data is stored in Firebase collections for easy growth.

*How to Install and Run the APK
1. Download the APK file from the `build/app/outputs/flutter-apk/app-release.apk` path (or as provided by your instructor).
2. Transfer the APK to your Android device.
3. On your device, enable installation from unknown sources (Settings > Security > Unknown sources).
4. Open the APK file and follow the prompts to install.
5. Launch the NeighborhoodAlert app from your app drawer.

*Scalability, Sustainability, and Security Overview
- Scalability:The app uses Firebase Firestore, which is horizontally scalable and supports real-time updates. Data models are designed for easy extension, and UI components use lazy loading and efficient data fetching for performance.
- Sustainability:Monetization via donations and premium features supports ongoing development. The codebase is modular, making it easy to maintain and extend.
- Security:Authentication is handled by Firebase Auth, ensuring secure sign-in. Role-based access restricts admin features. Sensitive operations (like payments and emergency contacts) are protected, and all data is stored securely in Firestore.

---my contact-----
+250792520988




