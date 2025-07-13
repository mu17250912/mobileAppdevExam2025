# mobileAppdevExam2025# FarmPay - Agricultural E-commerce Mobile App

## Overview
FarmPay is a comprehensive Flutter-based mobile application designed for agricultural e-commerce, enabling farmers and agricultural businesses to buy and sell products with integrated payment systems and monetization features.

## Key Features

### 🛒 **Multi-Order System**
- Create and manage multiple orders simultaneously
- Bulk payment processing for multiple orders
- Order history tracking and management

### 💳 **Payment Integration**
- Stripe payment gateway integration
- In-app purchase capabilities
- Secure transaction processing
- Multiple payment methods support

### 📱 **User Management**
- User authentication with Firebase Auth
- User dashboard with personalized experience
- Admin dashboard for business management
- Role-based access control

### 🎯 **Monetization Features**
- Google Mobile Ads integration
- In-app purchase subscriptions
- Revenue tracking and analytics
- Multiple monetization strategies

### 🛍️ **Product Management**
- Product catalog with detailed information
- Product search and filtering
- Shopping cart functionality
- Order approval workflow

### 🔔 **Notifications**
- Push notification system
- Order status updates
- Payment confirmations
- Marketing notifications

## Technology Stack

- **Frontend**: Flutter 3.32.2
- **Backend**: Firebase (Firestore, Auth)
- **Payments**: Stripe
- **Ads**: Google Mobile Ads
- **State Management**: Flutter built-in
- **Database**: Cloud Firestore

## Quick Start

### Prerequisites
- Flutter SDK 3.32.2+
- Android Studio / VS Code
- Firebase project setup
- Stripe account

### Installation
```bash
# Clone the repository
git clone <repository-url>
cd farmpay

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Configuration
1. Set up Firebase project and add `google-services.json`
2. Configure Stripe API keys
3. Set up Google Mobile Ads
4. Configure in-app purchase products

## Project Structure
```
lib/
├── main.dart                 # App entry point
├── user_dashboard_screen.dart
├── admin_dashboard_screen.dart
├── products_screen.dart
├── cart_screen.dart
├── payment_screen.dart
├── order_*.dart             # Order management screens
├── services/
│   ├── firebase_service.dart
│   └── monetization_service.dart
└── session_manager.dart
```

## Features in Detail

### For Farmers/Buyers
- Browse agricultural products
- Add items to cart
- Create multiple orders
- Secure payment processing
- Track order status
- View order history

### For Sellers/Admins
- Product management
- Order approval workflow
- Sales analytics
- Revenue tracking
- User management

## Monetization
- **Ad Revenue**: Google Mobile Ads integration
- **Subscription**: Premium features via in-app purchases
- **Transaction Fees**: Payment processing fees
- **Commission**: Platform fees on sales

## Security
- Firebase Authentication
- Secure payment processing
- Data encryption
- Role-based permissions

## Support
For technical support or feature requests, please contact the development team.

---

**FarmPay** - Empowering Agricultural Commerce Through Technology
