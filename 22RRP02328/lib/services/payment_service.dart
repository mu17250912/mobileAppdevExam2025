import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';
import '../utils/constants.dart';

class PaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create payment
  static Future<void> createPayment(PaymentModel payment) async {
    await _firestore
        .collection(AppConstants.paymentsCollection)
        .doc(payment.id)
        .set(payment.toJson());
  }

  // Get payments for a user
  static Future<List<PaymentModel>> getPaymentsForUser(String userId) async {
    final query = await _firestore
        .collection(AppConstants.paymentsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs.map((doc) => PaymentModel.fromJson(doc.data())).toList();
  }

  static Future<List<PaymentModel>> getAllPayments() async {
    final query = await _firestore
        .collection(AppConstants.paymentsCollection)
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs.map((doc) => PaymentModel.fromJson(doc.data())).toList();
  }
} 