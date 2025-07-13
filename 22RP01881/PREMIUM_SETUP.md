# SmartBudget Premium System Setup Guide

## Overview
SmartBudget now includes a complete premium system with real in-app purchases, subscription management, and feature restrictions. This guide will help you set up the premium system for production use.

## Features Included

### Premium Features
- ✅ Advanced Analytics & Reports
- ✅ Unlimited Categories (vs 5 for free users)
- ✅ Saving Goals & Tracking
- ✅ Smart Reminders
- ✅ AI Spending Insights
- ✅ Ad-Free Experience
- ✅ Multi-Device Sync
- ✅ Export Data
- ✅ Priority Support
- ✅ Custom Budgets

### Subscription Plans
1. **Monthly Plan**: $4.99/month
2. **Yearly Plan**: $39.99/year (Save 33%)
3. **Lifetime Plan**: $99.99 (One-time payment)

## Setup Instructions

### 1. App Store Connect Setup (iOS)

1. **Create In-App Purchase Products**:
   - Log into [App Store Connect](https://appstoreconnect.apple.com)
   - Go to your app → Features → In-App Purchases
   - Create the following products:

   ```
   Product ID: smartbudget_premium_monthly
   Type: Auto-Renewable Subscription
   Price: $4.99
   
   Product ID: smartbudget_premium_yearly
   Type: Auto-Renewable Subscription
   Price: $39.99
   
   Product ID: smartbudget_premium_lifetime
   Type: Non-Consumable
   Price: $99.99
   ```

2. **Configure Subscription Groups** (for monthly/yearly):
   - Create a subscription group called "SmartBudget Premium"
   - Add both monthly and yearly products to this group
   - Set up subscription levels and pricing

3. **Add Product Descriptions**:
   - Provide clear descriptions for each product
   - Include feature lists and benefits

### 2. Google Play Console Setup (Android)

1. **Create In-App Products**:
   - Log into [Google Play Console](https://play.google.com/console)
   - Go to your app → Monetize → Products → In-app products
   - Create the following products:

   ```
   Product ID: smartbudget_premium_monthly
   Type: Subscription
   Price: $4.99/month
   
   Product ID: smartbudget_premium_yearly
   Type: Subscription
   Price: $39.99/year
   
   Product ID: smartbudget_premium_lifetime
   Type: One-time purchase
   Price: $99.99
   ```

2. **Configure Subscription Details**:
   - Set up billing periods
   - Configure grace periods
   - Add subscription benefits

### 3. Firebase Configuration

1. **Update Security Rules**:
   Add the following to your Firestore security rules:

   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Users collection
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
       
       // Purchases collection
       match /purchases/{purchaseId} {
         allow read, write: if request.auth != null && 
           request.auth.uid == resource.data.userId;
       }
     }
   }
   ```

2. **Enable Firestore**:
   - Make sure Firestore is enabled in your Firebase project
   - The app will automatically create the necessary collections

### 4. Testing the Premium System

#### Development Testing
1. **Test Button**: Use the "Upgrade to Premium (Test)" button for development
2. **Restore Purchases**: Test purchase restoration functionality
3. **Feature Restrictions**: Verify free users are limited to 5 categories

#### Production Testing
1. **Sandbox Testing**: Use App Store Connect sandbox accounts
2. **TestFlight**: Distribute via TestFlight for iOS testing
3. **Internal Testing**: Use Google Play internal testing for Android

### 5. Code Structure

#### Key Files
- `lib/premium_screen.dart` - Main premium upgrade screen
- `lib/purchase_handler.dart` - Purchase management logic
- `lib/app_store_config.dart` - Product configuration
- `lib/dashboard_screen.dart` - Premium feature integration

#### Purchase Flow
1. User taps "Upgrade to Premium"
2. Premium screen shows subscription plans
3. User selects a plan
4. In-app purchase is initiated
5. Purchase is verified and user status is updated
6. Premium features are unlocked

### 6. Premium Feature Implementation

#### Category Limits
```dart
// Check if user can add more categories
if (!isPremium && userCategories.length >= 5) {
  // Show upgrade prompt
  showPremiumUpgradeDialog();
}
```

#### Feature Gating
```dart
// Check premium status before showing features
if (isPremium) {
  // Show premium features
} else {
  // Show upgrade prompt
}
```

### 7. Monitoring and Analytics

#### Firebase Analytics Events
Track the following events:
- `premium_upgrade_initiated`
- `premium_upgrade_completed`
- `premium_feature_used`
- `subscription_cancelled`

#### Revenue Tracking
- Monitor subscription revenue in App Store Connect/Google Play Console
- Track conversion rates from free to premium
- Analyze which subscription plans are most popular

### 8. Customer Support

#### Common Issues
1. **Purchase not recognized**: Use "Restore Purchases" button
2. **Subscription expired**: Check premium status and expiry dates
3. **Feature not working**: Verify premium status in Firestore

#### Support Tools
- Purchase restoration functionality
- Premium status verification
- Subscription management

### 9. Legal Requirements

#### Privacy Policy
Update your privacy policy to include:
- In-app purchase information
- Subscription terms
- Data collection for premium features

#### Terms of Service
Include:
- Subscription cancellation terms
- Refund policies
- Feature availability

### 10. Launch Checklist

- [ ] App Store Connect products configured
- [ ] Google Play Console products configured
- [ ] Firebase security rules updated
- [ ] Premium features tested
- [ ] Purchase flow tested
- [ ] Restore purchases tested
- [ ] Privacy policy updated
- [ ] Terms of service updated
- [ ] Customer support prepared

## Troubleshooting

### Common Issues

1. **"Store not available" error**:
   - Check if running on physical device (not emulator)
   - Verify app store accounts are properly configured

2. **Purchase not completing**:
   - Check network connection
   - Verify product IDs match exactly
   - Test with sandbox accounts

3. **Premium status not updating**:
   - Check Firestore permissions
   - Verify purchase handler is initialized
   - Check for errors in console

### Debug Mode
Enable debug logging by adding:
```dart
print('Purchase status: ${purchaseDetails.status}');
print('Product ID: ${purchaseDetails.productID}');
```

## Support

For technical support or questions about the premium system implementation, please refer to the code comments and documentation in the respective files.

---

**Note**: This premium system is production-ready but requires proper app store configuration and testing before launch. Always test thoroughly with sandbox accounts before releasing to production. 