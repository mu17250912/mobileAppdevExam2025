import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Conditional import for in_app_purchase
// ignore: uri_does_not_exist
import 'purchase_handler_mobile.dart' if (dart.library.html) 'purchase_handler_web.dart';

abstract class PurchaseHandler {
  void initialize();
  void dispose();
  Future<List<dynamic>> getProducts();
  Future<void> buy(dynamic product);
  Future<bool> restorePurchases();
  Future<bool> isPremium();
}

PurchaseHandler getPurchaseHandler() => PurchaseHandlerImpl(); 