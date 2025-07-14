import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  List<PaymentModel> _payments = [];
  bool _isLoading = false;
  String? _error;

  List<PaymentModel> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPayments(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _payments = await PaymentService.getPaymentsForUser(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createPayment(PaymentModel payment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await PaymentService.createPayment(payment);
      _payments.insert(0, payment);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllPayments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _payments = await PaymentService.getAllPayments();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 