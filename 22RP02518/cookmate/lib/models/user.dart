import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String id;
  String name;
  String email;
  String role; // 'chef' or 'user'
  String? phone;
  String? location;
  String? emailAddress;

  static const List<String> roles = ['chef', 'user'];

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'user',
    this.phone,
    this.location,
    this.emailAddress,
  });

  static AppUser fromFirebaseUserAndData(User user, Map<String, dynamic>? data) {
    return AppUser(
      id: user.uid,
      name: data != null && data['name'] != null ? data['name'] as String : '',
      email: user.email ?? '',
      role: data != null && data['role'] != null ? data['role'] as String : 'user',
      phone: data != null && data['phone'] != null ? data['phone'] as String : null,
      location: data != null && data['location'] != null ? data['location'] as String : null,
      emailAddress: data != null && data['emailAddress'] != null ? data['emailAddress'] as String : null,
    );
  }
}

// Contact request model for chef analytics and management
enum ContactRequestStatus { pending, approved, rejected }

class ContactRequest {
  final String userId;
  final String chefId;
  ContactRequestStatus status;
  final DateTime timestamp;
  String? docId;

  ContactRequest({
    required this.userId,
    required this.chefId,
    this.status = ContactRequestStatus.pending,
    DateTime? timestamp,
    this.docId,
  }) : timestamp = timestamp ?? DateTime.now();
} 