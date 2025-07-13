// import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'purchase_handler.dart';

// Temporary stub classes to replace in_app_purchase
class InAppPurchase {
  static InAppPurchase get instance => InAppPurchase();
  Stream<List<PurchaseDetails>> get purchaseStream => Stream.empty();
  Future<dynamic> queryProductDetails(Set<String> productIds) async => null;
  Future<void> buyNonConsumable({required dynamic purchaseParam}) async {}
  Future<void> buyConsumable({required dynamic purchaseParam}) async {}
  Future<void> restorePurchases() async {}
  Future<void> completePurchase(PurchaseDetails purchase) async {}
}

class PurchaseDetails {
  final String productID;
  final String purchaseID;
  final double rawPrice;
  final String currencyCode;
  final PurchaseStatus status;
  final bool pendingCompletePurchase;
  
  PurchaseDetails({
    required this.productID,
    required this.purchaseID,
    required this.rawPrice,
    required this.currencyCode,
    required this.status,
    required this.pendingCompletePurchase,
  });
}

class PurchaseStatus {
  static const purchased = PurchaseStatus._('purchased');
  static const restored = PurchaseStatus._('restored');
  
  const PurchaseStatus._(this.value);
  final String value;
}

class PurchaseParam {
  final dynamic productDetails;
  PurchaseParam({required this.productDetails});
}

class PurchaseHandlerImpl extends PurchaseHandler {
  static const String monthlyProductId = 'smartbudget_premium_monthly';
  static const String yearlyProductId = 'smartbudget_premium_yearly';
  static const String lifetimeProductId = 'smartbudget_premium_lifetime';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<List<PurchaseDetails>> _subscription;

  PurchaseHandlerImpl() {
    _subscription = _inAppPurchase.purchaseStream;
    _subscription.listen(_onPurchaseUpdate);
  }

  @override
  void initialize() {
    // Initialize the purchase handler
  }

  @override
  void dispose() {
    // Clean up resources if needed
  }

  @override
  Future<List<dynamic>> getProducts() async {
    try {
      final response = await _inAppPurchase.queryProductDetails({
        monthlyProductId, 
        yearlyProductId, 
        lifetimeProductId
      });
      return response.productDetails;
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  @override
  Future<void> buy(dynamic product) async {
    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      if (product.id == lifetimeProductId) {
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      print('Error making purchase: $e');
      rethrow;
    }
  }

  @override
  Future<bool> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      return true;
    } catch (e) {
      print('Error restoring purchases: $e');
      return false;
    }
  }

  @override
  Future<bool> isPremium() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      final isPremium = data['isPremium'] ?? false;
      if (!isPremium) return false;
      
      final subscriptionType = data['subscriptionType'];
      if (subscriptionType != 'lifetime') {
        final expiryDate = data['premiumExpiryDate'] as Timestamp?;
        if (expiryDate != null && DateTime.now().isAfter(expiryDate.toDate())) {
          await _firestore.collection('users').doc(user.uid).update({
            'isPremium': false,
            'subscriptionType': null,
            'premiumExpiryDate': null,
          });
          return false;
        }
      }
      return true;
    } catch (e) {
      print('Error checking premium status: $e');
      return false;
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased || 
          purchase.status == PurchaseStatus.restored) {
        await _handleSuccessfulPurchase(purchase);
      }
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      String subscriptionType = 'premium';
      DateTime? expiryDate;
      
      switch (purchase.productID) {
        case monthlyProductId:
          subscriptionType = 'monthly';
          expiryDate = DateTime.now().add(const Duration(days: 30));
          break;
        case yearlyProductId:
          subscriptionType = 'yearly';
          expiryDate = DateTime.now().add(const Duration(days: 365));
          break;
        case lifetimeProductId:
          subscriptionType = 'lifetime';
          expiryDate = null;
          break;
      }
      
      // Update user's premium status
      await _firestore.collection('users').doc(user.uid).update({
        'isPremium': true,
        'subscriptionType': subscriptionType,
        'premiumSince': FieldValue.serverTimestamp(),
        'premiumExpiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate) : null,
        'lastPurchaseDate': FieldValue.serverTimestamp(),
        'purchaseToken': purchase.purchaseID,
        'productId': purchase.productID,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Record the purchase transaction
      await _firestore.collection('purchases').add({
        'userId': user.uid,
        'productId': purchase.productID,
        'subscriptionType': subscriptionType,
        'purchaseDate': FieldValue.serverTimestamp(),
        'purchaseToken': purchase.purchaseID,
        'amount': purchase.rawPrice,
        'currency': purchase.currencyCode,
        'status': 'completed',
        'platform': 'mobile',
      });
      
      print('Purchase completed successfully: ${purchase.productID}');
    } catch (e) {
      print('Error handling successful purchase: $e');
    }
  }
} 