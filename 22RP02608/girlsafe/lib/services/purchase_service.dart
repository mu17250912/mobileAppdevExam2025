import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/firebase_service.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../services/ad_service.dart';
import '../services/security_service.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;

  // Product IDs
  static const String _premiumMonthlyId = 'premium_monthly';
  static const String _premiumYearlyId = 'premium_yearly';
  static const String _premiumLifetimeId = 'premium_lifetime';

  // Getters
  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;

  // Initialize purchase service
  Future<void> initialize() async {
    // Check if in-app purchases are available
    _isAvailable = await _inAppPurchase.isAvailable();
    
    if (!_isAvailable) {
      print('In-app purchases not available');
      return;
    }

    // Set up purchase stream
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => print('Purchase stream error: $error'),
    );

    // Load products
    await _loadProducts();
  }

  // Load available products
  Future<void> _loadProducts() async {
    final Set<String> productIds = {
      _premiumMonthlyId,
      _premiumYearlyId,
      _premiumLifetimeId,
    };

    try {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        print('Products not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      print('Loaded ${_products.length} products');
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  // Get product by ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  // Purchase product
  Future<bool> purchaseProduct(String productId) async {
    if (!_isAvailable) {
      print('In-app purchases not available');
      return false;
    }

    final product = getProduct(productId);
    if (product == null) {
      print('Product not found: $productId');
      return false;
    }

    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      
      bool success = false;
      if (product.id.contains('subscription')) {
        success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        success = await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      }

      return success;
    } catch (e) {
      print('Error purchasing product: $e');
      return false;
    }
  }

  // Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _handlePurchase(purchaseDetails);
    }
  }

  // Handle individual purchase
  void _handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.pending) {
      print('Purchase pending: ${purchaseDetails.productID}');
    } else if (purchaseDetails.status == PurchaseStatus.purchased ||
               purchaseDetails.status == PurchaseStatus.restored) {
      print('Purchase successful: ${purchaseDetails.productID}');
      
      // Verify purchase
      if (await _verifyPurchase(purchaseDetails)) {
        await _activatePremium(purchaseDetails.productID);
      }
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      print('Purchase error: ${purchaseDetails.error}');
    } else if (purchaseDetails.status == PurchaseStatus.canceled) {
      print('Purchase canceled: ${purchaseDetails.productID}');
    }

    // Complete purchase
    if (purchaseDetails.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchaseDetails);
    }
  }

  // Verify purchase (basic implementation)
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // In a real app, you would verify the purchase with your backend
    // For now, we'll just check if the purchase details are valid
    return purchaseDetails.productID.isNotEmpty && 
           purchaseDetails.purchaseID != null;
  }

  // Activate premium based on product
  Future<void> _activatePremium(String productId) async {
    bool isPremium = false;
    DateTime? expiryDate;

    switch (productId) {
      case _premiumMonthlyId:
        isPremium = true;
        expiryDate = DateTime.now().add(const Duration(days: 30));
        break;
      case _premiumYearlyId:
        isPremium = true;
        expiryDate = DateTime.now().add(const Duration(days: 365));
        break;
      case _premiumLifetimeId:
        isPremium = true;
        expiryDate = null; // Lifetime
        break;
    }

    if (isPremium) {
      // Update local storage
      await LocalStorageService.setPremiumStatus(true);
      
      // Update Firebase
      await FirebaseService().updatePremiumStatus(true);
      
      print('Premium activated for product: $productId');
    }
  }

  // Restore purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      print('Error restoring purchases: $e');
    }
  }

  // Check if user has active premium
  Future<bool> hasActivePremium() async {
    // Check local storage first
    bool localPremium = await LocalStorageService.isPremium();
    if (localPremium) return true;

    // Check Firebase
    bool firebasePremium = await FirebaseService().getUserPremiumStatus();
    if (firebasePremium) {
      await LocalStorageService.setPremiumStatus(true);
      return true;
    }

    return false;
  }

  // Get premium products
  List<ProductDetails> getPremiumProducts() {
    return _products.where((product) => 
      product.id.contains('premium')
    ).toList();
  }

  // Format price
  String formatPrice(ProductDetails product) {
    return product.price;
  }

  // Get product description
  String getProductDescription(String productId) {
    switch (productId) {
      case _premiumMonthlyId:
        return 'Premium Monthly - Full access for 30 days';
      case _premiumYearlyId:
        return 'Premium Yearly - Full access for 1 year (Save 40%)';
      case _premiumLifetimeId:
        return 'Premium Lifetime - Full access forever';
      default:
        return 'Premium Access';
    }
  }

  // Dispose
  void dispose() {
    _subscription.cancel();
  }
} 

class PremiumPaymentDialog extends StatefulWidget {
  @override
  _PremiumPaymentDialogState createState() => _PremiumPaymentDialogState();
}

class _PremiumPaymentDialogState extends State<PremiumPaymentDialog> {
  final _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Shyiramo nimero yawe ya telefoni'),
      content: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          labelText: 'Mobile Number',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // TODO: Integrate payment logic here
            // After payment, update Firebase user as premium
            await FirebaseService().updateUserProfile({
              'isPremium': true,
              'phoneNumber': _phoneController.text.trim(),
            });
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Wabaye premium!')),
            );
            setState(() {}); // Refresh UI
          },
          child: Text('Pay & Upgrade'),
        ),
      ],
    );
  }
} 