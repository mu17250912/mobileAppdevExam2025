# EasyRent

## Student Registration Number

**22RP01964**

## App Name

**EasyRent**

## Brief Description

EasyRent is a mobile application that connects property owners with renters, streamlining the process of listing, searching, and renting properties. The app provides secure authentication, user profiles, property listings, and payment simulation, making property rental easy and efficient for both owners and renters.

---

## The Problem Your App Solves

Finding and managing rental properties can be time-consuming and inefficient for both property owners and renters. Existing solutions often lack secure payment integration, user-friendly interfaces, and features tailored for the local market. EasyRent addresses these issues by providing a seamless, secure, and scalable platform for property rental and management.

---

## Target Audience

- Property owners looking to list and manage their properties.
- Renters searching for available properties.
- Individuals seeking a secure and easy-to-use rental platform.

---

## Monetization Strategy

**Commission-Based Model with MTN Mobile Money Integration**

EasyRent generates revenue by charging a commission on each successful rental transaction processed through the app. This commission is automatically deducted when a renter makes a payment to a property owner using the integrated payment system.

### How It Works

1. **Payment Flow:**

   - When a renter decides to book a property, they initiate a payment through the app.
   - The app uses the **MTN Mobile Money API** to process the payment. This is a real (or simulated) integration with MTN’s mobile money platform, which is widely used in the region for secure and instant mobile payments.
   - The payment is sent from the renter’s mobile wallet to the property owner’s wallet, with the app automatically deducting a small commission before forwarding the remainder to the owner.

2. **Technologies Used:**

   - **MTN Mobile Money API:**  
     The app integrates with the official MTN Mobile Money API to handle real-time payment transactions. This ensures that payments are secure, traceable, and convenient for users who already use mobile money services.
   - **Firebase Firestore:**  
     All transaction records, including commission details, are securely stored in Firestore for transparency and future reference.
   - **Firebase Cloud Functions (optional):**  
     Can be used to automate commission calculation and payment splitting, ensuring that the business logic is handled securely on the backend.

3. **Why This Model?**

   - **Familiarity:**  
     Mobile money is a trusted and widely adopted payment method in the target market, making it easy for users to adopt the app.
   - **Scalability:**  
     The commission model grows with the number of transactions, ensuring sustainable revenue as the user base increases.
   - **Transparency:**  
     All payments and commissions are recorded and can be audited, building trust with both property owners and renters.

4. **User Experience:**
   - Renters can pay for bookings directly from their mobile wallets.
   - Property owners receive payments instantly, minus the commission.
   - Both parties receive notifications and receipts for every transaction.

### Example Flow

1. Renter selects a property and initiates a booking.
2. The app prompts the renter to pay using MTN Mobile Money.
3. The payment is processed via the MTN API.
4. The app deducts a commission (e.g., 2%) and credits the remaining amount to the property owner’s wallet.
5. Both users are notified of the successful transaction.

**In summary:**  
EasyRent’s monetization is powered by a commission-based model, leveraging the MTN Mobile Money API for secure, real-time payments. This approach is technically robust, user-friendly, and highly scalable for the local market.

---

## Key Features Implemented

- **User Authentication:**
  - Google Sign-In and Email/Password authentication.
- **User Profiles:**
  - Owners and renters have distinct profiles with editable information.
- **Property Listings:**
  - Owners can add, edit, and manage property listings.
  - Renters can browse and search for properties.
- **Wallet & Payment Simulation:**
  - Owners can set up a wallet (e.g., MTN Mobile Money).
  - Simulated payment flow for rental transactions.
- **Role-Based Navigation:**
  - Different dashboards and features for property owners and renters.
- **Responsive UI:**
  - Works on various Android devices and web (Chrome).
- **Firebase Integration:**
  - Uses Firebase Auth, Firestore, and Analytics.

---

## How to Install and Run the APK File

1. **Download the APK file** from the provided link or the `22RP01964_AppFiles.zip` archive.
2. **Transfer the APK to your Android device** (via USB, email, or cloud storage).
3. **On your device, enable installation from unknown sources** (Settings > Security > Unknown sources).
4. **Open the APK file** and follow the prompts to install.
5. **Launch the EasyRent app** and sign in or register to get started.

---

## Scalability, Sustainability, and Security Considerations

### Scalability

- Uses Firebase backend for scalable data storage and authentication.
- Codebase is modular, allowing for easy addition of new features (e.g., more payment methods, advanced search).
- Efficient data handling and lazy loading for performance in low-bandwidth environments.

### Sustainability

- **Continuous Updates:**  
  Plan to gather user feedback and release regular updates.
- **User Retention:**  
  Features like push notifications (future), and easy property management encourage ongoing use.
- **Low CAC:**  
  Organic growth through user referrals and social sharing features.

### Security

- **Authentication:**  
  Secure sign-in with Firebase Auth (Google and Email/Password).
- **Data Privacy:**  
  User data is stored securely in Firestore, with access rules enforced.
- **Compliance:**  
  Awareness of GDPR/local data protection; no sensitive data is stored without user consent.
- **API Security:**  
  All backend interactions use secure Firebase APIs.

### Reliability

- Tested on multiple Android devices and Chrome browser.
- Error handling and user feedback for failed operations.
- Minimal downtime due to Firebase’s managed infrastructure.

---

## Analytics & Tracking

- **Firebase Analytics** is integrated to track user sign-ins, property listings, and rental transactions.
- Analytics data is used to improve user experience and optimize monetization strategies.

---

## Contact

- **Name:** GIKUNDIRO Ange Ghislaine
- **Registration Number:** 22RP01964
- **Email:** gikundiro513@gmail.com

---

