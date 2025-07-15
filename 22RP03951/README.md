# AgriConnect - Agricultural Marketplace Mobile Application

## 📱 Project Overview

AgriConnect is a comprehensive Flutter-based mobile application designed to bridge the gap between farmers and buyers in the agricultural marketplace. The app facilitates direct trade between agricultural producers and consumers, promoting sustainable farming practices and local commerce.

**Student Information:**
- **Student RegNo:** 22RP03951
- **Project:** AgriConnect Mobile Application
- **Technology Stack:** Flutter, Firebase, Google Sign-In
- **Version:** 1.0.0

##  Key Features

###  Authentication & User Management
- **Multi-Platform Sign-In:** Google Sign-In and Email/Password authentication
- **User Type System:** Three distinct user roles (Farmer, Buyer, Admin)
- **Profile Management:** User profiles with subscription plans and preferences
- **Secure Authentication:** Firebase Authentication with real-time state management

###  Product Management
- **Product Listings:** Farmers can add, edit, and manage their products
- **Product Categories:** Organized product catalog with detailed descriptions
- **Image Support:** Product images with cloud storage integration
- **Inventory Management:** Real-time stock tracking and quantity updates

###  Shopping Experience
- **Shopping Cart:** Add products to cart with quantity management
- **Order Processing:** Complete checkout flow with payment options
- **Order History:** Track order status and history for both buyers and sellers
- **Payment Integration:** Multiple payment methods including Mobile Money and Cash on Delivery

###  Order Management
- **Real-time Updates:** Live order status tracking
- **Role-based Views:** 
  - **Buyers:** View their own orders with status tracking
  - **Farmers:** View orders containing their products with management controls
  - **Admins:** Full order management with status updates and payment tracking
- **Status Management:** Order status updates (Pending, Confirmed, Shipped, Delivered, Cancelled)

###  Subscription System
- **Tiered Plans:** Basic, Premium, and Enterprise subscription levels
- **Feature Access:** Premium features for subscribed users
- **Payment Processing:** USSD payment integration for subscription plans
- **Admin Approval:** Subscription approval workflow for admins

###  Analytics & Admin Features
- **Sales Analytics:** Track order placements and revenue
- **User Management:** Admin panel for user oversight
- **Subscription Management:** Admin approval system for subscriptions
- **Order Analytics:** Comprehensive order tracking and reporting

##  Technical Architecture

### Frontend Technologies
- **Framework:** Flutter 3.8.1
- **State Management:** Provider pattern for reactive UI
- **UI Components:** Material Design with custom theme
- **Navigation:** Flutter Navigator with route management

### Backend Services
- **Authentication:** Firebase Authentication
- **Database:** Cloud Firestore (NoSQL)
- **Storage:** Firebase Storage for images
- **Analytics:** Firebase Analytics integration

### Key Dependencies
```yaml
firebase_core: ^3.15.1
firebase_auth: ^5.6.2
cloud_firestore: ^5.6.11
google_sign_in: ^7.1.0
provider: ^6.1.2
path_provider: ^2.1.2
```


### Main Application
- Home screen with product listings
- Product details with add to cart functionality
- Shopping cart with quantity management
- Checkout process with payment options

### User Dashboards
- **Farmer Dashboard:** Product management and order tracking
- **Buyer Dashboard:** Order history and shopping experience
- **Admin Dashboard:** Analytics and user management

## Installation & Setup

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- Firebase project setup
- Google Cloud Console configuration

###  Sample Test Accounts

For testing purposes, the following accounts are pre-configured in the system:

| Email | Password | Role | Description |
|-------|----------|------|-------------|
| `hakbertin@gmail.com` | `Tumba@123` | **Farmer** | Test farmer account with product management capabilities |
| `muhire@gmail.com` | `Tumba@123` | **Buyer** | Test buyer account for shopping and order placement |
| `admin@gmail.com` | `Tumba@123` | **Admin** | Test admin account with full system access |

**Note:** These accounts are for testing and demonstration purposes. In production, users should create their own accounts through the registration process.

### Installation Steps

1. **Clone the Repository**
   ```bash
   git clone <https://github.com/oficialbertin/mobileAppdevExam2025>
   cd agriconnect
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Create a Firebase project
   - Add Android app with package name: `com.example.agriconnect`
   - Download `google-services.json` and place in `android/app/`
   - Configure Google Sign-In in Firebase Console

4. **Google Sign-In Setup**
   - Add SHA-1 fingerprint to Firebase project
   - Configure OAuth consent screen
   - Enable Google Sign-In API

5. **Run the Application**
   ```bash
   flutter run
   ```

### Build Instructions

**Debug APK:**
```bash
flutter build apk --debug
```

**Release APK:**
```bash
flutter build apk --release
```

**Web Build:**
```bash
flutter build web
```

##  User Roles & Permissions

### Farmer
- **Product Management:** Add, edit, and manage products
- **Order Management:** View and update orders containing their products
- **Inventory Control:** Track stock levels and availability
- **Sales Analytics:** View sales performance and order statistics

### Buyer
- **Product Browsing:** Browse and search products
- **Shopping Cart:** Add products and manage quantities
- **Order Placement:** Complete checkout and payment
- **Order Tracking:** View order history and status
- **Subscription:** Access premium features with subscription

### Admin
- **User Management:** Oversee all users and their activities
- **Order Management:** Full control over all orders
- **Subscription Approval:** Approve or reject subscription requests
- **Analytics Dashboard:** Comprehensive system analytics
- **Content Moderation:** Manage products and user content

## Configuration

### Firebase Setup
1. Create Firebase project
2. Enable Authentication (Email/Password, Google Sign-In)
3. Enable Firestore Database
4. Configure security rules
5. Set up Firebase Storage for images

### Google Sign-In Configuration
1. Enable Google Sign-In API
2. Configure OAuth consent screen
3. Add SHA-1 fingerprints for Android
4. Configure web client ID for web platform

### Environment Variables
- Firebase configuration is handled through `google-services.json`
- No additional environment variables required

## Database Schema

### Users Collection
```json
{
  "uid": "user_id",
  "email": "user@example.com",
  "displayName": "User Name",
  "userType": "Farmer|Buyer|Admin",
  "subscriptionPlan": "Basic|Premium|Enterprise",
  "subscriptionStatus": "active|pending|inactive",
  "photoURL": "profile_image_url",
  "lastSignInTime": "timestamp",
  "creationTime": "timestamp"
}
```

### Products Collection
```json
{
  "id": "product_id",
  "name": "Product Name",
  "description": "Product description",
  "price": 1000.0,
  "quantity": 50,
  "unit": "kg",
  "farmerId": "farmer_user_id",
  "farmerName": "Farmer Name",
  "imageUrl": "product_image_url",
  "category": "category_name",
  "createdAt": "timestamp"
}
```

### Orders Collection
```json
{
  "id": "order_id",
  "customerId": "buyer_user_id",
  "customerName": "Customer Name",
  "customerEmail": "customer@email.com",
  "items": [{"productId": "id", "productName": "name", "quantity": 5, "unit": "kg", "price": 1000.0, "farmerId": "farmer_id"}],
  "totalAmount": 5000.0,
  "status": "pending|confirmed|shipped|delivered|cancelled",
  "paymentMethod": "Mobile Money|Bank Transfer|Cash on Delivery",
  "isPaid": false,
  "shippingAddress": "delivery_address",
  "phoneNumber": "contact_number",
  "createdAt": "timestamp"
}
```

## UI/UX Design

### Color Scheme
- **Primary Color:** Green (#2E7D32) - Represents agriculture and growth
- **Secondary Color:** White (#FFFFFF) - Clean and professional
- **Accent Colors:** Various shades for status indicators and highlights

### Design Principles
- **Responsive Design:** Adapts to different screen sizes
- **Material Design:** Follows Google's Material Design guidelines
- **Accessibility:** High contrast and readable fonts
- **User-Friendly:** Intuitive navigation and clear call-to-actions

## Security Features

- **Firebase Security Rules:** Database access control
- **Authentication:** Secure user authentication with multiple providers
- **Data Validation:** Input validation and sanitization
- **Role-based Access:** User permissions based on account type

## Performance Optimizations

- **Lazy Loading:** Images and data loaded on demand
- **Caching:** Local storage for frequently accessed data
- **Optimized Queries:** Efficient Firestore queries
- **Image Compression:** Optimized image sizes for faster loading

## Testing

### Manual Testing
- Authentication flow testing
- Order placement and management
- User role functionality
- Payment flow validation
- Cross-platform compatibility

### Automated Testing
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for critical flows

## Deployment

### Android
- Generate signed APK
- Upload to Google Play Store
- Configure Firebase for production

### Web
- Build web version
- Deploy to Firebase Hosting
- Configure custom domain

## Future Enhancements

### Planned Features
- **Push Notifications:** Real-time order updates
- **Payment Gateway:** Direct payment processing
- **Chat System:** Buyer-seller communication
- **Reviews & Ratings:** Product and seller reviews
- **Advanced Analytics:** Detailed sales and user analytics
- **Multi-language Support:** Localization for different regions

### Technical Improvements
- **Offline Support:** Offline data synchronization
- **Performance Optimization:** Further app optimization
- **Security Enhancements:** Additional security measures
- **Scalability:** Architecture improvements for growth

## Contributing

### Development Guidelines
- Follow Flutter best practices
- Use consistent code formatting
- Write comprehensive documentation
- Test thoroughly before submitting

### Code Standards
- Dart/Flutter linting rules
- Material Design guidelines
- Firebase security best practices
- Accessibility standards

## Support & Contact

### Technical Support
- **Documentation:** Comprehensive inline code documentation
- **Error Handling:** Detailed error messages and logging
- **Debug Mode:** Enhanced debugging capabilities

### User Support
- **In-app Help:** User guides and tutorials
- **FAQ Section:** Common questions and answers
- **Contact Information:** Support channels for users

## License

This project is developed for educational purposes as part of the academic assessment. All rights reserved.

---

**Developed by:** RegNo: 22RP03951  
**Project:** AgriConnect Mobile Application  
**Technology:** Flutter, Firebase, Google Sign-In  
**Version:** 1.0.0  
**Date:** 2025
