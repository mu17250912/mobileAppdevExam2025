import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // Helper to safely parse numbers from Firestore
  num _parseNum(dynamic value) {
    if (value is num) return value;
    if (value is String) {
      // Remove commas, handle k/m suffixes, etc.
      final cleaned = value.replaceAll(',', '').toLowerCase();
      if (cleaned.endsWith('k')) {
        final n = num.tryParse(cleaned.replaceAll('k', ''));
        if (n != null) return n * 1000;
      }
      if (cleaned.endsWith('m')) {
        final n = num.tryParse(cleaned.replaceAll('m', ''));
        if (n != null) return n * 1000000;
      }
      return num.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  final CollectionReference borrowers = FirebaseFirestore.instance.collection('borrowers');
  final CollectionReference loans = FirebaseFirestore.instance.collection('loans');
  final CollectionReference payments = FirebaseFirestore.instance.collection('payments');
  final CollectionReference notifications = FirebaseFirestore.instance.collection('notifications');

  // Borrower operations
  Future<void> addBorrower(Map<String, dynamic> borrowerData) async {
    await borrowers.add({
      ...borrowerData,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
    });
  }

  Future<List<Map<String, dynamic>>> getBorrowers() async {
    final snapshot = await borrowers.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<Map<String, dynamic>?> getBorrower(String borrowerId) async {
    final doc = await borrowers.doc(borrowerId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }
    return null;
  }

  Future<void> updateBorrower(String borrowerId, Map<String, dynamic> data) async {
    await borrowers.doc(borrowerId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteBorrower(String borrowerId) async {
    await borrowers.doc(borrowerId).delete();
  }

  // Loan operations
  Future<void> addLoan(Map<String, dynamic> loanData) async {
    await loans.add({
      ...loanData,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
      'totalPaid': 0.0,
      'remainingAmount': loanData['amount'],
    });
  }

  Future<List<Map<String, dynamic>>> getLoans() async {
    final snapshot = await loans.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      // Defensive parsing for numeric fields
      data['amount'] = _parseNum(data['amount']);
      data['remainingAmount'] = _parseNum(data['remainingAmount']);
      data['totalPaid'] = _parseNum(data['totalPaid']);
      data['interestRate'] = _parseNum(data['interestRate']);
      data['term'] = _parseNum(data['term']);
      return data;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getLoansByBorrower(String borrowerId) async {
    final snapshot = await loans
        .where('borrowerId', isEqualTo: borrowerId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> updateLoan(String loanId, Map<String, dynamic> data) async {
    await loans.doc(loanId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Payment operations
  Future<void> addPayment(Map<String, dynamic> paymentData) async {
    await payments.add({
      ...paymentData,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'completed',
    });

    // Update loan remaining amount
    final loanId = paymentData['loanId'];
    final amount = paymentData['amount'];
    
    final loanDoc = await loans.doc(loanId).get();
    if (loanDoc.exists) {
      final loanData = loanDoc.data() as Map<String, dynamic>;
      final currentRemaining = loanData['remainingAmount'] ?? 0.0;
      final currentTotalPaid = loanData['totalPaid'] ?? 0.0;
      
      await loans.doc(loanId).update({
        'remainingAmount': currentRemaining - amount,
        'totalPaid': currentTotalPaid + amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getPayments() async {
    final snapshot = await payments.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getPaymentsByLoan(String loanId) async {
    final snapshot = await payments
        .where('loanId', isEqualTo: loanId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // Notification operations
  Future<void> addNotification(Map<String, dynamic> notificationData) async {
    await notifications.add({
      ...notificationData,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final snapshot = await notifications.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await notifications.doc(notificationId).update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllNotificationsAsRead() async {
    final batch = FirebaseFirestore.instance.batch();
    final unreadNotifications = await notifications.where('read', isEqualTo: false).get();
    
    for (var doc in unreadNotifications.docs) {
      batch.update(doc.reference, {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();
  }

  // Analytics methods
  Future<Map<String, dynamic>> getAnalytics() async {
    final borrowersSnapshot = await borrowers.get();
    final loansSnapshot = await loans.get();
    final paymentsSnapshot = await payments.get();
    
    double totalLoaned = 0;
    double totalCollected = 0;
    
    for (var doc in loansSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalLoaned += (data['amount'] ?? 0.0);
    }
    
    for (var doc in paymentsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalCollected += (data['amount'] ?? 0.0);
    }
    
    return {
      'totalBorrowers': borrowersSnapshot.docs.length,
      'totalLoans': loansSnapshot.docs.length,
      'totalLoaned': totalLoaned,
      'totalCollected': totalCollected,
      'outstandingAmount': totalLoaned - totalCollected,
    };
  }
} 