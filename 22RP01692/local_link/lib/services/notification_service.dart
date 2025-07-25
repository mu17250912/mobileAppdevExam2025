import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Send notification to provider when user makes a booking
  static Future<void> sendBookingNotification({
    required String providerId,
    required String userId,
    required String userName,
    required String serviceType,
    required String location,
    required DateTime dateTime,
    required double price,
    String? notes,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(providerId)
          .collection('notifications')
          .add({
        'type': 'booking',
        'title': 'New Booking Request',
        'message': '$userName has requested a $serviceType service on ${_formatDate(dateTime)} at $location',
        'userId': userId,
        'userName': userName,
        'serviceType': serviceType,
        'location': location,
        'dateTime': Timestamp.fromDate(dateTime),
        'price': price,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'action': 'view_booking',
      });
    } catch (e) {
      print('Error sending booking notification: $e');
    }
  }

  // Send notification when user makes a payment
  static Future<void> sendPaymentNotification({
    required String providerId,
    required String userId,
    required String userName,
    required String serviceType,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(providerId)
          .collection('notifications')
          .add({
        'type': 'payment',
        'title': 'Payment Received',
        'message': 'Payment of ${amount.toInt()} FRW received from $userName for $serviceType service via $paymentMethod',
        'userId': userId,
        'userName': userName,
        'serviceType': serviceType,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'action': 'view_payment',
      });
    } catch (e) {
      print('Error sending payment notification: $e');
    }
  }

  // Send notification when user submits a service request
  static Future<void> sendServiceRequestNotification({
    required String providerId,
    required String userId,
    required String userName,
    required String serviceCategory,
    required String title,
    required String description,
    required String urgency,
    String? budget,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(providerId)
          .collection('notifications')
          .add({
        'type': 'service_request',
        'title': 'New Service Request',
        'message': '$userName has submitted a $urgency priority request for $serviceCategory: $title',
        'userId': userId,
        'userName': userName,
        'serviceCategory': serviceCategory,
        'title': title,
        'description': description,
        'urgency': urgency,
        'budget': budget,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'action': 'view_service_request',
      });
    } catch (e) {
      print('Error sending service request notification: $e');
    }
  }

  // Send notification when user purchases premium features
  static Future<void> sendPremiumPurchaseNotification({
    required String providerId,
    required String userId,
    required String userName,
    required String featureName,
    required double amount,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(providerId)
          .collection('notifications')
          .add({
        'type': 'premium_purchase',
        'title': 'Premium Feature Purchase',
        'message': '$userName has purchased $featureName for ${amount.toInt()} FRW',
        'userId': userId,
        'userName': userName,
        'featureName': featureName,
        'amount': amount,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'action': 'view_premium_purchase',
      });
    } catch (e) {
      print('Error sending premium purchase notification: $e');
    }
  }

  // Send notification when user subscribes to a plan
  static Future<void> sendSubscriptionNotification({
    required String providerId,
    required String userId,
    required String userName,
    required String planName,
    required double amount,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(providerId)
          .collection('notifications')
          .add({
        'type': 'subscription',
        'title': 'New Subscription',
        'message': '$userName has subscribed to $planName plan for ${amount.toInt()} FRW',
        'userId': userId,
        'userName': userName,
        'planName': planName,
        'amount': amount,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'action': 'view_subscription',
      });
    } catch (e) {
      print('Error sending subscription notification: $e');
    }
  }

  // Send notification when user sends a message
  static Future<void> sendMessageNotification({
    required String providerId,
    required String userId,
    required String userName,
    required String message,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(providerId)
          .collection('notifications')
          .add({
        'type': 'message',
        'title': 'New Message',
        'message': '$userName: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}',
        'userId': userId,
        'userName': userName,
        'fullMessage': message,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'action': 'open_chat',
      });
    } catch (e) {
      print('Error sending message notification: $e');
    }
  }

  // Send notification when user rates a service
  static Future<void> sendRatingNotification({
    required String providerId,
    required String userId,
    required String userName,
    required int rating,
    String? review,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(providerId)
          .collection('notifications')
          .add({
        'type': 'rating',
        'title': 'New Rating',
        'message': '$userName has rated your service ${rating}/5 stars',
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'review': review,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'action': 'view_rating',
      });
    } catch (e) {
      print('Error sending rating notification: $e');
    }
  }

  // Send notification when user cancels a booking
  static Future<void> sendBookingCancellationNotification({
    required String providerId,
    required String userId,
    required String userName,
    required String serviceType,
    required DateTime dateTime,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(providerId)
          .collection('notifications')
          .add({
        'type': 'cancellation',
        'title': 'Booking Cancelled',
        'message': '$userName has cancelled their $serviceType booking for ${_formatDate(dateTime)}',
        'userId': userId,
        'userName': userName,
        'serviceType': serviceType,
        'dateTime': Timestamp.fromDate(dateTime),
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'action': 'view_cancellation',
      });
    } catch (e) {
      print('Error sending cancellation notification: $e');
    }
  }

  // Send notification when user reschedules a booking
  static Future<void> sendRescheduleNotification({
    required String providerId,
    required String userId,
    required String userName,
    required String serviceType,
    required DateTime oldDateTime,
    required DateTime newDateTime,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(providerId)
          .collection('notifications')
          .add({
        'type': 'reschedule',
        'title': 'Booking Rescheduled',
        'message': '$userName has rescheduled their $serviceType booking from ${_formatDate(oldDateTime)} to ${_formatDate(newDateTime)}',
        'userId': userId,
        'userName': userName,
        'serviceType': serviceType,
        'oldDateTime': Timestamp.fromDate(oldDateTime),
        'newDateTime': Timestamp.fromDate(newDateTime),
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'action': 'view_reschedule',
      });
    } catch (e) {
      print('Error sending reschedule notification: $e');
    }
  }

  // Send notification when user adds funds to virtual balance
  static Future<void> sendBalanceAddedNotification({
    required String providerId,
    required String userId,
    required String userName,
    required double amount,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(providerId)
          .collection('notifications')
          .add({
        'type': 'balance_added',
        'title': 'Balance Added',
        'message': '$userName has added ${amount.toInt()} FRW to their virtual balance',
        'userId': userId,
        'userName': userName,
        'amount': amount,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'action': 'view_balance',
      });
    } catch (e) {
      print('Error sending balance notification: $e');
    }
  }

  // Send notification when user updates their profile
  static Future<void> sendProfileUpdateNotification({
    required String providerId,
    required String userId,
    required String userName,
    required List<String> updatedFields,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(providerId)
          .collection('notifications')
          .add({
        'type': 'profile_update',
        'title': 'Profile Updated',
        'message': '$userName has updated their profile: ${updatedFields.join(', ')}',
        'userId': userId,
        'userName': userName,
        'updatedFields': updatedFields,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'action': 'view_profile',
      });
    } catch (e) {
      print('Error sending profile update notification: $e');
    }
  }

  // Send notification to all providers when user registers
  static Future<void> sendNewUserNotification({
    required String userId,
    required String userName,
    required String email,
  }) async {
    try {
      // Get all providers
      final providersSnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'provider')
          .get();

      // Send notification to each provider
      for (final providerDoc in providersSnapshot.docs) {
        await _db
            .collection('users')
            .doc(providerDoc.id)
            .collection('notifications')
            .add({
          'type': 'new_user',
          'title': 'New User Registered',
          'message': '$userName has joined Local Link',
          'userId': userId,
          'userName': userName,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
          'action': 'view_user',
        });
      }
    } catch (e) {
      print('Error sending new user notification: $e');
    }
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String providerId, String notificationId) async {
    try {
      await _db
          .collection('users')
          .doc(providerId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Get unread notification count for provider
  static Stream<int> getUnreadNotificationCount(String providerId) {
    return _db
        .collection('users')
        .doc(providerId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Helper method to format date
  static String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 