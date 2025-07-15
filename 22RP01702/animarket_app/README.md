# AniMarket – Local Animal Buy & Sell Platform

## i. Registration Number
**22RP01702**

## ii. App Name and Description
**App Name:** AniMarket  
**Description:** AniMarket is a Flutter-based mobile application that connects farmers (sellers) and buyers for local animal trading. The platform offers real-time listings, direct WhatsApp communication, secure authentication, and a premium subscription system to improve visibility and user experience.

## iii. Problem Statement
In many rural and agricultural communities, farmers face challenges finding reliable and local buyers for their livestock. Traditional markets are limited, and lack of exposure leads to delayed sales and low prices. AniMarket addresses this by providing a digital marketplace that bridges the gap between buyers and sellers, ensuring fair trade and access to a larger audience.

## iv. Monetization Strategy
AniMarket uses a **freemium subscription model**:
- **Free Tier**: Limited listings, standard visibility
- **Premium Tier ($10/month)**: Unlimited listings, priority placement, advanced filters, and WhatsApp contact access
- Payments handled securely via PayPal

## v. Key Features Implemented
- Dual user roles (Buyers & Sellers)
- Firebase Authentication (email/password)
- Role-based UI experience
- Animal listing creation with images and location
- WhatsApp contact link for buyer-seller communication
- Real-time push notifications using Firebase Cloud Messaging (FCM)
- Premium upgrade system with PayPal payment integration
- Firebase Analytics for user and behavior tracking

## vi. Installation and Running Instructions (APK)
1. Download the `AniMarket.apk` file from the release section or your instructor.
2. Transfer it to your Android device.
3. Enable **Install from Unknown Sources** in device settings.
4. Locate and tap on the APK file to install.
5. Open the app and create a user account to get started.

## vii. Scalability, Sustainability, and Security

### Scalability
- Firebase backend allows for seamless scaling with low-latency reads/writes
- Listing caching and pagination help manage performance with many users
- Designed for regional and international expansion in future phases

### Sustainability
- Low customer acquisition cost (referral & community programs)
- Continuous update pipeline (monthly release plan)
- In-app feedback and analytics-driven updates
- Beta program to test features before global rollout

### Security
- Firebase Authentication ensures secure login
- Role-based access limits feature misuse
- All API calls are made over HTTPS
- No sensitive data is stored locally
- Payments are handled via secure PayPal SDK

---

## Project Overview

AniMarket simplifies animal trading by enabling users to list, discover, and buy animals within their region. Key design considerations include performance, accessibility, and community-focused features.

### Key Features

- Dual User Roles: Interfaces and functionality customized for Farmers (Sellers) and Buyers
- Location-Based Listings: Real-time listings with regional filtering
- WhatsApp Contact: Buyers can contact sellers directly through a clickable WhatsApp chat link
- Firebase Authentication: Secure email/password login and role-based access
- PayPal Integration: Enables premium subscription payments
- Push Notifications: Alerts for new listings, price drops, and updates
- Responsive UI: Adaptive layout for all screen sizes and platforms

---

## Monetization Strategy & Sustainability

### Freemium Model

**Free Tier:**
- Limit of 3 active listings per seller
- Basic search and browse functionality
- Standard listing visibility

**Premium Tier ($10/month):**
- To get premium you have to go in user profile,click on top-right star button for premium,pay with paypal,then i will have to accept for you in my firebase to be premium.
- Unlimited animal listings
- Priority listing placement in search results
- Direct WhatsApp communication with sellers
- Premium badge on listings
- Enhanced search filters
- Analytics dashboard for sellers

**WhatsApp Contact Integration:**
- Dynamic `wa.me` links allow buyers to chat with sellers instantly

**Payment Processing:**
- PayPal (Sandbox & Live) for secure subscription handling
- Future plan to support Mobile Money and Bank Transfers

---

## Analytics & Tracking

Firebase Analytics monitors behavior and performance:

- Active users & retention
- Premium conversions
- Listing interaction rates
- User location heatmaps
- Search frequency by animal type

**Metrics Tracked:**
- Monthly Active Users (MAU)
- Average Revenue Per User (ARPU)
- Churn Rate
- Conversion Funnel
- Lifetime Value (LTV)

---

## Technical Architecture

### Tech Stack

- Frontend: Flutter (Dart)
- Backend: Firebase (Firestore, Auth, Analytics)
- Payment: PayPal Web Checkout
- State Management: Provider
- Push Services: Firebase Cloud Messaging (FCM)

### Project Structure

lib/
├── models/ # Data models
├── providers/ # Auth and app state management
├── screens/ # UI screens
│ ├── auth/ # Login, SignUp
│ ├── buyer/ # Buyer dashboard
│ ├── seller/ # Seller dashboard
│ └── common/ # Shared pages
├── utils/ # Constants, helper functions
├── widgets/ # Custom UI widgets
└── assets/ # App images and static content