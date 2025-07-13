import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetails {
  final String uid;
  final String fullName;
  final String email;
  final List<String> skillsOffered;
  final List<String> skillsToLearn;
  final String phone;
  final String availability;
  final String location;
  final bool isOnline;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserDetails({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.skillsOffered,
    required this.skillsToLearn,
    required this.phone,
    required this.availability,
    required this.location,
    required this.isOnline,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserDetails.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserDetails(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      skillsOffered: List<String>.from(data['skillsOffered'] ?? []),
      skillsToLearn: List<String>.from(data['skillsToLearn'] ?? []),
      phone: data['phone'] ?? '',
      availability: data['availability'] ?? 'Available',
      location: data['location'] ?? '',
      isOnline: data['isOnline'] ?? false,
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'skillsOffered': skillsOffered,
      'skillsToLearn': skillsToLearn,
      'phone': phone,
      'availability': availability,
      'location': location,
      'isOnline': isOnline,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserDetails copyWith({
    String? fullName,
    String? email,
    List<String>? skillsOffered,
    List<String>? skillsToLearn,
    String? phone,
    String? availability,
    String? location,
    bool? isOnline,
    String? photoUrl,
  }) {
    return UserDetails(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      skillsOffered: skillsOffered ?? this.skillsOffered,
      skillsToLearn: skillsToLearn ?? this.skillsToLearn,
      phone: phone ?? this.phone,
      availability: availability ?? this.availability,
      location: location ?? this.location,
      isOnline: isOnline ?? this.isOnline,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
