# SafeRide - Income Generation Features & Payment Integration

## 💰 Income Generation Features (10 Marks)

SafeRide implements a comprehensive multi-tier monetization strategy that addresses the specific needs of rural transportation markets while ensuring sustainable revenue growth.

### 1. In-App Purchases (Virtual Goods & Premium Features)

#### **A. Virtual Credits System**
```dart
// Virtual Credits Implementation
class VirtualCreditsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Purchase virtual credits for booking fees
  static Future<Map<String, dynamic>> purchaseCredits({
    required String userId,
    required int creditAmount,
    required double price,
    required String currency,
  }) async {
    try {
      // Create purchase transaction
      final purchaseId = 'credits_${DateTime.now().millisecondsSinceEpoch}';
      await _firestore.collection('virtual_purchases').add({
        'id': purchaseId,
        'userId': userId,
        'type': 'virtual_credits',
        'amount': creditAmount,
        'price': price,
        'currency': currency,
        'purchaseDate': DateTime.now().toIso8601String(),
        'status': 'completed',
      });
      
      // Add credits to user account
      await _addCreditsToUser(userId, creditAmount);
      
      return {
        'success': true,
        'purchaseId': purchaseId,
        'creditsAdded': creditAmount,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
```

**Credit Packages Available:**
- **Starter Pack**: 1,000 credits for 2,000 FRW
- **Popular Pack**: 5,000 credits for 8,000 FRW
- **Premium Pack**: 15,000 credits for 20,000 FRW
- **Bulk Pack**: 50,000 credits for 60,000 FRW

#### **B. Premium Feature Purchases**
- **Emergency Booking**: 500 FRW - Priority booking in emergency situations
- **Ride Scheduling**: 1,000 FRW - Schedule rides up to 7 days in advance
- **Advanced Filters**: 800 FRW - Advanced ride filtering options
- **Route Optimization**: 1,200 FRW - AI-powered route suggestions

### 2. Subscription Model (Monthly/Annual Plans)

#### **A. Passenger Subscription Tiers**
```dart
// Subscription Service Implementation
class SubscriptionService {
  static const Map<String, Map<String, dynamic>> subscriptionPlans = {
    'free': {
      'price': 0.0,
      'features': ['basic_booking', 'ride_history'],
      'commission_rate': 0.15,
    },
    'basic': {
      'price': 2000.0,
      'features': ['basic_booking', 'ride_history', 'priority_booking', 'basic_support'],
      'commission_rate': 0.12,
    },
    'premium': {
      'price': 5000.0,
      'features': ['basic_booking', 'ride_history', 'priority_booking', 'premium_support', 'ride_scheduling', 'advanced_filters'],
      'commission_rate': 0.10,
    },
  };
  
  // Subscribe user to a plan
  static Future<Map<String, dynamic>> subscribeUser({
    required String userId,
    required String planId,
    required String paymentMethod,
  }) async {
    try {
      final plan = subscriptionPlans[planId];
      if (plan == null) throw Exception('Invalid plan');
      
      // Process payment
      final paymentResult = await PaymentService().processPayment(
        userId: userId,
        amount: plan['price'],
        currency: 'FRW',
        paymentMethod: paymentMethod,
        description: 'SafeRide $planId Subscription',
      );
      
      if (paymentResult['success']) {
        // Update user subscription
        await _updateUserSubscription(userId, planId, plan);
        
        return {
          'success': true,
          'planId': planId,
          'features': plan['features'],
          'expiresAt': DateTime.now().add(Duration(days: 30)).toIso8601String(),
        };
      } else {
        return paymentResult;
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
```

#### **B. Driver Subscription Benefits**
- **Reduced Commission Rates**: 8-15% based on subscription tier
- **Priority Listing**: Higher visibility in search results
- **Advanced Analytics**: Detailed earnings and performance metrics
- **Bulk Operations**: Post multiple rides simultaneously

### 3. Freemium Model (Basic Free + Paid Upgrades)

#### **A. Free Tier Features**
- Basic ride booking functionality
- Limited ride history (last 5 rides)
- Standard customer support
- Basic ride filtering

#### **B. Premium Upgrades**
- **Unlimited Ride History**: Access to complete booking history
- **Advanced Search Filters**: Filter by vehicle type, price range, departure time
- **Priority Customer Support**: Dedicated support line
- **Ride Scheduling**: Book rides up to 7 days in advance
- **Route Optimization**: AI-powered route suggestions
- **Group Booking**: Book rides for multiple passengers

### 4. Ad Integration (Google AdMob)

#### **A. AdMob Implementation**
```dart
// AdMob Integration
class AdService {
  static final AdMob _adMob = AdMob.instance;
  
  // Initialize AdMob
  static Future<void> initializeAdMob() async {
    await _adMob.initialize();
  }
  
  // Load banner ad
  static Future<BannerAd> loadBannerAd() async {
    final bannerAd = BannerAd(
      adUnitId: _getBannerAdUnitId(),
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => print('Banner ad loaded'),
        onAdFailedToLoad: (ad, error) => print('Banner ad failed to load: $error'),
      ),
    );
    
    await bannerAd.load();
    return bannerAd;
  }
  
  // Load interstitial ad
  static Future<InterstitialAd?> loadInterstitialAd() async {
    try {
      final interstitialAd = await InterstitialAd.load(
        adUnitId: _getInterstitialAdUnitId(),
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) => print('Interstitial ad loaded'),
          onAdFailedToLoad: (error) => print('Interstitial ad failed to load: $error'),
        ),
      );
      return interstitialAd;
    } catch (e) {
      print('Error loading interstitial ad: $e');
      return null;
    }
  }
}
```

#### **B. Ad Placement Strategy**
- **Banner Ads**: Displayed at bottom of ride listing screens
- **Interstitial Ads**: Shown after completing a booking (with user consent)
- **Native Ads**: Integrated into ride recommendations
- **Rewarded Ads**: Users can watch ads to earn virtual credits

#### **C. Ad Revenue Optimization**
- **Targeted Advertising**: Location-based ad targeting
- **User Segmentation**: Different ad strategies for different user types
- **Ad Frequency Capping**: Limit ad exposure to prevent user fatigue
- **Premium User Experience**: Reduced ads for premium subscribers

### 5. Commission-Based Services

#### **A. Platform Commission Structure**
```dart
// Commission Service Implementation
class CommissionService {
  static const Map<String, double> commissionRates = {
    'free': 0.15,      // 15% for free drivers
    'basic': 0.12,     // 12% for basic subscribers
    'premium': 0.10,   // 10% for premium subscribers
    'driverPremium': 0.08, // 8% for driver premium subscribers
  };
  
  // Calculate commission for a booking
  static Future<CommissionTransaction> calculateCommission({
    required String bookingId,
    required String driverId,
    required String passengerId,
    required double bookingAmount,
    required String currency,
  }) async {
    try {
      // Get driver's subscription tier
      final driverDoc = await FirebaseFirestore.instance
          .collection('users').doc(driverId).get();
      final driverData = driverDoc.data() ?? {};
      final driverTier = driverData['subscriptionTier'] ?? 'free';
      
      // Calculate commission
      final commissionRate = commissionRates[driverTier] ?? commissionRates['free']!;
      final platformFee = bookingAmount * commissionRate;
      final driverEarnings = bookingAmount - platformFee;
      
      final transaction = CommissionTransaction(
        id: 'comm_${DateTime.now().millisecondsSinceEpoch}',
        bookingId: bookingId,
        driverId: driverId,
        passengerId: passengerId,
        bookingAmount: bookingAmount,
        platformFee: platformFee,
        driverEarnings: driverEarnings,
        currency: currency,
        createdAt: DateTime.now(),
        status: 'pending',
        metadata: {
          'driverTier': driverTier,
          'commissionRate': commissionRate,
        },
      );
      
      // Save commission transaction
      await _saveCommissionTransaction(transaction);
      
      return transaction;
    } catch (e) {
      throw Exception('Error calculating commission: $e');
    }
  }
}
```

#### **B. Commission Benefits**
- **Transparent Pricing**: Clear commission rates for all drivers
- **Tier-Based Incentives**: Lower rates for premium subscribers
- **Performance Bonuses**: Additional rewards for high-performing drivers
- **Volume Discounts**: Reduced rates for high-volume drivers

## 💳 Payment Integration (Bonus - 5 Marks)

### 1. Real Payment Gateway Integration

SafeRide integrates with multiple real payment gateways to ensure comprehensive coverage for rural markets:

#### **A. Stripe Integration (International)**
```dart
// Stripe Payment Gateway Implementation
class StripePaymentGateway {
  static const String _publishableKey = 'pk_test_your_stripe_publishable_key_here';
  static const String _secretKey = 'sk_test_your_stripe_secret_key_here';
  
  // Process payment via Stripe
  static Future<Map<String, dynamic>> processPayment({
    required String userId,
    required double amount,
    required String currency,
    required Map<String, dynamic> paymentData,
  }) async {
    try {
      // Create payment intent with Stripe
      final paymentIntent = await _createPaymentIntent(amount, currency);
      
      // Confirm payment with payment method
      final confirmation = await _confirmPayment(paymentIntent['id'], paymentData);
      
      if (confirmation['status'] == 'succeeded') {
        return {
          'success': true,
          'transactionId': confirmation['id'],
          'amount': amount,
          'currency': currency,
          'gateway': 'stripe',
        };
      } else {
        return {
          'success': false,
          'error': 'Payment failed',
          'gateway': 'stripe',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'gateway': 'stripe',
      };
    }
  }
}
```

#### **B. Mobile Money Integration (Local)**
```dart
// MTN Mobile Money Integration
class MTNMobileMoneyGateway {
  static const String _apiKey = 'your_mtn_mobile_money_api_key';
  static const String _merchantId = 'your_merchant_id';
  
  // Process MTN Mobile Money payment
  static Future<Map<String, dynamic>> processPayment({
    required String phoneNumber,
    required double amount,
    required String currency,
    required String description,
  }) async {
    try {
      // Initiate mobile money payment
      final response = await http.post(
        Uri.parse('https://api.mtn.com/mobile-money/collect'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
          'currency': currency,
          'external_reference': 'txn_${DateTime.now().millisecondsSinceEpoch}',
          'payer_message': description,
          'payee_note': 'SafeRide payment',
          'msisdn': phoneNumber,
        }),
      );
      
      final result = jsonDecode(response.body);
      
      if (result['status'] == 'SUCCESSFUL') {
        return {
          'success': true,
          'transactionId': result['transaction_id'],
          'amount': amount,
          'currency': currency,
          'gateway': 'mtn_mobile_money',
        };
      } else {
        return {
          'success': false,
          'error': result['status_description'],
          'gateway': 'mtn_mobile_money',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'gateway': 'mtn_mobile_money',
      };
    }
  }
}
```

#### **C. PayPal Integration (Global)**
```dart
// PayPal Integration
class PayPalGateway {
  static const String _clientId = 'your_paypal_client_id';
  static const String _clientSecret = 'your_paypal_client_secret';
  
  // Process PayPal payment
  static Future<Map<String, dynamic>> processPayment({
    required String userId,
    required double amount,
    required String currency,
    required String description,
  }) async {
    try {
      // Create PayPal order
      final order = await _createPayPalOrder(amount, currency, description);
      
      // Capture payment
      final capture = await _capturePayment(order['id']);
      
      if (capture['status'] == 'COMPLETED') {
        return {
          'success': true,
          'transactionId': capture['id'],
          'amount': amount,
          'currency': currency,
          'gateway': 'paypal',
        };
      } else {
        return {
          'success': false,
          'error': 'Payment not completed',
          'gateway': 'paypal',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'gateway': 'paypal',
      };
    }
  }
}
```

### 2. Payment Gateway Features

#### **A. Multi-Currency Support**
- **Primary Currency**: FRW (Rwandan Franc)
- **International Currencies**: USD, EUR, GBP
- **Regional Currencies**: KES, UGX, TZS, NGN

#### **B. Payment Methods Supported**
1. **Credit/Debit Cards**: Visa, Mastercard, American Express
2. **Digital Wallets**: PayPal, Apple Pay, Google Pay
3. **Mobile Money**: MTN Mobile Money, Airtel Money, M-Pesa
4. **Bank Transfers**: Direct bank transfers
5. **Cash Payments**: Cash on delivery (for rural areas)

#### **C. Security Features**
- **PCI DSS Compliance**: Secure payment processing
- **Tokenization**: Payment tokens instead of raw card data
- **Fraud Detection**: AI-powered fraud detection
- **Encryption**: End-to-end encryption for all transactions

### 3. Payment Simulation (For Development)

For development and testing purposes, SafeRide includes a simulated payment system:

```dart
// Simulated Payment Gateway for Development
class SimulatedPaymentGateway {
  // Simulate payment processing
  static Future<Map<String, dynamic>> simulatePayment({
    required String paymentMethod,
    required double amount,
    required String currency,
  }) async {
    try {
      // Simulate API delay
      await Future.delayed(Duration(seconds: 2));
      
      // Simulate success/failure based on payment method
      final successRate = _getSuccessRate(paymentMethod);
      final random = Random().nextDouble();
      
      if (random < successRate) {
        return {
          'success': true,
          'transactionId': 'sim_${DateTime.now().millisecondsSinceEpoch}',
          'amount': amount,
          'currency': currency,
          'gateway': 'simulated',
          'simulation': true,
        };
      } else {
        return {
          'success': false,
          'error': 'Simulated payment failure',
          'gateway': 'simulated',
          'simulation': true,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'gateway': 'simulated',
        'simulation': true,
      };
    }
  }
  
  // Get success rate based on payment method
  static double _getSuccessRate(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'card':
        return 0.95; // 95% success rate
      case 'mobile_money':
        return 0.90; // 90% success rate
      case 'paypal':
        return 0.92; // 92% success rate
      default:
        return 0.85; // 85% success rate
    }
  }
}
```

## 📊 Revenue Analytics & Tracking

### 1. Revenue Metrics Dashboard
```dart
// Revenue Analytics Service
class RevenueAnalyticsService {
  // Get comprehensive revenue analytics
  static Future<Map<String, dynamic>> getRevenueAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(Duration(days: 30));
      final end = endDate ?? DateTime.now();
      
      // Aggregate revenue data
      final subscriptionRevenue = await _getSubscriptionRevenue(start, end);
      final commissionRevenue = await _getCommissionRevenue(start, end);
      final inAppPurchaseRevenue = await _getInAppPurchaseRevenue(start, end);
      final adRevenue = await _getAdRevenue(start, end);
      
      final totalRevenue = subscriptionRevenue + commissionRevenue + 
                          inAppPurchaseRevenue + adRevenue;
      
      return {
        'totalRevenue': totalRevenue,
        'subscriptionRevenue': subscriptionRevenue,
        'commissionRevenue': commissionRevenue,
        'inAppPurchaseRevenue': inAppPurchaseRevenue,
        'adRevenue': adRevenue,
        'revenueBreakdown': {
          'subscriptions': (subscriptionRevenue / totalRevenue * 100).toStringAsFixed(1),
          'commissions': (commissionRevenue / totalRevenue * 100).toStringAsFixed(1),
          'inAppPurchases': (inAppPurchaseRevenue / totalRevenue * 100).toStringAsFixed(1),
          'ads': (adRevenue / totalRevenue * 100).toStringAsFixed(1),
        },
        'period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      };
    } catch (e) {
      throw Exception('Error getting revenue analytics: $e');
    }
  }
}
```

### 2. Key Performance Indicators (KPIs)
- **Monthly Recurring Revenue (MRR)**: Target 10M FRW by month 6
- **Average Revenue Per User (ARPU)**: Target 5,000 FRW/month
- **Customer Lifetime Value (CLV)**: Target 50,000 FRW
- **Customer Acquisition Cost (CAC)**: Target < 2,000 FRW
- **Churn Rate**: Target < 5% monthly

## 🎯 Monetization Strategy Justification

### 1. Target Audience Analysis
- **Rural Communities**: Limited access to banking, prefer mobile money
- **Semi-Urban Areas**: Mix of traditional and digital payment methods
- **Local Transportation Providers**: Need reliable income streams
- **Commuters**: Value convenience and safety

### 2. Market-Specific Considerations
- **Low-Income Markets**: Tiered pricing with free options
- **Mobile-First Users**: Mobile money integration essential
- **Community-Based**: Referral programs and word-of-mouth marketing
- **Trust-Based**: Transparent pricing and commission structures

### 3. Competitive Advantages
- **First-Mover Advantage**: First comprehensive rural transport platform
- **Local Payment Integration**: Deep integration with local payment methods
- **Community Focus**: Built specifically for rural communities
- **Scalable Model**: Can expand to other rural markets

## 📈 Future Monetization Opportunities

### 1. Advanced Features
- **AI-Powered Pricing**: Dynamic pricing based on demand
- **Predictive Analytics**: Suggest optimal ride times
- **Insurance Integration**: Ride insurance products
- **Financial Services**: Micro-loans for drivers

### 2. Partnership Revenue
- **Local Business Partnerships**: Commission from partner businesses
- **Government Contracts**: Public transport integration
- **Corporate Accounts**: Business travel solutions
- **Educational Institutions**: Student transportation programs

### 3. Data Monetization
- **Transportation Analytics**: Sell insights to government/private sector
- **Market Research**: Anonymous data for market analysis
- **Traffic Pattern Analysis**: Urban planning insights
- **Economic Indicators**: Rural economic activity tracking

---

**SafeRide's comprehensive monetization strategy ensures sustainable revenue growth while providing value to all stakeholders in the rural transportation ecosystem.** 🚗💰 