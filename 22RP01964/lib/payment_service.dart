import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentService {
  static const String apiId = "HDEV-2f7b3554-eb27-477b-8ebb-2ca799f03412-ID";
  static const String apiKey = "HDEV-28407ece-5d24-438d-a9e8-73105c905a7d-KEY";
  static const String apiUrl =
      "https://payment.hdevtech.cloud/api_pay/api/$apiId/$apiKey";

  /// Initiates a payment request to the HDEV API and stores it in Firestore.
  static Future<Map<String, dynamic>> initiatePayment({
    required String tel,
    required String amount,
  }) async {
    String txRef = "TX- 2${DateTime.now().millisecondsSinceEpoch}";
    final response = await http.post(
      Uri.parse(apiUrl),
      body: {
        'ref': 'pay',
        'tel': tel,
        'tx_ref': txRef,
        'amount': amount,
        'link': 'tracklost.rw',
      },
    );
    final data = json.decode(response.body);
    if (data['status'] == 'success') {
      await FirebaseFirestore.instance.collection('payments').doc(txRef).set({
        'amount': amount,
        'payment_gateway': 'MoMo MTN',
        'tx_ref': txRef,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'tel': tel,
      });
      return {
        'success': true,
        'tx_ref': txRef,
        'message': 'Please confirm payment on your phone.',
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Payment initiation failed.',
      };
    }
  }

  /// Polls the HDEV API for payment status and updates Firestore accordingly.
  static Future<String> pollPaymentStatus(
    String txRef, {
    Function(String status)? onStatus,
  }) async {
    const pollInterval = Duration(seconds: 5);
    bool done = false;
    String statusMessage = '';
    while (!done) {
      await Future.delayed(pollInterval);
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'ref': 'read', 'tx_ref': txRef},
      );
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        await FirebaseFirestore.instance
            .collection('payments')
            .doc(txRef)
            .update({'status': 'paid'});
        statusMessage = '✅ Payment successful!';
        onStatus?.call('paid');
        done = true;
      } else if (data['status'] == 'pending') {
        statusMessage = 'Please confirm payment on your phone...';
        onStatus?.call('pending');
      } else {
        await FirebaseFirestore.instance
            .collection('payments')
            .doc(txRef)
            .update({'status': 'failed'});
        statusMessage = '❌ Payment failed or cancelled.';
        onStatus?.call('failed');
        done = true;
      }
    }
    return statusMessage;
  }

  /// After payment, update property status, calculate commission, and record transactions for owner and admin.
  static Future<void> handlePostPayment({
    required String propertyId,
    required String propertyType,
    required double price,
    required String ownerId,
    required String txRef,
    required String buyerId,
  }) async {
    // 1. Update property status
    String newStatus = propertyType == 'rent' ? 'rented' : 'sold';
    await FirebaseFirestore.instance
        .collection('properties')
        .doc(propertyId)
        .update({'status': newStatus});
    // 2. Calculate commission and net amount
    double commission = price * 0.02;
    double ownerNet = price - commission;
    // 2.5 Fetch property title
    String propertyTitle = '';
    final propertyDoc = await FirebaseFirestore.instance
        .collection('properties')
        .doc(propertyId)
        .get();
    if (propertyDoc.exists) {
      propertyTitle = propertyDoc.data()?['title'] ?? '';
    }
    // 3. Record transactions for owner and admin
    final now = DateTime.now();
    await FirebaseFirestore.instance.collection('transactions').add({
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'txRef': txRef,
      'type': propertyType,
      'amount': price,
      'commission': commission,
      'ownerNet': ownerNet,
      'ownerId': ownerId,
      'buyerId': buyerId,
      'adminId': 'admin', // or your admin UID
      'status': newStatus,
      'createdAt': now,
    });
    // 3.5 Create notification for buyer
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': buyerId,
      'title': propertyType == 'rent'
          ? 'Booking Confirmed'
          : 'Purchase Confirmed',
      'message':
          'Your ${propertyType == 'rent' ? 'booking' : 'purchase'} for "$propertyTitle" was successful.',
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'txRef': txRef,
      'type': propertyType,
      'status': 'unread',
      'createdAt': now,
    });
    // Optionally, notify the owner as well
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': ownerId,
      'title': propertyType == 'rent'
          ? 'Your Property Was Rented'
          : 'Your Property Was Sold',
      'message':
          'Your property "$propertyTitle" has been ${propertyType == 'rent' ? 'rented' : 'sold'}.',
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'txRef': txRef,
      'type': propertyType,
      'status': 'unread',
      'createdAt': now,
    });
    // 4. Optionally, update owner's wallet/earnings
    await FirebaseFirestore.instance.collection('users').doc(ownerId).set({
      'walletBalance': FieldValue.increment(ownerNet),
      'totalEarnings': FieldValue.increment(ownerNet),
    }, SetOptions(merge: true));
    // 5. Optionally, update admin's wallet/earnings
    await FirebaseFirestore.instance.collection('admin').doc('platform').set({
      'walletBalance': FieldValue.increment(commission),
      'totalEarnings': FieldValue.increment(commission),
    }, SetOptions(merge: true));
  }
}
