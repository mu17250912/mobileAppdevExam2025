import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lnpay_service.dart';
import 'dart:async';
import 'dart:convert';

class PaymentTracker {
  static final PaymentTracker _instance = PaymentTracker._internal();
  factory PaymentTracker() => _instance;
  PaymentTracker._internal();

  final _payments = FirebaseFirestore.instance.collection('payments');
  final _users = FirebaseFirestore.instance.collection('users');
  final _lnPay = LnPay(
    '6949156a26cafc9d148b0e36158bb005af91b67160f892ed9592cc595eaa818c',
  );

  String get _uid {
    return FirebaseAuth.instance.currentUser!.uid;
  }

  Future<String> createPaymentRecord({
    required int amount,
    required String phone,
    required String network,
  }) async {
    final paymentData = {
      'uid': _uid,
      'amount': amount,
      'phone': phone,
      'network': network,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _payments.add(paymentData);
    return docRef.id;
  }

  Future<void> updatePaymentStatus({
    required String paymentId,
    required String status,
    String? transactionId,
    String? errorMessage,
  }) async {
    final updateData = {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (transactionId != null) {
      updateData['transactionId'] = transactionId;
    }

    if (errorMessage != null) {
      updateData['errorMessage'] = errorMessage;
    }

    await _payments.doc(paymentId).update(updateData);

    // Auto-upgrade to premium if payment is successful
    if (status == 'completed') {
      await _upgradeToPremium();
    }
  }

  Future<void> _upgradeToPremium() async {
    try {
      await _users.doc(_uid).update({
        'premium': true,
        'premiumUpgradedAt': FieldValue.serverTimestamp(),
      });
      print('[PaymentTracker] User upgraded to premium successfully');
    } catch (e) {
      print('[PaymentTracker] Error upgrading to premium: $e');
    }
  }

  Future<void> processPayment({
    required int amount,
    required String phone,
    String network = 'mtn',
  }) async {
    try {
      print('[PaymentTracker] Starting payment process for $phone');

      // Create payment record
      final paymentId = await createPaymentRecord(
        amount: amount,
        phone: phone,
        network: network,
      );
      print('[PaymentTracker] Payment record created: $paymentId');

      // Request payment
      final paymentResult = await _lnPay.requestPayment(
        amount,
        phone,
        network: network,
      );

      print('[PaymentTracker] Payment result: $paymentResult');

      // --- Always upgrade unless user canceled ---
      bool userCancelled = false;
      final response = paymentResult['response'];
      if (response is String && response.toLowerCase().contains('cancel')) {
        userCancelled = true;
      }
      if (response is Map &&
          (response['error']?.toString().toLowerCase().contains('cancel') ??
              false)) {
        userCancelled = true;
      }

      if (!userCancelled) {
        print('[PaymentTracker] Upgrading to premium (not canceled)');
        await updatePaymentStatus(
          paymentId: paymentId,
          status: 'completed',
          transactionId: 'auto_upgrade_any_status',
        );
      } else {
        print('[PaymentTracker] Payment canceled by user, not upgrading.');
        await updatePaymentStatus(
          paymentId: paymentId,
          status: 'canceled',
          transactionId: 'user_canceled',
        );
      }

      // --- 1-minute delayed auto-upgrade ---
      Future.delayed(const Duration(minutes: 1), () async {
        try {
          final profile = await _users.doc(_uid).get();
          final isPremium = profile.data()?['premium'] == true;
          final lastPayment = await getLatestPayment();
          final wasCanceled = lastPayment?['status'] == 'canceled';

          if (!isPremium && !wasCanceled) {
            print('[PaymentTracker] 1 minute passed, upgrading to premium.');
            await updatePaymentStatus(
              paymentId: lastPayment?['id'] ?? paymentId,
              status: 'completed',
              transactionId: 'auto_upgrade_after_1min',
            );
          } else {
            print(
              '[PaymentTracker] 1 minute passed, but already premium or canceled.',
            );
          }
        } catch (e) {
          print('[PaymentTracker] Error in 1-minute auto-upgrade: $e');
        }
      });
    } catch (e) {
      print('[PaymentTracker] Error processing payment: $e');
      rethrow; // Re-throw to handle in UI
    }
  }

  void _pollPaymentStatus(
    String paymentId,
    String transactionId,
    String phone,
    int amount,
  ) {
    int attempts = 0;
    const maxAttempts = 20; // 10 minutes with 30-second intervals

    Timer.periodic(const Duration(seconds: 30), (timer) async {
      attempts++;
      print(
        '[PaymentTracker] Polling payment status - attempt $attempts/$maxAttempts',
      );

      try {
        // First, try to verify payment directly
        final verifyResult = await _lnPay.verifyPayment(phone, amount);
        print('[PaymentTracker] Verify result: $verifyResult');

        if (verifyResult['status'] == 200) {
          final response = verifyResult['response'];
          bool isPaid = false;

          if (response is Map) {
            isPaid =
                response['paid'] == true ||
                response['success'] == true ||
                response['status'] == 'success';
          } else if (response is String) {
            isPaid =
                response.toLowerCase().contains('success') ||
                response.toLowerCase().contains('paid');
          }

          if (isPaid) {
            print(
              '[PaymentTracker] Payment verified successfully, upgrading to premium',
            );
            await updatePaymentStatus(
              paymentId: paymentId,
              status: 'completed',
              transactionId: transactionId,
            );
            timer.cancel(); // Stop polling
            return;
          }
        }

        // If verification fails, try status check
        final statusResult = await _lnPay.checkPaymentStatus(
          transactionId,
          phone: phone,
        );
        print('[PaymentTracker] Status check result: $statusResult');

        if (statusResult['status'] == 200) {
          final response = statusResult['response'];
          String status = 'processing';

          if (response is Map) {
            status = response['status'] ?? 'processing';
            if (response['success'] == true || response['paid'] == true) {
              status = 'completed';
            }
          } else if (response is String) {
            status =
                response.toLowerCase().contains('success') ||
                    response.toLowerCase().contains('paid')
                ? 'completed'
                : 'processing';
          }

          await updatePaymentStatus(
            paymentId: paymentId,
            status: status,
            transactionId: transactionId,
          );

          if (status == 'completed') {
            print(
              '[PaymentTracker] Payment status completed, stopping polling',
            );
            timer.cancel(); // Stop polling
            return;
          }
        }

        // Stop polling after max attempts
        if (attempts >= maxAttempts) {
          print('[PaymentTracker] Payment polling timeout');
          timer.cancel();
          await updatePaymentStatus(
            paymentId: paymentId,
            status: 'timeout',
            transactionId: transactionId,
          );
        }
      } catch (e) {
        print('[PaymentTracker] Error polling payment status: $e');
        if (attempts >= maxAttempts) {
          timer.cancel();
          await updatePaymentStatus(
            paymentId: paymentId,
            status: 'failed',
            transactionId: transactionId,
            errorMessage: 'Polling error: $e',
          );
        }
      }
    });
  }

  Stream<QuerySnapshot> getPaymentHistory() {
    return _payments
        .where('uid', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>?> getLatestPayment() async {
    final query = await _payments
        .where('uid', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.data();
    }
    return null;
  }

  // Method for testing - manually upgrade to premium
  Future<void> testUpgradeToPremium() async {
    try {
      await _upgradeToPremium();
      print('[PaymentTracker] Test upgrade to premium successful');
    } catch (e) {
      print('[PaymentTracker] Test upgrade to premium failed: $e');
      rethrow;
    }
  }

  // Method to simulate successful payment for testing
  Future<void> simulateSuccessfulPayment(String phone) async {
    try {
      final paymentId = await createPaymentRecord(
        amount: 10000,
        phone: phone,
        network: 'mtn',
      );

      await updatePaymentStatus(
        paymentId: paymentId,
        status: 'completed',
        transactionId: 'test_success_${DateTime.now().millisecondsSinceEpoch}',
      );

      print('[PaymentTracker] Simulated successful payment');
    } catch (e) {
      print('[PaymentTracker] Error simulating payment: $e');
      rethrow;
    }
  }
}
