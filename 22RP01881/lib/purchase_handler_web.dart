import 'package:flutter/material.dart';
import 'purchase_handler.dart';

class PurchaseHandlerImpl extends PurchaseHandler {
  @override
  void initialize() {}
  @override
  void dispose() {}
  @override
  Future<List<dynamic>> getProducts() async => [];
  @override
  Future<void> buy(dynamic product) async {
    debugPrint('In-app purchases are not supported on web.');
  }
  @override
  Future<bool> restorePurchases() async {
    debugPrint('Restore purchases not supported on web.');
    return false;
  }
  @override
  Future<bool> isPremium() async => false;
} 