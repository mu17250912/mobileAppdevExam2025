# BerwaStore In-App Purchase Setup Guide

This guide will help you set up in-app purchases for your BerwaStore Flutter app.

## 🎯 Overview

BerwaStore now supports in-app purchases for sellers to unlock premium features:

### Premium Features Available:
1. **Premium Analytics** (RWF 1,000)
   - Advanced sales reports
   - Stock forecasting
   - Customer analytics
   - Revenue trends

2. **Unlimited Products** (RWF 2,000)
   - No product limit
   - Bulk import/export
   - Advanced product categories
   - Product variants

3. **Remove Ads** (RWF 500)
   - No advertisements
   - Clean interface
   - Faster loading

4. **Export Reports** (RWF 800)
   - Excel export
   - PDF reports
   - Data backup
   - Custom reports

## 📱 Step-by-Step Implementation

### Step 1: Dependencies Added ✅
```yaml
dependencies:
  in_app_purchase: ^3.1.8
```

### Step 2: Android Configuration ✅
- Updated `android/app/build.gradle.kts` with `minSdk = 21`
- Added billing permission in `AndroidManifest.xml`

### Step 3: Google Play Console Setup

#### 3.1 Create Google Play Developer Account
1. Go to [Google Play Console](https://play.google.com/console)
2. Pay the one-time $25 registration fee
3. Complete account setup

#### 3.2 Create In-App Products
1. In Google Play Console, navigate to your app
2. Go to **Monetize** → **In-app products**
3. Click **Create product** for each premium feature:

**Product 1: Premium Analytics**
- Product ID: `premium_analytics`
- Type: **Managed Product**
- Price: RWF 1,000 (or equivalent in your currency)
- Status: **Active**

**Product 2: Unlimited Products**
- Product ID: `unlimited_products`
- Type: **Managed Product**
- Price: RWF 2,000
- Status: **Active**

**Product 3: Remove Ads**
- Product ID: `no_ads`
- Type: **Managed Product**
- Price: RWF 500
- Status: **Active**

**Product 4: Export Reports**
- Product ID: `export_reports`
- Type: **Managed Product**
- Price: RWF 800
- Status: **Active**

### Step 4: Firebase Integration ✅

The app automatically updates user's premium features in Firestore:

```dart
// When purchase is successful
await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .update({
  'premiumFeatures': FieldValue.arrayUnion([productId]),
  'lastPurchase': FieldValue.serverTimestamp(),
});
```

### Step 5: Testing In-App Purchases

#### 5.1 Test Accounts
1. Add test accounts in Google Play Console
2. Use these accounts to test purchases without real money

#### 5.2 Testing Process
1. Build and install the app on a test device
2. Sign in with a test Google account
3. Navigate to **Premium Features** in the seller dashboard
4. Try purchasing features
5. Verify features are unlocked in the app

## 🔧 Code Structure

### Services
- `lib/services/in_app_purchase_service.dart` - Handles all purchase logic

### Screens
- `lib/screens/premium_features_screen.dart` - Premium features marketplace
- `lib/screens/enhanced_analytics_screen.dart` - Analytics with premium features

### Integration Points
- Seller dashboard now includes "Premium Features" card
- Add product screen checks for unlimited products feature
- Analytics screen shows different content based on premium status

## 💡 Feature Implementation Examples

### 1. Product Limit Check
```dart
final hasUnlimitedProducts = await purchaseService.hasPremiumFeature('unlimited_products');
if (!hasUnlimitedProducts && productCount >= 5) {
  // Show upgrade prompt
}
```

### 2. Premium Analytics
```dart
final hasPremiumAnalytics = await purchaseService.hasPremiumFeature('premium_analytics');
if (hasPremiumAnalytics) {
  // Show advanced analytics
} else {
  // Show basic analytics with upgrade prompt
}
```

### 3. Ad Removal
```dart
final hasNoAds = await purchaseService.hasPremiumFeature('no_ads');
if (!hasNoAds) {
  // Show ads
}
```

## 🚀 Deployment Checklist

### Before Release:
- [ ] Test all premium features with test accounts
- [ ] Verify Google Play Console products are active
- [ ] Test purchase flow end-to-end
- [ ] Verify Firebase integration works
- [ ] Test feature unlocking after purchase
- [ ] Verify currency display (RWF)

### Production Release:
- [ ] Upload APK to Google Play Console
- [ ] Set up production signing
- [ ] Configure release build
- [ ] Test with real Google accounts
- [ ] Monitor purchase analytics

## 🔍 Troubleshooting

### Common Issues:

1. **"Product not found" error**
   - Verify product IDs match exactly in Google Play Console
   - Ensure products are active
   - Check test account has access

2. **Purchase not completing**
   - Verify billing permission is added
   - Check internet connection
   - Ensure Google Play Services is updated

3. **Features not unlocking**
   - Check Firebase connection
   - Verify user authentication
   - Check Firestore rules

### Debug Tips:
```dart
// Add debug prints to track purchase flow
debugPrint('Purchase initiated: $productId');
debugPrint('Purchase status: ${purchase.status}');
debugPrint('User premium features: $premiumFeatures');
```

## 📊 Analytics & Monitoring

### Track in Google Play Console:
- Purchase conversion rates
- Revenue per user
- Most popular features
- Refund rates

### Firebase Analytics:
- Feature usage patterns
- User engagement with premium features
- Conversion funnel analysis

## 🎉 Success Metrics

Monitor these key metrics:
- **Conversion Rate**: % of users who purchase premium features
- **ARPU**: Average Revenue Per User
- **Feature Adoption**: Which premium features are most popular
- **Retention**: Do premium users stay longer?

## 📞 Support

For technical support:
1. Check Flutter in_app_purchase documentation
2. Review Google Play Console help articles
3. Test with different devices and accounts
4. Monitor Firebase logs for errors

---

**Note**: This implementation uses RWF (Rwandan Franc) as the currency. Adjust prices and currency display according to your target market. 